class TwilioWebhookService

  # @param webhook_params [Hash] The parameters received from Twilio webhook
  # @param conversations_service [TwilioConversationsService] The service to handle conversation operations
  # @param webhook_params [Hash] The parameters received from Twilio webhook
  #   For onMessageAdded:
  #     - MessageSid [String] The unique ID of the message
  #     - ConversationSid [String] The unique ID of the conversation
  #     - Author [String] The phone number of the message sender (with whatsapp: prefix)
  #     - Body [String] The text content of the message
  #     - MediaUrl0 [String] URL of the first media attachment (if any)
  #     - EventType [String] Will be 'onMessageAdded'
  # @param conversations_service [TwilioConversationsService] The service to handle conversation operations
  def initialize(webhook_params, conversations_service = TwilioConversationsService.new)
    Rails.logger.info "[TwilioWebhookService] params keys: #{webhook_params.inspect}"
    @webhook_params = webhook_params
    @conversations_service = conversations_service
    @message_sid = webhook_params['MessageSid']
    @conversation_sid = webhook_params['ConversationSid']
    @author = webhook_params['Author']&.gsub('whatsapp:', '')
    @message_content = webhook_params['Body']

    # Parse Media JSON string if present
    # The Media field is a JSON string not a hash
    @media_sid = nil
    if webhook_params['Media'].present?
      begin
        media_array = JSON.parse(webhook_params['Media'])
        @media_sid = media_array.first&.dig('Sid') if media_array.any?
        @filename = media_array.first&.dig('Filename')
        Rails.logger.info "Parsed media SID: #{@media_sid}"
      rescue JSON::ParserError => e
        Rails.logger.error "Failed to parse Media JSON: #{e.message}"
        Rails.logger.error "Media content: #{webhook_params['Media']}"
      end
    end

    @state = webhook_params['State']
  end

  # Main entry point to route webhook to appropriate job
  # @return [Hash] The result of routing the webhook
  # @raise [TwilioWebhookError] If the webhook routing fails
  def route
    Rails.logger.info "Routing Twilio webhook: #{@webhook_params.inspect}"

    case @webhook_params['EventType']
    when 'onMessageAdded'
      process_message_webhook
    when 'onConversationStateUpdated', 'onConversationUpdated'
      process_conversation_state_updated_webhook
    when 'onParticipantAdded'
      # For now, we'll ignore participant events or handle them separately
      Rails.logger.info "Ignoring participant event: #{@webhook_params['EventType']}"
      { status: 'ignored', reason: 'participant_event' }
    else
      Rails.logger.warn "Unhandled webhook event type: #{@webhook_params['EventType']}"
      { status: 'ignored', reason: 'unhandled_event_type' }
    end
  rescue StandardError => e
    Rails.logger.error "Error routing webhook: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise TwilioWebhookError, "Failed to route webhook: #{e.message}"
  end

  # Process message webhook (called by TwilioInboundMessageJob)
  # @return [Hash] The result of processing the message
  # @raise [TwilioWebhookError] If the message processing fails
  def process_message
    Rails.logger.info "Processing message: #{@message_sid}"

    # Find or create conversation
    conversation = Conversation.find_or_create_from_webhook(
      provider_conversation_id: @conversation_sid,
      customer_phone_number: @author
    )

    # Associate conversation with human if exists
    if conversation.human.nil?
      human = Human.find_by_phone_number(@author)
      conversation.associate_with_human(human) if human.present?
    end

    # Create message body with media link if media is present
    message_body = create_message_body_with_media

    Rails.logger.info "Creating inbound message for conversation #{conversation.id}"
    # Create message record
    message = Message.create!(
      conversation: conversation,
      provider_message_id: @message_sid,
      body: message_body,
      direction: :inbound,
      sent_at: Time.current,
      media_url: @media_url
    )
    Rails.logger.info "Created inbound message #{message.id}"

    # Enqueue the job to send the notification
    TwilioNotificationJob.perform_later(conversation.id, message.id)
    Rails.logger.info "Enqueued Twilio notification job for conversation #{conversation.id} and message #{message.id}"

    # Update conversation's last_message_at
    conversation.update!(last_message_at: message.sent_at)

    # Broadcast the message
    channel = "#{conversation.id}"
    Rails.logger.info "Broadcasting message #{message.id} to #{channel}"
    message.broadcast_append_to channel,
                              target: "messages",
                              partial: "admin/messages/message",
                              locals: { message: message }
    Rails.logger.info "Message #{message.id} broadcasted to #{channel}"

    { status: 'success', message_id: message.id }
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create message: #{e.message}"
    raise TwilioWebhookError, "Invalid message data: #{e.message}"
  end

  private

  # Route message webhook with automatic reply logic
  # @return [Hash] The result of routing the webhook
  def process_message_webhook
    # Extract phone number for automatic reply check
    author = @webhook_params['Author']&.gsub('whatsapp:', '')

    # Check if we should send automatic reply BEFORE processing the webhook
    should_send_automatic_reply = AutomaticReplyService.should_send_automatic_reply?(author)
    reply_type = AutomaticReplyService.determine_reply_type(author) if should_send_automatic_reply

    Rails.logger.info "Should send automatic reply: #{should_send_automatic_reply}"
    Rails.logger.info "Reply type: #{reply_type}"

    # Enqueue the job with automatic reply information
    job = TwilioInboundMessageJob.perform_later(
      @webhook_params,
      should_send_automatic_reply,
      reply_type
    )

    # Log the job ID for tracking
    Rails.logger.info "Enqueued TwilioInboundMessageJob with ID: #{job.job_id}"

    { status: 'success', job_id: job.job_id, job_type: 'TwilioInboundMessageJob' }
  end


  # Route conversation status webhook to background job
  # @return [Hash] The result of routing the webhook
  def process_conversation_state_updated_webhook
    # Enqueue the conversation status sync job
    job = TwilioConversationStatusSyncJob.perform_later(@webhook_params)
    Rails.logger.info "Enqueued TwilioConversationStatusSyncJob with ID: #{job.job_id}"

    { status: 'success', job_id: job.job_id, job_type: 'TwilioConversationStatusSyncJob' }
  end


  def create_message_body_with_media
    body = @message_content || ""

    if @media_sid.present?
      begin
        Rails.logger.info "Processing media SID: #{@media_sid.inspect}"
        Rails.logger.info "Media SID class: #{@media_sid.class}"

        # Validate media_sid is a valid string
        unless @media_sid.is_a?(String) && @media_sid.match?(/^ME[a-f0-9]{32}$/)
          Rails.logger.error "Invalid media SID format: #{@media_sid}"
          return body
        end

        # create download link using TwilioMediaService
        media_service = TwilioMediaService.new
        media_info = media_service.get_media_info(@media_sid)
        Rails.logger.info "Media info: #{media_info.inspect}"

        # Add media download link to the body
        download_link = Rails.application.routes.url_helpers.integrations_twilio_media_url(@media_sid)
        Rails.logger.info "Generated download link: #{download_link}"
        Rails.logger.info "Download link class: #{download_link.class}"

        media_text = "\n[File Received] \n #{media_info[:filename]} \n #{download_link}"

        body += media_text
        Rails.logger.info "Added media link to message body: #{download_link}"
      rescue => e
        Rails.logger.error "Failed to create media link: #{e.message}"
        Rails.logger.error "Error occurred at: #{e.backtrace.first}"
        # Continue without media link if there's an error
      end
    end

    Rails.logger.info "Final message body: #{body}"
    body
  end
end

# Custom error class for webhook processing errors
class TwilioWebhookError < StandardError; end

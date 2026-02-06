class TwilioConversationStatusSyncJob < ApplicationJob
  queue_as :default

  # Rails built-in retry mechanism
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(webhook_params)
    Rails.logger.info ">>>> Processing Twilio Conversation Status Sync Job"
    Rails.logger.info "Webhook params: #{webhook_params.inspect}"

    conversation_sid = webhook_params['ConversationSid']
    state = webhook_params['StateTo']

    # Find the conversation in our database
    conversation = Conversation.find_by(provider_conversation_id: conversation_sid)

    if conversation
      # Map Twilio state to our internal status
      new_status = map_twilio_status(state)

      # Update conversation status
      conversation.update!(status: new_status)

      Rails.logger.info "Updated conversation #{conversation.id} status to #{new_status}"

      # Broadcast the conversation status update to the UI
      broadcast_status_update(conversation)

      Rails.logger.info "Successfully processed conversation status webhook for conversation #{conversation.id}"
    else
      Rails.logger.warn "Conversation not found for SID: #{conversation_sid}"
      raise StandardError, "Conversation not found for SID: #{conversation_sid}"
    end
  rescue StandardError => e
    Rails.logger.error "Error in conversation status sync job: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise # This will trigger the retry mechanism
  end

  private

  # Map Twilio conversation state to our status
  # @param twilio_state [String] The state from Twilio
  # @return [Symbol] Our internal status
  def map_twilio_status(twilio_state)
    case twilio_state
    when 'active'
      :active
    when 'closed'
      :closed
    when 'inactive'
      :active # we don't want to mark inactive conversations as closed
    else
      :active # default to active for unknown states
    end
  end

  # Broadcast the conversation status update to the UI
  # @param conversation [Conversation] The conversation to broadcast updates for
  def broadcast_status_update(conversation)
    channel = "#{conversation.id}"
    Rails.logger.info "Broadcasting conversation status update to #{channel}"
    Rails.logger.info "New conversation status: #{conversation.status}"
    Rails.logger.info "Target element ID: status_badge_#{conversation.id}"

    # Channel is the conversation ID used to identify which Turbo Stream connection should receive the update
    # Target specifies the HTML element ID that will be replaced with the new content
    # Partial defines the template that will be used to generate the replacement content
    begin
      conversation.broadcast_replace_to channel,
                                    target: "status_badge_#{conversation.id}", # Element ID to update
                                    partial: "admin/conversations/status_badge", # Template to use
                                    locals: { conversation: conversation }
      Rails.logger.info "Status badge broadcast sent successfully"
    rescue => e
      Rails.logger.error "Failed to broadcast status badge: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end

    begin
      conversation.broadcast_replace_to channel,
                                    target: "conversation_actions_#{conversation.id}",
                                    partial: "admin/conversations/action_button",
                                    locals: { conversation: conversation }
      Rails.logger.info "Action button broadcast sent successfully"
    rescue => e
      Rails.logger.error "Failed to broadcast action button: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end

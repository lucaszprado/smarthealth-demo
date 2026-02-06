# Service for managing Twilio Conversations, including messages and participants.
# Handles all Twilio API operations
# Organized by resource type (conversations, messages, participants)
# Includes helper methods for common operations
# Twilio's Ruby SDK (twilio-ruby), the JSON response is automatically parsed into Ruby objects, not raw JSON strings.
# Internally, the SDK parses the API's JSON into Ruby model objects.
# @see https://www.twilio.com/docs/conversations/api for API documentation

require 'net/http'
require 'json'
require 'twilio_constants'
require 'fileutils'
require "uri"

class TwilioConversationsService
  include WhatsappUtils

  # @param conversation_service [Twilio::REST::ConversationsService] The Twilio conversations service client
  def initialize(conversations_service = TwilioApiClient.new.conversations_service)
    @conversations_service = conversations_service
  end

  # Create a new conversation with a participant
  # @param phone_number [String] The phone number of the customer in E.164 format
  # @return [Twilio::REST::Conversations::V1::Conversation] The created conversation
  def create_conversation(phone_number)
    conversation = @conversations_service.conversations.create(
      friendly_name: "Conversation with #{phone_number}"
    )

    add_participant(conversation.sid, phone_number)
    conversation
  end

  # Find a conversation by its SID
  # @param conversation_sid [String] The SID of the conversation
  # @return [Twilio::REST::Conversations::V1::Conversation] The found conversation
  def find_conversation(conversation_sid)
    @conversations_service.conversations(conversation_sid).fetch
  end


  # Update the status of a conversation
  # @param conversation_sid [String] The SID of the conversation
  # @param status [String] The new status of the conversation ('active', 'closed', 'inactive')
  # @return [Twilio::REST::Conversations::V1::Conversation] The updated conversation object with the new status
  def update_conversation_status(conversation_sid, status)
    @conversations_service.conversations(conversation_sid).update(
      state: status,
      x_twilio_webhook_enabled: 'true'
      )
  end

  def close_conversation(conversation_sid)
    Rails.logger.info "TwilioConversationsService: Closing conversation #{conversation_sid}"
    begin
      conversation = @conversations_service.conversations(conversation_sid).update(
        state: 'closed',
        x_twilio_webhook_enabled: 'true'
        )
      Rails.logger.info "TwilioConversationsService: Successfully closed conversation #{conversation_sid}"
      conversation
    rescue Twilio::REST::RestError => e
      Rails.logger.error "TwilioConversationsService: Failed to close conversation #{conversation_sid}"
      Rails.logger.error "Error Code: #{e.code} - #{e.message}"
      Rails.logger.error "More Info: #{e.more_info}" if e.more_info
      raise e
    rescue => e
      Rails.logger.error "TwilioConversationsService: Unexpected error closing conversation #{conversation_sid}"
      Rails.logger.error "Error: #{e.message}"
      raise e
    end
  end

  # Delete a conversation by its SID
  # @param conversation_sid [String] The SID of the conversation
  # @return [Boolean] True if the conversation was deleted, false otherwise
  def delete_conversation(conversation_sid)
    @conversations_service.conversations(conversation_sid).delete
  end

  # Delete all conversations for a specific participant
  # @param participant_number [String] The participant's WhatsApp number (in E.164 format)
  # @return [Hash] A hash with the count of deleted conversations and any errors
  def delete_conversations_by_participant(participant_number)
    participant_number = ensure_whatsapp_prefix(participant_number)
    result = { deleted: 0, errors: [] }

    # Get all conversations
    conversations = @conversations_service.conversations.list
    Rails.logger.info "Found #{conversations.size} total conversations"

    # Delete conversations that have the target participant
    conversations.each do |conversation|
      # Get participants for each conversation
      participants = @conversations_service
                          .conversations(conversation.sid)
                          .participants
                          .list

      # Check if this conversation has our target participant
      has_participant = participants.any? do |p|
        binding_address = p.messaging_binding&.dig('address')
        binding_address == participant_number
      end

      if has_participant
        Rails.logger.info "Found participant in conversation #{conversation.sid}, deleting..."
        begin
          @conversations_service
                .conversations(conversation.sid)
                .delete
          result[:deleted] += 1
          Rails.logger.info "Successfully deleted conversation #{conversation.sid}"
        rescue => e
          Rails.logger.error "Failed to delete conversation #{conversation.sid}: #{e.message}"
          result[:errors] << { sid: conversation.sid, error: e.message }
        end
      end
    end

    Rails.logger.info "Deleted #{result[:deleted]} conversations for participant #{participant_number}"
    Rails.logger.info "Encountered #{result[:errors].size} errors" if result[:errors].any?

    result
  end

  def get_conversation_details(conversation_sid)
    conversation = find_conversation(conversation_sid)
    participants = get_participants(conversation_sid)
    messages = get_messages(conversation_sid)

    {
      conversation: {
        sid: conversation.sid,
        status: conversation.state,
        friendly_name: conversation.friendly_name,
        date_created: conversation.date_created,
        date_updated: conversation.date_updated,
        url: conversation.url
      },
      participants: participants.map do |p|
        {
          sid: p.sid,
          identity: p.identity,
          messaging_binding: p.messaging_binding,
          date_created: p.date_created,
          date_updated: p.date_updated
        }
      end,
      messages: messages.map do |m|
        {
          body: m.body,
          author: m.author,
          date_created: m.date_created,
          date_updated: m.date_updated,
          index: m.index
        }
      end
    }
  end

  def list_conversations
    conversations = @conversations_service.conversations.list

    conversations.map do |conversation|
      participants = get_participants(conversation.sid)

      {
        sid: conversation.sid,
        status: conversation.state,
        friendly_name: conversation.friendly_name,
        date_created: conversation.date_created,
        date_updated: conversation.date_updated,
        customer: participants.map { |p| p.messaging_binding&.dig('address') },
        participant_count: participants.size
      }
    end.sort_by { |conv| conv[:date_created] }
  end

  def delete_all_conversations
    result = { deleted: 0, errors: [] }

    @conversations_service.conversations.list.each do |conversation|
      begin
        delete_conversation(conversation.sid)
        result[:deleted] += 1
      rescue => e
        result[:errors] << { sid: conversation.sid, error: e.message }
      end
    end

    result
  end


  ### Message Operations ###

  # Send a message to a conversation
  # @param [Conversation]
  # @param message_body [String] The body of the message
  # @return @return [Hash{Symbol => Object}]
  #    A hash representing a Twilio message in JSON format.
  #    Derived from a Twilio::REST::Conversations::V1::Message instance.
  def send_message(conversation, message_body)
    begin
      twilio_message = @conversations_service
                      .conversations(conversation.provider_conversation_id)
                      .messages
                      .create(body: message_body)

    # Store error details if the API call fails
    rescue Twilio::REST::RestError => e
      Rails.logger.error "Twilio API Error: #{e.code} - #{e.message}"
      raise e # <-- This will propagate the error to the job for retry
      # If error is not raised, the job will not retry because the method returns nil
    end
  end

  # Get messages from a conversation
  # @param conversation_sid [String] The SID of the conversation
  # @param limit [Integer] The maximum number of messages to return (default: 20)
  # @return [Array<Twilio::REST::Conversations::V1::Message>] The messages
  def get_messages(conversation_sid, limit: 20)
    @conversations_service
               .conversations(conversation_sid)
               .messages
               .list(limit: limit)
  end

  # Search for messages by phone number in the conversation API
  # @param phone_number [String] The phone number to search for
  # @return [Array<Hash>] The messages found
  def search_messages_by_number(phone_number)
    phone_number = ensure_whatsapp_prefix(phone_number)
    messages = []

    # Search in Conversations API
    conversations = @conversations_service.conversations.list

    conversations.each do |conversation|
      # Get participants for this conversation
      participants = get_participants(conversation.sid)

      # Only process conversations where the phone number is a participant
      if participants.any? { |p| p.messaging_binding&.dig('address') == phone_number }
        conversation_messages = get_messages(conversation.sid)

        messages.concat(conversation_messages.map do |m|
          {
            sid: m.sid,
            body: m.body,
            author: m.author,
            conversation_sid: conversation.sid,
            date_created: m.date_created,
            date_updated: m.date_updated,
            source: 'conversation_api'
          }
        end)
      end
    end

    messages.sort_by { |m| m[:date_created] }
  end


  ### Receipt Operations ###

  # Fetches failed and undelivered message receipts for a specific customer in a conversation
  # @param conversation_sid [String] The SID of the conversation to check receipts for
  # @param message_sid [String] The SID of the message to check receipts for
  # @param customer_phone_number [String] The customer's phone number to check receipts for
  # @return [Hash, nil] A hash containing error_code and error_message if a failed/undelivered receipt is found, nil otherwise
  # @example
  #   fetch_failed_and_undelivered_receipts("CHXXXXXXX", "IMXXXXXXX", "+1234567890")
  #   # => { error_code: "30007", error_message: "Message delivery failed" }
  def fetch_failed_and_undelivered_receipts(conversation_sid, message_sid, customer_phone_number)
    begin
      # First, get the participant SID for the customer
      customer_participant = find_customer_participant(conversation_sid, customer_phone_number)
      return nil unless customer_participant

      # Get all receipts for the message
      receipts = @conversations_service
                .conversations(conversation_sid)
                .messages(message_sid)
                .delivery_receipts
                .list

      # Filter receipts for our target customer using participant_sid
      customer_receipts = receipts.select do |receipt|
        receipt.participant_sid == customer_participant.sid
      end

      # Find any failed or undelivered receipt
      failed_receipt = customer_receipts.find do |receipt|
        ['failed', 'undelivered'].include?(receipt.status)
      end

      return nil unless failed_receipt

      # Get error message from Twilio's error codes
      error_details = fetch_twilio_error_details(failed_receipt.error_code)

      {
        error_code: failed_receipt.error_code,
        error_message: error_details&.dig('message')
      }
    rescue Twilio::REST::RestError => e
      {
        error_code: e.code,
        error_message: e.message
      }
    end
  end



  ### Participant Operations ###

  # Add a participant to a conversation
  # @param conversation_sid [String] The SID of the conversation
  # @param phone_number [String] The phone number of the participant in E.164 format
  # @return [Twilio::REST::Conversations::V1::Participant] The added participant
  def add_participant(conversation_sid, phone_number)
    phone_number = ensure_whatsapp_prefix(phone_number)
    proxy_address = "whatsapp:#{TwilioConstants::PhoneNumbers.whatsapp_sender}"
    # proxy_address: the company's WhatsApp number. It's "how" a participant connects to WhatsApp.

    @conversations_service
               .conversations(conversation_sid)
               .participants
               .create(
                 messaging_binding_address: phone_number,
                 messaging_binding_proxy_address: proxy_address
               )
  end

  def get_participants(conversation_sid)
    @conversations_service
               .conversations(conversation_sid)
               .participants
               .list
  end

  def get_webhooks
    webhooks = @conversations_service.webhooks.list
    webhooks.each do |wh|
      puts "#{wh.sid} → #{wh.configuration.url}"
      puts "   filters: #{wh.configuration.filters.join(', ')}"
    end
  end


  # Image operations
  # Get Twilio media file information and return download URL
  # @param service_sid [String] The Twilio service SID
  # @param media_sid [String] The Twilio media SID
  # @param filename [String] Optional filename for the download
  # @return [Hash] Hash containing download_url, content_type, and file_size
  def get_twilio_media_info(service_sid, media_sid, filename = nil)
    uri_meta = URI("https://mcs.us1.twilio.com/v1/Services/#{service_sid}/Media/#{media_sid}")
    req_meta = Net::HTTP::Get.new(uri_meta)
    req_meta.basic_auth(
                        Rails.application.credentials.dig(:twilio, :account_sid),
                        Rails.application.credentials.dig(:twilio, :auth_token)
                      )


    res_meta = Net::HTTP.start(uri_meta.host, uri_meta.port, use_ssl: true) do |http|
      http.request(req_meta)
    end

    meta = JSON.parse(res_meta.body)
    download_url = meta["links"]["content_direct_temporary"]

    Rails.logger.info "TwilioConversationsService: Download URL: #{meta.inspect}"

    {
      download_url: download_url,
      content_type: meta["content_type"],
      file_size: meta["size"],
      filename: filename || meta["filename"] || "twilio_media_#{media_sid}",
      service_sid: service_sid,
      media_sid: media_sid
    }
  end

  # Stream Twilio media file directly to browser
  # @param service_sid [String] The Twilio service SID
  # @param media_sid [String] The Twilio media SID
  # @return [String] The file data as a string
  def stream_twilio_media(service_sid, media_sid)
    media_info = get_twilio_media_info(service_sid, media_sid)

    uri_file = URI(media_info[:download_url])
    file_data = Net::HTTP.get(uri_file)

    file_data
  end


  private


  # Find a specific customer participant in a conversation
  # @param conversation_sid [String] The SID of the conversation to search in
  # @param customer_phone_number [String] The customer's phone number to find (with or without whatsapp: prefix)
  # @return [Twilio::REST::Conversations::V1::Participant, nil] The found participant or nil if not found
  def find_customer_participant(conversation_sid, customer_phone_number)
    customer_phone_number = ensure_whatsapp_prefix(customer_phone_number)

    participants = @conversations_service
                  .conversations(conversation_sid)
                  .participants
                  .list

    participants.find do |participant|
      participant.messaging_binding&.dig('address') == customer_phone_number
    end
  end

  def fetch_twilio_error_details(error_code)
    return nil unless error_code

    # Cache the error codes to avoid frequent HTTP requests
    # @return [Hash] A parsed JSON hash containing the error code and error message
    Rails.cache.fetch("twilio_error_codes", expires_in: 1.day) do
      uri = URI('https://www.twilio.com/docs/api/errors/twilio-error-codes.json')
      response = Net::HTTP.get(uri)
      JSON.parse(response)
    end.find { |error| error['code'] == error_code }
  end



end

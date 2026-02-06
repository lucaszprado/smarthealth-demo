class TwilioOutboundMessageJob < ApplicationJob
  queue_as :default

  retry_on Twilio::REST::RestError, wait: :exponentially_longer, attempts: 3
 
  def perform(conversation_id, message_id)
    Rails.logger.info ">>>> Processing Outbound Message Job"
    Rails.logger.info "Conversation ID: #{conversation_id}"
    Rails.logger.info "Message ID: #{message_id}"

    conversation = Conversation.find(conversation_id)
    message = Message.find(message_id)

    begin
      # Send the message using Twilio Conversations API
      twilio_message = TwilioConversationsService.new.send_message(
        conversation,
        message.body
      )

      # Update our message with the Twilio message ID
      message.update!(
        provider_message_id: twilio_message.sid
      )

      # Enqueue a job to check the message receipt only if Twilio returns a 200 status code
      TwilioMessageReceiptJob.set(wait: 5.seconds).perform_later(message.id)

      # Log the message sent successfully
      Rails.logger.info "Message sent successfully sent to Twilio: #{twilio_message.sid}"
    rescue Twilio::REST::RestError => e
      # This will trigger a retry for Twilio API errors - Status 4xx or 5xx
      # Only Twilio API errors will trigger retry
      Rails.logger.error "Failed to send message (Attempt #{executions}): #{e.message}"
      Rails.logger.error "Error code: #{e.code}"
      raise e

    rescue StandardError => e
      # For any other unexpected errors, update the message and don't retry
      message.update!(
        error_code: 99,
        error_message: e.message
      )
      # Don't raise here, as we don't want to retry for these errors
      # It's a better practice to avoid retrying on errors that are unlikely to succeed on retry (like database errors or validation errors).
      # The following errors are rescued here:
      #    - Database errors: ActiveRecord::RecordNotFound, ActiveRecord::ConnectionTimeoutError
      #    - Service Initialization Error: ArgumentError, NamedError
      #    - Job Enqueuing Error: ActiveJob::SerializationError, ActiveJob::QueueAdapterError,
      Rails.logger.error "Failed to send message (Attempt #{executions}): #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end

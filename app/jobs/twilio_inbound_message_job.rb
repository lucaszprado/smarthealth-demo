class TwilioInboundMessageJob < ApplicationJob
  queue_as :default

  def perform(webhook_params, should_send_automatic_reply, reply_type)
    begin
      Rails.logger.info ">>>> Processing Twilio Inbound Message Job"
      Rails.logger.info "Webhook params: #{webhook_params.inspect}"
      Rails.logger.info "Should send automatic reply: #{should_send_automatic_reply}"
      Rails.logger.info "Reply type: #{reply_type}"

      # Process the webhook (creates conversation and message)
      webhook_service = TwilioWebhookService.new(webhook_params)
      result = webhook_service.process_message

      if result[:status] != 'success'
        Rails.logger.warn "Webhook processing result: #{result.inspect}"
        return
      end

      # If webhook processing was successful and we should send automatic reply
      if should_send_automatic_reply
        begin
          # Get the conversation that was just created
          conversation = Conversation.find_by(provider_conversation_id: webhook_params['ConversationSid'])
          Rails.logger.info "Conversation to send automatic reply found: #{conversation.inspect}"
          # Send automatic reply
          AutomaticReplyService.send_automatic_reply(conversation, reply_type)
        rescue StandardError => e
          Rails.logger.error "Failed to send automatic reply: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          # Don't raise the error as the main webhook processing was successful
        end
      end
    rescue StandardError => e
      Rails.logger.error "Error in webhook job: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise # This will trigger the retry mechanism
    end
  end
end

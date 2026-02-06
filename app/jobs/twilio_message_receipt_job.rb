class TwilioMessageReceiptJob < ApplicationJob
  queue_as :default

  retry_on Twilio::REST::RestError, wait: :exponentially_longer, attempts: 3

  def perform(message_id)
    message = Message.find(message_id)
    service = TwilioConversationsService.new

    receipt_result = service.fetch_failed_and_undelivered_receipts(
      message.conversation.provider_conversation_id,
      message.provider_message_id,
      message.conversation.customer_phone_number
    )

    if receipt_result.present?
      message.update!(
        error_code: receipt_result[:error_code],
        error_message: receipt_result[:error_message]
      )
      # The after_update_commit callback in the Message model will handle the broadcast
    end
  end
end

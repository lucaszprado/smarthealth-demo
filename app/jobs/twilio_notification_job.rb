class TwilioNotificationJob < ApplicationJob
  queue_as :default

  def perform(conversation_id, message_id)
    conversation = Conversation.find(conversation_id)
    message = Message.find(message_id)
    NotificationMessageService.new.send_notification(conversation, message)
    Rails.logger.info "Twilio notification sent for conversation #{conversation.id} and message #{message.id}"
  rescue StandardError => e
    Rails.logger.error "Error sending Twilio notification for message #{message.id}: #{e.message}"
    raise e #This will trigger the retry mechanism
  end
end

class NotificationMessageService
  def initialize(messaging_service = TwilioMessagingService.new)
    @messaging_service = messaging_service
  end

  def send_notification(conversation, message)
    customer_identifier = conversation&.human&.name || conversation.customer_phone_number
    template_data = {
      '1' => customer_identifier,
    }

    @messaging_service.send_template_message(
      # Using :: to access constants from the Twilio module -> Global namespace
      to: TwilioConstants::PhoneNumbers.notification_number,
      template_sid: TwilioConstants::Templates.notification_message,
      template_data: template_data
    )
  end
end

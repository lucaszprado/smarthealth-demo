require 'twilio_constants'

class TwilioMessagingService
  include WhatsappUtils

  def initialize(messaging_service = TwilioApiClient.new.messaging_service)
    @messaging_service = messaging_service
  end

  def send_template_message(to:, template_sid:, template_data:)
    @messaging_service.create(
      from: ensure_whatsapp_prefix(TwilioConstants::PhoneNumbers.whatsapp_sender),
      to: ensure_whatsapp_prefix(to),
      content_sid: template_sid,
      content_variables: template_data.to_json
    )
  end
end

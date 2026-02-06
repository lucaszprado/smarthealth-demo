
# Rails is namespace that respresents the Rails Module
# The Rails module brings all the methods and classes that are available in the Rails framework
twilio_config = Rails.application.credentials.twilio

if twilio_config && twilio_config[:account_sid] && twilio_config[:auth_token]
  Twilio.configure do |config|
    config.account_sid = twilio_config[:account_sid]
    config.auth_token = twilio_config[:auth_token]
  end
  Rails.logger.info("Twilio client configured successfully")
else
  Rails.logger.warn("Twilio credentials not found or incomplete. Skipping Twilio configuration.")
end

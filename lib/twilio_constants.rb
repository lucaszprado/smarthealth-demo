# Constants for Twilio-related configuration
module TwilioConstants
  module Templates
    # Template for notifying about new messages
    # Each constant represents a different template used in the application
    # Templates are located in the Twilio Console: https://console.twilio.com/us1/develop/sms/content-template-builder
    def self.notification_message
      case Rails.env
      when 'production'
        "HXa5e3630f955847cb71582fd428a28abc" # Production template
      when 'development'
        "HX22a10f4c1c481dfad3080f867cb7da7e" # Development template
      when 'test'
        "HXtest_template_id_here" # Test template
      else
        raise "Unknown environment: #{Rails.env}"
      end
    end
  end

  module PhoneNumbers
    def self.notification_number
      case Rails.env
      when 'production'
        "+5511914273709"
      when 'development'
        "+5511914273709" # Development notification number
      when 'test'
        "+5511888888888" # Test notification number
      else
        raise "Unknown environment: #{Rails.env}"
      end
    end

    def self.whatsapp_sender
      case Rails.env
      when 'production'
        "+5511920472765"
      when 'development'
        "+18573823159" # Development WhatsApp number
      when 'test'
        "+5511666666666" # Test WhatsApp number
      else
        raise "Unknown environment: #{Rails.env}"
      end
    end
  end
end

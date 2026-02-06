# Application-wide constants
module ApplicationConstants
  module Contact
    def self.whatsapp_number
      case Rails.env
      when 'production'
        "5511920472765" # Production WhatsApp number
      when 'development'
        "5511920472765" # Development WhatsApp number (same as production for testing)
      when 'test'
        "5511999999999" # Test WhatsApp number
      else
        raise "Unknown environment: #{Rails.env}"
      end
    end

    def self.whatsapp_url
      "https://wa.me/#{whatsapp_number}"
    end
  end
end

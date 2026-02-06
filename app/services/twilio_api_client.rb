# Client for interacting with Twilio's API.
# This is the base client that handles authentication and provides access to Twilio's services.
# Handles authentication and basic client setup
# Provides access to different Twilio services
# Centralizes error handling

class TwilioApiClient
  # Expose media-related attributes for TwilioMediaService
  attr_reader :base_url, :account_sid, :auth_token

  # @return [Twilio::REST::Client] The Twilio client
  def initialize
    @client = Twilio::REST::Client.new(
      Rails.application.credentials.dig(:twilio, :account_sid),
      Rails.application.credentials.dig(:twilio, :auth_token)
    )

    # Add instance variables for direct HTTP operations
    # Twilio Media Content Service - MCS is not wrapped in the Twilio::REST::Client

    @base_url = "https://mcs.us1.twilio.com/v1/Services/#{Rails.application.credentials.dig(:twilio, :conversation_service_sid)}"
    Rails.logger.info "Base URL constructed: #{@base_url.inspect}"

    @account_sid = Rails.application.credentials.dig(:twilio, :account_sid)
    @auth_token = Rails.application.credentials.dig(:twilio, :auth_token)
  end



  # @return [Twilio::REST::Api::V2010::AccountContext::MessageList] The Twilio conversations service
  def conversations_service
    @client.conversations.v1.services(
      Rails.application.credentials.dig(:twilio, :conversation_service_sid)
    )
  end

  # @return [Twilio::REST::MessagingService] The Twilio messaging service
  def messaging_service
    @client.api.v2010.messages
  end

  private

  def handle_twilio_error(error)
    Rails.logger.error "Twilio API Error: #{error.message}"
    Rails.logger.error "Error Code: #{error.code}"
    Rails.logger.error "More Info: #{error.more_info}"
    raise error
  end
end

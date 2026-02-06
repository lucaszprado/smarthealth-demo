class Integrations::Twilio::ConversationsWebhooksController < ActionController::API

  before_action :validate_twilio_request, only: [:create]


  def create
    # Log the raw parameters received from Twilio
    Rails.logger.info ">>>> Twilio Conversations Webhook Received:"
    Rails.logger.info "Request URL: #{request.original_url}"
    Rails.logger.info "Request Method: #{request.method}"
    Rails.logger.info "Request Headers: #{request.headers.to_h.select { |k,v| k.start_with?('HTTP_', 'X_') }}"
    Rails.logger.info "Request Params: #{JSON.pretty_generate(params.to_unsafe_h)}"

    # route the webhook using the service
    webhook_service = TwilioWebhookService.new(webhook_params)
    action = webhook_service.route

    # Log the result for tracking
    Rails.logger.info "Webhook processing result: #{action.inspect}"

    # Respond with success to Twilio to acknowledge receipt
    head :ok
  end

  private

  def webhook_params
    params.permit!.to_h
  end

  def validate_twilio_request
    # Use the centralized TwilioApiClient to get the auth token
    auth_token = twilio_api_client.instance_variable_get(:@client).auth_token

    # Helper from twilio-ruby to validate requests
    # Uses the Auth Token from the TwilioApiClient to verify the signature
    validator = Twilio::Security::RequestValidator.new(auth_token)

    # Get the full URL of the request and the parameters
    request_url = request.original_url # Get the full URL of the request. Request object encapsulates all the details about the incoming HHTP request.

    # Use request.POST to get only the parameters from the POST body, excluding Rails routing parameters
    post_vars = request.POST

    # Get the X-Twilio-Signature header from the request
    signature = request.headers['X-Twilio-Signature']

    # Validate the request
    unless validator.validate(request_url, post_vars, signature)
      Rails.logger.warn ">>>> Twilio Request Validation Failed!"
      render plain: "Twilio Request Validation Failed.", status: :forbidden
      # Stop execution if validation fails
      return false # Or raise an error
    end

    # If validation passes, execution continues to the 'create' action
    Rails.logger.info ">>>> Twilio Request Validation Succeeded."
  end

  # Returns a memoized instance of TwilioApiClient used for validating webhook requests
  # The client handles authentication with Twilio's API using credentials from Rails credentials
  # @return [TwilioApiClient] A singleton instance of the Twilio API client
  # @see TwilioApiClient For details on the client implementation
  def twilio_api_client
    # Ruby's memoization pattern
    # If @twilio_api_client is nil, create a new instance of TwilioApiClient
    @twilio_api_client ||= TwilioApiClient.new
  end
end

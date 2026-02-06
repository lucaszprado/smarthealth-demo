class Integrations::Twilio::MessagingWebhooksController < ActionController::API
  # Twilio sends POST requests, authenticity is verified via middleware/before_action

  before_action :validate_twilio_request, only: [:create]

  # This action will handle incoming messages/events from Twilio Conversations
  def create
    # Log the raw parameters received from Twilio
    Rails.logger.info ">>>> Twilio Webhook Received:"
    Rails.logger.info "Request URL: #{request.original_url}"
    Rails.logger.info "Request Method: #{request.method}"
    Rails.logger.info "Request Headers: #{request.headers.to_h.select { |k,v| k.start_with?('HTTP_', 'X_') }}"
    Rails.logger.info "Request Params: #{params.to_unsafe_h}"

    # Log specific message details
    Rails.logger.info "Message Details:"
    Rails.logger.info "From: #{params['From']}"
    Rails.logger.info "To: #{params['To']}"
    Rails.logger.info "Body: #{params['Body']}"
    Rails.logger.info "MessageSid: #{params['MessageSid']}"
    Rails.logger.info "MessageStatus: #{params['MessageStatus']}"

    # Enqueue the job to process the webhook asynchronously
    job = TwilioWebhookProcessorJob.perform_later(params.to_unsafe_h)

    # Log the job ID for tracking
    Rails.logger.info "Enqueued job with ID: #{job.job_id}"

    # Respond with success to Twilio to acknowledge receipt
    head :ok
  end

  # (Optional but recommended) Action to handle status callbacks
  # def status
  #   # TODO: Log or handle status updates (e.g., message delivery)
  #   head :ok
  # end

  private

  # X-Twilio-Signature
  # Twilio's Side: Before sending the webhook request to your ngrok URL, Twilio takes:
  # The full URL it's sending to (https://e20e-.../create)
  # All the data it's sending in the request body (the post_vars)
  # Your Auth Token (which only you and Twilio should know)
  # It combines these pieces of information using a standard cryptographic process (HMAC-SHA1) to create a unique code – this code is the signature.
  # Twilio puts this signature into the X-Twilio-Signature header and sends the request to your server.
  # Your Server's Side (using validator.validate):
  # Your code receives the request, including the URL (request_url), the body parameters (post_vars), and the signature Twilio sent (signature).
  # The validator, which you initialized with your copy of the Auth Token, performs the exact same cryptographic process using the request_url and post_vars it received.
  # It compares the signature it just calculated with the signature that came in the X-Twilio-Signature header.
  # If they match exactly, validate returns true. This proves:
  # The request definitely came from Twilio (because only Twilio has your Auth Token to create the correct signature).
  # The URL and the parameters were not changed by anyone (like ngrok or other intermediaries) between Twilio sending the request and your server receiving it.
  # If they don't match, validate returns false.
  def validate_twilio_request
    # Helper from twilio-ruby to validate requests
    # Uses the Auth Token from your credentials to verify the signature
    validator = Twilio::Security::RequestValidator.new(Rails.application.credentials.twilio[Rails.env, :twilio, :auth_token])

    # Get the full URL of the request and the parameters
    request_url = request.original_url # Get the full URL of the request. Request object encapsulates all the details about the incoming HHTP request.

    # Use request.POST to get only the parameters from the POST body, excluding Rails routing parameters
    post_vars = request.POST

    # Get the X-Twilio-Signature header from the request
    signature = request.headers['X-Twilio-Signature']

    # Validate the request
    unless validator.validate(request_url, post_vars, signature)
      Rails.logger.warn ">>>> Twilio Request Validation Failed!"
      Rails.logger.warn "Request URL: #{request_url}"
      Rails.logger.warn "Signature: #{signature}"
      render plain: "Twilio Request Validation Failed.", status: :forbidden
      # Stop execution if validation fails
      return false # Or raise an error
    end

    # If validation passes, execution continues to the 'create' action
    Rails.logger.info ">>>> Twilio Request Validation Succeeded."
  end
end

class TwilioConversationCloseJob < ApplicationJob
  queue_as :default

  # Rails built-in retry mechanism
  retry_on Twilio::REST::RestError,   wait: :exponentially_longer, attempts: 3
  retry_on StandardError,             wait: :exponentially_longer, attempts: 2

  # This block runs *after* retries are exhausted
  # Handles rescue_from for StandardError by delegating to rescue_from_exception method
  # @param StandarError [StandardError] The exception that was raised
  # @param exception [StandardError] The exception object that finally escaped your perform
  # @ param args [Array] The arguments passed to perform_later. * is Ruby's splat operator
  # @return nil
  rescue_from(StandardError) do |exception, args|
    handle_retry_exhausted(*args)
  end

  def perform(conversation_id, status)
    Rails.logger.info "TwilioConversationCloseJob#perform called with conversation_id: #{conversation_id}, status: #{status}"
    Rails.logger.info "Arguments received: #{arguments.inspect}"

    update_status_to_closing(conversation_id, status)
    call_twilio_and_mark_closed(conversation_id)
  end

  private

  def update_status_to_closing(conversation_id, status)
    @conversation = Conversation.find(conversation_id)
    unless @conversation.closing?
      Rails.logger.warn "TwilioConversationCloseJob: Conversation #{conversation_id} is not in closing state, skipping"
      raise ArgumentError, "Conversation #{conversation_id} is not in closing state"
      # ArgumentError is a subclass of StandardError, so it will be caught by the rescue_from block
    end
  end

  def call_twilio_and_mark_closed(conversation_id)
    @conversation = Conversation.find(conversation_id)
    twilio_service = TwilioConversationsService.new
    twilio_service.close_conversation(@conversation.provider_conversation_id)
    Rails.logger.info "TwilioConversationCloseJob: Conversation #{conversation_id} closed successfully"

    # Update the conversation status to closed -> Must be done in webhook service
    # @conversation.update(status: :closed)

  end

  def handle_retry_exhausted(conversation_id, status)
    Rails.logger.error "TwilioConversationCloseJob: All retries exhausted for conversation #{conversation_id}"
    conversation = Conversation.find(conversation_id)
    if conversation.closing?
      conversation.update!(status: :close_failed)
      Rails.logger.error "TwilioConversationCloseJob: Marked conversation #{conversation_id} as close_failed after all retries"
    else
      Rails.logger.warn "TwilioConversationCloseJob: Conversation #{conversation_id} is no longer in closing state, not updating to close_failed"
    end
  end
end

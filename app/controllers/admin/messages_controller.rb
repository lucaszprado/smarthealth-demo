class Admin::MessagesController < ApplicationController
  before_action :authenticate_admin_user!

  def create
    @conversation = Conversation.find(params[:conversation_id])
    # Create message record in our database
    @message = Message.new(
      conversation: @conversation,
      provider_message_id: nil,
      body: message_params[:body],
      direction: :outbound,
      sent_at: Time.current,
      error_code: nil,
      error_message: nil
    )
    if @message.save
      # Enqueue the job to process the message asynchronously
      job = TwilioOutboundMessageJob.perform_later(
        @conversation.id,
        @message.id
      )

      # Log the job ID for tracking
      Rails.logger.info "Enqueued outbound message job with ID: #{job.job_id}"

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("messages",
            partial: "admin/messages/message",
            locals: { message: @message }
          )
        end
        format.html { redirect_to admin_conversation_path(@conversation) }
      end
    else
      flash[:alert] = "Failed to create message"
      redirect_to admin_conversation_path(@conversation)
    end
  end

  private

  def message_params
    params.require(:message).permit(:body)
  end
end

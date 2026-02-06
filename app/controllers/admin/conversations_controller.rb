class Admin::ConversationsController < ApplicationController
  before_action :authenticate_admin_user!

  def index
    @conversations = Conversation.includes(:messages, :human).order(updated_at: :desc)
  end

  def show
    @conversation = Conversation.includes(:messages).find(params[:id])
    @messages = @conversation.messages.order(sent_at: :asc)
    @human = @conversation&.human
    @message = Message.new # For the new message form
  end

  def update
    @conversation = Conversation.find(params[:id])

    @conversation.update(conversation_params)
    # Enqueue background job to update Twilio status
    Rails.logger.info "Enqueuing TwilioConversationCloseJob with conversation_id: #{@conversation.id}, status: #{@conversation.status}"

    # Enqueue job - log errors but don't fail the request
    begin
      job = TwilioConversationCloseJob.perform_later(@conversation.id, @conversation.status)
      Rails.logger.info "Job enqueued with ID: #{job.job_id}"
    rescue => e
      Rails.logger.error "Failed to enqueue job: #{e.message}"
      # Don't fail the request - just log the error
    end

    # Always respond with success since the database update worked
    respond_to do |format|
      format.turbo_stream { head :ok }
      format.html { redirect_to admin_conversation_path(@conversation), notice: 'Conversation status updated.' }
    end
  end

  private

  def conversation_params
    params.require(:conversation).permit(:status)
  end
end

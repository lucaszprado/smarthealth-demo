class Message < ApplicationRecord
  belongs_to :conversation
  validates :provider_message_id, uniqueness: { allow_blank: true }, if: :provider_message_id_changed?

  enum direction: { inbound: 0, outbound: 1 }

  after_create_commit :broadcast_message
  after_update_commit :broadcast_message_update

  private

  def broadcast_message
    channel = "#{conversation.id}"
    Rails.logger.info ">>>>>>>>>>>>>>>>>>Broadcasting message #{id} (#{direction})"
    Rails.logger.info "Channel: #{channel}"
    Rails.logger.info "Target: messages"
    Rails.logger.info "Message body: #{body}"
    Rails.logger.info "Broadcast method: #{direction == 'outbound' ? 'Turbo Stream (form submission)' : 'ActionCable broadcast'}"
    Rails.logger.info "Created at: #{created_at}"

    # Broadcast the new message to the channel as the last message in the list identified by the id=messages
    broadcast_append_to channel,
                      target: "messages",
                      partial: "admin/messages/message",
                      locals: { message: self }

    Rails.logger.info "Message #{id} broadcasted to #{channel}"
  end


  def broadcast_message_update
    channel = "#{conversation.id}"
    Rails.logger.info ">>>>>>>>>>>>>>>>>>Broadcasting message update #{id} (#{direction})"
    Rails.logger.info "Channel: #{channel}"
    Rails.logger.info "Target: messages"
    Rails.logger.info "Message body: #{body}"

    # Broadcast the updated message to the channel as the message with the same id as self
    # self refers to the message instance that triggered the callback
    # Turbo Streams identifies the element to replace using the dom_id helper
    broadcast_replace_to channel,
                      target: self,
                      partial: "admin/messages/message",
                      locals: { message: self }
  end

end

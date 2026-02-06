require 'twilio_constants'

class Conversation < ApplicationRecord
  belongs_to :human, optional: true
  has_many :messages, dependent: :destroy
  enum status: { active: 0, closed: 1, closing: 2, close_failed: 3 } # 2 and 3 are transitional states
  scope :active, -> { where(status: :active) }
  scope :closed, -> { where(status: :closed) }
  before_validation :set_default_status, on: :create
  validates :customer_phone_number, presence: true
  validates :status, presence: true


  def self.ransackable_associations(auth_object = nil)
    ["human"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["id", "customer_phone_number", "company_phone_number", "status" "created_at", "updated_at"]
  end

  # @param phone_number [String] The customer's phone number
  # @return [Conversation, nil] The open conversation if found
  def self.find_open_by_customer_phone_number(phone_number)
    where(customer_phone_number: phone_number, status: :active)
    .order(last_message_at: :desc)
    .first
  end

  # @param phone_number [String] The customer's phone number
  # @return [ActiveRecord::Relation] All conversations with the given phone number
  def self.find_by_customer_phone_number(phone_number)
    where(customer_phone_number: phone_number)
  end

  # @param phone_number [String] The customer's phone number
  # @param human [Human] The human to associate with
  # @return [Integer] The number of conversations associated
  def self.associate_with_human_by_phone_number(phone_number, human)
    where(customer_phone_number: phone_number, human_id: nil)
    .update_all(human_id: human.id)
  end

  # Find or create a conversation for the webhook
  # @return [Conversation] The found or created conversation
  def self.find_or_create_from_webhook(provider_conversation_id:, customer_phone_number:)
    conversation = Conversation.find_by(provider_conversation_id: provider_conversation_id)
    return conversation if conversation

    # Create new conversation if it doesn't exist
    Conversation.create!(
      provider_conversation_id: provider_conversation_id,
      customer_phone_number: customer_phone_number,
      status: :active,
      company_phone_number: TwilioConstants::PhoneNumbers.whatsapp_sender.gsub('whatsapp:', '')
    )
  end

  # @param human [Human] The human to associate with this conversation
  # @return [Boolean] Whether the association was successful
  def associate_with_human(human)
    update(human: human)
  end

  # Instance method
  # @return [Boolean] Whether the conversation was closed
  def close!
    update!(status: :closed)
  end

  # Instance method
  # @return [Boolean] Whether the conversation was reopened
  def reopen!
    update!(status: :active)
  end

  # Instance method to check if conversation is in closing state
  # @return [Boolean] Whether the conversation is currently being closed
  def closing?
    status == 'closing'
  end

  private



  def set_default_status
    self.status ||= :active
    # It only sets self.status to :open if self.status is currently nil
  end
end

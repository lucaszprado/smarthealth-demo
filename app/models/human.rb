class Human < ApplicationRecord
  has_many :sources, dependent: :destroy
  has_many :measures, through: :sources
  has_many :imaging_reports, through: :sources
  has_many :conversations, dependent: :destroy
  has_many :biomarkers, -> { distinct }, through: :measures
  has_many :filters, through: :measures

  # Get biomarkers filtered by source_type
  def biomarkers_by_source_type(source_type)
    source_type = SourceType.find_by(name: source_type)
    return Biomarker.none unless source_type

    biomarkers.joins(measures: :source)
              .where(sources: { source_type_id: source_type.id })
              .distinct
  end

  # Callbacks to automatically associate conversations when human is created or phone number is updated
  after_create :associate_existing_conversations
  after_update :associate_existing_conversations, if: :saved_change_to_phone_number?

  def self.ransackable_associations(auth_object = nil)
    ["sources", "measures", "conversations", "imaging_reports"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["birthdate", "created_at", "gender", "id", "id_value", "name", "updated_at", "phone_number"]
  end


  def age_at_measure(date)
    ((date.to_date - self.birthdate) / 365.25).floor
  end

  # @param phone_number [String] The phone number to find a human for
  # @return [Human, nil] The found human or nil if not found
  def self.find_by_phone_number(phone_number)
    find_by(phone_number: phone_number)
  end

  # @param phone_number [String] The phone number to find conversations for
  # @return [ActiveRecord::Relation] The conversations with the given phone number
  def self.find_conversations_by_phone_number(phone_number)
    Conversation.where(customer_phone_number: phone_number, human_id: nil)
  end

  private

  # Associates existing conversations that match this human's phone number
  # @return [void]
  def associate_existing_conversations
    return unless phone_number.present?

    # Find conversations with this phone number that aren't already associated
    unassociated_conversations = Conversation.where(
      customer_phone_number: phone_number,
      human_id: nil
    )

    # Associate each conversation with this human
    unassociated_conversations.update_all(human_id: id)
  end

end

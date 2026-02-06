class LabelAssignment < ApplicationRecord
  belongs_to :label
  belongs_to :labelable, polymorphic: true

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "label_id", "labelable_id", "labelable_type", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["measure", "label", "imaging_report"]
  end

end

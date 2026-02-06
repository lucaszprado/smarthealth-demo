class UnitFactor < ApplicationRecord
  belongs_to :biomarker
  belongs_to :unit

  def self.ransackable_associations(auth_object = nil)
    ["unit", "biomarker"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "updated_at", "id", "factor"]
  end
end

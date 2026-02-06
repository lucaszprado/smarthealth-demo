class Synonym < ApplicationRecord
  belongs_to :biomarker

  def self.ransackable_associations(auth_object = nil)
    ["biomarker"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["biomarker_id", "created_at", "id", "id_value", "language", "name", "updated_at"]
  end
end

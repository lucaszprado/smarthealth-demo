class HealthProfessional < ApplicationRecord
  has_many :sources, dependent: :nullify
  has_many :imaging_reports, through: :sources

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "name", "updated_at",]
  end

  def self.ransackable_associations(auth_object = nil)
    ["sources", "imaging_reports"]
  end

end

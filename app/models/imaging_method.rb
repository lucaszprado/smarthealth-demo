class ImagingMethod < ApplicationRecord
  has_many :imaging_reports

  def self.ransackable_attributes(auth_object = nil)
    ["id", "name", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["imaging_reports"]
  end

end

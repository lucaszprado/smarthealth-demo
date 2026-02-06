class Unit < ApplicationRecord
  has_many :unit_factors
  has_many :measures

  def self.ransackable_associations(auth_object = nil)
    ["unit_factors", "measures"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "external_ref", "id", "name", "synomys_string", "updated_at", "value_type"]
  end
end

class Category < ApplicationRecord
  belongs_to :parent, class_name: "Category", optional: true
  has_many :subcategories, class_name: "Category", foreign_key: "parent_id"

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "external_ref", "id", "id_value", "name", "parent_id", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["parent", "subcategories"]
  end
end

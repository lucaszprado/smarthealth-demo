class LabelRelationship < ApplicationRecord
  belongs_to :parent_label, class_name:"Label", inverse_of: :child_relationships
  belongs_to :child_label, class_name:"Label", inverse_of: :parent_relationships

  def self.ransackable_attributes(auth_object = nil)
    ["id", "child_label_id", "parent_label_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["labels"]
  end
end

class AddExternalRefToObjects < ActiveRecord::Migration[7.1]
  def change
    add_column :categories, :external_ref, :integer
    add_column :units, :external_ref, :integer
    add_column :biomarkers, :external_ref, :integer
  end
end

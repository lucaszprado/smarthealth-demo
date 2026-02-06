class CreateLabelRelationships < ActiveRecord::Migration[7.1]
  def change
    create_table :label_relationships do |t|
      t.references :parent_label, null: false, foreign_key: {to_table: :labels}
      t.references :child_label, null: false, foreign_key: {to_table: :labels}

      t.timestamps
    end
  end
end

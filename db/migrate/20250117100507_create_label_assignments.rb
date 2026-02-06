class CreateLabelAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :label_assignments do |t|
      t.references :label, null: false, foreign_key: true
      t.references :labelable, polymorphic: true, null: false

      t.timestamps
    end
  end
end

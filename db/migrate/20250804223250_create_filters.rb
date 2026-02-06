class CreateFilters < ActiveRecord::Migration[7.1]
  def change
    create_table :filters do |t|
      t.references :measure, null: false, foreign_key: true
      t.integer :range_status, default: 0, null: false
      t.boolean :is_from_latest_exam, default: false, null: false
      t.integer :filterable_type, null: false

      t.timestamps
    end

    add_index :filters, :measure_id, name: 'idx_filters_measure_id'
    add_index :filters, :filterable_type, name: 'idx_filters_filterable_type'
    add_index :filters, [:measure_id, :filterable_type], name: 'idx_filters_measure_and_type'
  end
end

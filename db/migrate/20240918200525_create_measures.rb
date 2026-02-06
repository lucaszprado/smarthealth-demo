class CreateMeasures < ActiveRecord::Migration[7.1]
  def change
    create_table :measures do |t|
      t.float :value
      t.float :original_value
      t.datetime :date
      t.references :biomarker, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.references :unit, null: false, foreign_key: true
      t.references :human, null: false, foreign_key: true

      t.timestamps
    end
  end
end

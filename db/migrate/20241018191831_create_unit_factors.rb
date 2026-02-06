class CreateUnitFactors < ActiveRecord::Migration[7.1]
  def change
    create_table :unit_factors do |t|
      t.float :factor
      t.references :biomarker, null: false, foreign_key: true
      t.references :unit, null: false, foreign_key: true

      t.timestamps
    end
  end
end

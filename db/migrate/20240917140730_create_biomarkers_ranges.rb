class CreateBiomarkersRanges < ActiveRecord::Migration[7.1]
  def change
    create_table :biomarkers_ranges do |t|
      t.string :gender
      t.integer :age
      t.float :possible_min_value
      t.float :possible_max_value
      t.string :optimal_min_value
      t.string :float
      t.float :optimal_max_value
      t.references :biomarker, null: false, foreign_key: true

      t.timestamps
    end
  end
end

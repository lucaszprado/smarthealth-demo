class CreateSynonyms < ActiveRecord::Migration[7.1]
  def change
    create_table :synonyms do |t|
      t.string :name
      t.references :biomarker, null: false, foreign_key: true

      t.timestamps
    end
  end
end

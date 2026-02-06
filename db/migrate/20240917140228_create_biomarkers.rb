class CreateBiomarkers < ActiveRecord::Migration[7.1]
  def change
    create_table :biomarkers do |t|
      t.string :name

      t.timestamps
    end
  end
end

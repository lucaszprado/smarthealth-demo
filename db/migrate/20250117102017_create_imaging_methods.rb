class CreateImagingMethods < ActiveRecord::Migration[7.1]
  def change
    create_table :imaging_methods do |t|
      t.string :name

      t.timestamps
    end
  end
end

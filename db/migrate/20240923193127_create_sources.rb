class CreateSources < ActiveRecord::Migration[7.1]
  def change
    create_table :sources do |t|
      t.string :file
      t.string :type

      t.timestamps
    end
  end
end

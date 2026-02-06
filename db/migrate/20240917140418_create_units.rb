class CreateUnits < ActiveRecord::Migration[7.1]
  def change
    create_table :units do |t|
      t.string :name
      t.string :synomys_string
      t.integer :value_type

      t.timestamps
    end
  end
end

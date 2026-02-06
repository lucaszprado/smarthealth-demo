class CreateSourceTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :source_types do |t|
      t.string :name

      t.timestamps
    end
  end
end

class CreateHealthProfessionals < ActiveRecord::Migration[7.1]
  def change
    create_table :health_professionals do |t|
      t.string :name

      t.timestamps
    end
  end
end

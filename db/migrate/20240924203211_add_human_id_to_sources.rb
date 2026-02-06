class AddHumanIdToSources < ActiveRecord::Migration[7.1]
  def change
    add_reference :sources, :human, null: false, foreign_key: true
  end
end

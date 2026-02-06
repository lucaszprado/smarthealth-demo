class AddSourceIdToMeasures < ActiveRecord::Migration[7.1]
  def change
    add_reference :measures, :source, null: false, foreign_key: true
  end
end

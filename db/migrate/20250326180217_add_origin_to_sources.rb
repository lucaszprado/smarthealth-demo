class AddOriginToSources < ActiveRecord::Migration[7.1]
  # When you add a column with a default value and enforce null: false,
  # Rails updates all existing records with that default valu
  def change
    add_column :sources, :origin, :integer, default: 0, null: false
  end
end

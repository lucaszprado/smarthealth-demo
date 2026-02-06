class RenameTypeColumnInSource < ActiveRecord::Migration[7.1]
  def change
    rename_column :sources, :type, :source_type
  end
end

class UpdateSourceModel < ActiveRecord::Migration[7.1]
  def change
    # Remove source_type column
    remove_column :sources, :source_type, :string

    # Add source_type_id to reference the SourceType model
    add_reference :sources, :source_type, foreign_key: true, null: true

  end
end

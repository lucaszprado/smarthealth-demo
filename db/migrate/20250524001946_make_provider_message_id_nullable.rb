class MakeProviderMessageIdNullable < ActiveRecord::Migration[7.1]
  def change
    change_column_null :messages, :provider_message_id, true

    # Drop the existing index
    remove_index :messages, :provider_message_id

    # Add the new index with where clause
    add_index :messages, :provider_message_id, unique: true, where: "provider_message_id IS NOT NULL"
  end
end

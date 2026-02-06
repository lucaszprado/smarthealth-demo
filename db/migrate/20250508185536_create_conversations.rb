class CreateConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :conversations do |t|
      t.references :human, null: true, foreign_key: true
      t.string :customer_phone_number, null: false
      t.string :company_phone_number, null: false
      t.string :provider_conversation_id, null: true
      t.integer :status, null: false, default: 0
      t.datetime :last_message_at

      t.timestamps

      t.index :provider_conversation_id, unique: true, where: "provider_conversation_id IS NOT NULL", name: 'index_unique_on_provider_conversation_id_not_null'
    end
    add_index :conversations, :customer_phone_number
    add_index :conversations, :company_phone_number
    add_index :conversations, :status
  end
end

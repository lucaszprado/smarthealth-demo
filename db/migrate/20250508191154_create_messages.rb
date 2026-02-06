class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.string :provider_message_id
      t.text :body
      t.integer :direction
      t.datetime :sent_at
      t.string :media_url
      t.integer :error_code
      t.string :error_message

      t.timestamps
    end
    add_index :messages, :provider_message_id, unique: true
    add_index :messages, :direction
  end
end

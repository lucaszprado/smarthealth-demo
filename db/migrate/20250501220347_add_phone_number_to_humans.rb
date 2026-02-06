class AddPhoneNumberToHumans < ActiveRecord::Migration[7.1]
  def change
    add_column :humans, :phone_number, :string
  end
end

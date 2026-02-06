class AddLanguageToSynonyms < ActiveRecord::Migration[7.1]
  def change
    add_column :synonyms, :language, :string
  end
end

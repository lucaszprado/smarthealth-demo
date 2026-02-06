class RemoveCategoryFromLabels < ActiveRecord::Migration[7.1]
  # This migration is not needed as the category column is not used in the labels table
  # I will keep the file were to not have a non file line in db:migrate:status
  # def change
  #   remove_reference :labels, :category, null: false, foreign_key: true
  # end
end

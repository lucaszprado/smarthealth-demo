class UpdateBiomarkersRangeTable < ActiveRecord::Migration[7.1]
  def change
        remove_column :biomarkers_ranges, :float, :string
        remove_column :biomarkers_ranges, :optimal_min_value, :string

        # Alterar o tipo da coluna `optimal_min_value` de string para float
        add_column :biomarkers_ranges, :optimal_min_value, :float
  end
end

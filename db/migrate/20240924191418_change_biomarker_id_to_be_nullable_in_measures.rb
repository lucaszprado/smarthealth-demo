class ChangeBiomarkerIdToBeNullableInMeasures < ActiveRecord::Migration[7.1]
  def change
    change_column_null :measures, :biomarker_id, true
    change_column_null :measures, :category_id, true
    change_column_null :measures, :unit_id, true
    change_column_null :measures, :human_id, true
    change_column_null :measures, :source_id, true
  end
end

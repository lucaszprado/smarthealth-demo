module BiomarkersHelper
  # Returns attributes for view partial depending on numeric and non numeric measures
  def result_card_attributes(human, biomarker)
    {
      link: human_measures_path(human.id, biomarker_ids: [biomarker[:biomarker_id]]), # This produces an array of biomarker IDs parameter -> example: biomarker_ids[]=159
      icon_path: biomarker[:source_type_name] == "Blood" ? "fa-solid fa-vial" : "fa-solid fa-weight-scale",
      title: biomarker[:display_name],
      key_info: biomarker[:unit_value_type] == 1 ? "#{format_value_2_decimals(biomarker[:original_value])} #{biomarker[:unit_name]}" : biomarker[:measure_text],
      status: biomarker[:unit_value_type] == 1 ? biomarker[:measure_status] : nil,
      date: biomarker[:date],
      labels: nil,
      data_type: biomarker[:source_type_name],
      context: 'biomarkers'
    }
  end

  def select_biomarker_sections_partial(biomarker_sections)
    if biomarker_sections.blank?
      'shared/no_data'
    else
      'biomarkers/data'
    end
  end

  def section_attributes(section)
    {
      name: section[:name],
      count: section[:count],
      order: section[:order],
      biomarkers: section[:biomarkers]
    }
  end
end

# Helpers should not have business logic and or render partials.
# Render partials should only be called in the views.
module MeasuresHelper
  def get_only_first_hash_value(measures)
    measures = measures.map {|key, value| [key, value[0]]}.to_h
  end

  def select_view_type(primary_biomarker_data, biomarker_series)
    if primary_biomarker_data[:last_measure_attributes][:unit_value_type] == 1
      #render 'measures/numeric', locals: {measure: measure, biomarker_series: biomarker_series}
      "measures/numeric"
    else
      #render 'measures/non_numeric', locals: {measure: measure}
      "measures/non_numeric"
    end
  end

  def select_measure_type(measure)
    if measure[:last_measure_attributes][:band_type] == 1
      #render "measures/ranges", locals: measure_attributes(measure)
      "measures/ranges"
    else
      #render 'measures/non_ranges', locals: measure_attributes(measure)
      "measures/non_ranges"
    end
  end

  # # Defines the path for the back button in humans/human_id/measuresbased on the source type
  # def return_path_for_measure(source_type, human)
  #   case source_type
  #   when "Blood"
  #     blood_human_biomarkers_path(human)
  #   when "Bioimpedance"
  #     bioimpedance_human_biomarkers_path(human)
  #   else
  #     human_biomarkers_path(human)
  #   end
  # end

  def measure_attributes(measure)
    if measure[:last_measure_attributes][:unit_value_type] == 1 && !measure[:last_measure_attributes][:upper_band].nil?
      if measure[:last_measure_attributes][:value] > measure[:last_measure_attributes][:upper_band]
        return {
          value: measure[:last_measure_attributes][:value],
          unit_name: measure[:last_measure_attributes][:unit_name],
          status_color_code: "yellow",
          status_text: "Acima",
          gender: measure[:last_measure_attributes][:gender],
          human_age: measure[:last_measure_attributes][:human_age],
          lower_band: measure[:last_measure_attributes][:lower_band],
          upper_band: measure[:last_measure_attributes][:upper_band]
        }



      elsif measure[:last_measure_attributes][:value] < measure[:last_measure_attributes][:lower_band]
        return {
          value: measure[:last_measure_attributes][:value],
          unit_name: measure[:last_measure_attributes][:unit_name],
          status_color_code: "yellow",
          status_text: "Abaixo",
          gender: measure[:last_measure_attributes][:gender],
          human_age: measure[:last_measure_attributes][:human_age],
          lower_band: measure[:last_measure_attributes][:lower_band],
          upper_band: measure[:last_measure_attributes][:upper_band]
        }
      else
        return {
          value: measure[:last_measure_attributes][:value],
          unit_name: measure[:last_measure_attributes][:unit_name],
          status_color_code: "green",
          status_text: "Normal",
          gender: measure[:last_measure_attributes][:gender],
          human_age: measure[:last_measure_attributes][:human_age],
          lower_band: measure[:last_measure_attributes][:lower_band],
          upper_band: measure[:last_measure_attributes][:upper_band]
        }
      end
    elsif measure[:last_measure_attributes][:unit_value_type] == 1 && measure[:last_measure_attributes][:upper_band].nil?
        return {
          value: measure[:last_measure_attributes][:value],
          unit_name: measure[:last_measure_attributes][:unit_name]
        }
    else
      if measure[:last_measure_attributes][:value] == 1
        return {
          value: "Positivo"
        }
      else
        return {
          value: "Negativo"
        }
      end
    end
  end

  # Process multiple biomarkers and group by unit + value range

  # Transforms biomarker series data to format expected by JavaScript chart controller
  # Converts date keys from full timestamp format to "YYYY-MM" format
  # @param biomarker_series [Array<Hash>] Array of biomarker series data
  # @return [Array<Hash>] Array with transformed date keys
  # @example
  #   biomarker_series = [{
  #     name: "Glucose",
  #     unit: "mg/dL",
  #     measures: { "2018-02-28 00:00:00 UTC" => 101, "2022-11-03 00:00:00 UTC" => 85 },
  #     upperBand: { "2018-02-28 00:00:00 UTC" => 99.09, "2022-11-03 00:00:00 UTC" => 99.09 },
  #     lowerBand: { "2018-02-28 00:00:00 UTC" => 70.26, "2022-11-03 00:00:00 UTC" => 70.26 }
  #   }]
  #   format_biomarker_series_for_chart(biomarker_series)
  #   # => [{
  #     name: "Glucose",
  #     unit: "mg/dL",
  #     measures: { "2018-02-28" => 101, "2022-11-03" => 85 },
  #     upperBand: { "2018-02-28" => 99.09, "2022-11-03" => 99.09 },
  #     lowerBand: { "2018-02-28" => 70.26, "2022-11-03" => 70.26 }
  #   }]
  def format_biomarker_series_for_chart(biomarker_series)
    return [] if biomarker_series.blank?

    biomarker_series.map do |series|
      {
        name: series[:name],
        unit: series[:unit],
        measures: transform_date_keys_to_yyyy_mm_dd(series[:measures]),
        upperBand: transform_date_keys_to_yyyy_mm_dd(series[:upperBand]),
        lowerBand: transform_date_keys_to_yyyy_mm_dd(series[:lowerBand])
      }
    end
  end

  def biomarker_selector_container_props(human, params, biomarker_sections)
    {
      human: human,
      selected_ids: Array.wrap(params.fetch(:biomarker_ids, [])),
      search_query: params[:query].to_s,
      biomarker_sections: biomarker_sections || []
    }
  end

  private

  # Transforms dates in a hash from standard date format to "yyyy-mm-dd" string format
  # @param hash_with_dates [Hash{Date => Object}] Hash with Date or String keys
  # @return [Hash{String => Object}] Hash with date strings in "yyyy-mm-dd" format as keys, preserving the original values
  # @example
  #   measures = { Date.new(2023,1,15) => 95, Date.new(2023,2,1) => 102 }
  #   transform_date_keys_to_yyyy_mm_dd(measures)
  #   # => { "2023-01-15" => 95, "2023-02-01" => 102 }
  def transform_date_keys_to_yyyy_mm_dd(hash_with_dates)
    return {} if hash_with_dates.blank?

    hash_with_dates.transform_keys { |date| date.strftime("%Y-%m-%d") }
  end

end

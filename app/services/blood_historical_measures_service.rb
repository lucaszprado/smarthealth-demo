require 'csv'

class BloodHistoricalMeasuresService
  def self.create(csv_file, pdf_files, origin)
    result = {success_count: 0, errors: []}
    sources = {} # Cache for created sources by health_provider_id

    ActiveRecord::Base.transaction do
      csv_data = CSV.parse(csv_file.read, headers: true)
      csv_data.each_with_index do |row, index|
      # row is a CSV::Row object
        row_data = row.to_h.transform_values(&:presence)
        # row.to_h converts CSV row into a hash
        # keys are the headers from the CSV
        # values are the corresponding cell values
        #
        #.transform_values(&:presence) = .transform_values{|v|v.presence}
        # presence is a Rails method that:
        # Returns the value if it's not blank
        # Returns nil if it's blank

        begin
          # Retrieve human and helath provider from CSV row
          human = Human.find(row_data["human_id"])
          health_provider = row_data["health_provider_id"].present? ? HealthProvider.find(row_data["health_provider_id"]) : nil
          health_professional = row_data["health_professional_id"].present? ? HealthProfessional.find(row_data["health_professional_id"]) : nil

          # Determine the key for the source cache (use a default key for nil).
          source_key = health_provider&.id || 'nil'
          # nil is different from 'nil'
          # 'nil' will be the key when no health_provider is associated with the measure / row

          # # Create a new source only if one doesn't already exist for a measure's health provider.
          # # Call SourceCreatorService to create the source
          unless sources[source_key]
            source_params = {
              human_id: human.id,
              source_type: SourceType.find_by(name: "Blood"),
              health_professional_id: health_professional.id,
              health_provider_id: health_provider.id,
              pdf_files: pdf_files,
              origin: origin.to_sym # Pass as string 'batch' in params, convert to symbol here
            }

            sources[source_key] = SourceCreatorService.create_source(source_params, "Blood")
          end

          source = sources[source_key]

          # Create the measure record.
          measure_date = DateTime.parse(row_data["date"])
          measure = Measure.create!(
            biomarker_id: row_data["biomarker_id"],
            source: source,
            unit_id: row_data["unit_id"],
            category_id: row_data["category_id"],
            original_value: row_data["original_value"],
            value: row_data["value"],
            date: measure_date
          )

          # Prepare potential range values from the current row first
          possible_min = row_data["possible_min_value"].present? ? row_data["possible_min_value"].to_f : nil
          possible_max = row_data["possible_max_value"].present? ? row_data["possible_max_value"].to_f : nil

          # Only proceed if the current row actually has range data
          if possible_min.present? || possible_max.present?
            # Check if an identical range record already exists
            existing_range = BiomarkersRange.find_by(
              biomarker_id: row_data["biomarker_id"],
              gender: row_data["gender"],
              age: row_data["age"],
              possible_min_value: possible_min, # Check against extracted value
              possible_max_value: possible_max  # Check against extracted value
            )

            # Create only if no identical record exists
            unless existing_range
              BiomarkersRange.create!(
                biomarker_id: row_data["biomarker_id"],
                gender: row_data["gender"],
                age: row_data["age"],
                possible_min_value: possible_min,
                possible_max_value: possible_max
              )
            end
          end

          result[:success_count] += 1

        rescue StandardError => e
          Rails.logger.error("Error on row #{index + 2}: #{e.message}")
          result[:errors] << "Row #{index + 2} : #{e.message}"
          # Index starts at zero and we move on up to disconsider headers
        end
      end
      raise ActiveRecord::Rollback if result[:errors].any?
      # Raise (triggering the rollback) must execute before the transaction block completes.
    end
    result
  end
end

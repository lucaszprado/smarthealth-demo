class BioimpedanceMeasuresService
  # This action create bioimpedance biomarkers
  # Params keys => :csv_file, :pdf_file, :human_id
  def self.create(params)
    result = { errors: [] }

    ActiveRecord::Base.transaction do
      # Process the csv file
      csv_data = CSV.parse(params[:csv_file].read, headers: true)

      # Reading data from first bioimpedance measure to create to prepare source_params to SourceCreatorService
      source_params = {
        human_id: params[:human_id],
        health_provider_id: csv_data[1]["health_provider_id"],
        health_professional_id: csv_data[1]["health_professional_id"],
        pdf_files: params[:pdf_files],
        origin: :manual
      }

      source = SourceCreatorService.create_source(source_params, "Bioimpedance")

      csv_data.each_with_index do |row, index|
        row_data = row.to_h.transform_values(&:presence)
        # row.to_h converts CSV row into a hash
        # keys are the headers from the CSV
        # values are the corresponding cell values
        #
        #.transform_values(&:presence) = .transform_values{|v|v.presence}
        # presence is a Rails method that:
        # Returns the value if it's not blank
        # Returns nil if it's blank

        # Reading data to create source and prepare source_params to SourceCreatorService


        # Instantiate Measure's Human
        human = Human.find(params[:human_id])

        # Define age to create BiomarkersRanges
        date = Time.at(row_data["date"].to_i).to_date
        age = calculate_age(human.birthdate, date)

        # Create Measure
        Measure.create!(
          biomarker_id: row_data["biomarker_id"],
          source: source,
          unit_id: row_data["unit_id"],
          category_id: row_data["category_id"],
          original_value: row_data["original_value"],
          value: row_data["value"],
          date: Time.at(row_data["date"].to_i)
        )

        # Prepare potential range values from the current row first
        possible_min = row_data["common_min"].nil? ? nil : row_data["common_min"].to_f
        possible_max = row_data["common_max"].nil? ? nil : row_data["common_max"].to_f
        optimal_min = row_data["optimal_min"].nil? ? nil : row_data["optimal_min"].to_f
        optimal_max = row_data["optimal_max"].nil? ? nil : row_data["optimal_max"].to_f

        # Only proceed if the current row actually has range data
        if possible_min.present? || possible_max.present?
          # Check if an identical range record already exists
          existing_range = BiomarkersRange.find_by(
            biomarker_id: row_data["biomarker_id"],
            gender: human.gender,
            age: age,
            possible_min_value: possible_min, # Check against extracted value
            possible_max_value: possible_max  # Check against extracted value
          )

          # Create only if no identical record exists
          unless existing_range
            BiomarkersRange.create!(
              biomarker_id: row_data["biomarker_id"],
              gender: human.gender,
              age: age,
              possible_min_value: possible_min,
              possible_max_value: possible_max,
              optimal_min_value: optimal_min, # Use prepared optimal values
              optimal_max_value: optimal_max  # Use prepared optimal values
            )
          end
        end
      rescue StandardError => e
        result[:errors] << "Row #{index + 2} : #{e.message}"
        raise ActiveRecord::Rollback
      end
    end
    result
  end

  def self.calculate_age(birthdate, date)
    ((date - birthdate) / 365.25).floor
  end
end

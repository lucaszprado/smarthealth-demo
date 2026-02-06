class ParsedPdfBloodMeasuresImporter
  def self.import(source, hash_data, human)
    begin
      ActiveRecord::Base.transaction do
        date = Time.at(hash_data["biomarkers"][0]["entries"][0]["date"]).to_date
        hash_data["biomarkers"].each do |biomarker_data|
          biomarker = Biomarker.find_or_create_by!(external_ref: biomarker_data["id"])
          category = Category.find_by(external_ref: biomarker_data["categoryId"])
          biomarker_data["entries"].each do |entry|
            Measure.create!(
              source: source,
              biomarker: biomarker,
              category: category,
              value: entry["value"],
              original_value: entry["originalValue"],
              date: Time.at(entry["date"]),
              unit: Unit.find_by(external_ref: entry["originalUnitId"])
            )
          end
        end

        hash_data["refs"].each do |external_ref, ranges|
          # Step 1: Find the corresponding Biomarker by its external_ref
          biomarker = Biomarker.find_or_create_by!(external_ref: external_ref.to_s.to_i)

          # Extract potential range values => Safe Navigation Operator requires the method call to be present. [](0)
          # Evaluate the hash at the zero index.
          possible_min = ranges["common"]&.[](0)
          possible_max = ranges["common"]&.[](1)
          optimal_min = ranges["optimal"]&.[](0)
          optimal_max = ranges["optimal"]&.[](1)

          # Step 2: Defining human variables
          gender = human.gender
          age = ((date - human.birthdate)/365.25).floor

          # Step 3: Only proceed if the current data actually has range data
          if possible_min.present? || possible_max.present?
            # Check if an identical range record already exists
            existing_range = BiomarkersRange.find_by(
              biomarker: biomarker, # Use the biomarker object found earlier
              gender: gender,
              age: age,
              possible_min_value: possible_min, # Check against extracted value
              possible_max_value: possible_max  # Check against extracted value
            )

            # Create only if no identical record exists
            unless existing_range
              BiomarkersRange.create!(
                biomarker: biomarker,
                gender: gender,
                age: age,
                possible_min_value: possible_min,
                possible_max_value: possible_max,
                optimal_min_value: optimal_min.presence, # Use prepared optimal values
                optimal_max_value: optimal_max.presence  # Use prepared optimal values
              )
            end
          end
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "ActiveRecord::RecordInvalid: #{e.message}"
      raise ActiveRecord::Rollback
    rescue StandardError => e
      Rails.logger.error "StandardError: #{e.message}"
      raise ActiveRecord::Rollback
    end
  end
end

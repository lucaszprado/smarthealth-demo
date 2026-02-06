class BiomarkersRange < ApplicationRecord
  belongs_to :biomarker
  # Validates that the combination of biomarker, gender, age, and value is unique
  # validates :biomarker, uniqueness: { scope: [:gender, :age, :possible_min_value, :possible_max_value, :optimal_min_value, :optimal_max_value], message: "combination already exists" }

  def self.ransackable_associations(auth_object = nil)
    ["biomarker"]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[create_at updated_at gender age id possible_min_value possible_max_value optimal_min_value optimal_max_value ]
  end

  # Fetch upper band and lower band value for each measure.
  # Retun an array with 2 hashes: upper band and lower band
  def self.bands_by_date(human, biomarker, unit_factor, measures)
    upper_band_measures = {}
    lower_band_measures = {}

    measures.each do |measure|
      # Calculate human's age at the time of the measure
      age_at_measure = human.age_at_measure(measure.date)

      # Get the upper and lower band values for this measure
      # Store the upper and lower band values in the hash with the measure date as the key
      upper_band_measures[measure.date] = upper_band(biomarker, human.gender, age_at_measure, unit_factor)
      lower_band_measures[measure.date] = lower_band(biomarker, human.gender, age_at_measure, unit_factor)
    end

    [upper_band_measures, lower_band_measures]
  end



  private

  # Fetch upper band measures for a given biomarker, gender, and age
  def self.upper_band(biomarker, gender, age, unit_factor)
    range = where(biomarker: biomarker, gender: gender, age: age).order(created_at: :desc).first
    range&.possible_max_value ? (range.possible_max_value / unit_factor).round(DECIMAL_PLACES) : nil
  end

  # Fetch lower band measures for a given biomarker, gender, and age
  def self.lower_band(biomarker, gender, age, unit_factor)
    range = where(biomarker: biomarker, gender: gender, age: age).order(created_at: :desc).first
    range&.possible_min_value ? (range.possible_min_value / unit_factor).round(DECIMAL_PLACES) : nil
  end
end

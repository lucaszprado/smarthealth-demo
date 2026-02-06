class Measure < ApplicationRecord
  belongs_to :biomarker, optional: true
  belongs_to :category, optional: true
  belongs_to :unit, optional: true
  belongs_to :source, optional: true
  has_many :label_assignments, as: :labelable, dependent: :destroy
  has_many :labels, through: :label_assignments
  has_many :filters #Can't use dependent: :destroy because it would destroy the filter before entering in the callback.

  # The callback after_create, after_update, before_destroy and after_destroy are executed before the transaction is commited to the database
  # If any error occurs during callbacks, the transaction is rolled back.
  # Filter recreation is done after the measure is destroyed to ensure the filter is created with the next most recent measure -> Record Id must be excluded from DB first.

  after_create :update_filters
  after_update :update_filters
  before_destroy :clean_up_filters
  after_destroy :recreate_filters

  # Ransackable associations
  def self.ransackable_associations(auth_object = nil)
    %w[source unit category biomarker label_assignments labels filters]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["biomarker_id", "category_id", "created_at", "date", "human_id", "id", "id_value", "original_value", "unit_id", "updated_at", "value", "source"]
  end

  # Calculate the range status for this measure
  # @param human [Human] The human who this measure belongs to
  # @return [Symbol] :normal, :out_of_range, or :not_available
  def calculate_range_status(human)
    return :not_available unless biomarker

    range = BiomarkersRange.where(
      biomarker: biomarker,
      gender: human.gender,
      age: human.age_at_measure(date)
    ).order(updated_at: :desc).first

    return :not_available unless range

    # Check if measure is within range
    min_value = range.possible_min_value
    max_value = range.possible_max_value

    if min_value && max_value
      if value >= min_value && value <= max_value
        :normal
      elsif value < min_value
        :below_range
      elsif value > max_value
        :above_range
      end
    else
      :not_available
    end
  end

  # Includes Biomarkers and Synonyms when bringing a Mesure
  # Used @
  # - ActiveAdmin Resource file
  scope :with_biomarker_and_synonyms, -> {
    includes(biomarker: :synonyms)
  }

  # Fetch Measures from a given human for a specific biomarker
  #
  # Rails best practics
  # This's a scope. Very similar to a class method. It's defined by using a lambda function
  scope :for_human_biomarker, ->(human, biomarker) {
    joins(:source)
    .where(sources: { human_id: human.id }, biomarker: biomarker)
    .order(:date)
  }

  # Fetch the most recent measure for a biomarker for a given human
  def self.most_recent(human, biomarker)
    for_human_biomarker(human, biomarker).order(date: :desc).first
  end

  # Tranform measure object into a hash with:
  # Key: Measure date
  # Value: Measure value
  # Converts measure values to the last used unit for a biomarker
  # @param measures [ActiveRecord::Relation<Measure>] Collection of measures to convert
  # @param unit_factor [Integer] Factor to convert measure values to the last used unit
  # @return [Hash{Date => Array}] Hash with measure dates as keys and arrays containing:
  #   - [0] [Float] Converted and rounded measure value
  #   - [1] [Source] Associated source object
  def self.for_human_biomarker_in_last_measure_unit(measures, unit_factor)
    measures.each_with_object({}) do |measure, hash|
      hash[measure.date] = [(measure.value / unit_factor).round(DECIMAL_PLACES), measure.source]
    end
  end



  # Query the measures belonging to a human and a biomarker
  # Processes biomarker measurement data for a given human and biomarker
  # @param human [Human] The human whose biomarker data is being processed
  # @param biomarker [Biomarker] The biomarker to process data for
  # @return [Hash] A hash containing:
  #   - last_measure_attributes: Hash containing latest measurement details including:
  #     - unit_name [String] Name of the measurement unit
  #     - unit_value_type [Integer] Type of unit value (1=numeric, 2=non-numeric)
  #     - value [Numeric, String] The measurement value
  #     - upper_band [Numeric, nil] Upper reference range if applicable
  #     - lower_band [Numeric, nil] Lower reference range if applicable
  #     - biomarker_title [String] Title of the biomarker
  #     - band_type [Integer] Whether reference ranges exist (1) or not (0)
  #     - gender [String] Human's gender ("Homem"/"Mulher")
  #     - human_age [Integer] Human's age at measurement time
  #     - status [Symbol, nil] Status relative to reference ranges
  #     - source_type [String] Type of measurement source
  #   - measure_series: Hash containing:
  #     - measures_with_sources [Hash] Measurements with sources in ascending order
  #     - measures_with_sources_desc [Hash] Measurements with sources in descending order
  #     - upper_band [Hash] Upper reference ranges by date
  #     - lower_band [Hash] Lower reference ranges by date
  def self.process_biomarker_data(human, biomarker)
    most_recent_measure = most_recent(human, biomarker)
    return {} unless most_recent_measure

    unit = most_recent_measure.unit
    unit_factor = UnitFactor.find_by(biomarker: biomarker, unit: unit)&.factor || 1

    measures = for_human_biomarker(human, biomarker)
    converted_measures = for_human_biomarker_in_last_measure_unit(measures, unit_factor)

    ranges = BiomarkersRange.bands_by_date(human, biomarker, unit_factor, measures)
    upper_band_measures = ranges[0]
    lower_band_measures = ranges[1]

    last_date = converted_measures.keys.last

    # Treat return for non-numeric measures
    if unit.value_type == 2
      converted_measures = converted_measures.transform_values do |value|
        if value.first == 1
          ["Positivo", value[1]]
        else
          ["Negativo", value[1]]
        end
      end

      return{
        last_measure_attributes: {
          unit_name: unit.name,
          unit_value_type: unit.value_type,
          value: converted_measures[last_date]&.first,
          upper_band: upper_band_measures[last_date],
          lower_band: lower_band_measures[last_date],
          biomarker_title: biomarker.title,
          band_type: upper_band_measures.values.first ? 1 : 0,
          gender: human.gender == "M" ? "Homem" : "Mulher",
          human_age: human.age_at_measure(last_date),
          status: nil,
          source_type: most_recent_measure.source.source_type.name
        },
        measure_series: {
          measures_with_sources: converted_measures,
          measures_with_sources_desc: converted_measures.to_a.reverse.to_h, # This line converts the converted_measures hash to an array, reverses its order, and converts it back to a hash. It creates a descending (newest-to-oldest) version of the measures, while the original measures_with_sources maintains the ascending (oldest-to-newest) order.
          upper_band: upper_band_measures,
          lower_band: lower_band_measures
        }
      }
    end

    # Treat return for numeric measures without reference values
    if unit.value_type == 1 && upper_band_measures[last_date] == nil
      return{
        last_measure_attributes: {
          unit_name: unit.name,
          unit_value_type: unit.value_type,
          value: converted_measures[last_date]&.first,
          upper_band: upper_band_measures[last_date],
          lower_band: lower_band_measures[last_date],
          biomarker_title: biomarker.title,
          band_type: upper_band_measures.values.first ? 1 : 0,
          gender: human.gender == "M" ? "Homem" : "Mulher",
          human_age: human.age_at_measure(last_date),
          status: nil,
          source_type: most_recent_measure.source.source_type.name
        },
        measure_series: {
          measures_with_sources: converted_measures,
          measures_with_sources_desc: converted_measures.to_a.reverse.to_h,
          upper_band: upper_band_measures,
          lower_band: lower_band_measures
        }
      }
    end

    {
      last_measure_attributes: {
        unit_name: unit.name,
        unit_value_type: unit.value_type,
        value: converted_measures[last_date]&.first,
        upper_band: upper_band_measures[last_date],
        lower_band: lower_band_measures[last_date],
        biomarker_title: biomarker.title,
        band_type: upper_band_measures.values.first ? 1 : 0,
        gender: human.gender == "M" ? "Homem" : "Mulher",
        human_age: human.age_at_measure(last_date),
        status: converted_measures[last_date]&.first <= upper_band_measures[last_date] &&
                converted_measures[last_date]&.first >= lower_band_measures[last_date] ? "green" : "yellow",
        source_type: most_recent_measure.source.source_type.name
      },
      measure_series: {
        measures_with_sources: converted_measures,
        measures_with_sources_desc: converted_measures.to_a.reverse.to_h,
        upper_band: upper_band_measures,
        lower_band: lower_band_measures
      }
    }
  end

  private

  # Updates filters associated with this measure using the FilterUpdateService
  # This method is called after measure creation/updates to ensure filters stay in sync
  # The method is wrapped in a transaction (via FilterUpdateService) to ensure atomicity
  # and consistency between measures and filters - if any part fails, all changes are rolled back
  #
  # @raise [ApplicationError::FilterError] If the filter update service fails or returns nil
  # @raise [ApplicationError::FilterError] If any unexpected error occurs during the update process
  # @return [Boolean] Returns the result from FilterUpdateService#call
  def update_filters
    result = FilterUpdateService.new(self).call

  # Errors on the FilterUpdateService are rescue on this block (included the unless block above).
  rescue => e
    # This line checks if the caught exception e is an instance of the custom FilterError class.
    # If it is, the error will be re-raised as-is; if not, it will be wrapped in a new FilterError
    # with additional context.
    # The else block in the rescue will be entered when any error occurs that is not a
    # FilterError. For example, if there's a database connection error,
    # a NoMethodError, or any other Ruby exception during the filter update process.
    # These errors will be wrapped in a new FilterError with additional
    # context before being re-raised.
    if e.is_a?(ApplicationError::FilterError)
      # Re-raise our custom error
      raise
    else
      # Log and wrap other errors
      error = ApplicationError::FilterError.new("Unexpected error during filter update")
      Rails.logger.error "#{error.class}: #{error.message} | Measure ID: #{id}"
      raise error
    end
  end


  # Cleans up and updates filters when a measure is deleted
  # This method ensures that if a measure with an associated filter is deleted,
  # the filter is either updated to point to the next most recent measure
  # or is deleted if no other measures exist for that biomarker-human combination.
  #
  # The method is wrapped in a transaction (via FilterUpdateService) to ensure atomicity
  # and consistency between measures and filters. If any part of the update process fails,
  # all changes are rolled back to maintain data integrity.
  #
  # @raise [ApplicationError::FilterError] If the filter update service fails or returns nil
  # @raise [ApplicationError::FilterError] If any unexpected error occurs during the cleanup process
  # @return [nil, Boolean] Returns nil if no filter exists, otherwise returns the result from FilterUpdateService#call
  def clean_up_filters
    filters = self.filters.where(filterable_type: self.source.source_type.name.downcase.to_sym)
    return unless filters.present?

    # Destroy the filter associated with this measure to allow a new filter creation to the triplet (human, biomarker and filterable_type)
    filters.destroy_all

  rescue => e
    if e.is_a?(ApplicationError::FilterError)
      raise e
    else
      error = ApplicationError::FilterError.new("Unexpected error during filter cleanup")
      Rails.logger.error error.message
      raise error
    end
  end

  def recreate_filters
    # Find the next most recent past self measure for this biomarker and human
    most_recent_past_self = Measure.joins(source: :human)
    .where(biomarker: self.biomarker, sources: { human: self.source.human })
    .order(date: :desc)
    .first

    Rails.logger.info "\n=====> Deleting measure Id: #{self.id}: #{self.biomarker&.name} - #{self.date}"
    Rails.logger.info "=====> most_recent_past_self: Measure Id #{most_recent_past_self&.id}: #{most_recent_past_self&.biomarker&.name} - #{most_recent_past_self&.date}"


    # Check if source is being destroyed using thread-local flag
    sources_being_deleted = Thread.current[:sources_being_deleted] || []
    is_source_being_destroyed = sources_being_deleted.include?(self.source_id)
    Rails.logger.info "====> Measure #{self.id} (source_id: #{self.source_id}) - sources_being_deleted: #{sources_being_deleted}, is_source_being_destroyed: #{is_source_being_destroyed}"

    if most_recent_past_self && is_source_being_destroyed
      Rails.logger.info "====> Entering FilterUpdateService with source_being_destroyed: true"
      result = FilterUpdateService.new(most_recent_past_self, self).call

    elsif most_recent_past_self
      Rails.logger.info "====> Entering FilterUpdateService with source_being_destroyed: false"
      result = FilterUpdateService.new(most_recent_past_self).call

    end

  rescue => e
    if e.is_a?(ApplicationError::FilterError)
      raise e
    else
      error = ApplicationError::FilterError.new("Unexpected error during filter recreation")
      Rails.logger.error error.message
      raise error
    end
  end

  # Process multiple biomarkers data for multi-chart display
  # @param human [Human] The human whose biomarker data is being processed
  # @param biomarkers [Array<Biomarker>] Array of biomarker objects to process
  # @return [Array<Hash>] Array of biomarker data hashes structured for chart controller:
  #   - name [String] The biomarker title
  #   - unit [String] The unit name for measurements
  #   - measures [Hash] Hash of measure values keyed by date (mm/yyyy format)
  #   - upperBand [Hash] Hash of upper band values keyed by date (mm/yyyy format)
  #   - lowerBand [Hash] Hash of lower band values keyed by date (mm/yyyy format)
  # @example
  #   biomarkers = [Biomarker.find(1), Biomarker.find(2)]
  #   Measure.process_multi_biomarker_data(human, biomarkers)
  #   # => [
  #   #   {
  #   #     name: "Hemoglobin",
  #   #     unit: "g/dL",
  #   #     measures: { "01/2023": 12.5, "02/2023": 13.1 },
  #   #     upperBand: { "01/2023": 15.5, "02/2023": 15.5 },
  #   #     lowerBand: { "01/2023": 12.0, "02/2023": 12.0 }
  #   #   },
  #   #   {
  #   #     name: "Glucose",
  #   #     unit: "mg/dL",
  #   #     measures: { "01/2023": 95, "02/2023": 102 },
  #   #     upperBand: { "01/2023": 100, "02/2023": 100 },
  #   #     lowerBand: { "01/2023": 70, "02/2023": 70 }
  #   #   }
  #   # ]
  def self.create_biomarker_series(human, biomarker_ids)
    return [] if biomarker_ids.blank?

    biomarkers = Biomarker.where(id: biomarker_ids)
    return [] if biomarkers.empty?

    multi_biomarker_data = []

    biomarkers.each do |biomarker|
      biomarker_data = process_biomarker_data(human, biomarker)
      next if biomarker_data.blank?

      biomarker_data_measures_series_without_source = biomarker_data[:measure_series][:measures_with_sources].transform_values { |value| value[0] }

      biomarker_data_formatted = {
        name: biomarker_data[:last_measure_attributes][:biomarker_title],
        unit: biomarker_data[:last_measure_attributes][:unit_name],
        measures: biomarker_data_measures_series_without_source,
        upperBand: biomarker_data[:measure_series][:upper_band],
        lowerBand: biomarker_data[:measure_series][:lower_band]
      }

      multi_biomarker_data << biomarker_data_formatted
    end

    multi_biomarker_data
  end
end

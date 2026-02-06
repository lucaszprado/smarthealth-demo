class Filter < ApplicationRecord 
  belongs_to :measure

  enum range_status: {
    not_available: 0,
    normal: 1,
    above_range: 2,
    below_range: 3
  }

  enum filterable_type: {
    bioimpedance: 1,
    blood: 2
  }

  validates :measure_id, :range_status, :filterable_type, presence: true
  validates :is_from_latest_exam, inclusion: { in: [true, false]}

  delegate :biomarker, to: :measure
  delegate :human, to: 'measure.source'
  delegate :source, to: :measure

  # you can define nested associations using dot notation as shown.
  # This syntax allows Ransack to traverse through the associations measure -> source and measure -> biomarker
  # for searching and filtering. The associations must match your model's defined relationships to work correctly.
  def self.ransackable_associations(auth_object = nil)
    ["measure", "measure.source", "measure.biomarker", "measure.source.human"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["range_status", "created_at", "is_from_latest_exam", "filterable_type", "id", "updated_at"]
  end

  scope :out_of_range, -> { where(range_status: [:above_range, :below_range]) }
  scope :is_from_latest_exam, -> { where(is_from_latest_exam: true) }
  scope :by_human, ->(human_id) {
    joins(measure: {source: :human})
    .where( source: { human_id: human_id } ) if human_id.present?
  }


  # Filters Filter records by source type(s)
  scope :by_filterable_type, ->(type) {
    where(filterable_type: Array(type).map(&:downcase))
  }

  # Applies multiple filters to Filter records
  # @param human_id [Integer] The ID of the human to filter records for
  # @param source_types [String, Array<String>] The source type(s) to filter by (e.g. 'Blood', 'Bioimpedance')
  # @param filters [Array<Symbol>] Array of filter types to apply. Valid values are:
  #   :out_of_range - Only include records where biomarker is out of normal range
  #   :from_latest_exam - Only include records from the most recent exam
  # @return [ActiveRecord::Relation] Filtered query of Filter records
  #   @example
  #     Filter.with_filters(1, ['Blood'], [:out_of_range, :from_latest_exam])
  #     # => #<ActiveRecord::Relation [
  #     #      #<Filter id: 1, measure_id: 2, range_status: :above_range, is_from_latest_exam: true>,
  #     #      #<Filter id: 3, measure_id: 4, range_status: :below_range, is_from_latest_exam: true>
  #     #    ]>
  scope :with_filters, ->(human_id, source_types, filters = []) {
    query = by_human(human_id).by_filterable_type(source_types)

      filters.each do |filter|
        case filter
        when :is_from_latest_exam
          query = query.is_from_latest_exam
        when :out_of_range
          query = query.out_of_range
        end
      end

    query
  }
end

# Service responsible for creating and updating filters based on measures.
# Ensures only one filter exists per human-biomarker-filterable_type triplet.
# Test:
# Start
# Ultimas medicoes: 156 measures and 27 above or below range
# Blood Last Exam Source: 2024-05-22: 37 measures and 6 above or below ranges
#
#
# After
# Ultimas medicoes: 157 measures and 22 above or below range
# Blood Last Exam Source: 2025-01-31: 43 measures and 5 above or below range


class FilterUpdateService
  # Initialize the service with an optional measure
  # @param measure [Measure, nil] The measure to process, can be set later
  def initialize(measure = nil, more_recent_than_measure = nil)
    @measure = measure
    @more_recent_than_measure = more_recent_than_measure
  end

  # Process a single measure to create or update its corresponding filter
  # @param measure [Measure, nil] The measure to process, defaults to @measure
  # @return [Boolean] Returns true if filter was successfully created/updated, false otherwise
  # @raise [ActiveRecord::RecordInvalid] If filter creation/update fails
  def call(measure = nil, more_recent_than_measure = nil)
    measure ||= @measure
    more_recent_than_measure ||= @more_recent_than_measure
    return unless measure&.biomarker.present?

    human = measure&.source.human
    return unless human.present?

    filterable_type = measure&.source.source_type.name.downcase
    return unless filterable_type.present?

    # Check if measure is the latest biomarker measure for the human and source type
    source_type = measure&.source.source_type
    is_latest_biomarker_measure = is_latest_biomarker_measure?(measure, human, source_type, measure.biomarker)
    return false unless is_latest_biomarker_measure


    ActiveRecord::Base.transaction do
      # Find or create the filter record for this human-biomarker-filterable_type triplet
      filter = find_or_create_filter_for_triplet(human, measure.biomarker, filterable_type, measure)

      # Update filter attributes for measure
      update_filter_attributes(filter, measure, human, filterable_type, measure.biomarker, more_recent_than_measure)
    end
  end


  private

  # Find existing filter for a triplet or create a new one
  # @param human [Human] The human associated with the filter
  # @param biomarker [Biomarker] The biomarker associated with the filter
  # @param filterable_type [String] The lowercase source type name
  # @param triggering_measure [Measure] The measure that triggered this filter creation
  # @return [Filter] The found or newly created filter
  # @raise [ActiveRecord::RecordInvalid] If filter creation fails
  def find_or_create_filter_for_triplet(human, biomarker, filterable_type, triggering_measure)
    # Find existing filter for this human-biomarker-filterable_type triplet
    existing_filter = Filter.joins(measure: :source)
                          .where(sources: { human: human })
                          .where(measures: { biomarker: biomarker })
                          .where(filterable_type: filterable_type)
                          .first

    if existing_filter
      # Return existing filter - it will be updated with new measure
      existing_filter
    else
      # Create new filter using the measure that triggered the creation
      Filter.create!(
        measure: triggering_measure,
        range_status: 0,
        is_from_latest_exam: false,
        filterable_type: filterable_type
      )
    end
  end

  # Update filter attributes based on the measure and human
  # Filter is only updated if the measure is the latest biomarker measure for the human and source type
  # @param filter [Filter] The filter to update
  # @param measure [Measure] The measure associated with the filter
  # @param human [Human] The human associated with the filter
  # @param filterable_type [String] The lowercase source type name
  # @return [Boolean] false if filter was not updated, true if filter was updated
  # @return [Filter] The updated filter if successful
  # @raise [ActiveRecord::RecordInvalid] If filter update fails
  def update_filter_attributes(filter, measure, human, filterable_type, biomarker, more_recent_than_measure)
    # Calculate range status using the Measure instance method
    range_status = measure.calculate_range_status(human)


    # Check if the measure is from the latest exam
    source_type = measure.source.source_type
    is_from_latest_exam = is_from_latest_exam?(measure, human, source_type, more_recent_than_measure)
    Rails.logger.info "====> Measure Id: #{measure.id} has is_from_latest_exam: #{is_from_latest_exam}"

    # Update filter attributes for measure
    filter.update!(
      range_status: range_status,
      is_from_latest_exam: is_from_latest_exam,
      measure: measure,
      filterable_type: filterable_type
    )

    # If the measure is from the latest exam, update the filters from other sources marked as latest exam
    # And update all filters from the same source as measure marked as latest exam
    if is_from_latest_exam == true

      # Find filters from other sources marked as latest exam and update them
      # When we're adding / Updating a new source, we need to update all filters from other sources that are marked as latest exam = true
      # In measure creation or deletion, we don't remove filters.
      filters_to_update = human.filters
                              .where(is_from_latest_exam: true)
                              .joins(measure: :source)
                              .where(sources: {source_type: source_type})
                              .where.not(sources: {id: measure.source.id})


      Rails.logger.info "====> filters_to_update to false: #{filters_to_update.count}"
      filters_to_update.update_all(is_from_latest_exam: false) if filters_to_update.present?

      # Update all filters from the same source as measure marked as latest exam
      # When we delete a source, we find the most recent measure past the deleted source's measure based on the biomarker id.
      # The new most recent source past the deleted source might have biomarkers different from the deleted source.
      # So we need to update all filters from the same source as measure marked as latest exam.
      filters_to_update = human.filters
                              .joins(measure: :source)
                              .where(sources: {id: measure.source.id})

      # Update all filters from the same source as measure marked as latest exam
      # When we delete a source, we find the most recent measure past the deleted source's measure based on the biomarker id.
      # The new most recent source past the deleted source might have biomarkers different from the deleted source.
      # So we need to update all filters from the same source as measure marked as latest exam.
      filters_to_update = human.filters
                              .joins(measure: :source)
                              .where(sources: {id: measure.source.id})

      filters_to_update.update_all(is_from_latest_exam: true) if filters_to_update.present?
      Rails.logger.info "====> filters_to_update to true: #{filters_to_update.count}"
    end

    return true
  end


  def is_latest_biomarker_measure?(measure, human, source_type, biomarker)
    latest_biomarker_measure = Measure.joins(source: :source_type)
                                      .where(sources: {human: human, source_type: source_type})
                                      .where(biomarker: biomarker)
                                      .maximum(:date)

    return false unless latest_biomarker_measure

    measure.date.to_date == latest_biomarker_measure.to_date
  end

  # Check if the given measure is from the latest exam for the human and source type
  # @param measure [Measure] The measure to check
  # @param human [Human] The human associated with the measure
  # @param source_type [SourceType] The source type of the measure
  # @return [Boolean] True if the measure is from the latest exam, false otherwise
  def is_from_latest_exam?(measure, human, source_type, more_recent_than_measure = nil)
    # Check if sources are being deleted
    sources_being_deleted = Thread.current[:sources_being_deleted] || []

    # Get the most recent measure date for a human, excluding the current measure's source
    # and optionally excluding more_recent_than_measure's source
    # BUT if the source is being deleted, don't exclude it from comparison
    excluded_source_ids = []
    excluded_source_ids << measure.source.id
    excluded_source_ids << more_recent_than_measure.source.id if more_recent_than_measure&.source&.id && sources_being_deleted.include?(more_recent_than_measure.source.id)

    query = Measure.joins(source: :source_type)
                   .where(sources: {human: human, source_type: source_type})
                   .where.not(sources: {id: excluded_source_ids})

    latest_measure_excluding_sources = query.order(date: :desc).first
    Rails.logger.info "====> latest_measure_excluding_sources: #{latest_measure_excluding_sources&.id} - #{latest_measure_excluding_sources&.date}"
    return true unless latest_measure_excluding_sources

    # Check if the current measure's date is the same as or later than the latest measure's date
    # from other sources
    result = measure.date.to_date >= latest_measure_excluding_sources.date.to_date
    Rails.logger.info "====> new_measure_is_from_latest_exam?: #{result}"

    result
  end
end

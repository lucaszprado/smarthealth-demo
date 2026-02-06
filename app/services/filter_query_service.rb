class FilterQueryService
  def initialize(human, selection_criteria = {})
    @human = human
    @selection_criteria = selection_criteria.to_h.symbolize_keys
    @types = Array(@selection_criteria[:types]&.map(&:titleize) || ["Blood", "Bioimpedance"])
    @filter_conditions = Array(@selection_criteria[:filters])
    @query = @selection_criteria[:query]
  end

  attr_reader :types, :filter_conditions, :query

  def call
    # if no filters are provided, return all biomarkers based on its type
    return get_unfiltered_biomarkers unless @filter_conditions.present?

    # Get filtered biomarkers from denormalized data
    filtered_biomarkers = get_filtered_biomarkers

    # If search query present, apply search on filtered results
    if @query.present?
      filtered_biomarkers = apply_search_on_filtered_biomarkers(filtered_biomarkers)
    end

    # Return filtered biomarkers
    filtered_biomarkers
  end

  private

  def get_unfiltered_biomarkers
    birthdate = @human.birthdate.strftime('%Y-%m-%d')
    gender = @human.gender
    @types = @types.present? ? @types : ["Blood", "Bioimpedance"]

    if @query.present?
      search_query = @query.split.map {|term| "#{term}:*"}.join(" | ")
      Biomarker.search_last_measure_by_source_for_ids(human_id: @human.id, birthdate: birthdate, gender: gender, query: search_query, source_type_names: @types)
    else
      Biomarker.search_last_measure_by_source_for_ids(human_id: @human.id, birthdate: birthdate, gender: gender, source_type_names: @types)
    end
  end

  def get_filtered_biomarkers
    # Get biomarkers IDs from filtered denormalized data
    filtered_biomarker_ids = get_filtered_biomarker_ids

    # If no biomarkers match filters, return empty array
    return [] if filtered_biomarker_ids.empty?

    # Get full biomarker data with measures for filtered biomarkers
    get_biomarkers_data_for_ids(filtered_biomarker_ids)
  end

  def get_filtered_biomarker_ids
    query = Filter.by_human(@human.id)

    # Add filterable type to the query
    query = query.by_filterable_type(Array(@types).map(&:downcase))

    # Apply filter conditions if any
    @filter_conditions.each do |filter|
      case filter
      when "out_of_range"
        query = query.out_of_range
      when "is_from_latest_exam"
        query = query.is_from_latest_exam
      end
    end

    # Rails.logger.info "query: #{query.to_sql}"
    query.joins(:measure).pluck('measures.biomarker_id') # Returns array of biomarker IDs
  end

  def get_biomarkers_data_for_ids(biomarker_ids)
    birthdate = @human.birthdate.strftime('%Y-%m-%d')
    gender = @human.gender

    Biomarker.search_last_measure_by_source_for_ids(human_id: @human.id, birthdate: birthdate, gender: gender, source_type_names: @types, biomarker_ids: biomarker_ids)
  end

  def apply_search_on_filtered_biomarkers(filtered_biomarkers)
    birthdate = @human.birthdate.strftime('%Y-%m-%d')
    gender = @human.gender

    Biomarker.search_last_measure_by_source_for_ids(
      human_id: @human.id,
      birthdate: birthdate,
      gender: gender,
      query: @query.split.map {|term| "#{term}:*"}.join(" | "),
      source_type_names: @types,
      biomarker_ids: filtered_biomarkers.pluck(:biomarker_id)
    )
  end
end

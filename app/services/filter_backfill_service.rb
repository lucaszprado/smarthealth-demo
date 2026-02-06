class FilterBackfillService
  def initialize(source_type)
    @stats = {
      humans_processed: 0,
      filters_created_or_updated: 0,
      errors: 0,
      start_time: Time.now,
      measures_with_errors: {}
    }
    @update_service = FilterUpdateService.new
    @source_type = source_type
  end

  def call
    Rails.logger.info "\n\nStarting FilterBackfillService...\n\n"

    ActiveRecord::Base.transaction do
     process_all_humans_with_measures(@source_type)
     log_summary_statistics
    end

    @stats
  rescue => e
    Rails.logger.error "Backfill failed: #{e.class}Error - #{e.message} \n"
    Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
    raise
  end

  private

  def process_all_humans_with_measures(source_type)
    source_type_obj = SourceType.find_by(name: source_type)

    return unless source_type_obj

    humans_with_measures = Human.joins(sources: :measures)
                                .where(sources: {source_type_id: source_type_obj.id})
                                .distinct
                                .includes(sources: {measures: :biomarker})

    Rails.logger.info "Found #{humans_with_measures.count} humans with measures"

    humans_with_measures.each do |human|
      process_humans_biomarkers(human, source_type)
      @stats[:humans_processed] += 1
    end
  end


  def process_humans_biomarkers(human, source_type)

    # Get unique biomarkers for this human filtered by source_type
    biomarkers = human.biomarkers_by_source_type(source_type)

    biomarkers.each do |biomarker|
      process_human_biomarker(human, biomarker)
    end
  rescue => e
    Rails.logger.error "Error processing human biomarker: #{e.class}- #{e.message} \n"
    Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
  end




  def process_human_biomarker(human, biomarker)
    latest_measure = Measure.joins(:source)
                          .where(source: {human: human})
                          .where(biomarker: biomarker)
                          .order(date: :desc)
                          .first

    return unless latest_measure

    # Use existing update service to create/update filter
    result = @update_service.call(latest_measure)

    @stats[:filters_created_or_updated] += 1 unless result.nil?

  rescue => e
    Rails.logger.error "Error processing human id #{human.id} biomarker id #{biomarker.id} \n #{e.class}Error - #{e.message} \n"
    @stats[:errors] += 1
  end

  def log_summary_statistics
    duration = Time.now - @stats[:start_time]
    Rails.logger.info "=== Backfill Summary ==="
    Rails.logger.info "Backfill completed in #{duration.round(2)} seconds"
    Rails.logger.info "Processed #{@stats[:humans_processed]} humans"
    Rails.logger.info "Created #{@stats[:filters_created_or_updated]} filters"
    Rails.logger.info "Errors: #{@stats[:errors]}"
    Rails.logger.info "=== End of Summary ==="
  end
end

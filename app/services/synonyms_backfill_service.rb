class SynonymsBackfillService

  def initialize
    file_prefix = Rails.env.production? ? 'prod' : 'development'
    file_pattern = Rails.root.join('external-files', 'environment-files', "#{file_prefix}_biomarkers_translated_*.xlsx")
    input_file_path = Dir[file_pattern].max # Get most recent file by sorting alphabetically. Dir[file_pattern] returns an array of file paths that match the given pattern using shell-style glob syntax.

    raise "No matching file found for pattern: #{file_pattern}" if input_file_path.nil?
    @biomarkers_missing_synonyms_array = ExcelParserService.new(input_file_path).parse_sheet('Sheet1')

    @error_count = 0
    @errors = []
    @success_count = 0
  end

  def backfill_synonyms

    @biomarkers_missing_synonyms_array.each do |biomarker|
      biomarker_id = biomarker[:biomarker_id]
      biomarker_synonym = biomarker[:portuguese_synonym].strip

      # Create a new synonym for the biomarker
      Synonym.create!(
        biomarker_id: biomarker_id,
        name: biomarker_synonym,
        language: 'PT'
      )

      @success_count += 1
    end

    log_results

    {
      success: @success_count,
      errors: @error_count,
      error_details: @errors
    }

  rescue ActiveRecord::RecordInvalid => e
    @error_count += 1
    @errors << "Row #{row_number}: Failed to create synonym - #{e.message}"
  rescue StandardError => e
    @error_count += 1
    @errors << "Row #{row_number}: Unexpected error - #{e.message}"
  end

  private

  def log_results
    Rails.logger.info "Synonyms backfill completed: #{@success_count} created, #{@error_count} errors"

    if @errors.any?
      Rails.logger.error "Backfill errors:\n#{@errors.join("\n")}"
    end
  end
end

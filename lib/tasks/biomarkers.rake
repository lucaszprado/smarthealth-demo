namespace :biomarkers do
  desc "Export biomarkers with no Portuguese synonyms to Excel file"
  task export_missing_synonyms: :environment do
    puts "Indentifying biomarkers with no Portuguese synonyms..."

    # Get the data
    identifier_service = IdentifyBiomarkersWithNoPortugueseSynonyms.new
    biomarkers_data = identifier_service.call_for_export # biomarkers_data is an array of hashes

    if biomarkers_data.empty?
      puts "No biomarkers with no Portuguese synonyms found"
      next
    end

    puts "Found #{biomarkers_data.count} biomarkers with no Portuguese synonyms"

    # Define headers for Excel export
    # the the headers in the export file must match the name of the hash's keys or the attributes of the active record attributes defined in the data to exported. In this case, biomarkers_data.
    headers = ["Row Number", "Biomarker ID", "Biomarker Name", "Biomarker External Reference", "Number of Measures"]

    # Create Excel export service
    excel_export_service = ExcelExportService.new(biomarkers_data, headers, sheet_name: "Missing Portuguese Synonyms")

    # Handle different environments
    if Rails.env.development?
      # Save to tmp doirectory in development
      file_path = excel_export_service.save_to_tmp("biomarkers_missing_portuguese_synonyms")
      puts "Excel file saved to: #{file_path}"
      puts "You can find the file at: #{File.expand_path(file_path)}" # File.expand_path(file_path) converts a relative file path into its absolute (full) path.
    else
      # In production/Heroku, we could save to S3 or just generate the content
      # For now, let's save to tmp and provide instructions
      file_path = excel_export_service.save_to_tmp("biomarkers_missing_portuguese_synonyms")
      puts "✅ Excel file generated at: #{file_path}"
      puts "⚠️  Note: On Heroku, this file is temporary and will be lost when the dyno restarts."
      puts "💡 Consider downloading it immediately or implementing S3 storage for production use."
    end

    puts "📋 Summary:"
    puts "   - Total biomarkers missing PT synonyms: #{biomarkers_data.count}"
    puts "   - File format: Excel (.xlsx)"
    puts "   - Columns: #{headers.join(', ')}"
  end

  

  desc "Backfill Portugueses synonyms for biomarkers"
  task backfill_synonyms: :environment do
    service = SynonymsBackfillService.new
    results = service.backfill_synonyms

    puts "Results: #{results[:success]} created, #{results[:errors]} errors"

    if results[:error_details].any?
      puts "\nErrors:"
      results[:error_details].each { |error| puts "  - #{error}" }
    end
  end
end

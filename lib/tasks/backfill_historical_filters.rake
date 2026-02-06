namespace :backfill do
  desc "Backfill historical filters for all existing measures"
  task historical_filters: :environment do
    puts "Starting historical filter backfill..."
    puts "This will create/update filters for all humans with existing measures."
    puts ""

    # Process Blood source type
    puts "Processing Blood source type..."
    begin
      service = FilterBackfillService.new("Blood")
      @stats = service.call
      puts "================================================"
      puts "Blood backfill completed successfully!"
      puts "Summary:"
      puts "  - Humans processed: #{@stats[:humans_processed]}"
      puts "  - Filters created or updated: #{@stats[:filters_created_or_updated]}"
      puts "  - Errors: #{@stats[:errors]}"
    rescue => e
      puts ""
      puts "❌ Blood backfill failed: #{e.message}"
      puts "Check the Rails logs for detailed error information."
    end

    puts ""
    puts "Processing Bioimpedance source type..."
    begin
      service = FilterBackfillService.new("Bioimpedance")
      @stats = service.call
      puts "================================================"
      puts "Bioimpedance backfill completed successfully!"
      puts "Summary:"
      puts "  - Humans processed: #{@stats[:humans_processed]}"
      puts "  - Filters created or updated: #{@stats[:filters_created_or_updated]}"
      puts "  - Errors: #{@stats[:errors]}"
    rescue => e
      puts ""
      puts "❌ Bioimpedance backfill failed: #{e.message}"
      puts "Check the Rails logs for detailed error information."
    end

    puts ""
    puts "Historical filter backfill process completed!"
  end
end

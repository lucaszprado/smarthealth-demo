namespace :biomarker_labels do
  desc "Setup biomarker labels"
  task setup: :environment do
    puts "Starting biomarker label setup process..."
    puts "This will create labels, relationships, and assignments from Excel file."
    puts "========================================"
    puts "Starting the process..."
    puts "======================================="

    begin
      service = BiomarkerLabelSetupService.new
      stats = service.call

      puts "======================================="
      puts "Biomarker label setup completed!"
      if stats[:errors].any?
        puts ""
        puts "Errors encountered:"
        stats[:errors].each do |error|
          puts "  - #{error}"
        end
      end
      puts "======================================="
      puts "Stats:"
      puts "Labels created: #{stats[:labels_created]}"
      puts "Label relationships created: #{stats[:label_relationships_created]}"
      puts "Label assignments created: #{stats[:label_assignments_created]}"
      puts "======================================="
      puts "Process completed successfully!"
    rescue => e
      puts "======================================="
      puts ""
      puts "❌ Biomarker label setup failed: #{e.message}"
      puts "Error details:"
      puts "#{e.backtrace.join("\n  - ")}"
      puts "Check the Rails logs for detailed error information."
      exit 1
      puts "======================================="
      next
    end

  end
end

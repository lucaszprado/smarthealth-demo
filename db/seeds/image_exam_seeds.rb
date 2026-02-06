require 'roo'

puts "Seeding data for the image exams..."

# Path to your XLSX file -> Roo needs the path name to be a string
xlsx_file_path = Rails.root.join('external-files', 'seed-files', 'seeds-image-exams.xlsx').to_s


# Open the XLSX file
xlsx = Roo::Spreadsheet.open(xlsx_file_path)

# Log file for errors
log_file_path = Rails.root.join('db', 'seeds', 'error_log.txt')
File.open(log_file_path, 'w') {} # Reset log file

def log_error(message)
  File.open(Rails.root.join('db', 'seeds', 'error_log.txt'), 'a') do |f|
    f.puts message
  end
end

# Iterate through each sheet (tab) to create instances of Models: ImageMethod, SourceType and Label
xlsx.sheets.each do |sheet_name|
  begin
    next if sheet_name.blank?

    # klass stores the model name: Label, LabelRelationship -> It will be used to create the instances of each model
    klass = sheet_name.singularize.camelize.constantize # Dynamically find model

    puts "Processing #{klass}..."

    # Read the sheet
    sheet = xlsx.sheet(sheet_name)

    # Convert headers (strings) into snake_case -> To match DB Column names
    # Headers is an array
    headers = sheet.row(1).map(&:underscore) # Normalize headers to match column names

    # Count rows for debugging
    total_rows = sheet.last_row - 1  # Exclude headers
    puts "Processing #{klass}... Found #{total_rows} rows"

    # Process rows, ensuring non-empty rows
    sheet.each_row_streaming(offset: 1).with_index do |row, index|
      values = row.map(&:value).compact  # Remove nil values
      next if values.empty? # Skip empty rows

      attributes = Hash[headers.zip(values)]

      if klass == LabelRelationship
        # Handle associations for LabelRelationship
        parent_label = Label.find_by(name: attributes['parent_label_name'])
        child_label = Label.find_by(name: attributes['child_label_name'])

        if parent_label && child_label
          klass.create!(parent_label_id: parent_label.id, child_label_id: child_label.id)
        else
          log_error("Skipping row: Parent or Child Label not found for #{attributes}")
        end
      else
        # Standard model insertion
        klass.create!(attributes)
      end
    end

    puts "#{klass} records inserted successfully!"

  rescue NameError
    log_error("Skipping #{sheet_name} - Model not found")
  rescue StandardError => e
    log_error("Error processing #{sheet_name}: #{e.message}")
  end
end

puts "Seeding completed! Check db/seeds/error_log.txt for any issues."

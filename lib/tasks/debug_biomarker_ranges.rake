namespace :debug do
  desc "Identify different ranges for biomarkers - debugging utility"
  task identify_biomarker_ranges: :environment do
    puts "%-12s | %-45s | %-6s | %-3s | %-10s | %-10s | %-10s | %-20s | %-20s" % ["Biomarker ID", "Biomarker Name", "Gender", "Age", "Range Id", "Min Value", "Max Value", "Updated At", "Last Updated At (DB)"]
    puts "-" * 165  # Separator line

    Measure.all.map(&:biomarker).uniq.each do |biomarker|
      IdentifyDifferentRangesForBiomarkers.new(biomarker).call
    end
  end
end

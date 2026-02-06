# Debugging utility service to identify biomarkers that don't have Portuguese synonyms.
# Results are sorted by number of measures (descending) to prioritize biomarkers with more data.
#
# @example Usage
#   IdentifyBiomarkersWithNoPortugueseSynonyms.new.call
# @example Usage for export
#   data = IdentifyBiomarkersWithNoPortugueseSynonyms.new.call_for_export
class IdentifyBiomarkersWithNoPortugueseSynonyms

  def initialize
    @biomarkers = Biomarker.left_joins(:measures)
                           .group('biomarkers.id')
                           .order('COUNT(measures.id) DESC')
  end

  # Print a table of biomarkers that don't have Portuguese synonyms
  # The table includes row ID, biomarker ID, name and number of measures
  #
  # @return [nil] This method prints to stdout and returns nil
  def call
    row_id = 0
    puts "%-12s | %-12s | %-90s | %-15s" % ["Row ID", "Biomarker ID", "Biomarker Name", "Number of Measures"]
    puts "-" * 75
    @biomarkers.each_with_index do |biomarker, index|
      if biomarker.synonyms.none? { |synonym| synonym.language == "PT" }
        measures_count = biomarker.measures.count
        printf "%-12s | %-12s | %-90s | %-15s\n",
               row_id += 1,
               biomarker.id,
               biomarker.name,
               measures_count
      end
    end
  end

  # Return data for export
  #
  # @return [Array<Hash>] Array of hashes with biomarker data
  # @example
  #   [
  #     {
  #       row_id: 1,
  #       biomarker_id: 123,
  #       biomarker_name: "Glucose",
  #       biomarker_external_reference: "GLU001",
  #       number_of_measures: 1500
  #     },
  #     {
  #       row_id: 2,
  #       biomarker_id: 456,
  #       biomarker_name: "Hemoglobin",
  #       biomarker_external_reference: "HGB002",
  #       number_of_measures: 1200
  #     }
  #   ]
  def call_for_export
    results = []
    row_id = 0

    @biomarkers.each do |biomarker|
      if biomarker.synonyms.none? { |synonym| synonym.language == "PT" }
        measures_count = biomarker.measures.count
        results << {
          row_number: row_id += 1,
          biomarker_id: biomarker.id,
          biomarker_name: biomarker.name,
          biomarker_external_reference: biomarker.external_ref,
          number_of_measures: measures_count
        }
      end
    end

    results
  end
end

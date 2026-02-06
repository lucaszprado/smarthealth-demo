# Debugging utility service to identify biomarkers with different ranges
# for the same gender and age combination.
#
# This service is used via the rake task: rails debug:identify_biomarker_ranges
#
# @example Usage
#   IdentifyDifferentRangesForBiomarkers.new(biomarker).call
class IdentifyDifferentRangesForBiomarkers
  def initialize(biomarker)
    @biomarker = biomarker
  end

  def call
    for gender in ["M", "F"]
      for age in 0..100
        ranges_ids = different_ranges_ids(@biomarker, gender, age)
        if ranges_ids.present?
          last_updated_at = @biomarker.biomarkers_ranges.where(gender: gender, age: age).order(updated_at: :desc).first.updated_at.strftime("%Y-%m-%d %H:%M:%S")
          ranges = BiomarkersRange.where(id: ranges_ids).each do |range|
            printf "%-12s | %-45s | %-6s | %-3s | %-10s | %-10s | %-10s | %-20s | %-20s\n",
                  @biomarker.id,
                  @biomarker.name,
                  gender,
                  age,
                  range.id,
                  range.possible_min_value,
                  range.possible_max_value,
                  range.updated_at.strftime("%Y-%m-%d %H:%M:%S"),
                  last_updated_at
          end
        end
      end
    end
  end



  private

  def different_ranges_ids(biomarker, gender, age)
    ranges = []
    biomarker.biomarkers_ranges.where(gender: gender, age: age).each_cons(2) do |range, next_range|
      if range.possible_min_value != next_range.possible_min_value || range.possible_max_value != next_range.possible_max_value
        unless ranges.include?(range.id)
          ranges << range.id
        end
        unless ranges.include?(next_range.id)
          ranges << next_range.id
        end
      end
    end
    ranges
  end

end

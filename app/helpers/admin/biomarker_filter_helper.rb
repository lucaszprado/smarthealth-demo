module Admin::BiomarkerFilterHelper
  def biomarker_dropdown_collection
    Biomarker.with_pt_synonyms_ordered_by_name.map do |b|
      [b.sort_name, b.id]
      #  because map returns an array, and you’re returning an array on each iteration, you end up with an array of arrays.
    end
  end
end

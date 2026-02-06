ActiveAdmin.register BiomarkersRange do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :name, :synomys_string, :value_type, :external_ref
  #
  # or
  #
  permit_params do
    permitted = [:biomarker_id, :gender, :age, :possible_min_value, :possible_max_value, :optimal_min_value, :optimal_max_value]
    permitted << :other if params[:action] == 'create'
    permitted
  end

  preserve_default_filters!
  filter :biomarker, as: :select, collection: -> {
    Biomarker.order(:id).map {|b| ["#{b.id} | #{b.name}", b.id]}
  }, label: "Biomarker ID"

  csv do
    column :id
    column :gender
    column :age
    column :possible_min_value
    column :possible_max_value
    column("Biomaker ID") { |biomarkers_range| biomarkers_range.biomarker.id }
    column(:biomaker_EN) { |biomarkers_range| biomarkers_range.biomarker.name }
    column(:biomarker_PT) do |measure|
      if measure.biomarker
        pt_synonyms = measure.biomarker.synonyms.select { |s| s.language == "PT" }
        pt_synonyms.map(&:name).join(", ") || measure.biomarker.name
      end
    end

    column :created_at
    column :updated_at
  end
end

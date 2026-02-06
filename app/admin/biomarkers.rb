ActiveAdmin.register Biomarker do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :name, :external_ref
  #
  # or
  #

  # Split the params into the array Ransack expects for *_cont_all -> Allows for multiple words to be searched for
  # for the key :name_or_synonyms_name_i_cont_all
  before_action only: :index do
    key = :name_or_synonyms_name_i_cont_all
    if (s = params.dig(:q, key)).is_a?(String)
      params[:q][key] = s.split(/\s+/).reject(&:blank?)
    end
  end

  # Include synonyms and categories in the index - eager load
  # De-duplicate results when JOINing synonyms (has_many) -> See before action callback
  controller do
    def scoped_collection
      collection = super.includes(:synonyms, :categories, :units).distinct
    end
  end



  permit_params do
    permitted = [:name, :external_ref, :biomarkers_range_id]
    permitted << :other if params[:action] == 'create'
    permitted
  end

  index do
    column :id
    column :name
    column :external_ref
    column(:biomarker_PT) do |biomarker|
      pt_synonyms = biomarker.synonyms.select { |s| s.language == "PT" }
    end
    column(:categories) do |biomarker|
      biomarker.categories.distinct
    end
    column(:units) do |biomarker|
      biomarker.units.distinct
    end
    column :created_at
    column :updated_at
    actions
  end

  # OR across attributes + partial match + ALL terms
  # Search will be on the attribute name or name from the associated synonyms table
  # i_cont_all -> case insensitive + partial match + ALL terms
  filter :name_or_synonyms_name_i_cont_all, as: :string, label: "Name or Synonym"


  filter :id, as: :select, collection: -> {
    Biomarker.order(:id).pluck(:id)
  }, label: "Biomarker ID"


  filter :external_ref, as: :select
  filter :created_at
  filter :updated_at

  # Show page for a biomarker
  show do
    attributes_table do
      row :id
      row :name
      row :external_ref
      row "Units" do |biomarker|
        biomarker.units
      end
      row :created_at
      row :updated_at
    end
  end

  csv do
    column :id
    column :name

    column("PT Synonyms") do |biomarker|
      pt_synonyms = biomarker.synonyms.select { |s| s.language == "PT" }
      pt_synonyms.map(&:name).join(", ") || nil
    end
    column("Unit") do |biomarker|
      biomarker.units.map(&:name).join(", ") || nil
    end
    column("Category") do |biomarker|
      biomarker.categories.map(&:name).join(", ") || nil
    end

    column :created_at
    column :updated_at
    column :external_ref

  end

end

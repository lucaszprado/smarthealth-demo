ActiveAdmin.register Measure do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :value, :original_value, :date, :biomarker_id, :category_id, :unit_id, :source_id
  #
  # or
  #


  before_action only: :index do
    key = :biomarker_name_or_biomarker_synonyms_name_i_cont_all
    if (s = params.dig(:q, key)).is_a?(String)
      params[:q][key] = s.split(/\s+/).reject(&:blank?)
    end
  end

  #De-duplicate results when JOINing synonyms (has_many) -> See before action callback
  # Chain is the current ActiveRecord::Relation for your resource at that point in ActiveAdmin’s pipeline (after scopes/authorization, etc.).
  controller do
    # Let AA build the chain as usual, then enforce DISTINCT
    # This is the current ActiveRecord::Relation for your resource at that point in ActiveAdmin’s pipeline (after scoped_collection, scopes/authorization, etc.).
    def apply_filtering(chain)
      super(chain).distinct
    end
  end

  permit_params do
    permitted = [:value, :original_value, :date, :biomarker_id, :category_id, :unit_id, :source_id]
    permitted << :other if params[:action] == 'create' # && current_user.admin? -> LP: Removed authorization
    permitted
  end

  # Measures index
  index do
    selectable_column
    id_column
    column :value
    column :original_value
    column :date
    column :biomarker
    column(:biomarker_PT) do |measure|
      if measure.biomarker
        pt_synonyms = measure.biomarker.synonyms.select { |s| s.language == "PT" }
        # pt_synonyms.map(&:name).join(", ") || measure.biomarker.name
        pt_synonyms || measure.biomarker
        # It's better to return the objects. This way ActiveAdmin make them clickable.
      end
    end
    column :category
    column :unit
    column :source
    column "Human" do |measure|
      link_to measure.source.human.name, admin_human_path(measure.source.human) if measure.source&.human
    end
    actions
  end

  # Show page for a measure
  show do
    attributes_table do
      row :value
      row :original_value
      row :date
      row :biomarker
      row :category
      row :unit
      row :source
      row :created_at
      row :updated_at
      row "Human" do |measure|
        link_to measure.source.human.name, admin_human_path(measure.source.human) if measure.source&.human
      end
    end
  end

  # Customize the form (Create) to use a dropdown for `source_id`
  form do |f|
    f.inputs do
      f.input :value
      f.input :original_value
      f.input :date, as: :datepicker
      f.input :biomarker, as: :select, collection: Biomarker.order(:name).pluck(:name, :id)
      f.input :category, as: :select, collection: Category.order(:name).pluck(:name, :id)
      f.input :unit, as: :select, collection: Unit.order(:name).pluck(:name, :id)
      f.input :source, as: :select, collection: Source.includes(:human).map { |source| ["#{source.id} - #{source.human.name}", source.id] }, label: "Source (ID - Human Name)"
    end
    f.actions
  end

  preserve_default_filters!

  filter :id, as: :select, collection: -> {
    Measure.order(:id).pluck(:id)
  }, label: "Measure ID"

  filter :source, as: :select, collection: -> {
    # Fetches the Source records and maps them to show `source_id - Human Name`
    Source.includes(:human).map do |source|
      human_name = source.human.name
      ["#{source.id} - #{human_name}", source.id]
    end
  }, label: "Source (ID - Human Name)"

  filter :source_human_id, as: :select, collection: -> {
    Human.order(:id).pluck(:id)
  }, label: "Human ID"

  filter :source_human_name_eq, as: :select, collection: -> {
    Human.order(:name).pluck(:name)
  }, label: "Exact Human Name"

  filter :biomarker, as: :select, collection: -> {
    Biomarker.order(:id).map {|b| ["#{b.id} | #{b.name}", b.id]}
  }, label: "Biomarker ID"

  filter :biomarker_synonyms_name_eq, as: :select, collection: -> {
    Synonym.where(language: "PT").order(:name).pluck(:name).uniq
  }, label: "Biomarker PT"


  filter :biomarker_name_or_biomarker_synonyms_name_i_cont_all, as: :string, label: "Biomarker Name or Synonym"

  # This filter can be used. Ransack only accepts one filter condition per resource.
  # filter :biomarker, as: :select, collection: -> {
  #   biomarker_dropdown_collection
  # }, label: "Biomarker PT"

  # Define custom csv export
  # By default ActiveAdmin only exports model attributes
  # If we want associantions os calculated fields we must
  # customize the csv DSL method provided by Active Admin
  # For each measure we bring the attribute or run the block
  # Measure is the argument for each block statement
  csv do
    column :id
    column :value
    column :original_value

    column(:date) do |measure|
      measure.date.strftime("%Y-%m-%d") if measure.date
    end

    column("Unit ID") { |measure| measure.unit.id if measure.unit }
    column(:unit) { |measure| measure.unit.name if measure.unit }
    column("Biomarker ID") {|measure| measure.biomarker.id if measure.biomarker}
    column(:biomarker_EN) {|measure| measure.biomarker.name if measure.biomarker}

    column(:biomarker_PT) do |measure|
      if measure.biomarker
        pt_synonyms = measure.biomarker.synonyms.select { |s| s.language == "PT" }
        pt_synonyms.map(&:name).join(", ") || measure.biomarker.name
      end
    end

    column("Category ID") { |measure| measure.category.id if measure.category }
    column(:category) { |measure| measure.category.name if measure.category }
    column("Human") { |measure| measure.source.human.name if measure.source&.human }
    column(:source_id) { |measure| measure.source.id if measure.source }
    column :created_at
    column :updated_at
  end


  # We're overriding ActiveAdmin standard controller behaviour
  # Super returns the standard controller class
  controller do

  # Measure.all is the standard controller method for this resource
  # The scope with_biomarkers_and_synonyms eager loads synonyms along with measures.all
  # Final output: Measure.all.includes(biomarker: :synonyms)
    def scoped_collection
      super.with_biomarker_and_synonyms
    end

    # Rails does not automatically include custom helper modules into ActiveAdmin DSL files
    # This tells ActiveAdmin’s controller/view layer to include your helper
    helper Admin::BiomarkerFilterHelper
  end
end

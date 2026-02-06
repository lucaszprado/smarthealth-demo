ActiveAdmin.register Filter do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :measure_id, :range_status, :is_from_latest_exam, :filterable_type
  #
  # or
  #
  # permit_params do
  #   permitted = [:measure_id, :range_status, :is_from_latest_exam, :filterable_type]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  index do
    column :id
    column :measure
    column :human do |filter| # This a virtual column
      filter.measure.source.human.name
    end

    column :biomarker do |filter|
      filter.measure.biomarker.name
    end

    column :range_status
    column :is_from_latest_exam
    column :filterable_type
    column :created_at
    column :updated_at
    actions
  end

  preserve_default_filters!

  # We use Ransack association to fetch the human name from the virtual column human
  filter :measure_source_human_name_eq, as: :select, collection: -> {
    Human.order(:name).pluck(:name)
  }, label: "Human"

  filter :measure_biomarker_id_eq, as: :select, collection: -> {
    Biomarker.order(:id).map {|b| ["#{b.id} | #{b.name}", b.id]}
  }, label: "Biomarker"

  filter :measure_id, as: :select, collection: -> {
    Measure.order(:id).pluck(:id)
  }, label: "Measure ID"

end

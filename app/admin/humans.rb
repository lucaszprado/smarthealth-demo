ActiveAdmin.register Human do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :name, :gender, :birthdate
  #
  # or
  #
  permit_params do
    permitted = [:name, :gender, :birthdate, :phone_number]
    permitted << :other if params[:action] == 'create'
    permitted
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :gender
      f.input :birthdate, as: :date_select, start_year: 1930, end_year: Date.today.year
      f.input :phone_number
    end
    f.actions
  end

  preserve_default_filters!

  filter :id, as: :select, collection: -> {
    Human.order(:id).pluck(:id)
  }, label: "Human ID"

  filter :name, as: :select, collection: -> {
    Human.order(:name).pluck(:name).uniq
  }, label: "Human name"

end

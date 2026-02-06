ActiveAdmin.register HealthProfessional do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :name
  #
  # or
  #
  permit_params do
    permitted = [:name]
    permitted << :other if params[:action] == 'create' # && current_user.admin? -> LP: Removed authorization
    permitted
  end

  index do
    selectable_column
    id_column
    column :name
    column :created_at
    column :updated_at
    actions
  end

  form do |f|
    f.inputs do
      f.input :name

    end
    f.actions
  end

end

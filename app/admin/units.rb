ActiveAdmin.register Unit do

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
    permitted = [:name, :synomys_string, :value_type, :external_ref]
    permitted << :other if params[:action] == 'create'
    permitted
  end

  show do
    attributes_table do
      row :id
      row :name
      row :synomys_string
      row :value_type
      row :external_ref
      row :created_at
      row :updated_at
    end
  end

end

ActiveAdmin.register Label do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :name, parent_ids: [], child_ids: []
  #
  # or
  #
  # permit_params do
  #   permitted = [:name]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  # Customize the form (Create)
  form do |f|
    f.inputs do
      f.input :name
      f.input :parents, label: "Parents", as: :select, collection: Label.order(:name).pluck(:name, :id), input_html: { multiple: true }
      f.input :children, label: "Children", as: :select, collection: Label.order(:name).pluck(:name, :id), input_html: { multiple: true }
    end
    f.actions
  end

  show do
    attributes_table do
      row :name
      row :children
      row :parents
      row :created_at
      row :updated_at
    end
  end
end

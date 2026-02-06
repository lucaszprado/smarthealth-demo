ActiveAdmin.register ImagingReport do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :content, :source_id, :imaging_method_id, :report_summary_id, :date
  #
  # or
  #
  # permit_params do
  #   permitted = [:content, :source_id, :imaging_method_id, :report_summary_id, :date]
  #   permitted << :other if params[:action] == 'create' && ## current_user.admin?
  #   permitted
  # end

  index do
    selectable_column
    id_column

    column "Human" do |imaging_report|
      link_to imaging_report.source.human.name, admin_human_path(imaging_report.source.human) if imaging_report.source&.human
    end

    column "Imaging Method", :imaging_method, sortable: "imaging_methods.name" do |report|
      report.imaging_method&.name
    end

    column "Source", :source, sortable: :source_id do |report|
      link_to report.source_id, admin_source_path(report.source) if report.source
    end

    column :content
    column :date
    column :report_summary_id
    actions
  end

  show do
    attributes_table do
      row :id

      row "Human" do |imaging_report|
      link_to imaging_report.source.human.name, admin_human_path(imaging_report.source.human) if imaging_report.source&.human
      end

      row "Imaging Method" do |report|
        report.imaging_method&.name
      end


      row "Source" do |report|
        link_to report.source_id, admin_source_path(report.source) if report.source
      end

      row :content
      row :date
      row :report_summary_id
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :imaging_method, as: :select, collection: ImagingMethod.all.map { |m| [m.name, m.id] }
      f.input :source, as: :select, collection: Source.includes(:human).map { |source| ["#{source.id} - #{source.human.name}", source.id] }, label: "Source (ID - Human Name)"
      f.input :content, as: :text, input_html: { rows: 10, cols: 80 }
      f.input :date, as: :datepicker
      f.input :report_summary_id
    end
    f.actions
  end



  filter :source, as: :select, collection: -> {
    # Fetches the Source records and maps them to show `source_id - Human Name`
    Source.includes(:human).map do |source|
      human_name = source.human.name
      ["#{source.id} - #{human_name}", source.id]
    end
  }, label: "Source (ID - Human Name)"

  filter :source_human_name_cont, as: :string, label: "Human Name"
  filter :label_assignments, as: :select, collection: -> { LabelAssignment.order(:label_id).pluck(:label_id, :id) }
end

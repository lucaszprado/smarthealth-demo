ActiveAdmin.register Source do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :source_type_id, :human_id, :health_professional_id, :health_provider_id, files: []
  #
  # or
  #

  # permit_params do
  #   permitted = :source_type_id, :human_id, {files: []}
  #   permitted << :other if params[:action] == 'create' #&& current_user.admin?
  #   permitted
  # end


  # @!method update
  #   Overrides ActiveAdmin's default update method to handle file attachments.
  #   When updating a source, if no new files are selected (i.e. the files parameter array
  #   contains only blank values), it removes the files parameter to prevent overriding
  #   existing attachments. This preserves existing files when the form is submitted
  #   without selecting new files.

  #   When a new file is selected, ActiveAdmin, by default, will replace all existing attachments with the new ones.
  #   In this process ActiveAdmin will upload the new files without the metadata. This will cause the files not to be displayed in the frontend.
  #
  #   @param [Hash] params The request parameters containing source attributes
  #   @option params [Array] :files Array of file attachments
  #   @return [void]
  #
  controller do
    def update
      # pull out the nested hash for your model
      src_params = params[:source]
      puts "🔍 ============SRC PARAMS BEFORE: #{src_params.inspect}"

      if src_params
        if src_params[:files].is_a?(Array) && src_params[:files].all?(&:blank?)
          # no real files selected → don’t override existing attachments
          src_params.delete(:files)
        end
      puts "🔍 ============SRC PARAMS AFTER: #{src_params.inspect}"
      end

      super
    end
  end




  # This form block defines the interface for both creating new sources and editing existing ones in the ActiveAdmin
  # It creates a form with dropdown selects for human, source type, health professional, and health provider, plus a multi-file upload field that also displays any currently attached files.
  form do |f|
    f.inputs do
      f.input :human, as: :select, collection: Human.all
      f.input :files, as: :file, input_html: {multiple: true} #input_html: { multiple: true } enables the multi-file picker.
      # show already attached files
      if f.object.files.attached?
        ul do
          f.object.files.each do |file|
            li do
              link_to file.filename.to_s, url_for(file)
            end
          end
        end
      end
      f.input :source_type, as: :select, collection: SourceType.all
      f.input :health_professional, as: :select, collection: HealthProfessional.all
      f.input :health_provider, as: :select, collection: HealthProvider.all
    end
    f.actions
  end

  index do
    selectable_column
    id_column
    column :human
    column :source_type
    column :origin
    column(:date) {|source| source&.date}
    column :created_at
    column :updated_at
    column "PDF File" do |source|
      if source.files.attached?
        link_to "View PDF", rails_blob_path(source.files.first, disposition: "inline"), target: "_blank"
      else
        "No File"
      end
    end
    actions
  end

  show do
    attributes_table do
      row :id
      row :human
      row :source_type
      row :health_professional
      row :health_provider
      row :created_at
      row :updated_at
      row :file do |source|
        if source.files.attached?
          ul do
            source.files.each do |file|
              li do
               link_to file.filename, rails_blob_path(source.files.first, disposition: "inline"), target: "_blank"
              end
            end
          end
        else
          "No File"
        end
      end
    end
    active_admin_comments
  end
end

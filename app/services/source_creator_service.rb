class SourceCreatorService
  # params is parameter that receives a hash as an argument
  def self.create_source(params, source_type)

    source_type = SourceType.find_by(name: source_type)
    raise StandardError, "SourceType #{source_type} not found" unless source_type

    model_source = Source.new(
      source_type_id: source_type.id,
      human_id: params[:human_id],
      health_professional_id: params[:health_professional_id],
      health_provider_id: params[:health_provider_id],
      origin: params[:origin]
    )

    ActiveRecord::Base.transaction do
      if model_source.save
        attach_files_with_metadata(model_source, params[:pdf_files], params[:metadata])
        return model_source
      else
        raise ActiveRecord::Rollback, "Failed to create Source: #{model_source.errors.full_messages.join(', ')}"
      end
    end

  rescue => e
    Rails.logger.error "SourceCreatorService Error: #{e.message}"
    raise StandardError, "Source creation failed: #{e.message}"
    # raise ActiveRecord::Rollback, "Failed to create Source: #{model_source.errors.full_messages.join(', ')}"
    # raise Active::Record doesn't stop the transaction -> Controller will receive nil
    # and we have measures with no source
  end

  private

  # This method attach pdf files to a source AND
  # their respective metadata if any.
  # attach_files_with_metadata method (lines 37-59) creates permanent attachments
  def self.attach_files_with_metadata(source, pdf_files, metadata)
    pdf_files.each_with_index do |uploaded_file, index|
      file_type = metadata&.dig(index.to_s, "file_type")
      # &. : safe navigation operator -> only call next method if the object metadata is not nil.
      # dig allows safe nested hash access -> similar to &. -> It's the same as metadata[index.to_s]["file_type"] but without raising an error if any part (key-value pair) is missing or nil.
      # index is converted to string beacuse the keys sent by Postman are strings and not integers.


      # Attach file along with metadata
      attachment = source.files.attach(
        io: uploaded_file,
        filename: uploaded_file.original_filename,
        content_type: uploaded_file.content_type,
        metadata: { file_type: file_type }
        # It's the same as  metadata: { file_type: metadata[index.to_s]["file_type"] }
        # But without raising an error if any part is missing or nil.
      )

      if attachment.blank?
        raise ActiveRecord::Rollback, "Failed to attach file: #{uploaded_file.original_filename}"
      end
    end
  end
end

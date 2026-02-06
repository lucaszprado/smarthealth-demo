class ImagingReportsService
  def self.create(params)
    result = nil

    ActiveRecord::Base.transaction do
      source = SourceCreatorService.create_source(params,"Image")
      fail_with!("Failed to create Source") unless source


      imaging_report = ImagingReport.new(
        imaging_method_id: params[:imaging_method_id],
        source_id: source.id,
        content: params[:content],
        date: Date.parse(params[:date])
      )

      fail_with!("Failed to create ImagingReport: #{imaging_report.errors.full_messages.join(', ')}") unless imaging_report.save

      labels = LabelAssignmentService.create(imaging_report, params)
      fail_with!("Failed to create Labels") unless labels

      result = {
        success: true,
        message: "Imaging report, source and Labels successfully created",
        imaging_report_id: imaging_report.id,
        source_id: source.id,
        labels: labels
      }
    rescue RollbackWithError => e
      result = {error: e.message}
    end

    result
  end

  private

  # We define a specific exeception class that we will raise in case of
  # having errors when creating Source, ImagingReport or Labels
  # This Allows us to rollback just if we get this specif error type.
  class RollbackWithError < StandardError; end


  # Class Method
  # fail_with!("Failed to create Labels") = ImagingReportsService.fail_with!("Failed to create Labels")
  def self.fail_with!(message)
    raise RollbackWithError, message
  end
end

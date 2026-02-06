class ImagingReportsController < ApplicationController

  def index
    Rails.logger.info("params: #{params.inspect}")
    @human = Human.find(params[:human_id])

    # Get structured data directly from the model
    @imaging_reports = ImagingReport.search_for_human(@human.id, params[:query])

    # Define controller response (normal render vs AJAX response)
    respond_to do |format|
      format.html # Follow regular flow of Rails -> Send back a full HTML page
      format.text {
        partial_name = @imaging_reports.empty? ? 'shared/no_data' : 'imaging_reports/data'
        render partial: partial_name, locals: {imaging_reports: @imaging_reports, human: @human}, formats: [:html]
      } # Send back a partial HTML fragment that will be replaced in the list element in the view by JavaScript AJAX
    end

  end

  def show
    @human = Human.find(params[:human_id])
    @imaging_report = ImagingReport.find_structured(params[:id])
  end

end

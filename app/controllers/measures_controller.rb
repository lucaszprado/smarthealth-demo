class MeasuresController < ApplicationController
  # @param biomarker_ids [String, Array<String>] Single ID or multiple biomarker IDs
  # Example:
  #    http://app/humans/1/measures?measures?biomarker_ids[]=159&biomarker_ids[]=39
  # First biomarker is the primary biomarker, the others are the secondary biomarkers
  def index
    @human = Human.find(params[:human_id])
    @selected_ids = Array(params.fetch(:biomarker_ids, []))
    @search_query = params[:query].to_s
    @biomarker_series = []

    # Handle multiple biomarkers request via query parameters
    if params[:biomarker_ids].present?
      biomarker_ids = Array(params[:biomarker_ids]).map(&:to_i)
      primary_biomarker = Biomarker.find(params[:biomarker_ids][0])
      @primary_biomarker_data = Measure.process_biomarker_data(@human, primary_biomarker)


      # Push each biomarker series to preserve the order of the biomarkers from the params request
      biomarker_ids.each do |biomarker_id|
        biomarker = Biomarker.find(biomarker_id)
        biomarker_serie = Measure.create_biomarker_series(@human, [biomarker])
        @biomarker_series.push(*biomarker_serie)
      end

    else
      # No biomarkers specified - show empty state or redirect
      @primary_biomarker_data = {}
      @biomarker_series = []
    end
  end
end

# Handles the following endpoint:
class Api::V1::ImagingReportsController < ActionController::API

  def create
    # Get params
    pdf_files = params[:pdf_files]

    #Validate required params
    if pdf_files.blank?
      return render json: {error: "Missing PDF file"}, status: :unprocessable_entity
    end

    # Create imaging report into database
    result = ImagingReportsService.create(params)

    if result[:error]
      render json: {message: "Erro during upload", error: result[:error]}, status: :unprocessable_entity
    else
      render json: {message: "Upload successful", result: result}, status: :created
    end

  rescue ActiveRecord::RecordNotFound => e
    render json: {error: e.message}, status: :not_found
  rescue StandardError => e
    render json: {error: e.message}, status: :unprocessable_entity
  end
end

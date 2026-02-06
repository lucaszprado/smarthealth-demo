class Api::V1::BioimpedanceMeasuresController < ActionController::API
  def create
    # Get params
    csv_file = params[:csv_file]

    # Validate required params
    if csv_file.blank?
      return render json: {error: "Missing CSV file"}, status: :unprocessable_entity
    end

    # Create bioimpedance measure into database
    result = BioimpedanceMeasuresService.create(params)

    if result[:errors].any?
      render json: {message: "Erro during upload", error: result[:errors]}, status: :unprocessable_entity
    else
      render json: {message: "Upload successful"}, status: :created
    end

  rescue StandardError => e
    render json: {error: e.message}, status: :unprocessable_entity
  end
end

class Api::V1::BloodMeasuresController < ActionController::API
  def create
    # Get params
    pdf_file = params[:pdf_files]
    health_professional_id = params[:health_professional_id]
    health_provider_id = params[:health_provider_id]
    human = Human.find(params[:human_id])


    # Create Source
    source_params = {
        human_id: human.id,
        health_provider_id: health_provider_id,
        health_professional_id: health_professional_id,
        pdf_files: pdf_file,
        origin: :unit
      }

    source = SourceCreatorService.create_source(source_params, "Blood")

    # Parse the pdf
    gender = human.gender
    hash_data = PdfParserApiClient.fetch_parsed_data(gender)

    # Import the parsed pdf into the database
    ParsedPdfBloodMeasuresImporter.import(source, hash_data, human)

    render json: { message: "Measures created successfully" }, status: :created
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end

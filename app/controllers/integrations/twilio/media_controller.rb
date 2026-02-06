class Integrations::Twilio::MediaController < ApplicationController
   # GET /integrations/twilio/twilio_media/:id
   # :id is the media sid
   def show
    media_sid = params[:id]

    begin
      media_service = TwilioMediaService.new
      media_info = media_service.get_media_info(media_sid)
      file_data = media_service.stream_media(media_sid)

      send_data file_data,
                filename: media_info[:filename],
                type: media_info[:content_type],
                disposition: 'inline'
    rescue => e
      Rails.logger.error "Failed to retrieve Twilio media: #{e.message}"
      render json: { error: "Failed to retrieve file" }, status: :unprocessable_entity
    end
  end
end

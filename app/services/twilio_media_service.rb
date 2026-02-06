require 'uri'
require 'net/http'

class TwilioMediaService
  def initialize(api_client = TwilioApiClient.new)
    Rails.logger.info "=== TwilioMediaService initializing ==="
    Rails.logger.info "API client provided: #{api_client.inspect}"
    Rails.logger.info "API client class: #{api_client.class}"

    @api_client = api_client

    # Access the variables through the API client's attr_reader methods
    Rails.logger.info "Getting base_url from API client..."
    @base_url = @api_client.base_url
    Rails.logger.info "Base URL retrieved: #{@base_url.inspect}"

    Rails.logger.info "Getting account_sid from API client..."
    @account_sid = @api_client.account_sid
    Rails.logger.info "Account SID retrieved: #{@account_sid.inspect}"

    Rails.logger.info "Getting auth_token from API client..."
    @auth_token = @api_client.auth_token
    Rails.logger.info "Auth token retrieved: #{@auth_token.inspect}"

    Rails.logger.info "=== TwilioMediaService initialization complete ==="
  end

  # Get Twilio media file information and return download URL
  # @param media_sid [String] The Twilio media SID
  # @param filename [String] Optional filename for the download
  # @return [Hash] Hash containing download_url, content_type, and file_size
  def get_media_info(media_sid)
    Rails.logger.info "=== get_media_info called ==="
    Rails.logger.info "Media SID parameter: #{media_sid.inspect}"
    Rails.logger.info "About to check cache for key: twilio_media_info_#{media_sid}"

    # Cache the media info to avoid repeated API calls
    cache_key = "twilio_media_info_#{media_sid}"
    Rails.logger.info "Cache key: #{cache_key.inspect}"

    begin
      cached_result = Rails.cache.read(cache_key)
      Rails.logger.info "Cache read completed"

      if cached_result
        Rails.logger.info "Cache HIT - returning cached result"
        Rails.logger.info "Cached result: #{cached_result.inspect}"
        return cached_result
      else
        Rails.logger.info "Cache MISS - will fetch from Twilio"
      end
    rescue => e
      Rails.logger.error "Cache read failed: #{e.message}"
      Rails.logger.error "Cache error class: #{e.class}"
      Rails.logger.error "Cache error backtrace: #{e.backtrace.join("\n")}"
      raise
    end

    begin
      Rails.logger.info "About to call Rails.cache.fetch"
      Rails.cache.fetch("twilio_media_info_#{media_sid}", expires_in: 1.hour) do
        Rails.logger.info "Cache miss - calling fetch_media_info"
        meta = fetch_media_info(media_sid)

      download_url = meta.dig("links", "content_direct_temporary")
      Rails.logger.info "Raw download URL from Twilio: #{download_url.inspect}"

      if download_url.blank?
        Rails.logger.error "Download URL is missing from Twilio response"
        Rails.logger.error "Full meta response: #{meta.inspect}"
        raise "Missing download URL in Twilio media response"
      end

      result = {
        download_url: download_url,
        content_type: meta["content_type"],
        file_size: meta["size"],
        filename: meta["filename"],
        media_sid: media_sid
      }

      Rails.logger.info "Created result hash: #{result.inspect}"
      result
    end
    rescue => e
      Rails.logger.error "Rails.cache.fetch failed: #{e.message}"
      Rails.logger.error "Cache fetch error class: #{e.class}"
      Rails.logger.error "Cache fetch error backtrace: #{e.backtrace.join("\n")}"
      raise
    end
  end

  # Stream Twilio media file directly to browser
  # @param media_sid [String] The Twilio media SID
  # @return [String] The file data as a string
  def stream_media(media_sid)
    media_info = get_media_info(media_sid)

    # Note: We don't cache the actual file data since it's temporary
    # and the download URL is already cached
    download_media(media_info[:download_url])
  end

  private

  # Fetch media information from Twilio using direct HTTP
  # @param media_sid [String] The Twilio media SID
  # @return [Hash] Parsed JSON response from Twilio
    def fetch_media_info(media_sid)
    Rails.logger.info "=== fetch_media_info called ==="
    Rails.logger.info "Media SID parameter: #{media_sid.inspect}"
    Rails.logger.info "Media SID class: #{media_sid.class}"
    Rails.logger.info "Media SID nil?: #{media_sid.nil?}"
    Rails.logger.info "Media SID blank?: #{media_sid.blank?}"

    Rails.logger.info "Base URL: #{@base_url.inspect}"
    Rails.logger.info "Base URL class: #{@base_url.class}"
    Rails.logger.info "Base URL nil?: #{@base_url.nil?}"

    full_url = "#{@base_url}/Media/#{media_sid}"
    Rails.logger.info "Full URL to fetch: #{full_url.inspect}"
    Rails.logger.info "Full URL class: #{full_url.class}"

    begin
      uri = URI(full_url)
      Rails.logger.info "URI object created: #{uri.inspect}"
    rescue => e
      Rails.logger.error "Failed to create URI: #{e.message}"
      Rails.logger.error "Error class: #{e.class}"
      Rails.logger.error "Full backtrace: #{e.backtrace.join("\n")}"
      raise
    end

    req = Net::HTTP::Get.new(uri)
    req.basic_auth(@account_sid, @auth_token)

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    if response.code != '200'
      raise "Failed to fetch media info: #{response.code} - #{response.body}"
    end
    Rails.logger.info "Response body: #{response.body.inspect}"
    JSON.parse(response.body)
  end

  # Download media file content
  # @param download_url [String] The direct download URL from Twilio
  # @return [String] The file data as a string
  def download_media(download_url)
    Rails.logger.info "Download URL: #{download_url.inspect}"
    Rails.logger.info "Download URL class: #{download_url.class}"

    if download_url.blank?
      Rails.logger.error "Download URL is blank or nil"
      raise "Invalid download URL: URL is blank"
    end

    begin
      uri = URI(download_url)
      Net::HTTP.get(uri)
    rescue URI::InvalidURIError => e
      Rails.logger.error "Invalid URI: #{download_url}"
      Rails.logger.error "URI error: #{e.message}"
      raise "Invalid download URL: #{e.message}"
    end
  end
end

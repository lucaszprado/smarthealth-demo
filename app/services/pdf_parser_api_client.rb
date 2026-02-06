require 'net/http'
require 'uri'

# This Client connects to vendor to get parsed PDF
# The endpoint changes based on gender
# Male gets extracted pdf with male references
# female gets extracted pdf with female references
class PdfParserApiClient

  PID_MALE = ENV['PARSER_MALE_ID']
  PID_FEMALE = ENV['PARSER_FEMALE_ID']

  PARSER_URL_MALE = "https://api.smarthealth.com/v1/parse/male"
  PARSER_URL_FEMALE = "https://api.smarthealth.com/v1/parse/female"


  def self.fetch_parsed_data(gender)
    if gender == "M"
      uri = URI.parse(PARSER_URL_MALE)
    else
      uri = URI.parse(PARSER_URL_FEMALE)
    end

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{ENV['VENDOR_API_TOKEN']}"


    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    JSON.parse(response.body)
  rescue => e
    raise "Error fetching response from vendor: #{e.message}"
  end
end

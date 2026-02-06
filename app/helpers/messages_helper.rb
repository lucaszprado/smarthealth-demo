module MessagesHelper
  def linkify_message_body(body)
    return body if body.blank?

    # Convert URLs to clickable links
    # Uses gsub with a regex pattern to find URLs in the text:
    # https?:\/\/ - Matches http:// or https://
    # [^\s]+ - Matches one or more non-whitespace characters
    # For each URL found, replaces it with a clickable link using link_to
    # - Opens in new tab with target: '_blank'
    # - Adds 'message-link' CSS class for styling
    # html_safe marks the output as safe HTML to render the links
    body.gsub(/(https?:\/\/[^\s]+)/) do |url|
      if url.include?('/integrations/twilio/media/')
        link_to 'Ver arquivo', url, target: '_blank', class: 'message-link', rel: 'noopener noreferrer'
      else
        link_to url, url, target: '_blank', class: 'message-link', rel: 'noopener noreferrer'
      end
    end.html_safe
  end
end

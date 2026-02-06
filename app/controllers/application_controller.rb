class ApplicationController < ActionController::Base

  # Default_url_options is a standard Rails method that's part of the URL generation system
  # image_url is a Rails helper that generates absolute URLs
  # It needs to know the host to create these absolute URLs
  # It looks for this information in default_url_options
  def default_url_options
    # If the environment variable DOMAIN is set, use it. Otherwise, use localhost:3000
    # DOMAIN is set in the production environment only (Heroku)
    { host: ENV["DOMAIN"] || "localhost:3000" }
  end

  private

end

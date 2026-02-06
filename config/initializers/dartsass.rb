# Configure dart-sass for Rails
Rails.application.config.dartsass.builds = {
  "application.scss" => "application.css"
}

# Set the build directory
Rails.application.config.dartsass.build_output_dir = "app/assets/builds"

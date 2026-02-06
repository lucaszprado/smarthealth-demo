require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Smarthealth
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    # LP 2025-06-16: This allows Zeitwerk to monitor lib/ for constants (classes and modules).
    # LP 2025-06-16: Zeiterk make them avilable at runtime.
    config.autoload_lib(ignore: %w(assets tasks))

    # config.autoload_paths << Rails.root.join("lib")
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Set the queue adapter to solid_queue
    config.active_job.queue_adapter = :solid_queue

    # Remove basic Http auth for mission_control-jobs
    config.mission_control.jobs.http_basic_auth_enabled = false

    # TODO: Review to implement pt locale on dates. This setup is creating side effects on ActiveAdmin.
    # config.i18n.default_locale = :en
    # config.i18n.available_locales = [:en, :pt]

  end
end

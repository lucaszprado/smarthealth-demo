# frozen_string_literal: true

# shadcn-rails configuration
Shadcn::Rails.configure do |config|
  # Base color theme
  # Available themes: neutral, slate, stone, zinc, gray
  config.base_color = "neutral"

  # Dark mode strategy
  # Available strategies: :class, :media, :both
  # - :class - Uses .dark class on <html> for manual toggling
  # - :media - Uses @media (prefers-color-scheme: dark) for system preference
  # - :both - Includes both for maximum flexibility
  config.dark_mode = :class
end

# Force local shadcn component overrides to win over the gem
#
# Problem
# You have two possible sources for the same constant:
# Gem has: .../gems/shadcn-rails/.../app/components/shadcn/combobox_component.rb
# App has: .../app/components/shadcn/combobox_component.rb
# Zeitwerk has both roots, and in your case the gem root is searched first, so the gem’s class gets defined first. Once defined, Ruby won’t automatically “swap it out” just because your app also has a file.
#
# The initializer:
# Forces Rails after finishes preparing the application to evaluate / load the local files agin.
# to_prepare runs:
#  - on boot
# - and on each reload in development
# load (unlike require) re-reads the file every time, which is what you want for overrides.
# So it guarantees: your local code is applied last, regardless of whether the gem loaded first.
#
Rails.application.config.to_prepare do
  Dir[Rails.root.join("app/components/shadcn/**/*.rb")].sort.each do |path|
    load path
  end
end

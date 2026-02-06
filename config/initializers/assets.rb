# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"



# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path


# Precompile additional assets.
#
# When Rails runs the asset precompilation step, also precompile these logical asset paths, in addition to whatever is listed in manifest.js.
#
# Each entry in the array is a logical asset path, not a physical file path. In plain English, it means: Find an asset with logical path shadcn/controllers/accordion_controller.js using Sprockets’ load paths
#
# application.js, application.css, and all non-JS/CSS in the app/assets folder are already added.
#
Rails.application.config.assets.precompile += %w[tailwind.css font_awesome.css]
Rails.application.config.assets.precompile += %w( .svg .eot .woff .ttf .woff2 )
# Precompile shadcn-rails gem assets
# shadcn/index.js imports controllers using relative paths, so those files need to be precompiled
# Wildcard patterns work correctly with Sprockets to match all files in those directories
Rails.application.config.assets.precompile += %w[
  shadcn/index.js
  shadcn/controllers/*.js
  shadcn/utils/*.js
]

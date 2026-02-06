# Rake Task to create WebP Files in app/assets/images/webp/
# This task converts all images in app/assets/images to WebP format
# Skips any image < 200KB
# Still skips images that already have a .webp version
# Only processes png, jpg, and jpeg
# load time is only affected by the assets actually used in the homepage — not by the number of files in app/assets/images/webp/.
# Rails (Sprockets) only compiles and serves:
# Files that are referenced in your code (views, CSS, JS, etc.)
# Files that are explicitly precompiled via configuration (e.g., config.assets.precompile)

require 'fileutils'
require 'open3'
require 'shellwords'

namespace :images do
  desc "Generate .webp versions of all .png and .jpg images in app/assets/images"
  task generate_webp: :environment do
    config_path = Rails.root.join("config/image_optimization.yml")
    settings = YAML.load_file(config_path)[Rails.env]["webp"]

    min_kb     = settings["min_kb"]
    quality    = settings["quality"]

    input_dir = Rails.root.join("app/assets/images")
    output_dir = Rails.root.join(settings["output_dir"])
    FileUtils.mkdir_p(output_dir)

    extensions = %w[png jpg jpeg]
    images = Dir.glob("#{input_dir}/**/*.{#{extensions.join(',')}}")

    puts "🔍 Found #{images.size} image(s) to process"

    images.each do |image_path|
      next if image_path.include?("/webp/") # skip already-generated webp images

      size_in_bytes = File.size(image_path)
      if size_in_bytes < min_kb * 1024
        puts "🟡 Skipping #{File.basename(image_path)} — under 200KB (#{(size_in_bytes / 1024.0).round(1)}KB)"
        next
      end

      basename = File.basename(image_path, File.extname(image_path))
      webp_path = output_dir.join("#{basename}.webp")

      if File.exist?(webp_path)
        puts "⚠️  Skipping #{webp_path.basename} — already exists"
        next
      end

      command = "cwebp -q #{quality} #{Shellwords.escape(image_path)} -o #{Shellwords.escape(webp_path)}"
      puts "▶️  Compressing #{File.basename(image_path)} at quality #{quality}"
      stdout, stderr, status = Open3.capture3(command)

      if status.success?
        original_kb = (size_in_bytes / 1024.0).round(1)
        compressed_kb = (File.size(webp_path) / 1024.0).round(1)
        reduction = (((original_kb - compressed_kb) / original_kb) * 100).round(1)

        puts "✅ Created: #{webp_path.relative_path_from(Rails.root)} — #{original_kb}KB → #{compressed_kb}KB (#{reduction}% smaller)"
      else
        puts "❌ Error creating WebP for #{image_path}"
        puts stderr
      end
    end

    puts "✅ Done generating WebP files."
  end
end

# This makes the task run automatically when you run `assets:precompile` in production
Rake::Task["assets:precompile"].enhance(["images:generate_webp"])

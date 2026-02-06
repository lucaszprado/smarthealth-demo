# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "Running the main seed file..."

# Load blood exam seed file
#load Rails.root.join('db/seeds/blood_exam_seeds.rb')

# Load bioimpedance seed file
#load Rails.root.join('db/seeds/bioimpedance_seeds.rb')

# Load image exam seed file
# load Rails.root.join('db/seeds/image_exam_seeds.rb')

# Load human biomarker filters seed file
load Rails.root.join('db/seeds/human_biomarker_filters_seeds.rb')

puts "All seed data loaded!"

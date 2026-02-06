puts "Hold your horses....."
require 'json'

# Create Categories
# Read and parse the JSON file
file_path = Rails.root.join('external-files', 'supplier_1', 'biomarkers-categories-en.json')
file_content = File.read(file_path)
categories_json = JSON.parse(file_content)

# Create the categories without parent_id first to avoid referencing issues
categories_json.each do |category_data|
  # Create or find the category by its external_ref (id from JSON)
  Category.find_or_create_by(external_ref: category_data["id"]) do |category|
    category.name = category_data["title"] # Copy title to name
    category.external_ref = category_data["id"] # Copy id to external_ref
  end
end

# Now update the parent-child relationships
categories_json.each do |category_data|
  next if category_data["parentId"].nil? # Skip if there is no parent_id

  # Find the category and its parent category
  category = Category.find_by(external_ref: category_data["id"])
  parent_category = Category.find_by(external_ref: category_data["parentId"])

  # Update the parent_id field with the corresponding Category ID
  category.update(parent_id: parent_category.id) if parent_category
end

# Create Units
# Read and parse the JSON file
file_path = Rails.root.join('external-files', 'supplier_1', 'measurement_units.json')
file_content = File.read(file_path)
units_json = JSON.parse(file_content)

# Create the units without parent_id first to avoid referencing issues
units_json.each do |unit_data|
  # Create or find the unit by its external_ref (id from JSON)
  Unit.find_or_create_by(external_ref: unit_data["id"]) do |unit|
    unit.name = unit_data["title"] # Copy title to name
    unit.external_ref = unit_data["id"] # Copy id to external_ref
    unit.value_type = unit_data["valueType"]
    unit.synomys_string = unit_data["synonymsString"]
  end
end
puts "Lembre da terceira lei da matemática...."
# Create Biomarkers, Synonyms and Units
# Read and parse the JSON file
file_path = Rails.root.join('external-files', 'supplier_1', 'biomarkes-v11-legends-en-pt.json')
file_content = File.read(file_path)
biomarkers_json = JSON.parse(file_content)

Synonym.delete_all
biomarkers_json["biomarkers"].each do |biomarker_data|
  biomarker = Biomarker.find_or_create_by(external_ref: biomarker_data["id"]) do |b|
    b.name = biomarker_data["title"]
    b.external_ref = biomarker_data["id"]
  end

  # Now that the biomarker is ensured to exist and has an id, you can create the synonyms
  biomarker_data["synonyms"].each do |synonym_data|
    Synonym.create(
      name: synonym_data["title"],
      language: synonym_data["language"],
      biomarker_id: biomarker.id
    )
  end

  # Each biomarker has its possible display units.
  # Unit factor allows the conversion from supplier_1 standard unit to one of the possible units
  # To convert we must divide Value (from Measures) by the the desired UnitFactor.
  biomarker_data["unitsFactors"].each do |unit_factor_data|
    UnitFactor.create(
      unit_id: Unit.find_by(external_ref: unit_factor_data[0]).id,
      factor: unit_factor_data[1],
      biomarker_id: biomarker.id
    )

  end

end

AdminUser.create!(email: '', password: '', password_confirmation: '') if Rails.env.development?

Human.create(
  name: "Joaquim Neto",
  gender: "M",
  birthdate: Date.new(1989, 4, 21)
  )
puts "Seed done!"

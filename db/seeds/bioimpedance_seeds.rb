puts "Seeding data for the bioimpedance..."

#0. Data Strcuture to Store Bioimpedance Biomarkers and its respective synonyms
# We use the same structure as uses
# We just need to add 3 new biomarkers to DB.
# Their standard unit will be percentage and we will have only one display unit: percentage
# Therefore we just need to setup one unitFactor, which UnitFactor will be 1
# unitsFactor elements are defined as [Unit_Id, UnitFactor]


biomarkers = [
  {
    title: "Muscle mass",
    synonyms: [
        {
            title: "Massa muscular",
            language: "PT"
        }
    ],
    unitsFactors: [
              [
                  1,
                  1
              ]
    ]
  },
  {
    title: "Fat Mass",
    synonyms: [
        {
            title: "Gordura corporal",
            language: "PT"
        }
    ],
    unitsFactors: [
              [
                  1,
                  1
              ]
    ]
  },
  {
    title: "Visceral Fat",
    synonyms: [
        {
            title: "Gordura visceral",
            language: "PT"
        }
    ],
    unitsFactors: [
              [
                  1,
                  1
              ]
    ]
  }
]

#1. Create bioimpedance category
Category.find_or_create_by!(name: "Bioimpedance")

#2. Create biomarkers, synonyms and unit_factors
biomarkers.each do |biomarker_data|
  #2.1 Create biomarker
  biomarker = Biomarker.find_or_create_by!(name: biomarker_data[:title])

  #2.2 Create associated synonyms
  biomarker_data[:synonyms].each do |synonym_data|
    Synonym.find_or_create_by!(name: synonym_data[:title]) do |s|
      s.language = synonym_data[:language]
      s.biomarker_id = biomarker.id
    end
  end

  #2.3 Differently from the main seed, where units are defined based on external_ref,
  # units in bioimpedance biormarkers data structure (step 0) are defined by
  # our system Unit Id.

  biomarker_data[:unitsFactors].each do |unit_factor_data|
    UnitFactor.find_or_create_by!(unit_id: Unit.find(unit_factor_data[0]).id, biomarker_id: biomarker.id) do |u|
      u.factor = unit_factor_data[1]
    end
  end
end

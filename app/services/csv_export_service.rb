require 'csv'

class CsvExportService

  def self.export_with_categories_to_csv(path)
    # 1) build your query
    rows = Biomarker.left_joins(measures: :category)
      .select(
        'biomarkers.id      AS id', # ← primary key for AR
        'biomarkers.id    AS biomarker_id', # ← your CSV column
        'biomarkers.name  AS biomarker_name',
        'categories.id    AS category_id',
        'categories.name  AS category_name'
      )
      .distinct

    # 2) open a CSV and write header + each row
    CSV.open(path, 'w', write_headers: true, headers: [
      'Biomarker ID', 'Biomarker Name', 'Category ID', 'Category Name'
    ]) do |csv|
      # loop in batches if you have a lot of records
      rows.find_each(batch_size: 1_000) do |record|
        csv << [
          record.biomarker_id,
          record.biomarker_name,
          record.category_id,
          record.category_name
        ]
      end
    end
  end

end

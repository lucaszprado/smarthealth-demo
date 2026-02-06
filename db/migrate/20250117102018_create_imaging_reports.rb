class CreateImagingReports < ActiveRecord::Migration[7.1]
  def change
    create_table :imaging_reports do |t|
      t.string :content
      t.references :source, null: false, foreign_key: true
      t.references :imaging_method, null: false, foreign_key: true
      t.references :report_summary, null: false, foreign_key: true
      t.datetime :date


      t.timestamps
    end
  end
end

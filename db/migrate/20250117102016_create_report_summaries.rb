class CreateReportSummaries < ActiveRecord::Migration[7.1]
  def change
    create_table :report_summaries do |t|
      t.string :content

      t.timestamps
    end
  end
end

class ChangeReportSummaryIdToBeNullableInImagingReports < ActiveRecord::Migration[7.1]
  def change
      change_column_null :imaging_reports, :report_summary_id, true
  end
end

module ImagingReportsHelper
  def render_imaging_reports_partial(imaging_reports)
    if imaging_reports.empty?
      'shared/no_data'
    else
      'imaging_reports/data'
    end
  end

  def imaging_report_card_attributes(human, imaging_report)
    {
      link: human_imaging_report_path(human.id, imaging_report[:id]),
      icon_path: "fa-solid fa-circle-radiation", #fa-solid fa-chart-line fa-light fa-x-ray fa-regular fa-image
      title: "#{imaging_report[:title][0]} #{imaging_report[:title][1]}",
      key_info: imaging_report[:imaging_method],
      status: nil,
      date: imaging_report[:date],
      labels: imaging_report[:label_system],
      data_type: imaging_report[:data_type],
      context: 'imaging_reports'
    }
  end
end

filters = [
  {
    range_status: :normal,
    is_from_latest_exam: true,
    measure_id: 540,
    human_id: 3,
    biomarker_id: 197
  },
  {
    range_status: :normal,
    is_from_latest_exam: true,
    measure_id: 361,
    human_id: 3,
    biomarker_id: 160
  },
  {
    range_status: :normal,
    is_from_latest_exam: true,
    measure_id: 535,
    human_id: 3,
    biomarker_id: 54
  },
  {
    range_status: :normal,
    is_from_latest_exam: true,
    measure_id: 273,
    human_id: 3,
    biomarker_id: 972
  },
  {
    range_status: :out_of_range,
    is_from_latest_exam: true,
    measure_id: 286,
    human_id: 3,
    biomarker_id: 720
  },
  {
    range_status: :normal,
    is_from_latest_exam: true,
    measure_id: 285,
    human_id: 3,
    biomarker_id: 721
  },
]

filters.each do |filter|
  HumanBiomarkerFilter.create(filter)
end

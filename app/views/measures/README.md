# Partial Structure
index.html.erb -> locals: {primary_biomarker_data: @primary_biomarker_data, biomarker_series: @biomarker_series} are passed down to the partials to select the appropriate view type and measure type.
└── helpers/measures_helper.rb
    └── select_view_type(measure) -> Define if the view will be numeric or non numeric
      If numeric,
       └── numeric.html.erb -> Displays the numeric view
        └── select_measure_type(measure) -> Define if the view will be ranges or non ranges
           └── ranges.html.erb -> Displays the ranges view
           └── non_ranges.html.erb -> Displays the non ranges view
      If non numeric,
       └── non_numeric.html.erb -> Displays the non numeric view


# Data Flow for the biomarker selector component
1. Search flow (refresh-list controller):
   - User types in search input → refresh-list#update() → updates biomarker-search-results turbo-frame
2. Add biomarker flow (drowpdown-selector controller):
User clicks "Add" → drowpdown-selector#add() → updates URL with new biomarker_ids[] → reloads chart_frame turbo-frame
3. Remove biomarker flow (drowpdown-selector controller):
User clicks "×" on tag → drowpdown-selector#remove() → updates URL with removed biomarker_ids[] → reloads chart_frame turbo-frame

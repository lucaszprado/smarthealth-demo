# Scope Context
## Scope Name
Responsive biomarker selection interface

## Scope Objective
Build a responsive layout for the biomarkers selector.

## Scope Description
Our current biomarker selector have the same layout for mobile and desktop.

Although we make adjustments in the component and font size when on mobile or desktop devices, this UX is not good when rendering in mobile devices because the selector gets to small.


## Key Elements
1. Redesigned biomarker selector
    - Unify `views/measures/_selected_biomarkers.html.erb` , `views/biomarkers/_search_results_selector.html` and  `views/measures/_biomarker_selector.html.erb` in a single component that will open once the user clicks in the "Plus” button above the chart
    - Mobile will present the chart options in a panel → similar to the  partial in `views/biomarkers_filters_panel.html.erb`

2. "Plus” button UX
    - Mobile: Blur background and open the modal
    - Desktop: Open the menu over the chart (as the current UX)

    The image provided in the prompt shows a high level blueprint for the mobile and desktop experience.


## Out of scope and No-Gos
NA

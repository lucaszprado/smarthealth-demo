# Partial Structure
index.html.erb
└── _data.html.erb (passes biomarker_sections and human)
    └── _section_list.html.erb (iterates through sections)
        └── _section.html.erb (renders each section)
            └── _result_card.html.erb (renders each biomarker)



# Scrollable Area
Browser Viewport (scrollable area)
├── 0px: Top of browser window
├── 160px: Where section headers stick
├── FixedHeader (sticky, top: 0, z-index: 1020)
│   └── Header content (0px to ~144px)
└── Biomarkers List (scrolls naturally)
    ├── Section 1 Header (sticks at 160px when scrolling)
    ├── Section 1 Content
    ├── Section 2 Header (sticks at 160px when scrolling)
    └── Section 2 Content

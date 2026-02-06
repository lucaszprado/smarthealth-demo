# System Patterns

## Architecture Overview
- Project follows a modern web application architecture with a focus on security, scalability, and maintainability.
- RESTful controllers and routes


## Web Interface
- Bootstrap and Tailwind styling for UI
- Responsive design for mobile and desktop
- Hotwire to add interactivity to the UI
- Chart.js for the charting library

## Database
To understand the current database structure you should check the application database at: @db/schema.rb

## Charts
- The project already has a chart controller that is used to display the charts.
- Chart.js is configured with the date-fns adapter and time scale, using `{x, y}` data points and axis titles to show biomarker units.

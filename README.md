# Health Wallet – Demo Version
A personal health data organizer that helps users track lab results, imaging reports, and bioimpedance exams in one place. Built with Ruby on Rails.

# Overview
This project was built to solve a personal frustration: how hard it is to keep track of medical exams and extract insights over time. The user can upload health documents and get a structured, searchable view of their health data and health timeline.

# Key Features
- Medical reports ingestion (e.g. blood tests, bioimpedance, image reports)
- AI-assisted text extraction (OCR + LLM)
- Visualization and study of biomarkers and imaging reports across time



## Main technologies
- PostgreSQL (primary database)
- Redis (caching layer)
- Solid Queue (background job processing)
- AWS (file storage and processing)
- Heroku (hosting and deployment)
- Hotwire (interactive UI workflows)
- Tailwind, ViewComponent, and Shadcn (frontend component architecture)
- OpenAI models for classification, RAG pipelines, and document structuring



# App Demo (Try It Yourself)
- [My user profile](https://smarthealth-prod-a89f7e2c4ece.herokuapp.com/humans/34/)
Link to my user health wallet profile, with my health data fully organized and read to use for medical interpretation.

- [Demo user Profile](https://smarthealth-prod-a89f7e2c4ece.herokuapp.com/humans/265/)
Demo health walltet profile where you can upload exams (e.g. blood test, bioimpedance or imaging report) and see it parsed and displayed in the user profile.

Want a test file? Let me know — I’ll gladly send one. Send me a message: lucaspradobr@gmail.com

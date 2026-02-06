# Technical Context

## Technology Stack
1. **Web Application**
   - Rails 7.1.4
   - Bootstrap, scss, Tailwindcss and font-awesome for frontend
      - We started the application with Bootstrap and scss, but now we're migrating to Tailwindcss to build more modern UI
   - Javascript is built with Turbo and Hotwire. Vanilla JavaScript should be used only when Hotwire and Stimulus are not enough.
   - Project must be the more Rails vanilla as possible
   - Charts are built with chart.js
   - Chat is built on top of WhatsApp API using Twilio
   - Use the gem roo for excel file parsing

2. **Integration Requirements**
   - Apple Watch API integration
   - Polar API integration
   - Garmin API integration
   - Medical data format support

## Development Setup
1. **Local Environment**
   - Development server
   - Database setup
   - API mocking capabilities


## Technical Constraints
1. **Security**
   - HIPAA compliance requirements
   - Data encryption standards
   - Secure authentication

2. **Performance**
   - Fast data retrieval
   - Efficient data storage
   - Real-time updates

3. **Scalability**
   - Multiple profile support
   - Large data volume handling
   - Concurrent user support

## Dependencies
1. **External APIs**
   - Wearable device APIs
   - Medical data providers
   - Storage services

2. **Development Tools**
   - Version control
   - CI/CD pipeline
   - Monitoring tools

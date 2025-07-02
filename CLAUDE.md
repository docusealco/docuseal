# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Starting the Application
```bash
# Start Rails server
PORT=3001 bundle exec rails s -p 3001

# Start Webpack dev server (separate terminal)
bundle exec ./bin/shakapacker-dev-server

# Or start both with foreman
foreman start -f Procfile.dev
```

### Database Operations
```bash
# Create and migrate database
rails db:create db:migrate

# Reset database
rails db:drop db:create db:migrate

# Run seeds
rails db:seed
```

### Testing
```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/path/to/test_spec.rb

# Run system tests with visible browser
HEADLESS=false bundle exec rspec spec/system/

# Run tests with coverage
COVERAGE=true bundle exec rspec
```

### Code Quality
```bash
# Ruby linting
bundle exec rubocop
bundle exec rubocop -a  # auto-correct

# JavaScript linting
yarn eslint

# ERB linting
bundle exec erblint --lint-all

# Security scanning
bundle exec brakeman
```

### Asset Management
```bash
# Install JavaScript dependencies
yarn install

# Compile assets for production
bundle exec rails assets:precompile

# Start webpack dev server
bundle exec ./bin/shakapacker-dev-server
```

## Application Architecture

### Core Domain Models
- **Template**: PDF form templates with fields for signing/filling
- **Submission**: Instance of a template being processed with specific submitters
- **Submitter**: Individual who needs to fill/sign a document within a submission
- **User**: System users (admins, team members) who manage templates and submissions
- **Account**: Multi-tenant organization container

### Key Relationships
- Templates belong to Accounts and have many Submissions
- Submissions have many Submitters (signing parties)
- Each Submitter has specific fields to complete
- CompletedSubmitter and CompletedDocument track completion state

### Frontend Architecture
- **Rails Views**: Server-rendered ERB templates with Turbo for interactivity
- **Vue.js Components**: Used for complex interactive forms (template builder, submission forms)
- **Stimulus**: Lightweight JavaScript controllers for DOM interactions
- **Tailwind CSS**: Utility-first CSS framework with DaisyUI components

### Background Jobs (Sidekiq)
- Document processing and PDF generation
- Email notifications and reminders
- Webhook deliveries
- Search indexing

### File Storage
- Uses Active Storage for file management
- Supports local disk, AWS S3, Google Cloud, Azure storage
- PDF processing with HexaPDF library
- Image processing with ruby-vips

### API Structure
- RESTful JSON API under `/api` namespace
- API authentication via access tokens
- Webhook system for real-time integrations
- OpenAPI documentation in `docs/openapi.json`

## Key Configuration Files
- `config/routes.rb`: Main routing configuration with API and web routes
- `config/application.rb`: Rails application configuration
- `shakapacker.yml`: JavaScript build configuration
- `tailwind.config.js`: CSS framework configuration

## Development Environment
- Ruby 3.4.2 required
- Node.js 18 for asset compilation
- SQLite for development (PostgreSQL supported)
- Redis for background jobs
- VIPS for image processing

## Testing Setup
- RSpec for Ruby testing with FactoryBot fixtures
- Capybara + Cuprite for system/integration tests
- WebMock for HTTP request stubbing
- Sidekiq testing utilities for background jobs

## Security Features
- Devise for authentication with 2FA support
- CanCanCan for authorization
- PDF signature verification
- Encrypted configuration storage
- Rate limiting middleware
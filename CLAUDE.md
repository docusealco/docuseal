# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

DocuSeal is an open-source document signing and filling platform built with Ruby on Rails 8.1. It provides secure PDF form creation, digital signatures, and document processing with a mobile-optimized interface.

**Key Technologies:**
- Backend: Rails 8.1 with Ruby 4.0.1
- Database: PostgreSQL (default), MySQL/Trilogy, or SQLite3
- Frontend: Vue 3 components with Hotwire Turbo, Tailwind CSS + DaisyUI
- JavaScript bundling: Shakapacker (webpack)
- Background jobs: Sidekiq
- PDF processing: HexaPDF, ruby-vips, pdfium
- Storage: Local disk, AWS S3, Google Cloud Storage, or Azure Blob

## Development Commands

### Setup
```bash
# Install dependencies
bundle install
yarn install

# Setup database
rails db:create db:migrate

# Start development servers (Rails + webpack dev server)
foreman start -f Procfile.dev
# Or individually:
# rails s -p 3000
# ./bin/shakapacker-dev-server
```

### Testing
```bash
# Run all specs
bundle exec rspec

# Run specific test file
bundle exec rspec spec/requests/api/submissions_spec.rb

# Run system tests (with browser)
HEADLESS=false bundle exec rspec spec/system/

# Run with coverage
COVERAGE=true bundle exec rspec
```

### Code Quality
```bash
# Lint Ruby code
bundle exec rubocop

# Lint Ruby code with auto-fix
bundle exec rubocop -A

# Lint JavaScript/Vue
yarn eslint

# Lint ERB templates
bundle exec erblint --lint-all

# Security scan
bundle exec brakeman
```

### Database
```bash
# Create migration
rails g migration AddFieldToTable field:type

# Run migrations
rails db:migrate

# Rollback
rails db:rollback

# Reset database (drop, create, migrate, seed)
rails db:reset
```

### Assets
```bash
# Precompile assets for production
rails assets:precompile

# Compile webpack bundles
./bin/shakapacker
```

## Architecture

### Backend Structure

**Core Models:**
- `Account` - Multi-tenant account/organization
- `User` - User authentication and management (Devise)
- `Template` - PDF form template with field definitions
- `Submission` - Document instance created from template
- `Submitter` - Individual who fills/signs a submission
- `CompletedSubmitter` - Final state after signing
- `CompletedDocument` - Generated signed PDF documents

**Key Service Modules (lib/):**
- `Submissions` - Handle submission lifecycle
- `Submitters` - Manage submitter workflow
- `Templates` - Template operations and cloning
- `Accounts` - Account configuration
- `PdfUtils` - PDF processing and manipulation
- `DownloadUtils` - File download handling
- `SendWebhookRequest` - Webhook delivery

**Background Jobs (app/jobs/):**
- Document generation
- Email sending
- Webhook delivery
- File processing

**Controllers:**
- Standard Rails controllers in `app/controllers/`
- API namespace in `app/controllers/api/` with JSON responses
- RESTful design following Rails conventions

### Frontend Structure

**Custom Web Components (`app/javascript/elements/`):**
- Built with `@github/catalyst` for custom element registration
- Located in `app/javascript/elements/`
- Examples: `file_dropzone.js`, `clipboard_copy.js`, `fetch_form.js`
- Autonomous, reusable components following web standards

**Vue 3 Applications:**
- `template_builder/` - WYSIWYG PDF form builder
  - Drag-and-drop field placement
  - Field settings and validation
  - Multi-submitter support
- `submission_form/` - Document signing interface
  - Step-by-step submission flow
  - Signature capture
  - Field completion

**Styling:**
- Tailwind CSS utility classes
- DaisyUI component library
- Multiple Tailwind configs:
  - `tailwind.config.js` - Main application
  - `tailwind.application.config.js` - Application-specific
  - `tailwind.form.config.js` - Form-specific

**JavaScript Entry Points:**
- `application.js` - Main app bundle
- `form.js` - Public form bundle
- `draw.js` - Drawing/signature tools

### Database Configuration

The app supports multiple database adapters configured via environment variables:

- **PostgreSQL** (default for dev/test): Set `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USER`, `DATABASE_PASSWORD`, `DATABASE_NAME`
- **MySQL/Trilogy**: Set `DATABASE_URL` with `mysql://` or `trilogy://` protocol
- **SQLite3**: Default for production when no DATABASE_URL is set

Connection pool size: `RAILS_MAX_THREADS` (default 15) + `SIDEKIQ_THREADS` (default 5)

### API

RESTful JSON API at `/api/*`:
- Authentication via access tokens
- Endpoints for submissions, templates, submitters, attachments
- Event tracking endpoints
- Webhook support for integrations
- See `config/routes.rb` API namespace for full endpoint list

### Testing

**Test Framework:** RSpec with FactoryBot

**Test Types:**
- Request specs (`spec/requests/`) - API endpoint testing
- System specs (`spec/system/`) - Full browser integration tests using Cuprite (headless Chrome)
- Job specs (`spec/jobs/`) - Background job testing
- Mailer specs (`spec/mailers/`)

**Test Configuration:**
- Capybara with Cuprite driver for system tests
- WebMock for HTTP request stubbing
- Sidekiq testing (fake mode default, inline for specific tests)
- SimpleCov for coverage (enable with `COVERAGE=true`)
- Headful mode for debugging: `HEADLESS=false bundle exec rspec`

### Deployment

**Docker:**
```bash
docker run --name docuseal -p 3000:3000 -v.:/data docuseal/docuseal
```

**Docker Compose:**
```bash
curl https://raw.githubusercontent.com/docusealco/docuseal/master/docker-compose.yml > docker-compose.yml
sudo HOST=your-domain.com docker compose up
```

**Supported Platforms:**
- Heroku, Railway, DigitalOcean, Render
- See README.md for one-click deploy buttons

### Environment Configuration

Key environment variables:
- `DATABASE_URL` - Database connection string
- `HOST` - Application host domain
- `APP_URL` - Application URL (default: http://localhost:3000)
- `MULTITENANT` - Enable multi-tenant mode
- Storage: `AWS_*`, `GOOGLE_*`, `AZURE_*` configs
- SMTP: Email delivery configuration
- `CERTS` - Custom SSL certificates (JSON)
- `TIMESERVER_URL` - Timestamp server for signatures

### Multitenant Support

The app supports multitenant deployment via `MULTITENANT=true`:
- Account-scoped data isolation
- Subdomain-based routing
- Console interface at `console.#{HOST}`
- CDN at `cdn.#{HOST}`

### Key Libraries and Patterns

**Authentication:** Devise with 2FA (TOTP) support via `devise-two-factor`

**Authorization:** CanCanCan for permissions

**PDF Processing:**
- HexaPDF for PDF generation and manipulation
- ruby-vips for image processing
- pdfium bindings for advanced PDF operations

**Background Jobs:** Sidekiq with Redis

**Frontend State Management:**
- Vue 3 Composition API
- Turbo Drive for page navigation
- Custom elements for isolated widgets

**File Storage:** ActiveStorage with multiple backends (disk, S3, GCS, Azure)

**API Integrations:**
- Webhooks for events
- REST API with JWT authentication
- Embedded signing widgets (React/Vue/Angular npm packages available)

### Code Style and Conventions

- Ruby: Follow Rubocop rules in `.rubocop.yml` (Standard Ruby style)
- JavaScript: ESLint with Standard style + Vue 3 recommended rules
- ERB: erb_lint for template validation
- Vue: Single-file components with `<script setup>` or Options API
- Frozen string literals enabled by default
- Rails 8.1 conventions and best practices

### Accessibility Focus

This codebase is specifically being enhanced for accessibility (a11y). When making changes:
- Follow WCAG 2.2 guidelines
- Test with screen readers
- Ensure keyboard navigation
- Maintain proper ARIA labels
- Check color contrast ratios

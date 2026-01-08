# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is **DocuSeal** - an open-source document filling and signing platform built with Ruby on Rails. The codebase is a brownfield Rails 7 application that provides secure digital document signing with PDF form building, multi-signer workflows, and API/webhook integrations.

## Tech Stack

**Backend:**
- Ruby 3.4.2, Rails 7.x
- PostgreSQL/MySQL/SQLite (via DATABASE_URL)
- Sidekiq for background jobs
- Devise for authentication with 2FA support
- Cancancan for authorization
- HexaPDF for PDF generation and signing

**Frontend:**
- Vue.js 3 with Composition API
- TailwindCSS 3.4.17 + DaisyUI 3.9.4
- Shakapacker 8.0 (Webpack)
- Hotwire Turbo for Rails UJS

**Storage:**
- Active Storage with S3, Google Cloud, Azure, or local disk
- Supports multiple storage backends simultaneously

## Common Commands

### Development
```bash
# Start development server
bin/rails server

# Start with foreman (includes Sidekiq)
bundle exec foreman start -f Procfile.dev

# Run specific test
bundle exec rspec spec/path/to/spec.rb:line_number

# Run all tests
bundle exec rspec

# Lint Ruby
bundle exec rubocop -A

# Lint JavaScript/Vue
yarn eslint app/javascript/**/*.{js,vue} --fix

# Run database migrations
bin/rails db:migrate

# Setup database from scratch
bin/rails db:setup
```

### Production
```bash
# Precompile assets
bin/rails assets:precompile

# Start production server
bundle exec puma -C config/puma.rb

# With Docker
docker run --name docuseal -p 3000:3000 -v.:/data docuseal/docuseal
```

## Architecture

### Core Models Hierarchy

```
Account (Tenant/Organization)
├── Users (Devise authentication)
├── Templates (Document templates with form fields)
│   ├── TemplateDocuments (PDF files)
│   └── TemplateFolders (Organization)
├── Submissions (Completed document workflows)
│   ├── Submitters (Signers/participants)
│   ├── CompletedDocuments (Final PDFs)
│   └── SubmissionEvents (Audit trail)
└── AccountConfig (Settings)
```

### Key Concepts

**Templates:**
- WYSIWYG PDF form builder with 12 field types (Signature, Date, File, Checkbox, etc.)
- Supports PDF upload or HTML-based template creation
- Multiple submitters per template
- Field tagging system for dynamic content

**Submissions:**
- Multi-signer document workflows
- State tracking (pending → completed)
- Email notifications and reminders
- Document generation and signing

**Submitters:**
- Individual participants in a submission
- Can fill and sign specific fields
- Receive email invitations and reminders
- Support for 2FA and identity verification

### Directory Structure

**app/models/** - Core business logic
- `submission.rb`, `submitter.rb`, `template.rb` - Main entities
- `user.rb`, `account.rb` - Authentication and multi-tenancy
- All models inherit from `ApplicationRecord` with `strip_attributes`

**app/controllers/** - Request handling
- RESTful controllers for templates, submissions, submitters
- API controllers under `app/controllers/api/`
- Settings controllers for user/account configuration

**app/javascript/** - Frontend code
- `application.js` - Main entry point with Vue app initialization
- `template_builder/` - PDF form builder UI
- `elements/` - Custom web components (Web Components + Vue)
- `submission_form/` - Multi-step signing interface

**lib/** - Utility modules
- `submissions.rb`, `submitters.rb` - Business logic helpers
- `pdf_utils.rb`, `pdfium.rb` - PDF processing
- `send_webhook_request.rb` - Webhook handling

**config/** - Rails configuration
- `routes.rb` - Main routing (includes API routes)
- `database.yml` - Database configuration
- `shakapacker.yml` - Webpack configuration

### Authentication & Authorization

**Authentication:**
- Devise with modules: database_authenticatable, registerable, recoverable, rememberable, validatable, omniauthable, two_factor_authenticatable
- JWT tokens for API access
- OAuth support via omniauth

**Authorization:**
- Cancancan with `Ability` class
- Role-based access control via `AccountAccess` model
- Template and submission sharing via `TemplateSharing`

### PDF Processing

**HexaPDF** is used for:
- PDF generation from templates
- Form field rendering
- Digital signature embedding
- Signature verification

**PDFium** provides:
- PDF rendering and preview
- Document manipulation
- Multi-page handling

### API Structure

**Base URL:** `/api/v1/`

**Key Endpoints:**
- `POST /templates` - Create template
- `POST /submissions` - Start submission workflow
- `GET /submissions/:id` - Get submission status
- `POST /submitters/:id/complete` - Complete submitter workflow
- `POST /webhooks` - Webhook events

**Authentication:** Bearer token in Authorization header

### Webhooks

**Events:**
- `submission.created` - New submission started
- `submission.completed` - All signers finished
- `submitter.completed` - Individual signer finished
- `template.created` - New template

**Delivery:** POST to configured URLs with JSON payload, retry with exponential backoff

### Background Jobs (Sidekiq)

**Queues:**
- `default` - General tasks
- `mailers` - Email delivery
- `webhooks` - Webhook delivery
- `pdf` - PDF generation

**Key Jobs:**
- `SubmissionEmailJob` - Send submission invitations
- `ReminderJob` - Send reminder emails
- `WebhookDeliveryJob` - Deliver webhook events
- `DocumentGenerationJob` - Generate final PDFs

### Database Schema

**Core Tables:**
- `accounts` - Multi-tenancy root
- `users` - Devise authentication
- `templates` - Document templates
- `submissions` - Document workflows
- `submitters` - Signers/participants
- `completed_documents` - Final signed PDFs
- `template_documents` - Template PDF files

**Supporting Tables:**
- `account_access` - User permissions
- `template_sharing` - Template sharing links
- `submission_events` - Audit trail
- `webhook_events` - Webhook delivery tracking
- `email_events` - Email delivery tracking

### Configuration

**Environment Variables:**
- `DATABASE_URL` - Database connection
- `SECRET_KEY_BASE` - Rails secrets
- `AWS_*`, `GOOGLE_*`, `AZURE_*` - Storage configs
- `SMTP_*` - Email delivery
- `REDIS_URL` - Sidekiq backend

**Feature Flags:**
- `Docuseal.multitenant?` - Multi-tenant mode
- `Docuseal.pro?` - Pro features enabled

### Testing

**RSpec** with:
- `spec/models/` - Model specs
- `spec/requests/` - API/request specs
- `spec/system/` - System/feature specs
- `spec/factories/` - FactoryBot factories

**Helpers:**
- `signing_form_helper.rb` - Form signing utilities
- `rails_helper.rb` - Rails test configuration

### BMAD Core Integration

This repository uses **BMAD Core** for AI-assisted development:
- Configuration: `.bmad-core/core-config.yaml`
- Tasks: `.bmad-core/tasks/` (e.g., `create-doc.md`, `document-project.md`)
- Templates: `.bmad-core/templates/` (e.g., `brownfield-prd-tmpl.yaml`)
- Agents: `.bmad-core/agent-teams/`

**Slash Commands:**
- `/BMad:agents:pm` - Product Manager agent
- `/BMad:agents:dev` - Developer agent

### FloDoc Enhancement (Current Work)

**Context:** Transforming DocuSeal into a 3-portal cohort management system for training institutions.

**Key Changes:**
- New models: `Cohort`, `CohortEnrollment`, `Institution`, `Sponsor`
- Three portals: Admin, Student, Sponsor
- Workflow: Admin creates cohort → Students enroll → Admin verifies → Sponsor signs → Admin finalizes
- Excel export for cohort data (FR23)
- Custom UI/UX (not DaisyUI)

**PRD Location:** `docs/prd.md`

### Important Files

- `README.md` - Project overview and deployment
- `SECURITY.md` - Security policy
- `Gemfile` - Ruby dependencies
- `package.json` - JavaScript dependencies
- `config/routes.rb` - All routes including API
- `app/models/user.rb` - Authentication model
- `app/javascript/application.js` - Frontend entry point

### Gotchas

1. **Multi-tenancy:** Check `Docuseal.multitenant?` before assuming single-account mode
2. **Storage:** Active Storage configs in `config/storage.yml` and `lib/load_active_storage_configs.rb`
3. **PDF Processing:** HexaPDF requires proper license for commercial use
4. **Sidekiq:** Requires Redis connection, configured via `REDIS_URL`
5. **Devise 2FA:** Requires `devise-two-factor` setup per user
6. **Vue + Rails:** Uses Shakapacker, not standard Webpack config
7. **Email Templates:** Stored in `app/views/mailers/`, use ERB variables

### Common Issues

**Database errors:** Run `bin/rails db:setup` or check `DATABASE_URL`
**Asset compilation:** Run `bin/rails assets:precompile` for production
**Sidekiq not processing:** Check Redis connection and `config/sidekiq.yml`
**PDF generation fails:** Verify HexaPDF installation and PDF permissions
**Webhook delivery fails:** Check network access and SSL certificates

### Next Steps for FloDoc Enhancement

1. **Architect Review:** Winston needs to review authentication strategy and multi-tenancy
2. **Database Migrations:** Create new tables for cohorts, enrollments, institutions
3. **Portal Development:** Build three separate Vue portals
4. **Workflow Integration:** Connect to existing DocuSeal submission system
5. **Excel Export:** Implement using `rubyXL` gem (already in Gemfile)
6. **Testing:** Add specs for new cohort workflows
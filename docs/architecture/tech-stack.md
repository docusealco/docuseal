# Tech Stack - FloDoc Architecture

**Document**: Tech Stack Specification
**Version**: 1.0
**Last Updated**: 2026-01-14

---

## 🎯 Technology Overview

FloDoc is a brownfield Rails 7 application enhanced with Vue.js 3 frontend. The stack is chosen for stability, developer productivity, and seamless integration with existing DocuSeal functionality.

---

## 🔧 Backend Stack

### Ruby on Rails
- **Version**: 7.x
- **Purpose**: Core application framework
- **Key Features**:
  - MVC architecture
  - Active Record ORM
  - Action Mailer for emails
  - Active Job for background processing
  - Built-in security features

### Database
- **Primary**: PostgreSQL 14+
- **Alternative**: MySQL 8+ or SQLite (for development)
- **Configuration**: `DATABASE_URL` environment variable
- **Key Tables**:
  - `institutions` - Single training institution
  - `cohorts` - Training program cohorts
  - `cohort_enrollments` - Student enrollments
  - `templates` (existing) - Document templates
  - `submissions` (existing) - Document workflows
  - `submitters` (existing) - Signers/participants

### Background Jobs
- **Framework**: Sidekiq
- **Backend**: Redis
- **Queues**:
  - `default` - General tasks
  - `mailers` - Email delivery
  - `webhooks` - Webhook delivery
  - `pdf` - PDF generation
- **Configuration**: `REDIS_URL` environment variable

### Authentication
- **Gem**: Devise 4.x
- **Modules**:
  - `database_authenticatable` - Password auth
  - `registerable` - User registration
  - `recoverable` - Password reset
  - `rememberable` - Remember me
  - `validatable` - Validations
  - `omniauthable` - OAuth support
  - `two_factor_authenticatable` - 2FA
- **API Auth**: JWT tokens (custom implementation)

### Authorization
- **Gem**: Cancancan 3.x
- **Ability Class**: `app/models/ability.rb`
- **Roles**: TP (admin), Student, Sponsor
- **Access Control**: Role-based via `AccountAccess` model

### PDF Processing
- **Generation**: HexaPDF 0.15+
  - PDF creation from templates
  - Form field rendering
  - Digital signatures
  - Signature verification
- **Rendering**: PDFium
  - PDF preview
  - Document manipulation
  - Multi-page handling

### Email Delivery
- **SMTP**: Standard Rails Action Mailer
- **Templates**: ERB in `app/views/mailers/`
- **Async**: Sidekiq `mailers` queue
- **Tracking**: `email_events` table

### Webhooks
- **Delivery**: Custom `WebhookDeliveryJob`
- **Events**: submission.created, submission.completed, etc.
- **Retry**: Exponential backoff
- **Tracking**: `webhook_events` table

---

## 🎨 Frontend Stack

### Vue.js
- **Version**: 3.x with Composition API
- **Build Tool**: Shakapacker 8.x (Webpack wrapper)
- **Entry Point**: `app/javascript/application.js`
- **Key Libraries**:
  - Vue Router (if needed for SPA sections)
  - Pinia for state management
  - Axios for HTTP requests

### State Management
- **Framework**: Pinia 2.x
- **Stores**:
  - `cohortStore` - Cohort management state
  - `submissionStore` - Submission workflow state
  - `authStore` - Authentication state
  - `uiStore` - UI state (modals, notifications)

### Styling
- **Framework**: TailwindCSS 3.4.17
- **Components**: DaisyUI 3.9.4
- **Customization**: `tailwind.config.js`
- **Design System**: Custom FloDoc branding (not DaisyUI defaults)

### Build & Development
- **Tool**: Shakapacker 8.x
- **Node**: 18+ recommended
- **Yarn**: Package management
- **Hot Reload**: Via Shakapacker dev server

### API Integration
- **HTTP Client**: Axios or Fetch API
- **Base URL**: `/api/v1/`
- **Auth**: Bearer tokens in headers
- **Response Format**: JSON

---

## 🔒 Security Stack

### Authentication
- **Web Sessions**: Devise + Rails session store
- **API Access**: JWT tokens
- **Ad-hoc Links**: Short-lived tokens with email verification
- **2FA**: Devise-two-factor for TP users

### Authorization
- **Backend**: Cancancan abilities
- **Frontend**: Route guards + UI visibility checks
- **API**: Token-based scope validation

### Data Protection
- **Encryption at Rest**:
  - Sensitive fields (emails) encrypted if policy requires
  - Database-level encryption available
- **Input Validation**: Rails strong parameters + model validations
- **XSS Prevention**: Vue template auto-escaping
- **SQL Injection**: ActiveRecord parameterized queries

### Web Security
- **CSRF**: Rails built-in protection
- **CORS**: Configured for API endpoints
- **HTTPS**: Enforced in production
- **Security Headers**: Via Rails default + custom

---

## 🧪 Testing Stack

### Ruby Tests
- **Framework**: RSpec 3.x
- **Coverage**: SimpleCov
- **Types**:
  - Model specs: `spec/models/`
  - Request specs: `spec/requests/`
  - System specs: `spec/system/`
  - Migration specs: `spec/migrations/`
  - Job specs: `spec/jobs/`

### JavaScript/Vue Tests
- **Framework**: Vue Test Utils + Vitest/Jest
- **Coverage**: Component unit tests
- **Location**: `spec/javascript/`

### E2E Tests
- **Framework**: Playwright or Cypress
- **Scope**: Critical user journeys
- **Scenarios**: 3-portal workflow

---

## 🐳 Infrastructure (Local Docker MVP)

### Docker Compose
- **Services**:
  - `app` - Rails application
  - `db` - PostgreSQL
  - `redis` - Sidekiq backend
  - `minio` - S3-compatible storage
  - `mailhog` - Email testing
- **Configuration**: `docker-compose.yml`
- **Volumes**: Persistent data storage

### Storage
- **Backend**: Active Storage
- **Local**: Minio (S3-compatible)
- **Configuration**: `config/storage.yml`
- **Environment**: `AWS_*` variables for Minio

### Development Tools
- **Linting**: RuboCop (Ruby), ESLint (JS)
- **Formatting**: StandardRB, Prettier
- **Debugging**: Byebug, Pry
- **Console**: Rails console

---

## 📦 Dependencies Summary

### Gemfile (Backend)
```ruby
# Core
gem 'rails', '~> 7.0'
gem 'pg', '~> 1.4'  # or 'mysql2', 'sqlite3'

# Authentication & Authorization
gem 'devise', '~> 4.8'
gem 'devise-two-factor'
gem 'cancancan', '~> 3.0'
gem 'jwt'

# Background Jobs
gem 'sidekiq', '~> 7.0'
gem 'redis', '~> 5.0'

# PDF Processing
gem 'hexapdf', '~> 0.15'
# PDFium via system library

# API
gem 'jbuilder', '~> 2.11'

# Security
gem 'rack-attack'

# File Uploads
gem 'activestorage'
```

### package.json (Frontend)
```json
{
  "dependencies": {
    "vue": "^3.3.0",
    "pinia": "^2.1.0",
    "axios": "^1.6.0",
    "tailwindcss": "^3.4.17",
    "daisyui": "^3.9.4"
  }
}
```

---

## 🔌 Environment Variables

### Required
```bash
# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/flo_doc

# Secrets
SECRET_KEY_BASE=your_rails_secret

# Redis (Sidekiq)
REDIS_URL=redis://localhost:6379

# Storage (Minio)
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=minioadmin
AWS_REGION=us-east-1
AWS_ENDPOINT_URL=http://localhost:9000
AWS_BUCKET_NAME=flo-doc

# Email (Development)
SMTP_ADDRESS=localhost
SMTP_PORT=1025  # MailHog
```

### Optional
```bash
# Feature Flags
FLODOC_MULTITENANT=false
FLODOC_PRO=false

# Webhooks
WEBHOOK_SECRET=your_webhook_secret

# Security
ENCRYPT_EMAILS=false
```

---

## 🎯 Technology Justifications

### Why Rails 7?
- **Brownfield**: DocuSeal is already Rails
- **Convention**: Rapid development with established patterns
- **Security**: Built-in protections
- **Ecosystem**: Rich gem ecosystem

### Why Vue 3 + Pinia?
- **Composition API**: Better TypeScript support
- **Performance**: Virtual DOM optimization
- **Ecosystem**: Strong community support
- **Integration**: Works well with Rails via Shakapacker

### Why PostgreSQL?
- **JSONB**: Perfect for flexible metadata (cohorts, uploads)
- **Reliability**: Production-ready
- **Performance**: Excellent for relational data
- **Extensions**: Full-text search if needed

### Why Docker Compose?
- **Consistency**: Same environment for all developers
- **Simplicity**: Single command setup
- **Isolation**: Services don't conflict
- **MVP**: No production infrastructure needed

---

## 📊 Performance Targets

| Metric | Baseline (DocuSeal) | FloDoc Target | Max Degradation |
|--------|---------------------|---------------|-----------------|
| Page Load | 1.0s | 1.2s | +20% |
| PDF Generation | 2.0s | 2.4s | +20% |
| DB Query (complex) | 100ms | 120ms | +20% |
| Sidekiq Job | 500ms | 600ms | +20% |

**NFR1**: All performance metrics must stay within 20% of baseline

---

## 🚀 Next Steps

1. **Setup Local Environment** → Follow `docs/architecture/infrastructure.md`
2. **Review Data Models** → Study `docs/architecture/data-models.md`
3. **Read Coding Standards** → Follow `docs/architecture/coding-standards.md`
4. **Start Story 1.1** → Database schema extension

---

**Document Status**: ✅ Complete
**Review Date**: After Phase 1 Implementation
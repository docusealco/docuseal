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

### FloDoc Enhancement - Current Development Workflow

**Completed Task:** `create-brownfield-prd` - Comprehensive PRD for 3-portal cohort management system

**PRD Status:** ✅ COMPLETE
- **Location:** `docs/prd.md`
- **Sections:** 6 sections following BMAD brownfield-prd-tmpl.yaml
- **Stories:** 21 stories across 7 phases (Phases 1-7 complete, Phase 8 with 2 infrastructure stories)
- **Commits:** Stories 8.0 and 8.0.1 committed to git

**Workflow Progress:**
1. ✅ **Section 1:** Intro Analysis & Context - Complete
2. ✅ **Section 2:** Requirements (FR1-FR24) - Complete
3. ✅ **Section 3:** Technical Constraints & Integration (TC1-TC10) - Complete
4. ✅ **Section 4:** UI Enhancement Goals (UI1-UI10) - Complete
5. ✅ **Section 5:** Epic & Story Structure (5.1-5.8) - Complete
6. ✅ **Section 6:** Epic Details (6.1-6.7) - Complete
7. ✅ **Section 6.8:** Phase 8 - Deployment & Documentation - Complete (Stories 8.0, 8.0.1)

**Current Phase:** ✅ **VALIDATION PHASE** (PO Agent)

**Next Agent:** PO (Product Owner) Agent
- **Task:** `po-master-checklist` - Validate all artifacts for integration safety
- **Purpose:** Verify story completeness, security, integration requirements, and BMAD compliance
- **Action:** PO will review `docs/prd.md` and flag any issues requiring updates

**After PO Validation:**
1. If issues found → Return to PM/Dev to fix
2. If approved → Move to story sharding (optional for IDE)
3. Then → Story implementation with Dev/QA agents

**Key Principles Followed:**
- ✅ No code changes until PRD complete
- ✅ Each story approved before committing
- ✅ Strict Story 4.6 structure compliance
- ✅ Advanced elicitation for every section
- ✅ Single institution model (not multi-tenant)
- ✅ Ad-hoc access pattern (no account creation for students/sponsors)
- ✅ Local Docker infrastructure (no production dependencies)

**Deferred Stories (Production Infrastructure):**
- Story 8.1: Production Infrastructure Setup (AWS)
- Story 8.2: Deployment Automation & CI/CD
- Story 8.3: Monitoring & Alerting
- Story 8.4: Documentation & Training

**Reason for Deferral:** Management wants to validate FloDoc system locally first before investing in production infrastructure.

### Next Steps for FloDoc Enhancement

1. **PO Validation** - Run `po-master-checklist` on complete PRD
2. **Address PO Feedback** - Fix any flagged issues
3. **Story Sharding** (Optional) - Create docs/prd/ folder for IDE support
4. **Story Implementation** - Dev agent implements stories 8.0 and 8.0.1
5. **QA Review** - QA agent reviews implementation
6. **Management Demo** - Run demo scripts to validate system

### Brownfield PRD Story Structure

**When writing stories in `docs/prd.md` during brownfield mode, STRICTLY adhere to Story 4.6 structure:**

```
#### Story X.X: [Descriptive Title]

**Status**: Draft/Pending
**Priority**: High/Medium/Low
**Epic**: [Epic Name]
**Estimated Effort**: [X days]
**Risk Level**: Low/Medium/High

##### User Story

**As a** [role],
**I want** [action],
**So that** [benefit].

##### Background

[Context, requirements, and rationale for this story]

##### Technical Implementation Notes

**Vue 3 Component Structure:**
```vue
<!-- app/javascript/[portal]/views/[Component].vue -->
<template>
  <!-- Component markup -->
</template>

<script setup>
// Component logic
</script>

<style scoped>
/* Component styles */
</style>
```

**Pinia Store:**
```typescript
// app/javascript/[portal]/stores/[store].ts
import { defineStore } from 'pinia'

export const use[Store]Store = defineStore('[store]', {
  state: () => ({
    // State properties
  }),
  actions: {
    // Async actions
  },
  getters: {
    // Computed properties
  }
})
```

**API Layer:**
```typescript
// app/javascript/[portal]/api/[resource].ts
export const [Resource]API = {
  async get[Resource](token: string): Promise<[Type]> {
    // API implementation
  }
}
```

**Type Definitions:**
```typescript
export interface [Type] {
  // Type properties
}
```

**Design System Compliance:**

Per FR28, all components must use design system assets from:
- `@.claude/skills/frontend-design/SKILL.md`
- `@.claude/skills/frontend-design/design-system/`

Specifically: colors, icons, typography, and layout patterns from the design system.

##### Acceptance Criteria

**Functional:**
1. ✅ [Functional requirement]
2. ✅ [Functional requirement]

**UI/UX:**
1. ✅ [UI/UX requirement]
2. ✅ [UI/UX requirement]

**Integration:**
1. ✅ [Integration requirement]
2. ✅ [Integration requirement]

**Security:**
1. ✅ [Security requirement]
2. ✅ [Security requirement]

**Quality:**
1. ✅ [Quality requirement]
2. ✅ [Quality requirement]

##### Integration Verification (IV1-4)

**IV1: API Integration**
- [Verification steps]

**IV2: Pinia Store**
- [Verification steps]

**IV3: Getters**
- [Verification steps]

**IV4: Token Routing**
- [Verification steps]

##### Test Requirements

**Component Specs:**
```javascript
// spec/javascript/[portal]/views/[Component].spec.js
import { mount, flushPromises } from '@vue/test-utils'
import [Component] from '@/[portal]/views/[Component].vue'
import { createPinia, setActivePinia } from 'pinia'

describe('[Component]', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('[test description]', async () => {
    // Test implementation
  })
})
```

**Integration Tests:**
- [Integration test requirements]

**E2E Tests:**
- [E2E test requirements]

##### Rollback Procedure

**If [failure scenario]:**
1. [Rollback step]
2. [Rollback step]

**Data Safety**: [Explanation of atomic operations]

##### Risk Assessment

**[Risk Level] because:**
- [Risk reason 1]
- [Risk reason 2]

**Specific Risks:**
1. **[Risk Name]**: [Risk description]
2. **[Risk Name]**: [Risk description]

**Mitigation:**
- [Mitigation strategy 1]
- [Mitigation strategy 2]

##### Success Metrics

- [Metric 1]
- [Metric 2]
- [Metric 3]
```

**Key Rules:**
1. **Always** use `#####` (H5) for all story subsections (User Story, Background, etc.)
2. **Always** include Status, Priority, Epic, Estimated Effort, Risk Level
3. **Always** include Integration Verification section (IV1-4)
4. **Always** include Test Requirements with code examples
5. **Always** include Rollback Procedure
6. **Always** include Risk Assessment with specific risks and mitigations
7. **Always** include Success Metrics
8. **Never** embed Acceptance Criteria inside User Story - use separate `##### Acceptance Criteria` section
9. **Always** use code blocks for Vue components, Pinia stores, API layers, and type definitions
10. **Always** reference design system compliance per FR28

**Commit Workflow:**
- **After each story is approved by user**: Commit the story to git before writing the next story
- **Commit message format**: `git commit -m "Add Story X.X: [Story Title]"`
- **Purpose**: Preserve each story independently, allow rollback if needed, maintain clear git history
- **Command sequence**:
  1. Write story to `docs/prd.md`
  2. User reviews and approves
  3. `git add docs/prd.md`
  4. `git commit -m "Add Story X.X: [Title]"`
  5. Proceed to next story
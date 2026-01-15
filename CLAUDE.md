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

### Git Commit Guidelines

**IMPORTANT:** When committing changes, follow these rules:

```bash
# ✅ CORRECT - Simple commit message
git commit -m "Add Story 1.1: Database Schema Extension"

# ❌ INCORRECT - Do NOT add Co-Authored-By
git commit -m "Add Story 1.1: Database Schema Extension

Co-Authored-By: Claude <noreply@anthropic.com>"
```

**Rules:**
- ✅ Use simple, descriptive commit messages
- ✅ Format: `git commit -m "Add Story X.X: [Story Title]"`
- ✅ Include story summary in commit body (optional)
- ❌ **NEVER** add `Co-Authored-By: Claude <noreply@anthropic.com>` or similar
- ❌ **NEVER** add AI assistant attribution in commit messages
- ✅ One story per commit for traceability

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
- Templates: `.bmad-core/templates/` (e.g., `brownfield-prd-tmpl.yaml`, `story-tmpl.yaml`)
- Agents: `.bmad-core/agent-teams/`

**Slash Commands:**
- `/BMad:agents:pm` - Product Manager agent
- `/BMad:agents:dev` - Developer agent

**Story Creation Workflow:**
- **Story Template**: `.bmad-core/templates/story-tmpl.yaml` - Defines story structure
- **Story Task**: `.bmad-core/tasks/create-next-story.md` - Automated story creation
- **Usage**: Use `/sm *draft` to create next story following the template
- **Output**: Stories created in `docs/stories/` with full context from architecture docs

### FloDoc Enhancement (Current Work)

**Context:** Transforming DocuSeal into a 3-portal cohort management system for training institutions.

**Key Changes:**
- New models: `Cohort`, `CohortEnrollment`, `Institution`, `Sponsor`
- Three portals: Admin, Student, Sponsor
- Workflow: Admin creates cohort → Students enroll → Admin verifies → Sponsor signs → Admin finalizes
- Excel export for cohort data (FR23)
- Custom UI/UX (not DaisyUI)

**Documentation Structure (Sharded):**
- **PRD**: `docs/prd.md` (main) + `docs/prd/` (sections)
- **Architecture**: `docs/architecture/` (sharded files)
  - `index.md` - Architecture overview
  - `tech-stack.md` - Technology stack
  - `data-models.md` - Database schemas and models
  - `api-design.md` - API specifications
  - `project-structure.md` - File organization
  - `security.md` - Security requirements
  - `coding-standards.md` - Code conventions
  - `testing-strategy.md` - Testing approach
  - `infrastructure.md` - Deployment setup
- **Stories**: `docs/stories/` - Individual story files (created via `*draft`)

**Story Creation:**
- Use `/sm *draft` to create next story
- Stories auto-populated from PRD + Architecture docs
- Follows `.bmad-core/templates/story-tmpl.yaml` structure
- Each story is a complete, self-contained implementation guide

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
3. **Story Sharding** ✅ COMPLETE - `docs/prd/` and `docs/architecture/` sharded
4. **Story Creation** - Use `/sm *draft` to create Story 1.1 (Database Schema Extension)
5. **QA Pre-Analysis** - Run `*risk` and `*design` on each story before development
6. **Story Implementation** - Dev agent implements stories with QA gates
7. **Management Demo** - Run demo scripts to validate system

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

**Story Creation Workflow (NEW):**

**MANDATORY WORKFLOW:** `create → review → approve → commit`

1. **Create**: SM creates story using `/sm *draft`
   - Story written to `docs/stories/` directory
   - Follows `.bmad-core/templates/story-tmpl.yaml` structure
   - Populated from PRD + Architecture docs

2. **Review**: User reviews the created story draft
   - Check for completeness, accuracy, and template compliance
   - Verify all sections present (User Story, Background, Tasks, Acceptance Criteria, etc.)
   - Confirm technical details match PRD requirements

3. **Approve**: User provides explicit approval
   - **CRITICAL**: Do NOT commit until user says "approved" or similar
   - User may request changes - return to step 1

4. **Commit**: After explicit approval only
   ```bash
   git add docs/stories/1.1.database-schema-extension.md
   git commit -m "Add Story 1.1: Database Schema Extension"
   ```
   - Commit message format: `git commit -m "Add Story X.X: [Story Title]"`
   - Purpose: Preserve each story independently, allow rollback, clear git history

**Key Rules:**
- ✅ **NEVER commit without explicit user approval**
- ✅ **Stories go in `docs/stories/`, NOT in `docs/prd.md`**
- ✅ **One story per commit for traceability**
- ✅ **If user requests changes, edit and re-submit for review**

**Example Session:**
```bash
# 1. Create story
@sm *draft
# Story created at docs/stories/1.1.database-schema-extension.md

# 2. User reviews (reads the file)

# 3. User provides feedback or approval
# "Looks good, approved" → Proceed to commit
# "Change X in section Y" → Edit and re-submit for review

# 4. Commit ONLY after approval
git add docs/stories/1.1.database-schema-extension.md
git commit -m "Add Story 1.1: Database Schema Extension"
```

## Enhanced IDE Development Workflow (STRICT BMAD CORE CYCLE)

**MANDATORY**: All FloDoc development MUST follow the BMad Core Development Cycle from `.bmad-core/user-guide.md`. This is **SUPER CRITICAL** for brownfield projects.

### 🚨 CRITICAL WORKFLOW RULES

**Violating these rules will result in broken code in master:**

1. **NEVER commit story implementation files until QA approves**
2. **ALWAYS create a git branch for each story after PO approval**
3. **QA must approve story implementation with >80% test pass rate**
4. **Only merge to master after QA approval**
5. **Delete branch after successful merge**
6. **Repeat cycle for each new story**

### The BMad Core Development Cycle (MANDATORY)

**Source:** `.bmad-core/user-guide.md` - "The Core Development Cycle (IDE)" diagram

```
┌─────────────────────────────────────────────────────────────┐
│  1. SM: Reviews Previous Story Dev/QA Notes                 │
│  2. SM: Drafts Next Story from Sharded Epic + Architecture  │
│  3. QA: *risk + *design (for brownfield/high-risk)          │
│  4. PO: Validate Story Draft (Optional)                     │
│  5. User: APPROVE STORY                                      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  6. DEV: Create Story Branch (YOUR REQUIREMENT)             │
│     git checkout -b story/1.1-database-schema               │
│     ⚠️ BRANCH CREATED ONLY AFTER USER APPROVAL              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  7. DEV: Implement Tasks + Write Tests                      │
│     - Use subtasks as TODO list                             │
│     - Mark [ ] → [x] in story file after each subtask       │
│     - Update Dev Agent Record with progress                 │
│  8. DEV: Run All Validations (rspec, lint, etc.)            │
│     - Must achieve >80% test pass rate                      │
│  9. DEV: Mark Ready for Review + Add Notes                  │
│     - Update story Status to "Ready for Review"             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  10. User Verification                                      │
│      └─ Request QA Review?                                  │
│         ├─ YES → Go to Step 11                              │
│         └─ NO → Skip to Step 12 (Verify tests yourself)     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  11. QA: Test Architect Review + Quality Gate              │
│      - *review: Comprehensive assessment                    │
│      - Requirements traceability                            │
│      - Test coverage analysis                               │
│      - Active refactoring (when safe)                       │
│      - Quality Gate Decision                                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  12. QA Decision:                                          │
│      ├─ PASS → Continue to Step 13                          │
│      ├─ CONCERNS → Team review, decide                      │
│      ├─ FAIL → Return to Dev (Step 7)                       │
│      └─ WAIVED → Document reasoning                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  13. IMPORTANT: Verify All Regression Tests and Linting    │
│      Are Passing (>80% pass rate required)                  │
│      ⚠️ CRITICAL: NO COMMIT WITHOUT QA APPROVAL             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  14. IMPORTANT: COMMIT YOUR CHANGES BEFORE PROCEEDING!     │
│      git add .                                              │
│      git commit -m "Add Story 1.1: Database Schema Extension"│
│      git push origin story/1.1-database-schema              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  15. Gate Update Needed?                                    │
│      └─ YES → QA: *gate to Update Status                    │
│      └─ NO → Continue                                       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  16. MERGE TO MASTER (Your Requirement)                     │
│      git checkout master                                    │
│      git merge story/1.1-database-schema                    │
│      git push origin master                                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  17. DELETE BRANCH (Your Requirement)                       │
│      git branch -d story/1.1-database-schema                │
│      git push origin --delete story/1.1-database-schema     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  18. Mark Story as Done                                     │
│  19. SM: Start Next Story Cycle                             │
│      Compact conversation, begin fresh                      │
└─────────────────────────────────────────────────────────────┘
```

**Key Points from Core Cycle:**
- **Step H (User Verification)**: User decides if QA review is needed
- **Step M**: Verify all tests pass BEFORE commit
- **Step N**: COMMIT happens AFTER QA approval
- **Step K**: Mark story as done, then loop back

**Your Additions:**
- **Step 6**: Branch creation (not in core diagram)
- **Step 16**: Merge to master (not in core diagram)
- **Step 17**: Delete branch (not in core diagram)
- **Step 7.1**: Mark subtasks [x] in story file
- **Step 7.2**: Update Dev Agent Record
- **Step 8.1**: >80% test pass rate required

### Branch Management Workflow

**For Each Story:**

```bash
# After PO approves story draft:
git checkout -b story/1.1-database-schema

# ... development work ...

# After QA approves implementation:
git add .
git commit -m "Add Story 1.1: Database Schema Extension"
git push origin story/1.1-database-schema

# Merge to master (via PR or direct):
git checkout master
git merge story/1.1-database-schema
git push origin master

# Delete branch:
git branch -d story/1.1-database-schema
git push origin --delete story/1.1-database-schema
```

### Dev Agent Task Management (CRITICAL)

**During story implementation, Dev agent MUST:**

1. **Use story subtasks as TODO list**
   - Read all subtasks from `Tasks / Subtasks` section
   - Treat each subtask as a development task to complete

2. **Mark subtasks complete in story file**
   - When subtask is done: `[ ]` → `[x]`
   - Update story file immediately after completing each subtask
   - Example:
     ```markdown
     - [x] Create migration file
     - [x] Create institutions table
     - [x] Create cohorts table
     - [x] Create cohort_enrollments table
     ```

3. **Track progress in Dev Agent Record**
   - Add completion notes for each major subtask
   - Update File List with all created/modified files
   - Log any issues or blockers in Debug Log References

4. **Update story Status**
   - Change from "Draft" → "In Progress" when dev starts
   - Change to "Ready for Review" when all tasks complete and tests pass

**Story File Update Rules:**
- ✅ **ALLOWED**: Tasks/Subtasks checkboxes, Dev Agent Record sections, Status
- ❌ **NOT ALLOWED**: User Story, Background, Acceptance Criteria, Testing sections

**Example Dev Agent Record Update:**
```markdown
### Dev Agent Record

### Agent Model Used
James (Full Stack Developer)

### Debug Log References
- Migration created successfully
- All foreign keys validated

### Completion Notes List
- [x] Subtask 1.1: Created migration file
- [x] Subtask 1.2: Created institutions table schema
- [x] Subtask 1.3: Created cohorts table schema
- [x] Subtask 1.4: Created cohort_enrollments table schema
- [x] Subtask 1.5: Added all indexes
- [x] Subtask 1.6: Added all foreign keys

### File List
- db/migrate/20260114000001_create_flo_doc_tables.rb
- spec/migrations/20260114000001_create_flo_doc_tables_spec.rb
- spec/integration/cohort_workflow_spec.rb

### Change Log
| Date | Action | Author |
|------|--------|--------|
| 2026-01-14 | Created migration and tests | James |
```

### Test Architect Command Reference

| Stage | Command | Purpose | Output | When to Use |
|-------|---------|---------|--------|-------------|
| **After PO Approval** | `*risk` | Identify integration & regression risks | `docs/qa/assessments/{epic}.{story}-risk-{YYYYMMDD}.md` | **REQUIRED for brownfield** |
| | `*design` | Create test strategy for dev | `docs/qa/assessments/{epic}.{story}-test-design-{YYYYMMDD}.md` | **REQUIRED for brownfield** |
| **During Development** | `*trace` | Verify test coverage | `docs/qa/assessments/{epic}.{story}-trace-{YYYYMMDD}.md` | Recommended |
| | `*nfr` | Validate quality attributes | `docs/qa/assessments/{epic}.{story}-nfr-{YYYYMMDD}.md` | Recommended |
| **After Dev Complete** | `*review` | **COMPREHENSIVE ASSESSMENT** | QA Results + Gate file | **MANDATORY - NO COMMIT WITHOUT THIS** |
| **Post-Review** | `*gate` | Update quality decision | Updated gate file | If issues found |

### Quality Gate Decisions (BLOCKING)

| Status | Meaning | Action Required | Can Commit? |
|--------|---------|-----------------|-------------|
| **PASS** | All critical requirements met, >80% tests pass | None | ✅ **YES** |
| **CONCERNS** | Non-critical issues found | Team review recommended | ⚠️ With approval |
| **FAIL** | Critical issues (security, missing P0 tests, <80% pass) | **MUST FIX** | ❌ **NO - BLOCKED** |
| **WAIVED** | Issues acknowledged and accepted | Document reasoning + approval | ⚠️ With approval |

### FloDoc-Specific Requirements

**For FloDoc Enhancement (Brownfield), ALWAYS:**

1. **After PO approves story**: Run `@qa *risk` and `@qa *design` BEFORE writing code
2. **During development**: Run `@qa *trace` to verify coverage
3. **Before commit**: Run `@qa *review` - **MANDATORY**
4. **Test pass rate**: Must be >80% for QA approval
5. **Branch per story**: Create `story/{number}-{slug}` branch
6. **Delete after merge**: Clean up branches after successful merge

**Why Strict Compliance Matters for FloDoc:**
- Brownfield changes risk breaking existing DocuSeal functionality
- 3-portal integration complexity requires thorough validation
- Security is critical (POPIA, sponsor portal access)
- Performance must be maintained (NFR1: <20% degradation)
- Management demo depends on working system

### Complete Example: Story 1.1 Implementation

```bash
# === PHASE 1: STORY CREATION ===
# 1. SM creates story
@sm *draft
# Creates: docs/stories/1.1.database-schema-extension.md

# 2. User reviews story
cat docs/stories/1.1.database-schema-extension.md

# 3. User approves story
# User says: "Story 1.1 approved"

# === PHASE 2: QA PRE-ANALYSIS (REQUIRED) ===
# 4. QA risk assessment
@qa *risk Story-1.1
# Creates: docs/qa/assessments/flodoc.1.1-risk-20260114.md

# 5. QA test design
@qa *design Story-1.1
# Creates: docs/qa/assessments/flodoc.1.1-test-design-20260114.md

# === PHASE 3: BRANCH CREATION ===
# 6. Dev creates story branch (AFTER PO APPROVAL)
git checkout -b story/1.1-database-schema

# === PHASE 4: IMPLEMENTATION ===
# 7. Dev implements story
# - Create migration: db/migrate/20260114000001_create_flo_doc_tables.rb
# - Write migration spec: spec/migrations/20260114000001_create_flo_doc_tables_spec.rb
# - Write integration spec: spec/integration/cohort_workflow_spec.rb

# 8. Dev runs tests
bundle exec rspec
# Must achieve >80% pass rate

# 9. Dev runs QA mid-dev check (optional but recommended)
@qa *trace Story-1.1
# Verifies: All acceptance criteria have tests

# 10. Dev marks ready for review
# Adds notes: "All tasks complete, tests written, ready for QA review"

# === PHASE 5: QA REVIEW (MANDATORY) ===
# 11. QA comprehensive review
@qa *review Story-1.1
# Creates: docs/qa/gates/flodoc.1.1-database-schema.yml
# Adds: QA Results section to story file

# 12. QA Decision:
# - PASS → Continue to commit
# - CONCERNS → Review with team
# - FAIL → Return to implementation

# === PHASE 6: ADDRESS ISSUES (IF NEEDED) ===
# 13. If QA found issues:
# - Fix the issues
# - Re-run tests
# - Request QA to update gate: @qa *gate Story-1.1

# === PHASE 7: COMMIT & MERGE (ONLY AFTER QA APPROVAL) ===
# 14. QA approves (>80% tests pass)
# User says: "QA approved, ready to commit"

# 15. Commit changes
git add .
git commit -m "Add Story 1.1: Database Schema Extension"

# 16. Push to branch
git push origin story/1.1-database-schema

# 17. Merge to master
git checkout master
git merge story/1.1-database-schema
git push origin master

# 18. Delete branch
git branch -d story/1.1-database-schema
git push origin --delete story/1.1-database-schema

# === PHASE 8: NEXT STORY ===
# 19. Compact conversation
# 20. Start next story cycle
```

### Common Pitfalls to Avoid

❌ **DON'T:**
- Commit before QA approval
- Skip `*risk` and `*design` for brownfield stories
- Merge without >80% test pass rate
- Delete branch before successful merge
- Skip branch creation and commit directly to master

✅ **DO:**
- Wait for explicit QA approval
- Create branch per story
- Run all required QA commands
- Verify tests pass before commit
- Clean up branches after merge

### Documentation & Audit Trail

**All QA activities create permanent records:**

```text
docs/qa/assessments/
  └── flodoc.1.1-risk-20260114.md
  └── flodoc.1.1-test-design-20260114.md
  └── flodoc.1.1-trace-20260114.md
  └── flodoc.1.1-nfr-20260114.md

docs/qa/gates/
  └── flodoc.1.1-database-schema.yml

docs/stories/
  └── 1.1.database-schema-extension.md (with QA Results section)
```

### Success Metrics

**The strict workflow ensures:**
- ✅ Zero regression defects in master
- ✅ 100% requirements coverage with tests
- ✅ Clear quality gates for go/no-go decisions
- ✅ Documented risk acceptance
- ✅ Consistent test quality
- ✅ Clean git history with per-story branches
- ✅ Management demo ready at all times

### Emergency Rollback

**If something breaks in master:**

```bash
# 1. Identify the problematic story
git log --oneline

# 2. Revert the merge commit
git revert <merge-commit-hash>

# 3. Push the revert
git push origin master

# 4. Re-open the story for fix
# Create new branch from master
git checkout -b story/1.1-fix
# Fix and re-run full QA cycle
```

**Remember: The workflow is SUPER CRITICAL. Violating it risks breaking the FloDoc enhancement project.**
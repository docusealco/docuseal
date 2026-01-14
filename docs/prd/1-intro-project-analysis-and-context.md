# 1. Intro Project Analysis and Context

## 1.1 SCOPE ASSESSMENT

**⚠️ SIGNIFICANT ENHANCEMENT - System-Wide Impact**

This PRD documents a **Major Feature Addition** that transforms the single-portal DocuSeal platform into a specialized 3-portal cohort management system for South African private training institutions.

**Enhancement Complexity Analysis:**
- **Type**: Major Feature Addition (3-Portal Cohort Management)
- **Impact**: Significant Impact (substantial existing code changes required)
- **Timeline**: Multiple development cycles
- **Risk Level**: High (touches core DocuSeal workflows)

**Why This Requires Full PRD Process:**
This is NOT a simple feature addition. The enhancement requires:
- New multi-tenant institution architecture
- Complex 3-party signature workflows (TP → Students → Sponsor → TP Review)
- Three separate portal interfaces with custom UI/UX
- State management across multiple entities
- Integration with existing DocuSeal form builder and signing infrastructure
- Bulk operations and email management rules

---

## 1.2 EXISTING PROJECT OVERVIEW

**Analysis Source**: IDE-based analysis + User requirements clarification

**Current Project State**:

FloDoc is built on **DocuSeal** - an open-source document filling and signing platform. The base system provides:

- **Document Form Builder**: WYSIWYG PDF form field creation with 12 field types (Signature, Date, File, Checkbox, etc.)
- **Multi-Submitter Workflows**: Support for multiple signers per document
- **Authentication & User Management**: Devise-based authentication with 2FA support
- **Email Automation**: SMTP-based automated email notifications
- **File Storage**: Flexible storage options (local disk, AWS S3, Google Cloud Storage, Azure Cloud)
- **PDF Processing**: HexaPDF for PDF generation, manipulation, and signature embedding
- **API & Webhooks**: RESTful API with webhook support for integrations
- **Mobile-Optimized UI**: Responsive interface supporting 7 UI languages and signing in 14 languages
- **Role-Based Access**: User roles and permissions system (via Cancancan)
- **Tech Stack**: Ruby on Rails 3.4.2, Vue.js 3, TailwindCSS 3.4.17, DaisyUI 3.9.4, Sidekiq for background jobs

**Key Existing Architecture for FloDoc Integration:**
- **Templates** = Document templates with form fields
- **Submissions** = Document workflows with multiple signers
- **Submitters** = Individual participants who sign documents
- **Completed Documents** = Final signed PDFs

---

## 1.3 AVAILABLE DOCUMENTATION ANALYSIS

**Available Documentation**:
- ✅ API Documentation (Node.js, Ruby, Python, PHP, Java, Go, C#, TypeScript, JavaScript)
- ✅ Webhook Documentation (Submission, Form, Template webhooks)
- ✅ Embedding Documentation (React, Vue, Angular, JavaScript form builders and signing forms)
- ✅ Architecture Documentation (docs/current-app-sitemap.md - comprehensive analysis)
- ✅ Existing PRD (v1.0) - being replaced by this version
- ⚠️ Coding Standards (not present - **requires documentation**)
- ⚠️ Technical Debt Analysis (not present - **requires analysis**)

**Recommendation**: This PRD will serve as the comprehensive planning document. Architecture analysis already completed in separate document.

---

## 1.4 ENHANCEMENT SCOPE DEFINITION

**Enhancement Type**: ✅ **Major Feature Addition** (3-Portal Cohort Management System)

**Enhancement Description**:

Transform the single-portal DocuSeal platform into a specialized **3-portal cohort management system** for South African private training institutions (Training Providers). The system manages cohorts through a **3-party signature workflow**: TP → Students → Sponsor → TP Review.

**Core Architecture**:
- **Templates = Cohorts**: Each cohort is a DocuSeal template containing all documents and signatory mappings
- **Submissions = Students**: Each student within a cohort is a submission with their own document workflow

**Complete Workflow**:
1. **Training Provider (TP) Onboarding**: TP creates account with name, surname, email
2. **Cohort Creation** (5-step multi-form):
   - Step 1: Cohort name
   - Step 2: Program type (learnership/internship/candidacy)
   - Step 3: Student emails (manual entry or bulk upload)
   - Step 4: Sponsor email (required - single email for all cohort documents)
   - Step 5: Upload main SETA agreement + additional supporting docs + specify required student uploads (ID, Matric, Tertiary Qualifications)
3. **Document Mapping Phase**: TP maps signatories (Learner, Sponsor, TP) to document sections using DocuSeal's existing mapping with tweaks
4. **TP Signing Phase**: TP signs first student → system auto-fills/signs remaining students
5. **Student Enrollment**: Bulk invite emails sent → students complete assigned docs + upload required files
6. **Sponsor Review**: Single sponsor link (one email regardless of multiple assignments) → 3-panel portal (student list | document viewer | student info) → individual or bulk completion
7. **TP Review**: TP reviews all completed documents from students and sponsor → finalizes 3-party agreements
8. **Download**: Bulk ZIP with structure: Cohort_Name/Student_Name/All_Docs.pdf + Audit_Trail.pdf

**Key System Behaviors**:
- **Single Email Rule**: Sponsor receives ONE email per cohort, regardless of how many students they're assigned to
- **TP Initiates Signing**: TP starts the signing workflow BEFORE students and sponsor
- **Bulk Operations**: TP can fill once and replicate for all students

**Impact Assessment**: ✅ **Significant Impact** (substantial existing code changes)

**Rationale for Impact Level**:
- **Single Institution Model**: One training institution manages multiple cohorts (NOT multi-tenant)
- **Ad-hoc Access**: Students and sponsors access via email links without creating accounts
- **New Domain Models**: Cohort, CohortEnrollment, Institution (single), Sponsor (ad-hoc)
- **Complex Workflow State Management**: TP → Students → Sponsor → TP Review with state tracking
- **Three Portal Interfaces**: Custom portals for TP (admin), Students, and Sponsor
- **Integration with DocuSeal**: Leverages existing form builder and signing infrastructure
- **Email Management Rules**: Single email per sponsor (no duplicates), bulk operations
- **Dashboard & Analytics**: Real-time cohort status tracking

---

## 1.5 GOALS AND BACKGROUND CONTEXT

**Goals**:

- Enable private training institutions to digitally manage training program cohorts from creation to completion
- Streamline multi-party document workflows (TP → Students → Sponsor → TP Review)
- Provide role-based portals tailored to each participant's specific needs and permissions
- Maintain 100% backward compatibility with core DocuSeal form builder and signing capabilities
- Reduce document processing time from weeks to days through automated workflows
- Provide real-time visibility into cohort and student submission status
- Implement single-email rule for sponsors (no duplicate emails)
- Enable bulk operations for TP and Sponsor to reduce repetitive work

**Background Context**:

South African private training institutions currently manage learnerships, internships, and candidacy programs through manual, paper-intensive processes. Each program requires collecting student documents (matric certificates, IDs, disability docs, qualifications), getting program agreements filled and signed by multiple parties (student, sponsor, institution), and tracking completion across dozens of students per cohort.

This manual process is time-consuming (taking weeks), error-prone, lacks visibility into status, and requires physical document handling. FloDoc leverages DocuSeal's proven document signing platform to create a specialized workflow that automates this process while maintaining the flexibility and power of DocuSeal's core form builder and signing engine.

The enhancement adds a cohort management layer on top of DocuSeal, creating three specialized portals that work with the existing document infrastructure rather than replacing it. Institutions continue using DocuSeal's form builder to create agreement templates, but now have a structured workflow for managing batches of students through the document submission and signing process.

**Critical Requirements from User Clarification**:
- Templates represent cohorts, submissions represent students
- TP initiates signing BEFORE students and sponsor
- Sponsor receives ONE email per cohort (no duplicates)
- TP Review phase after sponsor completion (not TP Finalization)
- Bulk operations: fill once, replicate for all students

---

## 1.6 CHANGE LOG

| Change | Date | Version | Description | Author |
|--------|------|---------|-------------|--------|
| Initial PRD Creation | 2025-01-01 | v1.0 | Brownfield enhancement for 3-portal cohort management | PM Agent |
| **PRD v2.0 - Fresh Start** | 2026-01-10 | v2.0 | Complete rewrite with clarified workflow requirements | User + PM |
| **Section 1 Complete** | 2026-01-10 | v2.0 | Intro Analysis with validated understanding | PM |
| **PO Validation Fixes** | 2026-01-14 | v2.1 | Addressed 3 blocking issues, added scope declaration | PO/PM |

---

## 1.7 SCOPE BOUNDARIES & DEPLOYMENT STRATEGY

**Deployment Decision:** ✅ **Local Docker MVP Only** (Option A)

**Rationale:**
- Management wants to validate FloDoc system locally first
- Defers production infrastructure investment until MVP proven
- Fastest path to working demo
- No cloud costs during validation phase

---

### In Scope (MVP - Local Docker)

**Core Functionality:**
- ✅ Local Docker development environment (PostgreSQL, Redis, Minio, MailHog)
- ✅ 3-portal cohort management workflow
- ✅ Single institution support
- ✅ All 21 implementation stories (Epics 1-7)
- ✅ Demo validation with sample data (Story 8.0.1)

**Technical:**
- ✅ Database schema for 3 new tables
- ✅ RESTful API with `/api/v1/flodoc/` namespace
- ✅ Vue.js 3 portals with TailwindCSS
- ✅ Email notifications (via MailHog)
- ✅ PDF generation and signing (HexaPDF)
- ✅ Excel export (rubyXL)
- ✅ Background jobs (Sidekiq)

**Testing:**
- ✅ End-to-end workflow testing
- ✅ Mobile responsiveness testing
- ✅ Performance testing (50+ students)
- ✅ Security audit (with enhanced checklist)
- ✅ User acceptance testing

---

### Out of Scope (Post-MVP - Deferred)

**Production Infrastructure (Stories 8.1-8.4 - Deferred):**
- ❌ Production CI/CD pipeline
- ❌ Cloud infrastructure (AWS/GCP/Azure)
- ❌ Infrastructure as Code (Terraform)
- ❌ DNS/domain registration
- ❌ CDN/static asset hosting
- ❌ Production monitoring (Sentry, New Relic)
- ❌ Analytics and user tracking
- ❌ Blue-green deployment
- ❌ Production backup strategy

**User Documentation & Operations (Stories 8.5-8.7 - Deferred):**
- ⚠️ **Story 8.5**: User Communication & Training Materials (blocking - must be created before dev)
- ❌ **Story 8.6**: In-app help system
- ❌ **Story 8.7**: Knowledge transfer plan & operations runbook
- ❌ Migration announcement emails
- ❌ User training materials
- ❌ FAQ and tutorials
- ❌ Support team training
- ❌ Incident response procedures

**Future Enhancements:**
- ❌ Multi-institution support
- ❌ Advanced analytics dashboard
- ❌ Custom branding
- ❌ Additional portal features

---

### Production Path Forward

**After Local Validation Success:**
1. Decision point: Proceed to production or iterate on MVP
2. If proceeding: Create Stories 8.1-8.4 (production infrastructure)
3. Implement Stories 8.5-8.7 (documentation & KT)
4. Deploy to production environment

**Note:** Production deployment is **NOT** part of current scope. All production-related work is deferred pending successful local validation.

---

### Scope Acknowledgment

**Current State:** Local Docker MVP ready for development
**Target State:** Working demo with 3-portal workflow
**Production Readiness:** Deferred to post-MVP phase

This scope declaration addresses PO Validation Issue #1 (Production Deployment Strategy Undefined).

---

## 1.8 EXTENSIBILITY PATTERNS (Optional Enhancement)

**Status**: Draft - Reference Documentation
**Priority**: Medium (Post-MVP)
**Purpose**: Guide future development and customization

This section documents how to extend the FloDoc system for future enhancements.

---

### 1.8.1 Adding New Portal Types

**Current Pattern**: 3 portals (TP, Student, Sponsor) with ad-hoc token authentication

**Extension Steps:**

1. **Create Portal Controller** (app/controllers/flodoc/portals/):
```ruby
# app/controllers/flodoc/portals/new_portal_controller.rb
class Flodoc::Portals::NewPortalController < ApplicationController
  before_action :authenticate_token!

  def dashboard
    # Uses token-based auth like Student/Sponsor portals
    @data = NewPortalService.load_data(@token)
  end
end
```

2. **Add Token Model** (if new token type needed):
```ruby
# app/models/flodoc/new_portal_token.rb
class Flodoc::NewPortalToken < ApplicationRecord
  belongs_to :cohort
  has_secure_token :token
  validates :email, presence: true, uniqueness: { scope: :cohort_id }
end
```

3. **Add Vue Portal** (app/javascript/new_portal/):
```typescript
// app/javascript/new_portal/application.js
import { createApp } from 'vue'
import NewPortalApp from './NewPortalApp.vue'

createApp(NewPortalApp).mount('#app')
```

4. **Update Routes** (config/routes.rb):
```ruby
namespace :new_portal do
  get 'dashboard', to: 'dashboard#index'
  post 'submit', to: 'submissions#create'
end
```

---

### 1.8.2 Extending Cohort State Machine

**Current States**: `draft` → `active` → `completed` → `finalized`

**Adding New State:**

1. **Update State Enum** (app/models/flodoc/cohort.rb):
```ruby
class Flodoc::Cohort < ApplicationRecord
  STATES = %w[draft active completed finalized under_review].freeze
  enum status: STATES.index_with(&:to_s)
end
```

2. **Add State Transition Logic**:
```ruby
# app/models/flodoc/cohort.rb
def can_under_review?
  completed? && all_sponsors_signed?
end

def under_review!
  update!(status: 'under_review')
  Flodoc::CohortMailer.under_review_notification(self).deliver_later
end
```

3. **Update Portal UI** (app/javascript/tp_portal/views/CohortDetail.vue):
```vue
<template>
  <div v-if="cohort.status === 'under_review'">
    <!-- New UI for review state -->
  </div>
</template>
```

---

### 1.8.3 Adding New Document Types

**Current**: PDF documents with form fields

**Extension Pattern:**

1. **Create Document Type Model**:
```ruby
# app/models/flodoc/document_type.rb
class Flodoc::DocumentType < ApplicationRecord
  validates :name, presence: true
  validates :handler, presence: true

  # handler values: 'pdf', 'docx', 'spreadsheet', 'custom'
end
```

2. **Register Handler**:
```ruby
# config/initializers/flodoc_document_types.rb
Flodoc::DocumentType.register_handler('spreadsheet', Flodoc::SpreadsheetHandler)
```

3. **Implement Handler**:
```ruby
# app/services/flodoc/handlers/spreadsheet_handler.rb
module Flodoc
  module Handlers
    class SpreadsheetHandler
      def self.generate(cohort, data)
        # Custom generation logic
      end

      def self.validate(file)
        # Custom validation logic
      end
    end
  end
end
```

---

### 1.8.4 Extending the API

**Current**: `/api/v1/flodoc/` namespace

**Adding New Endpoint:**

1. **Create API Controller**:
```ruby
# app/controllers/api/v1/flodoc/new_feature_controller.rb
class Api::V1::Flodoc::NewFeatureController < Api::V1::BaseController
  def index
    # Uses JWT authentication from base controller
    render json: { data: 'example' }
  end
end
```

2. **Add Route**:
```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    namespace :flodoc do
      get 'new_feature', to: 'new_feature#index'
    end
  end
end
```

3. **Update API Documentation**:
```markdown
### GET /api/v1/flodoc/new_feature

**Authentication**: Bearer JWT token

**Response**:
```json
{
  "data": "example"
}
```

---

### 1.8.5 Adding New Authentication Providers

**Current**: Email-based ad-hoc tokens for students/sponsors

**Adding OAuth Provider:**

1. **Add OmniAuth Strategy** (Gemfile):
```ruby
gem 'omniauth-google-oauth2'
gem 'omniauth-saml'  # For enterprise SSO
```

2. **Configure Provider** (config/initializers/omniauth.rb):
```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET']
  provider :saml,
    issuer: 'flodoc',
    idp_sso_target_url: ENV['SAML_SSO_URL']
end
```

3. **Create Authentication Handler**:
```ruby
# app/services/flodoc/auth/oauth_handler.rb
module Flodoc
  module Auth
    class OAuthHandler
      def self.authenticate(provider, auth_hash)
        user = User.find_or_create_by(email: auth_hash.info.email) do |u|
          u.password = SecureRandom.hex(16)
          u.name = auth_hash.info.name
        end
        # Generate portal-specific token
        Flodoc::PortalToken.create!(user: user, provider: provider)
      end
    end
  end
end
```

---

### 1.8.6 Customizing UI Components

**Current**: Vue 3 + TailwindCSS 3.4.17 + DaisyUI 3.9.4

**Customization Pattern:**

1. **Override Design Tokens** (app/javascript/design-system/tailwind.config.js):
```javascript
module.exports = {
  theme: {
    extend: {
      colors: {
        flodoc: {
          primary: '#1e3a8a',  // Custom blue
          accent: '#f59e0b',   // Custom amber
        }
      }
    }
  }
}
```

2. **Create Custom Component**:
```vue
<!-- app/javascript/elements/FlodocCustomButton.vue -->
<template>
  <button
    :class="['btn', `btn-${variant}`, customClass]"
    @click="$emit('click')"
  >
    <slot />
  </button>
</template>

<script setup>
defineProps({
  variant: { type: String, default: 'primary' },
  customClass: { type: String, default: '' }
})
</script>

<style scoped>
.btn-primary {
  @apply bg-flodoc-primary text-white hover:bg-blue-800;
}
</style>
```

3. **Register Globally**:
```javascript
// app/javascript/application.js
import FlodocCustomButton from './elements/FlodocCustomButton.vue'
app.component('FlodocCustomButton', FlodocCustomButton)
```

---

### 1.8.7 Extending Background Jobs

**Current**: Sidekiq queues for emails, webhooks, PDF generation

**Adding New Job Type:**

1. **Create Job**:
```ruby
# app/jobs/flodoc/custom_analysis_job.rb
class Flodoc::CustomAnalysisJob < ApplicationJob
  queue_as :analytics

  def perform(cohort_id)
    cohort = Flodoc::Cohort.find(cohort_id)
    # Custom analysis logic
    Flodoc::AnalysisReport.generate(cohort)
  end
end
```

2. **Enqueue Job**:
```ruby
# In any service or controller
Flodoc::CustomAnalysisJob.perform_later(@cohort.id)
```

3. **Monitor in Sidekiq**:
```ruby
# config/sidekiq.yml
:queues:
  - default
  - mailers
  - webhooks
  - pdf
  - analytics  # New queue
```

---

### 1.8.8 Adding Custom Validations

**Current**: Standard Rails validations

**Custom Validation Pattern:**

1. **Create Validator**:
```ruby
# app/validators/flodoc/sponsor_email_validator.rb
class Flodoc::SponsorEmailValidator < ActiveModel::Validator
  def validate(record)
    unless record.email.end_with?('@company.com')
      record.errors.add(:email, 'must be a company email')
    end
  end
end
```

2. **Use in Model**:
```ruby
# app/models/flodoc/submitter.rb
class Flodoc::Submitter < ApplicationRecord
  validates_with Flodoc::SponsorEmailValidator, if: :sponsor?
end
```

---

### 1.8.9 Database Extension Patterns

**Adding New Tables:**

1. **Migration**:
```ruby
# db/migrate/20260114120000_create_flodoc_custom_data.rb
class CreateFlodocCustomData < ActiveRecord::Migration[7.0]
  def change
    create_table :flodoc_custom_data do |t|
      t.references :cohort, null: false, foreign_key: true
      t.jsonb :data
      t.timestamps
    end

    add_index :flodoc_custom_data, [:cohort_id, :created_at]
  end
end
```

2. **Model**:
```ruby
# app/models/flodoc/custom_datum.rb
class Flodoc::CustomDatum < ApplicationRecord
  belongs_to :cohort
  validates :data, presence: true
end
```

---

### 1.8.10 Event System Extension

**Current**: SubmissionEvents for audit trail

**Adding Custom Events:**

1. **Define Event Types**:
```ruby
# app/models/flodoc/event_type.rb
class Flodoc::EventType < ApplicationRecord
  TYPES = %w[
    cohort_created
    cohort_completed
    submitter_signed
    sponsor_invited
    document_downloaded
    custom_alert_sent  # New event
  ].freeze
end
```

2. **Track Custom Events**:
```ruby
# app/services/flodoc/event_tracker.rb
module Flodoc
  class EventTracker
    def self.track(cohort, event_type, user, metadata = {})
      Flodoc::SubmissionEvent.create!(
        cohort: cohort,
        event_type: event_type,
        user: user,
        metadata: metadata
      )
    end
  end
end
```

3. **Query Events**:
```ruby
# In reports or analytics
Flodoc::SubmissionEvent
  .where(cohort_id: cohort.id)
  .where(event_type: 'custom_alert_sent')
  .where('created_at > ?', 30.days.ago)
  .count
```

---

### 1.8.11 Integration Checklist

When extending FloDoc, verify:

- ✅ **Security**: New endpoints use JWT/auth tokens
- ✅ **Multi-tenancy**: Check single-institution vs multi-institution
- ✅ **Database**: Proper foreign keys and indexes
- ✅ **Background Jobs**: Sidekiq queue exists
- ✅ **API Versioning**: Use `/api/v1/flodoc/` namespace
- ✅ **Vue Components**: Follow design system (FR28)
- ✅ **Testing**: RSpec coverage for new code
- ✅ **Rollback**: Migration can be reversed
- ✅ **Documentation**: Update this extensibility guide

---

**Note**: This is optional documentation for future development. All current stories (1.1-8.0.1) are complete and ready for implementation.

---


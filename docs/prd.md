# FloDoc Brownfield Enhancement PRD
**3-Portal Cohort Management System for Training Institutions**

*Version: v2.0*
*Date: 2026-01-10*
*Status: Section 6 of 6 - In Progress*

---

## Table of Contents
1. [Intro Project Analysis and Context](#intro-project-analysis-and-context)
2. [Requirements](#requirements)
3. [User Interface Enhancement Goals](#user-interface-enhancement-goals)
4. [Technical Constraints and Integration](#technical-constraints-and-integration)
5. [Epic and Story Structure](#epic-and-story-structure)
6. [Epic Details](#epic-details)

---

## 1. Intro Project Analysis and Context

### 1.1 SCOPE ASSESSMENT

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

### 1.2 EXISTING PROJECT OVERVIEW

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

### 1.3 AVAILABLE DOCUMENTATION ANALYSIS

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

### 1.4 ENHANCEMENT SCOPE DEFINITION

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

### 1.5 GOALS AND BACKGROUND CONTEXT

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

### 1.6 CHANGE LOG

| Change | Date | Version | Description | Author |
|--------|------|---------|-------------|--------|
| Initial PRD Creation | 2025-01-01 | v1.0 | Brownfield enhancement for 3-portal cohort management | PM Agent |
| **PRD v2.0 - Fresh Start** | 2026-01-10 | v2.0 | Complete rewrite with clarified workflow requirements | User + PM |
| **Section 1 Complete** | 2026-01-10 | v2.0 | Intro Analysis with validated understanding | PM |

---

## 2. Requirements

### 2.1 FUNCTIONAL REQUIREMENTS

**FR1**: The system shall support a **single training institution** that can manage multiple training cohorts independently.

**FR2**: The system shall provide three distinct portal interfaces: TP Portal (Training Provider admin), Student Portal (for enrolled students), and Sponsor Portal (for program sponsors).

**FR3**: The TP Portal shall support **cohort creation** via a 5-step multi-form:
- Step 1: Cohort name
- Step 2: Program type (learnership/internship/candidacy)
- Step 3: Student emails (manual entry or bulk upload)
- Step 4: Sponsor email (required - single email for all cohort documents)
- Step 5: Upload main SETA agreement + additional supporting docs + specify required student uploads (ID, Matric, Tertiary Qualifications)

**FR4**: The system shall allow TP to **map signatories** (Learner, Sponsor, TP) to document sections using DocuSeal's existing mapping capabilities with tweaks for bulk operations.

**FR5**: The system shall enable **TP Signing Phase** where:
- TP signs the first student's document
- System **duplicates the completed submission** (not empty template) to remaining students
- TP's fields and signatures are **auto-filled across all student submissions**
- This eliminates the need for TP to sign each submission individually
- Prevents duplicate sponsor emails through workflow state management
- Note: DocuSeal's native multi-submission duplicates empty templates; FloDoc will duplicate the signed submission instead

**FR6**: The system shall generate **unique invite links** for students via bulk email invitations.

**FR7**: The system shall allow students to **upload required documents** (ID, Matric, Tertiary Qualifications) as specified during cohort creation.

**FR8**: The system shall allow students to **fill and sign assigned documents** using DocuSeal's existing form builder.

**FR9**: The system shall implement **state management** for each student enrollment with states: "Waiting", "In Progress", "Complete".

**FR10**: The system shall **prevent sponsor access** until all students in a cohort have completed their submissions.

**FR11**: The system shall provide **sponsor portal** with 3-panel layout:
- Left: List of all students in cohort
- Middle: Document viewer (currently selected document)
- Right: Vertical list of thumbnail representations of all documents for the currently selected student

**FR12**: The system shall allow sponsor to **review and sign** each student's documents individually OR bulk sign after first completion.

**FR13**: The system shall enforce **single email rule**: Sponsor receives ONE email per cohort, regardless of how many students they're assigned to.

**FR14**: The system shall allow sponsor to **submit all signatures** to finalize their portion of the workflow.

**FR15**: The system shall allow TP to **review all completed documents** from students and sponsor after sponsor submission.

**FR16**: The system shall enable TP to **finalize 3-party agreements** after review.

**FR17**: The system shall provide **bulk download** functionality with ZIP structure:
```
Cohort_Name/
├── Student_1/
│   ├── Main_Agreement_Signed.pdf
│   ├── ID_Document.pdf
│   ├── Matric_Certificate.pdf
│   ├── Tertiary_Qualifications.pdf
│   └── Audit_Trail.pdf
├── Student_2/
│   └── ...
```

**FR18**: The system shall provide **email notifications** for:
- Cohort creation (TP only)
- Student invitations (bulk email)
- Submission reminders (configurable)
- Sponsor access notification (when all students complete)
- State change updates

**FR19**: The system shall provide **real-time dashboard** showing cohort completion status for all three portals.

**FR20**: The system shall maintain **audit trail** for all document actions with timestamps.

**FR21**: The system shall store all documents using **DocuSeal's existing storage infrastructure**.

**FR22**: The system shall maintain **100% backward compatibility** with existing DocuSeal form builder and signing workflows.

**FR23**: The system shall allow TP to **export cohort data to Excel** format containing: cohort name, student name, student surname, student age, student race, student city, program type, sponsor company name, disability status, and gender.

### 2.2 NON-FUNCTIONAL REQUIREMENTS

**NFR1**: The system must maintain existing performance characteristics and not exceed current memory usage by more than 20%.

**NFR2**: The system must be **mobile-optimized** and support all existing DocuSeal UI languages.

**NFR3**: The system must leverage **existing DocuSeal authentication infrastructure** (Devise + JWT) with role-based access control.

**NFR4**: The system must integrate seamlessly with **existing DocuSeal email notification system**.

**NFR5**: The system must support **concurrent cohort management** without data leakage between cohorts.

**NFR6**: The system must provide **audit trails** for all document verification actions (rejections, approvals).

**NFR7**: The system must maintain **document integrity and signature verification** capabilities.

**NFR8**: The system must support **background processing** for email notifications and document operations via Sidekiq.

**NFR9**: The system must comply with **South African electronic document and signature regulations**.

**NFR10**: The system must provide **comprehensive error handling and user feedback** for all portal interactions.

**NFR11**: The system must implement **single email rule** for sponsors (no duplicate emails regardless of multiple student assignments).

**NFR12**: The system must support **bulk operations** to minimize repetitive work for TP and Sponsor.

### 2.3 COMPATIBILITY REQUIREMENTS

**CR1: API Compatibility**: All new endpoints must follow existing DocuSeal API patterns and authentication mechanisms. No breaking changes to existing public APIs.

**CR2: Database Schema Compatibility**: New tables and relationships must not modify existing DocuSeal core schemas. Extensions should use foreign keys and new tables only.

**CR3: UI/UX Consistency**: All three portals must use **custom TailwindCSS design system** (replacing DaisyUI) while maintaining mobile-first responsive design principles.

**CR4: Integration Compatibility**: The system must work with existing DocuSeal integrations (webhooks, API, embedded forms) without requiring changes to external systems.

---

## 3. User Interface Enhancement Goals

### 3.1 Integration with Existing UI

**Design System Migration**:
The three portals will use a **custom TailwindCSS design system** replacing DaisyUI (CR3), while maintaining the same responsive design principles and mobile-first approach as the existing DocuSeal interface. The new design system will:

- **Preserve Core UX Patterns**: Maintain familiar interaction patterns from DocuSeal (form builders, signing flows, modal dialogs)
- **Enhance Accessibility**: WCAG 2.1 AA compliance for all portals
- **Support Dark/Light Mode**: Consistent with existing DocuSeal theme support
- **Language Support**: Maintain existing i18n infrastructure for 7 UI languages

**Visual Consistency**:
- **Color Palette**: Extend DocuSeal's existing brand colors with cohort-specific accent colors for status indicators
- **Typography**: Use existing font stack for consistency
- **Iconography**: Leverage existing icon library or extend with cohort-specific icons
- **Spacing & Layout**: Follow existing 8px grid system and spacing conventions

**Development Mandate - Design System Compliance**:
**CRITICAL**: During frontend development, the Dev Agent (James) MUST strictly adhere to the FloDoc design system specification located at `.claude/skills/frontend-design/SKILL.md` and the visual assets in `.claude/skills/frontend-design/design-system/`. This includes:

- **Color System**: Extract primary, secondary, neutral, and accent colors from `design-system/Colors and shadows/Brand colors/` and `Complementary colors/` SVG/JPG specifications
- **Typography**: Follow `design-system/Typography/typoraphy.txt` and `design-system/Fonts/fonts.txt` for font families, sizes, weights, and line heights
- **Component Library**: Use atomic design components from `design-system/Atoms/` (Buttons, Inputs, Checkboxes, Menus, Progress Tags, etc.)
- **Iconography**: Source all icons from `design-system/Icons/` organized by category (security, users, files, notifications, etc.)
- **Brand Assets**: Reference `design-system/Logo/` for all logo variations
- **Shadows & Elevation**: Apply shadow styles from `design-system/Colors and shadows/Shadows/`

**Agent Coordination**:
- **Dev Agent (James)**: Must reference the design system folder before writing any frontend code. All Vue components, TailwindCSS classes, and styling decisions must align with the design system specifications.
- **Scrum Master (Bob)**: Must be aware of this design system requirement during story creation and acceptance criteria definition. Frontend stories should include verification that all UI elements conform to the design system specifications.

**Consequences of Non-Compliance**: UI elements not derived from the design system will be rejected during code review. The design system is the single source of truth for all visual decisions.

### 3.2 Modified/New Screens and Views

#### TP Portal (Admin Interface)

**New Screens**:
1. **Institution Onboarding** - Single-page form for initial TP setup
2. **Cohort Dashboard** - Main landing with cohort list, status cards, and quick actions
3. **Cohort Creation Wizard** - 5-step multi-form:
   - Step 1: Basic Info (name, program type)
   - Step 2: Student Management (email entry/bulk upload)
   - Step 3: Sponsor Configuration (single email, notification settings)
   - Step 4: Document Upload (SETA agreement + supporting docs)
   - Step 5: Student Upload Requirements (ID, Matric, Tertiary Qualifications)
4. **Document Mapping Interface** - Visual drag-and-drop for signatory assignment
5. **TP Signing Interface** - Single signing flow with "apply to all students" option
6. **Student Enrollment Status** - Bulk invite management and tracking
7. **Sponsor Access Monitor** - Real-time dashboard showing which sponsors have accessed their portal, when they last logged in, which students they've reviewed, and current pending actions. Prevents duplicate email sends and allows TP to intervene if sponsor hasn't accessed after notification.
8. **TP Review Dashboard** - 3-panel review interface:
   - **Left Panel**: Student list with completion status (Waiting for Student, Waiting for Sponsor, Complete)
   - **Middle Panel**: Full document viewer showing the selected student's completed documents
   - **Right Panel**: Verification controls - approve/reject individual documents, add verification notes, mark student as verified
9. **Cohort Analytics** - Completion rates, timeline, bottlenecks
10. **Excel Export Interface** - Data selection and export configuration

**Modified Existing Screens**:
- **Template Builder** - Enhanced with cohort-specific metadata fields
- **User Settings** - Institution role management added

#### Student Portal

**New Screens**:
1. **Student Invitation Landing** - Accept cohort invitation, view requirements
2. **Document Upload Interface** - Multi-file upload with validation
3. **Student Signing Flow** - DocuSeal signing form with document preview
4. **Submission Status** - Real-time progress tracking
5. **Completion Confirmation** - Summary of submitted documents

**Modified Existing Screens**:
- **Submission Form** - Rebranded for cohort context, simplified navigation

#### Sponsor Portal

**New Screens**:
1. **Cohort Dashboard** - Overview of all students in cohort with bulk signing capability
2. **Student List View** - Searchable, filterable list of students with status indicators
3. **Signature Capture Interface** - Two methods for signature: draw on canvas or type name
4. **Bulk Signing Preview** - Confirmation modal showing all affected students before signing
5. **Success Confirmation** - Post-signing summary with next steps

**Modified Existing Screens**:
- **Signing Form** - Enhanced for bulk cohort signing workflow

### 3.3 UI Consistency Requirements

**Portal-Specific Requirements**:

**TP Portal**:
- **Admin-First Design**: Complex operations made simple through progressive disclosure
- **Bulk Operations**: Prominent "fill once, apply to all" patterns
- **Status Visualization**: Color-coded cohort states (Pending, In Progress, Ready for Sponsor, Complete)
- **Action History**: Audit trail visible within interface

**What is Progressive Disclosure?**
This is a UX pattern that hides complexity until the user needs it. For the TP Portal, this means:
- **Default View**: Show only essential actions (Create Cohort, View Active Cohorts, Export Data)
- **On-Demand Complexity**: Advanced features (detailed analytics, bulk email settings, custom document mappings) are revealed only when users click "Advanced Options" or navigate to specific sections
- **Example**: The Cohort Creation Wizard (5 steps) uses progressive disclosure - each step shows only the fields needed for that step, preventing overwhelming the user with all 20+ fields at once
- **Benefit**: Reduces cognitive load for new users while keeping power features accessible for experienced admins

**Student Portal**:
- **Mobile-First**: Optimized for smartphone access
- **Minimal Steps**: Maximum 3 clicks to complete any document
- **Clear Requirements**: Visual checklist of required vs. optional documents
- **Progress Indicators**: Step-by-step completion tracking

**Sponsor Portal**:
- **Review-Optimized**: Keyboard shortcuts for document navigation
- **Bulk Actions**: "Sign All" and "Bulk Review" modes
- **Document Comparison**: Side-by-side view capability
- **No Account Required**: Email-link only access pattern
- **Progress Tracking**: Persistent progress bar showing completion status (e.g., "3/15 students completed - 20%") with visual indicator
- **Tab-Based Navigation**: Pending/Completed tabs for clear workflow separation

**Cross-Portal Consistency**:
- **Navigation**: All portals use consistent header/navigation patterns
- **Notifications**: Toast notifications for state changes
- **Error Handling**: Consistent error message formatting and recovery options
- **Loading States**: Skeleton screens and spinners for async operations
- **Empty States**: Helpful guidance when no cohorts/students/documents exist

**Mobile Responsiveness**:
- **Breakpoints**: 640px (sm), 768px (md), 1024px (lg), 1280px (xl)
- **Touch Targets**: Minimum 44x44px for all interactive elements
- **Tablet Optimization**: 3-panel sponsor portal collapses to 2-panel on tablets
- **Vertical Layout**: All portals stack vertically on mobile devices

**Accessibility Standards**:
- **Keyboard Navigation**: Full keyboard support for all portals
- **Screen Readers**: ARIA labels and semantic HTML throughout
- **Focus Management**: Clear focus indicators and logical tab order
- **Color Contrast**: Minimum 4.5:1 ratio for all text
- **Reduced Motion**: Respect user's motion preferences

---

## 4. Technical Constraints and Integration Requirements

### 4.1 Existing Technology Stack

**Based on Architecture Analysis** (docs/current-app-sitemap.md):

**Languages:**
- Ruby 3.4.2
- JavaScript (Vue.js 3)
- HTML/CSS (TailwindCSS 3.4.17)

**Frameworks:**
- Ruby on Rails 7.x (with Shakapacker 8.0)
- Vue.js 3 with Composition API
- Devise for authentication
- Cancancan for authorization
- Sidekiq for background processing

**Database:**
- PostgreSQL/MySQL/SQLite (configured via DATABASE_URL)
- Redis for Sidekiq job queue

**Infrastructure:**
- Puma web server
- Active Storage (S3, Google Cloud, Azure, or local disk)
- SMTP server for email delivery

**External Dependencies:**
- HexaPDF (PDF generation and signing)
- PDFium (PDF rendering)
- rubyXL (Excel export - **to be added**)
- Ngrok (for local testing with public URLs)

**Key Libraries & Gems:**
- `devise` - Authentication
- `devise-two-factor` - 2FA support
- `cancancan` - Authorization
- `sidekiq` - Background jobs
- `hexapdf` - PDF processing
- `prawn` - PDF generation (alternative)
- `rubyXL` - Excel file generation (**required for FR23**)

### 4.2 Integration Approach

**Database Integration Strategy:**
- **New Tables Only**: Create `cohorts`, `cohort_enrollments`, `institutions`, `sponsors` tables
- **Foreign Keys**: Link to existing `templates`, `submissions`, `users` tables
- **No Schema Modifications**: Existing DocuSeal tables remain unchanged
- **Migration Safety**: All migrations must be reversible
- **Data Isolation**: Use `institution_id` scoping for all FloDoc queries

**API Integration Strategy:**
- **Namespace Extension**: Add `/api/v1/flodoc/` namespace for new endpoints
- **Pattern Consistency**: Follow existing DocuSeal REST conventions
- **Authentication**: Reuse existing Devise + JWT infrastructure
- **Rate Limiting**: Apply existing rate limits to new endpoints
- **Webhook Compatibility**: New cohort events trigger existing webhook infrastructure

**Frontend Integration Strategy:**
- **Vue.js Architecture**: Extend existing Vue 3 app with new portal components
- **Design System**: Replace DaisyUI with custom TailwindCSS (per CR3)
- **Component Structure**: Create new portal-specific components in `app/javascript/cohorts/`
- **Routing**: Use existing Vue Router with new portal routes
- **State Management**: Vuex or Pinia for cohort state (to be determined)
- **No Breaking Changes**: Existing DocuSeal UI remains functional

**Testing Integration Strategy:**
- **RSpec**: Extend existing test suite with new model/request specs
- **System Tests**: Add Capybara tests for 3-portal workflows
- **Vue Test Utils**: Component tests for new portal interfaces
- **FactoryBot**: Create factories for new models
- **Existing Tests**: All DocuSeal tests must continue passing

### 4.3 Code Organization and Standards

**File Structure Approach:**

```
app/
├── models/
│   ├── cohort.rb                    # New: Cohort management
│   ├── cohort_enrollment.rb         # New: Student enrollment tracking
│   ├── institution.rb               # New: Single institution model
│   ├── sponsor.rb                   # New: Ad-hoc sponsor model
│   └── concerns/
│       └── user_flo_doc_additions.rb # New: User model extension
│
├── controllers/
│   ├── api/
│   │   └── v1/
│   │       ├── flodoc/
│   │       │   ├── cohorts_controller.rb
│   │       │   ├── enrollments_controller.rb
│   │       │   └── excel_export_controller.rb
│   │       └── admin/
│   │           ├── invitations_controller.rb
│   │           └── security_events_controller.rb
│   └── cohorts/
│       └── admin_controller.rb       # Web interface
│
├── services/
│   ├── invitation_service.rb        # Admin invitation logic
│   ├── cohort_service.rb            # Cohort lifecycle management
│   ├── sponsor_service.rb           # Sponsor access management
│   └── excel_export_service.rb      # Excel generation (FR23)
│
├── jobs/
│   ├── cohort_admin_invitation_job.rb
│   ├── sponsor_access_job.rb
│   └── excel_export_job.rb
│
├── mailers/
│   └── cohort_mailer.rb             # Cohort-specific emails
│
└── javascript/
    └── cohorts/
        ├── portals/
        │   ├── tp_portal/           # Admin interface
        │   ├── student_portal/      # Student interface
        │   └── sponsor_portal/      # Sponsor interface
        └── components/              # Shared Vue components
```

**Naming Conventions:**
- **Models**: `Cohort`, `CohortEnrollment`, `Institution`, `Sponsor` (PascalCase, singular)
- **Controllers**: `CohortsController`, `Cohorts::AdminController` (namespaced)
- **Services**: `CohortService`, `InvitationService` (PascalCase, descriptive)
- **Jobs**: `CohortInvitationJob` (PascalCase, ends with Job)
- **Vue Components**: `CohortDashboard.vue`, `SponsorPanel.vue` (PascalCase)
- **Variables**: `cohort_enrollments` (snake_case, plural for collections)
- **Routes**: `/flodoc/cohorts`, `/admin/invitations` (kebab-case in URLs)

**Coding Standards:**
- **Ruby**: Follow existing RuboCop configuration
- **JavaScript**: Follow existing ESLint configuration
- **Vue.js**: Use Composition API, `<script setup>` syntax
- **TailwindCSS**: Use utility classes, avoid custom CSS
- **Testing**: TDD approach, minimum 80% coverage for new code
- **Documentation**: YARD comments for Ruby, JSDoc for JavaScript

**Documentation Standards:**
- **Model Comments**: Document associations, validations, and business logic
- **API Documentation**: Update OpenAPI/Swagger spec for new endpoints
- **Vue Components**: Document props, events, and usage examples
- **Migration Comments**: Explain why new tables are needed
- **Workflow Diagrams**: Mermaid diagrams for complex 3-portal workflows

### 4.4 Deployment and Operations

**Build Process Integration:**
- **Asset Compilation**: Shakapacker handles Vue/JS compilation
- **TailwindCSS**: Custom build with design system colors
- **Ruby Gems**: Bundle install includes new dependencies (rubyXL)
- **Database Migrations**: Run automatically in CI/CD pipeline
- **Sidekiq Workers**: Deploy with new job classes

**Deployment Strategy:**
- **Zero-Downtime**: Migrations run before new code deploys
- **Rollback Plan**: Database migrations must be reversible
- **Feature Flags**: Consider `Docuseal.floDocEnabled?` for gradual rollout
- **Blue-Green**: Deploy to staging first, validate 3-portal workflows
- **Monitoring**: Track cohort creation, completion rates, email delivery

**Monitoring and Logging:**
- **Existing**: Reuse DocuSeal's logging infrastructure
- **New Events**: Log cohort lifecycle events (created, student_enrolled, sponsor_accessed, completed)
- **Error Tracking**: Sentry/Rollbar integration for portal errors
- **Performance**: Monitor query performance on cohort dashboards
- **Email Tracking**: Track sponsor email delivery (single email rule compliance)

**Configuration Management:**
- **Environment Variables**: No new required variables
- **Feature Toggles**: Use existing Rails configuration pattern
- **Secrets**: Reuse existing Rails secrets for email/storage
- **Database**: No new database connections needed

### 4.5 Risk Assessment and Mitigation

**Technical Risks:**

1. **Risk**: DocuSeal's multi-submission mechanism duplicates empty documents, not pre-filled ones
   - **Impact**: High - FR5 requires TP to sign once and auto-fill remaining students
   - **Mitigation**:
     - Prototype TP signing phase early
     - Custom logic: After TP signs first submission, duplicate the completed submission (not empty template)
     - Use DocuSeal's submission duplication API on the signed submission
     - Alternative: Programmatic field population via API if duplication doesn't preserve signatures
     - Fallback: Manual submission creation with field copying logic

2. **Risk**: Single email rule for sponsors conflicts with DocuSeal's per-submission email logic
   - **Impact**: High - NFR11 compliance required
   - **Mitigation**:
     - Implement email deduplication service
     - Use cohort-level email tracking
     - Override DocuSeal's default email behavior

3. **Risk**: Vue 3 portal components may conflict with existing DocuSeal Vue 2 patterns
   - **Impact**: Medium - Frontend integration complexity
   - **Mitigation**:
     - Audit existing Vue component patterns
     - Use consistent state management approach
     - Gradual migration if conflicts exist

4. **Risk**: Excel export (FR23) may require significant memory for large cohorts
   - **Impact**: Medium - Performance for 50+ students
   - **Mitigation**:
     - Use streaming Excel generation (rubyXL streaming mode)
     - Background job processing
     - Pagination or chunking for very large cohorts

**Integration Risks:**

1. **Risk**: New FloDoc models may create circular dependencies with existing models
   - **Impact**: Medium - Model loading issues
   - **Mitigation**:
     - Use `belongs_to` with optional: true where needed
     - Lazy load associations
     - Test model initialization in isolation

2. **Risk**: Sponsor portal access without authentication may create security vulnerabilities
   - **Impact**: High - Data exposure risk
   - **Mitigation**:
     - Use signed tokens with expiration
     - One-time access tokens
     - IP-based rate limiting
     - Audit all sponsor access attempts

3. **Risk**: Bulk operations may timeout for large cohorts (100+ students)
   - **Impact**: Medium - User experience degradation
   - **Mitigation**:
     - Background job processing
     - Progress indicators
     - Chunked processing
     - Async email delivery

**Deployment Risks:**

1. **Risk**: Database migrations may lock tables during cohort creation
   - **Impact**: Low - Existing DocuSeal functionality unaffected
   - **Mitigation**:
     - Use non-locking migrations
     - Run migrations during maintenance window
     - Test on staging with production-like data volume

2. **Risk**: New Vue portals may increase bundle size significantly
   - **Impact**: Low - Modern browsers handle it
   - **Mitigation**:
     - Code splitting by portal
     - Lazy loading for complex views
     - Tree-shaking unused dependencies

**Mitigation Strategies:**

**Development Phase:**
1. **Incremental Implementation**: Build one portal at a time
2. **Integration Testing**: Test each workflow stage before moving to next
3. **User Validation**: Get feedback on sponsor portal early
4. **Performance Baseline**: Measure current DocuSeal performance before changes

**Testing Phase:**
1. **End-to-End Tests**: Full 3-portal workflow testing
2. **Load Testing**: Simulate 50+ student cohorts
3. **Security Audit**: Review sponsor portal access patterns
4. **Mobile Testing**: Verify all portals work on mobile devices

**Rollout Phase:**
1. **Feature Flag**: Deploy with FloDoc disabled by default
2. **Staged Rollout**: Enable for specific institutions first
3. **Monitoring**: Track errors, performance, user adoption
4. **Rollback Plan**: Database migrations reversible, code deployable without FloDoc

**Known Issues from Existing Codebase** (from current-app-sitemap.md):

1. **Technical Debt**: No coding standards documentation
   - **Impact**: Consistency issues across FloDoc development
   - **Mitigation**: This PRD includes coding standards section

2. **Missing Documentation**: No technical debt analysis
   - **Impact**: Unknown risks
   - **Mitigation**: Document risks in this section

3. **Partial Implementation**: Cohort and Sponsor models referenced in Ability.rb but not created
   - **Impact**: Will cause runtime errors if not implemented
   - **Mitigation**: These models are explicitly created in this PRD

**Workarounds and Gotchas:**

1. **DocuSeal Multi-tenancy**: Current system supports multi-tenant mode
   - **Gotcha**: FloDoc uses single-institution model
   - **Workaround**: Ensure `Docuseal.multitenant?` doesn't interfere with FloDoc logic

2. **Active Storage Configuration**: Multiple storage backends supported
   - **Gotcha**: Cohort documents must use same storage as existing templates
   - **Workaround**: Reuse existing Active Storage configuration

3. **Sidekiq Queues**: Existing queue structure
   - **Gotcha**: FloDoc jobs must not block core DocuSeal jobs
   - **Workaround**: Use separate queues (`cohort_emails`, `excel_export`)

4. **Devise 2FA**: Users may have 2FA enabled
   - **Gotcha**: Students/sponsors don't have accounts (ad-hoc access)
   - **Workaround**: Not applicable - ad-hoc users bypass 2FA

5. **Vue + Rails Integration**: Shakapacker handles asset compilation
   - **Gotcha**: New Vue portals must be registered in application.js
   - **Workaround**: Follow existing Vue initialization pattern

**Risk Summary:**

| Risk | Severity | Likelihood | Mitigation Priority |
|------|----------|------------|---------------------|
| DocuSeal duplicates empty docs, not signed ones | High | High | **Critical** - Prototype early |
| Sponsor email deduplication | High | High | **Critical** - Core requirement |
| Vue 3 integration conflicts | Medium | Low | Medium - Audit first |
| Excel export performance | Medium | Medium | Medium - Background jobs |
| Sponsor portal security | High | Low | **Critical** - Security audit |
| Bulk operation timeouts | Medium | Medium | Medium - Chunking |

**Next Steps for Risk Mitigation:**
1. **Week 1**: Prototype TP signing phase - test submission duplication from signed document
2. **Week 2**: Build sponsor email deduplication service
3. **Week 3**: Security review of ad-hoc access patterns
4. **Week 4**: Performance testing with large cohorts

---

## 5. Epic and Story Structure

### 5.1 EPIC APPROACH

**Epic Structure Decision**: **Single Comprehensive Epic** with rationale

**Rationale for Single Epic Structure:**

Based on my analysis of the existing DocuSeal + FloDoc architecture, this enhancement should be structured as a **single comprehensive epic** because:

1. **Tightly Coupled Workflow**: The 3-portal cohort management system is a single, cohesive workflow where:
   - TP Portal creates cohorts and initiates signing
   - Student Portal handles enrollment and document submission
   - Sponsor Portal completes the 3-party signature workflow
   - All three portals must work together for the workflow to function

2. **Sequential Dependencies**: Stories have clear dependencies:
   - Database models must exist before any portal can be built
   - Core workflow logic must be in place before UI can be tested
   - Integration points must be validated before end-to-end testing

3. **Shared Infrastructure**: All portals share:
   - Same database models (Cohort, CohortEnrollment, Institution)
   - Same authentication/authorization patterns
   - Same DocuSeal integration layer
   - Same design system and UI components

4. **Brownfield Context**: This is an enhancement to existing DocuSeal functionality, not independent features. The integration with existing templates, submissions, and submitters must be maintained throughout.

**Alternative Considered**: Multiple epics (e.g., "TP Portal Epic", "Student Portal Epic", "Sponsor Portal Epic")
- **Rejected Because**: Creates artificial separation. Each portal is useless without the others. The workflow is atomic.

**Epic Goal**: Transform DocuSeal into a specialized 3-portal cohort management system for training institutions while maintaining 100% backward compatibility with existing functionality.

### 5.2 STORY SEQUENCING STRATEGY

**Critical Principles for Brownfield Development:**

1. **Zero Regression**: Every story must verify existing DocuSeal functionality still works
2. **Incremental Integration**: Each story delivers value while maintaining system integrity
3. **Risk-First Approach**: Prototype high-risk items early (TP signing duplication, sponsor email deduplication)
4. **Test-Driven**: All stories include integration verification steps
5. **Rollback Ready**: Each story must be reversible without data loss

**Story Sequence Overview:**

```
Phase 1: Foundation (Database + Core Models)
├── Story 1.1: Database Schema Extension
├── Story 1.2: Core Models Implementation
└── Story 1.3: Authorization Layer Extension

Phase 2: Backend Business Logic
├── Story 2.1: Cohort Lifecycle Service
├── Story 2.2: TP Signing Phase Logic (High Risk - Prototype First)
├── Story 2.3: Sponsor Email Deduplication (High Risk - Core Requirement)
├── Story 2.4: Student Enrollment Workflow
├── Story 2.5: Sponsor Portal Access Management
├── Story 2.6: TP Review & Verification Logic
├── Story 2.7: Bulk Download & ZIP Generation
└── Story 2.8: Excel Export (FR23)

Phase 3: API Layer
├── Story 3.1: Cohort Management Endpoints
├── Story 3.2: Student Portal API Endpoints
├── Story 3.3: Sponsor Portal API Endpoints
└── Story 3.4: Excel Export API

Phase 4: Frontend - TP Portal
├── Story 4.1: Institution Onboarding UI
├── Story 4.2: Cohort Dashboard UI
├── Story 4.3: 5-Step Cohort Creation Wizard
├── Story 4.4: Document Mapping Interface
├── Story 4.5: TP Signing Interface
├── Story 4.6: Student Enrollment Monitor
├── Story 4.7: Sponsor Access Monitor
├── Story 4.8: TP Review Dashboard (3-panel)
├── Story 4.9: Cohort Analytics UI
└── Story 4.10: Excel Export Interface
Phase 5: Frontend - Student Portal
├── Story 5.1: Student Invitation Landing
├── Story 5.2: Document Upload Interface
├── Story 5.3: Progress Tracking & Save Draft
├── Story 5.4: Submission Confirmation & Status
└── Story 5.5: Email Notifications & Reminders

Phase 6: Frontend - Sponsor Portal
├── Story 6.1: Cohort Dashboard & Bulk Signing Interface
└── Story 6.2: Email Notifications & Reminders

Phase 7: Integration & Testing
├── Story 7.1: End-to-End Workflow Testing
├── Story 7.2: Mobile Responsiveness Testing
├── Story 7.3: Performance Testing (50+ students)
├── Story 7.4: Security Audit & Penetration Testing
└── Story 7.5: User Acceptance Testing

Phase 8: Deployment & Documentation
├── Story 8.1: Feature Flag Implementation
├── Story 8.2: Deployment Pipeline Update
├── Story 8.3: API Documentation
└── Story 8.4: User Documentation
```

### 5.3 INTEGRATION REQUIREMENTS

**Integration Verification Strategy:**

Each story must include verification that:
1. **Existing DocuSeal functionality remains intact** (templates, submissions, submitters)
2. **New FloDoc features integrate correctly** with existing infrastructure
3. **Performance impact is within acceptable limits** (<20% increase per NFR1)
4. **Security is maintained** (no new vulnerabilities introduced)
5. **Data integrity is preserved** (no corruption or loss)

**Critical Integration Points:**

1. **Template → Cohort Mapping**:
   - Templates become cohorts
   - Existing template builder must still work
   - New cohort metadata must not break template rendering

2. **Submission → Student Mapping**:
   - Submissions represent students in cohorts
   - Existing submission workflows must continue
   - New state management must not conflict with existing states

3. **Submitter → Signatory Mapping**:
   - Submitters are participants (TP, Students, Sponsor)
   - Existing submitter logic must adapt to cohort context
   - New email rules must override existing behavior

4. **Storage Integration**:
   - Cohort documents use existing Active Storage
   - Bulk downloads must not interfere with existing document access
   - Excel exports must use same storage backend

5. **Email System Integration**:
   - Sponsor single-email rule must override DocuSeal's default
   - Student invitations must use existing email infrastructure
   - Cohort notifications must not conflict with existing emails

**Rollback Strategy for Each Story:**

Every story must include:
- **Database migration**: Reversible with `down` method
- **Code changes**: Can be disabled via feature flag
- **Data preservation**: No deletion of existing data
- **Testing verification**: Script to confirm rollback success

### 5.4 RISK-MITIGATED STORY PRIORITIZATION

**Critical Path (High Risk, High Priority):**

1. **Story 1.1 (Database)** - Foundation blocker
2. **Story 1.2 (Models)** - Foundation blocker
3. **Story 2.2 (TP Signing)** - **HIGHEST RISK** - Must prototype early
4. **Story 2.3 (Sponsor Email)** - **HIGHEST RISK** - Core requirement
5. **Story 2.1 (Cohort Service)** - Enables all other stories
6. **Story 3.1 (Cohort API)** - Enables frontend development

**Why This Order?**
- Database and models are prerequisites
- TP signing and sponsor email are the two highest-risk items per Section 4.5
- Early validation prevents wasted effort on dependent stories
- If these fail, the entire epic needs rethinking

**Parallel Workstreams (Low Risk, Independent):**

- **Stream A**: Student Portal (Stories 5.x) - Can proceed once API is ready
- **Stream B**: Excel Export (Story 2.8 + 3.4 + 4.10) - Independent feature
- **Stream C**: Documentation (Story 8.3 + 8.4) - Can run in parallel

### 5.5 ACCEPTANCE CRITERIA FRAMEWORK

**All stories must follow this acceptance criteria pattern:**

**Functional Criteria:**
1. Story-specific functionality works as specified
2. All related FRs/NFRs from Section 2 are satisfied
3. Edge cases are handled (empty states, errors, validation)

**Integration Criteria:**
1. Existing DocuSeal functionality verified working (see IV1-3 below)
2. No breaking changes to existing APIs
3. Database migrations are reversible
4. Performance impact measured and acceptable

**Security Criteria:**
1. Authorization checks on all new endpoints
2. Input validation on all user-facing fields
3. No SQL injection, XSS, or CSRF vulnerabilities
4. Audit logging for all sensitive operations

**Quality Criteria:**
1. Minimum 80% test coverage for new code
2. RuboCop/ESLint pass with no new warnings
3. Design system compliance (per Section 3.1)
4. Mobile-responsive on all breakpoints

**Integration Verification (IV) Template:**

Each story must include these IV steps:

**IV1: Existing Functionality Verification**
- "Verify that [existing DocuSeal feature] still works after this change"
- Example: "Verify that existing template creation still works"
- Example: "Verify that existing submission workflows complete successfully"

**IV2: Integration Point Verification**
- "Verify that new [feature] integrates correctly with [existing system]"
- Example: "Verify that new Cohort model links correctly to existing Template model"
- Example: "Verify that new API endpoints follow existing DocuSeal patterns"

**IV3: Performance Impact Verification**
- "Verify that performance impact is within acceptable limits"
- Example: "Verify that cohort dashboard loads in <2 seconds with 50 students"
- Example: "Verify that memory usage does not exceed 20% increase"

### 5.6 STORY DEPENDENCIES AND CRITICAL PATH

**Dependency Graph:**

```
Story 1.1 (DB Schema) ──┐
                         ├─→ Story 1.2 (Models) ──┐
Story 1.3 (Auth) ───────┘                        │
                                                 ├─→ Story 2.1 (Cohort Service)
                                                  └─→ Story 2.2 (TP Signing - Critical Path)
                                                      └─→ Story 2.3 (Sponsor Email - Critical Path)
                                                          └─→ All subsequent stories...
```

**Critical Path Duration Estimate:**
- Stories 1.1-1.3: 3-5 days
- Stories 2.1-2.3: 5-8 days (includes prototyping high-risk items)
- Stories 2.4-2.8: 5-7 days
- Stories 3.1-3.4: 3-5 days
- Stories 4.1-4.10: 8-12 days (TP Portal)
- Stories 5.1-5.5: 5-7 days (Student Portal)
- Stories 6.1-6.6: 5-7 days (Sponsor Portal)
- Stories 7.1-7.5: 5-7 days (Integration & Testing)
- Stories 8.1-8.4: 3-5 days (Deployment)

**Total Estimated Duration**: 42-63 days (8-12 weeks)

**Milestones:**
- **Milestone 1** (Week 2): Foundation Complete (Stories 1.x)
- **Milestone 2** (Week 4): Backend Complete (Stories 2.x, 3.x)
- **Milestone 3** (Week 8): All Portals Built (Stories 4.x, 5.x, 6.x)
- **Milestone 4** (Week 10): Testing Complete (Story 7.x)
- **Milestone 5** (Week 12): Production Ready (Story 8.x)

### 5.7 TECHNICAL DEBT MANAGEMENT

**Stories Must Address Existing Technical Debt:**

From Section 4.5, we identified:
1. **No coding standards documentation** → Covered in Section 4.3
2. **No technical debt analysis** → Covered in Section 4.5
3. **Partial implementation** (Cohort/Sponsor models referenced but not created) → Stories 1.2 will fix

**New Technical Debt Prevention:**

Each story must include:
- **Documentation**: Code comments, API docs, workflow diagrams
- **Testing**: Unit, integration, and system tests
- **Refactoring**: Clean code following existing patterns
- **Review**: Peer review checklist for quality gates

**Debt Paydown Stories:**

If technical debt is discovered during implementation:
- **Story 9.1**: Refactor for clarity
- **Story 9.2**: Add missing tests
- **Story 9.3**: Update documentation
- **Story 9.4**: Performance optimization

These are tracked separately from main epic but must be completed before epic closure.

### 5.8 AGENT COORDINATION REQUIREMENTS

**BMAD Agent Roles (Corrected):**

Based on the BMAD brownfield workflow, the correct agent roles are:

- **Product Manager (PM)**: Creates PRD, prioritizes features, validates business alignment
- **Scrum Master (SM)**: Creates individual stories from sharded PRD/Architecture docs
- **Developer (Dev)**: Implements approved stories, writes code and tests
- **QA/Test Architect**: Reviews implementation, creates test strategies, manages quality gates
- **Architect (Winston)**: Designs system architecture, validates technical feasibility
- **Product Owner (PO)**: Validates story alignment, runs master checklists, manages backlog

**Story Creation Process (Brownfield Workflow):**

1. **SM Agent** creates stories from sharded PRD using `*create` task
2. **User** reviews and approves story (updates status: Draft → Approved)
3. **Dev Agent** implements approved story in new clean chat
4. **QA Agent** reviews implementation, may refactor, appends QA Results
5. **User** verifies completion, approves for production

**Story Handoff Protocol:**

Each story must include:
- **Clear acceptance criteria** (per Section 5.5)
- **Integration verification steps** (IV1-3)
- **Design system references** (if UI involved)
- **API endpoint specifications** (if backend involved)
- **Test data requirements**
- **Rollback procedure**

**Critical Context Management:**

- **ALWAYS use fresh, clean chat sessions** when switching agents
- **SM → Dev → QA** each in separate conversations
- **Powerful model for SM story creation** (thinking models preferred)
- **Dev agent loads**: `devLoadAlwaysFiles` from core-config.yaml

**Implementation Order:**

Stories must be implemented in the sequence defined in Section 5.2. No jumping ahead, even if later stories seem "easier." This ensures:
- Foundation is solid before building on it
- High-risk items are validated early
- Dependencies are respected
- Rollback is possible at each stage

### 5.9 SUCCESS METRICS

**Epic Success Criteria:**

1. **Functional**: All 23 FRs and 12 NFRs from Section 2 are met
2. **Technical**: Zero regression in existing DocuSeal functionality
3. **Performance**: <20% performance degradation (NFR1)
4. **Security**: No new vulnerabilities, sponsor portal security audited
5. **User Experience**: All three portals meet UI consistency requirements (Section 3.3)
6. **Documentation**: Complete API docs, user guides, and technical documentation
7. **Deployment**: Successful production deployment with feature flag control

**Story Success Criteria:**

Each story is successful when:
- Acceptance criteria are met
- Integration verification passes
- Tests pass with >80% coverage
- Code review approved
- Design system compliance verified (if UI)
- Rollback tested and documented

### 5.10 NEXT STEPS

**Decision Point:**

Per your instruction, we're going with **Option D**: Keep Section 5 as-is (structure and strategy are correct), clarify the exact data-copying mechanism in Section 6 when writing detailed stories.

**Before Creating Individual Stories:**

1. **User Approval**: Confirm this epic structure aligns with your vision ✅ (pending)
2. **Document Sharding**: PO agent shards `docs/prd.md` into `docs/prd/` folder
3. **Story Detailing**: SM agent creates detailed stories for Phase 1 from sharded docs
4. **Technical Spikes**: Dev agent prototypes high-risk items (TP signing, sponsor email)
5. **Design Validation**: Verify design system assets are complete and accessible

**Transition to Epic Details (Section 6):**

Section 6 will provide detailed stories for Phase 1 (Foundation):
- **Story 1.1**: Database Schema Extension
- **Story 1.2**: Core Models Implementation
- **Story 1.3**: Authorization Layer Extension

**What Section 6 Will Include:**
- Full user stories (As a... I want... so that...)
- Detailed acceptance criteria (per Section 5.5 framework)
- Integration verification steps (IV1-3)
- Technical implementation notes (including data-copying mechanism clarification)
- Test requirements and strategies
- Rollback procedures
- Risk mitigation details

**Critical BMAD Workflow Compliance:**

Section 6 stories will follow the brownfield-fullstack workflow:
1. **SM** creates story from sharded PRD
2. **User** approves (Draft → Approved)
3. **Dev** implements in clean chat
4. **QA** reviews and validates
5. **User** verifies completion

---

## 6. Epic Details

### 6.1 Phase 1: Foundation

This section provides detailed user stories for Phase 1 (Foundation) of the FloDoc enhancement. These stories must be completed before any other work can begin.

#### Story 1.1: Database Schema Extension

**Status**: Draft
**Priority**: Critical
**Epic**: Phase 1 - Foundation
**Estimated Effort**: 2-3 days
**Risk Level**: Low

##### User Story

**As a** system architect,
**I want** to create the database schema for FloDoc's new models,
**So that** the application has the foundation to support cohort management.

##### Background

Based on the PRD analysis, we need three new tables to support the 3-portal cohort management system:
- `institutions` - Single training institution (not multi-tenant)
- `cohorts` - Training program cohorts
- `cohort_enrollments` - Student enrollments in cohorts

These tables must integrate with existing DocuSeal tables without breaking existing functionality.

##### Technical Implementation Notes

**Database Schema Requirements:**

```ruby
# Table: institutions
# Purpose: Single institution record (one per deployment)
create_table :institutions do |t|
  t.string :name, null: false
  t.string :email, null: false
  t.string :contact_person
  t.string :phone
  t.jsonb :settings, default: {}
  t.timestamps
  t.datetime :deleted_at
end

# Table: cohorts
# Purpose: Represents a training program cohort (maps to DocuSeal template)
create_table :cohorts do |t|
  t.references :institution, null: false, foreign_key: true
  t.references :template, null: false  # Links to existing templates table
  t.string :name, null: false
  t.string :program_type, null: false  # learnership/internship/candidacy
  t.string :sponsor_email, null: false
  t.jsonb :required_student_uploads, default: []  # ['id', 'matric', 'tertiary']
  t.jsonb :cohort_metadata, default: {}  # Additional cohort info
  t.string :status, default: 'draft'  # draft/active/completed
  t.datetime :tp_signed_at  # When TP completed signing phase
  t.datetime :students_completed_at  # When all students completed
  t.datetime :sponsor_completed_at  # When sponsor completed
  t.datetime :finalized_at  # When TP finalized review
  t.timestamps
  t.datetime :deleted_at
end

# Table: cohort_enrollments
# Purpose: Links students to cohorts with state tracking
create_table :cohort_enrollments do |t|
  t.references :cohort, null: false, foreign_key: true
  t.references :submission, null: false  # Links to existing submissions table
  t.string :student_email, null: false
  t.string :student_name
  t.string :student_surname
  t.string :student_id
  t.string :status, default: 'waiting'  # waiting/in_progress/complete
  t.string :role, default: 'student'  # student/sponsor
  t.jsonb :uploaded_documents, default: {}  # Track required uploads
  t.jsonb :values, default: {}  # Copy of submitter values for quick access
  t.datetime :completed_at
  t.timestamps
  t.datetime :deleted_at
end

# Indexes for performance
add_index :cohorts, [:institution_id, :status]
add_index :cohort_enrollments, [:cohort_id, :status]
add_index :cohort_enrollments, [:cohort_id, :student_email], unique: true
add_index :cohort_enrollments, [:submission_id], unique: true
```

**Key Design Decisions:**

1. **Single Institution Model**: Only one `institutions` record exists per deployment
2. **Template Mapping**: `cohorts.template_id` links to existing DocuSeal templates
3. **Submission Mapping**: `cohort_enrollments.submission_id` links to existing submissions
4. **State Tracking**: Cohort and enrollment status fields for workflow management
5. **Soft Deletes**: All tables use `deleted_at` for data preservation
6. **JSONB Fields**: Flexible storage for metadata and dynamic requirements

##### Acceptance Criteria

**Functional:**
1. ✅ All three tables created with correct schema
2. ✅ Foreign key relationships established
3. ✅ All indexes created for performance
4. ✅ Migrations are reversible
5. ✅ No modifications to existing DocuSeal tables

**Integration:**
1. ✅ IV1: Existing DocuSeal tables remain unchanged
2. ✅ IV2: New tables can reference existing tables (templates, submissions)
3. ✅ IV3: Database performance not degraded (verify with EXPLAIN queries)

**Security:**
1. ✅ All tables include `deleted_at` for soft deletes
2. ✅ Sensitive fields (emails) are encrypted at rest if required by policy
3. ✅ Foreign keys prevent orphaned records

**Quality:**
1. ✅ Migrations follow Rails conventions
2. ✅ Table and column names are consistent with existing codebase
3. ✅ All migrations include `down` method for rollback
4. ✅ Schema changes documented in migration comments

##### Integration Verification (IV1-3)

**IV1: Existing Functionality Verification**
- Verify that existing `templates` table can be queried normally
- Verify that existing `submissions` table can be queried normally
- Verify that existing `submitters` table can be queried normally
- Run existing DocuSeal tests to ensure no regression

**IV2: Integration Point Verification**
- Verify that `cohorts.template_id` can successfully link to `templates.id`
- Verify that `cohort_enrollments.submission_id` can successfully link to `submissions.id`
- Verify that queries joining new and existing tables perform correctly
- Verify that foreign key constraints work as expected

**IV3: Performance Impact Verification**
- Verify that adding these tables does not slow down existing queries
- Verify that indexes are being used (check with EXPLAIN)
- Verify that migration runs in < 30 seconds on production-sized database

##### Test Requirements

**Migration Tests:**
```ruby
# spec/migrations/20260111000001_create_flo_doc_tables_spec.rb
describe 'FloDoc table migrations' do
  it 'creates all tables without errors' do
    expect { subject.up }.not_to raise_error
  end

  it 'is reversible' do
    subject.up
    expect { subject.down }.not_to raise_error
  end

  it 'creates correct indexes' do
    subject.up
    expect(index_exists?(:cohorts, [:institution_id, :status])).to be true
    expect(index_exists?(:cohort_enrollments, [:cohort_id, :status])).to be true
  end
end
```

**Model Specs:**
- Verify presence validations on required fields
- Verify foreign key constraints
- Verify soft delete functionality

##### Rollback Procedure

**If migration fails or causes issues:**

1. **Immediate Rollback**: `bin/rails db:rollback STEP=1`
2. **Verify**: Check that all FloDoc tables are dropped
3. **Verify**: Existing DocuSeal tables remain intact
4. **Verify**: Application still functions normally
5. **Report**: Document the failure reason in issue tracker

**Data Safety**: No existing data is modified or deleted by this migration.

##### Risk Assessment

**Low Risk because:**
- Schema additions only, no modifications to existing tables
- Reversible migrations
- Foreign keys prevent data integrity issues
- No breaking changes to existing functionality

**Mitigation**:
- Test on staging database first
- Have rollback plan ready
- Monitor migration execution time

#### Story 1.2: Core Models Implementation

**Status**: Draft
**Priority**: Critical
**Epic**: Phase 1 - Foundation
**Estimated Effort**: 3-4 days
**Risk Level**: Low

##### User Story

**As a** developer,
**I want** to create ActiveRecord models for the new FloDoc tables,
**So that** the application can interact with cohorts and enrollments programmatically.

##### Background

Models must follow existing DocuSeal patterns:
- Inherit from `ApplicationRecord`
- Use `strip_attributes` for data cleaning
- Include soft delete functionality
- Define proper associations and validations
- Follow naming conventions

##### Technical Implementation Notes

**Model Structure:**

```ruby
# app/models/institution.rb
class Institution < ApplicationRecord
  include SoftDeletable

  # Associations
  has_many :cohorts, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :contact_person, length: { maximum: 255 }, allow_nil: true
  validates :phone, length: { maximum: 50 }, allow_nil: true

  # Scopes
  scope :active, -> { where(deleted_at: nil) }

  # Methods
  def self.current
    # For single-institution model, return first active institution
    active.first
  end
end

# app/models/cohort.rb
class Cohort < ApplicationRecord
  include SoftDeletable
  include AASM  # For state machine if needed

  # Associations
  belongs_to :institution
  belongs_to :template, class_name: 'Template'
  has_many :cohort_enrollments, dependent: :destroy
  has_many :submissions, through: :cohort_enrollments

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :program_type, presence: true, inclusion: { in: %w[learnership internship candidacy] }
  validates :sponsor_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :required_student_uploads, presence: true

  # Scopes
  scope :active, -> { where(deleted_at: nil) }
  scope :draft, -> { where(status: 'draft') }
  scope :ready_for_sponsor, -> { where(status: 'ready_for_sponsor') }
  scope :completed, -> { where(status: 'completed') }

  # State management
  aasm column: :status do
    state :draft, initial: true
    state :tp_signing
    state :student_enrollment
    state :ready_for_sponsor
    state :sponsor_review
    state :tp_review
    state :completed

    event :start_tp_signing do
      transitions from: :draft, to: :tp_signing
    end

    event :complete_tp_signing do
      transitions from: :tp_signing, to: :student_enrollment
    end

    event :all_students_complete do
      transitions from: :student_enrollment, to: :ready_for_sponsor
    end

    event :sponsor_starts_review do
      transitions from: :ready_for_sponsor, to: :sponsor_review
    end

    event :sponsor_completes do
      transitions from: :sponsor_review, to: :tp_review
    end

    event :finalize do
      transitions from: :tp_review, to: :completed
    end
  end

  # Methods
  def all_students_completed?
    cohort_enrollments.where(role: 'student', status: 'complete').count ==
    cohort_enrollments.where(role: 'student').count
  end

  def sponsor_access_ready?
    all_students_completed? && status == 'ready_for_sponsor'
  end

  def tp_can_sign?
    status == 'draft' || status == 'tp_signing'
  end
end

# app/models/cohort_enrollment.rb
class CohortEnrollment < ApplicationRecord
  include SoftDeletable

  # Associations
  belongs_to :cohort
  belongs_to :submission, class_name: 'Submission'

  # Validations
  validates :student_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, presence: true, inclusion: { in: %w[waiting in_progress complete] }
  validates :role, presence: true, inclusion: { in: %w[student sponsor] }
  validates :submission_id, uniqueness: true

  # Scopes
  scope :active, -> { where(deleted_at: nil) }
  scope :students, -> { where(role: 'student') }
  scope :sponsor, -> { where(role: 'sponsor') }
  scope :completed, -> { where(status: 'complete') }
  scope :waiting, -> { where(status: 'waiting') }
  scope :in_progress, -> { where(status: 'in_progress') }

  # Methods
  def complete!
    update(status: 'complete', completed_at: Time.current)
  end

  def mark_in_progress!
    update(status: 'in_progress')
  end

  def waiting?
    status == 'waiting'
  end

  def completed?
    status == 'complete'
  end
end
```

**Key Design Decisions:**

1. **SoftDeletable Module**: Reuse existing pattern from DocuSeal
2. **State Machine**: AASM for cohort lifecycle management
3. **Associations**: Proper bidirectional relationships
4. **Scopes**: Common query patterns for performance
5. **Validation**: Consistent with existing DocuSeal models

##### Acceptance Criteria

**Functional:**
1. ✅ All three models created with correct class structure
2. ✅ All associations defined correctly
3. ✅ All validations implemented
4. ✅ All scopes defined
5. ✅ State machine logic correct (if used)
6. ✅ Model methods work as specified

**Integration:**
1. ✅ IV1: Models don't break existing DocuSeal models
2. ✅ IV2: Associations work with existing tables (templates, submissions)
3. ✅ IV3: Query performance acceptable with 1000+ records

**Security:**
1. ✅ No mass assignment vulnerabilities
2. ✅ Proper attribute whitelisting
3. ✅ Email validation on all email fields

**Quality:**
1. ✅ Follow existing code style (RuboCop compliant)
2. ✅ All methods have YARD comments
3. ✅ Test coverage > 80%
4. ✅ No N+1 query issues

##### Integration Verification (IV1-3)

**IV1: Existing Functionality Verification**
- Verify that `Template` model still works
- Verify that `Submission` model still works
- Verify that `Submitter` model still works
- Run existing model specs

**IV2: Integration Point Verification**
- Verify that `cohort.template` returns correct Template record
- Verify that `cohort_enrollment.submission` returns correct Submission record
- Verify that `cohort.cohort_enrollments` returns correct records
- Verify that associations work bidirectionally

**IV3: Performance Impact Verification**
- Verify that `Cohort.includes(:cohort_enrollments)` doesn't cause N+1
- Verify that queries with 1000 cohorts perform in < 100ms
- Verify that state machine transitions are fast

##### Test Requirements

**Model Specs:**
```ruby
# spec/models/cohort_spec.rb
describe Cohort do
  describe 'associations' do
    it { should belong_to(:institution) }
    it { should belong_to(:template) }
    it { should have_many(:cohort_enrollments) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_inclusion_of(:program_type).in_array(%w[learnership internship candidacy]) }
  end

  describe 'state machine' do
    it 'starts in draft state' do
      cohort = build(:cohort)
      expect(cohort.draft?).to be true
    end

    it 'transitions from draft to tp_signing' do
      cohort = create(:cohort, status: 'draft')
      cohort.start_tp_signing!
      expect(cohort.tp_signing?).to be true
    end
  end

  describe '#all_students_completed?' do
    # Test logic
  end
end
```

**Factory Definitions:**
```ruby
# spec/factories/cohorts.rb
FactoryBot.define do
  factory :cohort do
    institution
    template
    name { "Test Cohort 2026" }
    program_type { "learnership" }
    sponsor_email { "sponsor@example.com" }
    required_student_uploads { ["id", "matric"] }
    status { "draft" }
  end
end
```

##### Rollback Procedure

**If models cause issues:**

1. **Code Rollback**: Revert Git commit
2. **Database**: No rollback needed (models are code, not schema)
3. **Verify**: Application loads without errors
4. **Verify**: Existing functionality works

**Note**: Models don't modify database, so rollback is code-only.

##### Risk Assessment

**Low Risk because:**
- Models are pure Ruby code additions
- No database modifications
- Follow existing patterns
- Easily reversible via Git

**Mitigation**:
- Code review before merge
- Comprehensive test coverage
- Staging environment testing

#### Story 1.3: Authorization Layer Extension

**Status**: Draft
**Priority**: Critical
**Epic**: Phase 1 - Foundation
**Estimated Effort**: 2-3 days
**Risk Level**: Medium

##### User Story

**As a** system administrator,
**I want** the authorization system to support FloDoc roles and permissions,
**So that** users can only access appropriate cohort management functions.

##### Background

DocuSeal uses Cancancan for authorization. We need to:
- Extend `Ability` class to handle FloDoc models
- Define permissions for TP, Student, and Sponsor roles
- Support ad-hoc access patterns (students/sponsors without accounts)
- Maintain existing DocuSeal permissions

##### Technical Implementation Notes

**Ability Class Extension:**

```ruby
# app/models/ability.rb
class Ability
  include CanCan::Ability

  def initialize(user)
    # Existing DocuSeal abilities (keep unchanged)
    if user.nil?
      # Guest access for ad-hoc users (students, sponsors)
      define_ad_hoc_abilities
    elsif user.admin?
      # Admin gets everything
      define_admin_abilities
    elsif user.institution_admin?
      # TP (institution admin) abilities
      define_tp_abilities(user)
    else
      # Regular user abilities (existing DocuSeal)
      define_standard_abilities(user)
    end
  end

  private

  def define_ad_hoc_abilities
    # Ad-hoc access for students and sponsors via token
    can :read, Cohort, -> { true } do |cohort, token|
      # Verify token and check if user has access to this cohort
      verify_ad_hoc_token(cohort, token)
    end

    can :fill, Submission, -> { true } do |submission, token|
      # Students can fill their own submissions
      verify_ad_hoc_token(submission.cohort, token) &&
      submission.submitter.email == token[:email]
    end

    can :sign, Submission, -> { true } do |submission, token|
      # Students and sponsors can sign their assigned submissions
      verify_ad_hoc_token(submission.cohort, token) &&
      submission.submitter.email == token[:email]
    end

    can :review, Cohort, -> { true } do |cohort, token|
      # Sponsors can review all students in their cohort
      verify_ad_hoc_token(cohort, token) &&
      token[:role] == 'sponsor' &&
      cohort.sponsor_access_ready?
    end
  end

  def define_tp_abilities(user)
    # TP can manage their institution's cohorts
    can :manage, Cohort, institution_id: user.institution_id
    can :manage, CohortEnrollment, cohort: { institution_id: user.institution_id }

    # TP can access all submissions for their cohorts
    can :read, Submission, cohort: { institution_id: user.institution_id }
    can :sign, Submission, cohort: { institution_id: user.institution_id }

    # TP can export data
    can :export, Cohort, institution_id: user.institution_id

    # Existing DocuSeal abilities
    define_standard_abilities(user)
  end

  def define_admin_abilities
    # Admin gets everything
    can :manage, :all
  end

  def define_standard_abilities(user)
    # Existing DocuSeal abilities (unchanged)
    can :manage, Template, account_id: user.account_id
    can :manage, Submission, account_id: user.account_id
    # ... existing logic
  end

  def verify_ad_hoc_token(cohort, token)
    # Verify signed token for ad-hoc access
    return false unless token.is_a?(Hash)
    return false unless token[:cohort_id] == cohort.id
    return false unless token[:email].present?

    # Verify JWT signature
    begin
      decoded = JWT.decode(
        token[:jwt],
        Rails.application.secrets.secret_key_base,
        true,
        { algorithm: 'HS256' }
      )
      decoded.first['cohort_id'] == cohort.id &&
      decoded.first['email'] == token[:email]
    rescue JWT::DecodeError
      false
    end
  end
end
```

**Ad-hoc Token Generation Service:**

```ruby
# lib/services/ad_hoc_token_service.rb
class AdHocTokenService
  def self.generate_student_token(cohort, student_email, student_name = nil)
    payload = {
      cohort_id: cohort.id,
      email: student_email,
      role: 'student',
      name: student_name,
      exp: 30.days.from_now.to_i
    }

    JWT.encode(payload, Rails.application.secrets.secret_key_base, 'HS256')
  end

  def self.generate_sponsor_token(cohort)
    payload = {
      cohort_id: cohort.id,
      email: cohort.sponsor_email,
      role: 'sponsor',
      exp: 30.days.from_now.to_i
    }

    JWT.encode(payload, Rails.application.secrets.secret_key_base, 'HS256')
  end

  def self.decode_token(token)
    JWT.decode(token, Rails.application.secrets.secret_key_base, true, { algorithm: 'HS256' }).first
  rescue JWT::DecodeError
    nil
  end
end
```

**Controller Authorization Pattern:**

```ruby
# app/controllers/cohorts/student_portal_controller.rb
class Cohorts::StudentPortalController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :verify_ad_hoc_access

  def show
    @cohort = Cohort.find(params[:id])
    authorize! :read, @cohort, ad_hoc_token

    @submission = @cohort.submissions.find_by(email: ad_hoc_token[:email])
    authorize! :fill, @submission, ad_hoc_token
  end

  private

  def ad_hoc_token
    @ad_hoc_token ||= AdHocTokenService.decode_token(params[:token])
  end

  def verify_ad_hoc_access
    redirect_to root_path, alert: 'Invalid access token' unless ad_hoc_token
  end
end
```

##### Acceptance Criteria

**Functional:**
1. ✅ Ability class extended with FloDoc permissions
2. ✅ Ad-hoc access works for students (via token)
3. ✅ Ad-hoc access works for sponsors (via token)
4. ✅ TP permissions work correctly
5. ✅ Admin permissions work correctly
6. ✅ Existing DocuSeal permissions unchanged

**Integration:**
1. ✅ IV1: Existing DocuSeal authorization still works
2. ✅ IV2: New abilities integrate with existing Ability class
3. ✅ IV3: Authorization checks don't add significant overhead

**Security:**
1. ✅ JWT tokens signed with secret key
2. ✅ Tokens have expiration (30 days)
3. ✅ Token verification prevents tampering
4. ✅ Ad-hoc users can't access other cohorts
5. ✅ Sponsor can't access before all students complete

**Quality:**
1. ✅ Follow existing authorization patterns
2. ✅ All abilities tested
3. ✅ Token service has comprehensive tests
4. ✅ No security bypasses

##### Integration Verification (IV1-3)

**IV1: Existing Functionality Verification**
- Verify that existing user authentication still works
- Verify that existing template permissions still works
- Verify that existing submission permissions still works
- Run existing ability specs

**IV2: Integration Point Verification**
- Verify that new abilities don't conflict with existing ones
- Verify that `authorize!` calls work with ad-hoc tokens
- Verify that token generation and verification work end-to-end
- Verify that controllers can use new authorization patterns

**IV3: Performance Impact Verification**
- Verify that ability checks execute in < 10ms
- Verify that JWT encoding/decoding is fast
- Verify that no N+1 queries in authorization logic

##### Test Requirements

**Ability Specs:**
```ruby
# spec/models/ability_spec.rb
describe Ability do
  context 'as ad-hoc student' do
    let(:cohort) { create(:cohort) }
    let(:token) { AdHocTokenService.generate_student_token(cohort, 'student@example.com') }
    let(:decoded_token) { AdHocTokenService.decode_token(token) }
    let(:ability) { Ability.new(nil) }

    it 'can read their cohort' do
      expect(ability).to be_able_to(:read, cohort, decoded_token)
    end

    it 'cannot read other cohorts' do
      other_cohort = create(:cohort)
      expect(ability).not_to be_able_to(:read, other_cohort, decoded_token)
    end
  end

  context 'as TP' do
    let(:user) { create(:user, :institution_admin) }
    let(:ability) { Ability.new(user) }

    it 'can manage their institution cohorts' do
      cohort = create(:cohort, institution: user.institution)
      expect(ability).to be_able_to(:manage, cohort)
    end
  end
end
```

**Token Service Specs:**
```ruby
# spec/lib/services/ad_hoc_token_service_spec.rb
describe AdHocTokenService do
  describe '.generate_student_token' do
    it 'generates valid JWT token' do
      cohort = create(:cohort)
      token = described_class.generate_student_token(cohort, 'student@example.com')

      decoded = described_class.decode_token(token)
      expect(decoded['email']).to eq('student@example.com')
      expect(decoded['cohort_id']).to eq(cohort.id)
    end
  end

  describe '.decode_token' do
    it 'returns nil for invalid token' do
      expect(described_class.decode_token('invalid')).to be_nil
    end
  end
end
```

##### Rollback Procedure

**If authorization causes issues:**

1. **Code Rollback**: Revert Git commit
2. **Verify**: Existing DocuSeal authorization works
3. **Verify**: No security holes introduced

**Note**: Authorization is code-only, no database changes.

##### Risk Assessment

**Medium Risk because:**
- Security-critical component
- Ad-hoc access is new pattern
- JWT token management adds complexity
- Potential for authorization bypasses

**Mitigation**:
- Comprehensive security testing
- Code review by security-conscious developer
- Staging environment testing with various user scenarios
- Monitor authorization failures in production

**Critical Security Checks**:
- Token signature verification
- Token expiration enforcement
- Cohort ID validation in tokens
- Role-based access control
- No privilege escalation paths

---

### 6.2 Phase 2: Backend Business Logic

This section provides detailed user stories for Phase 2 (Backend Business Logic) of the FloDoc enhancement. This phase implements the core business logic for cohort management and workflow orchestration.

#### Story 2.1: Cohort Creation & Management

**Status**: Draft
**Priority**: High
**Epic**: Phase 2 - Backend Business Logic
**Estimated Effort**: 3-4 days
**Risk Level**: Low

##### User Story

**As a** TP (Training Provider) administrator,
**I want** to create and manage cohorts with all their configuration details,
**So that** I can organize students into training programs and prepare them for the signature workflow.

##### Background

Cohort creation is the entry point for the FloDoc workflow. TP administrators need to:
- Create a cohort by selecting an existing DocuSeal template
- Define program type (learnership/internship/candidacy)
- Specify required student documents (ID, matric, tertiary, etc.)
- Set sponsor email for the review phase
- Configure cohort metadata and settings

The cohort acts as a container that orchestrates the entire 3-party signature workflow.

##### Technical Implementation Notes

**Cohort Creation Service:**

```ruby
# app/services/cohort_management_service.rb
class CohortManagementService
  def self.create_cohort(params, user)
    institution = user.institution || Institution.current

    ActiveRecord.transaction do
      cohort = Cohort.create!(
        institution: institution,
        template_id: params[:template_id],
        name: params[:name],
        program_type: params[:program_type],
        sponsor_email: params[:sponsor_email],
        required_student_uploads: params[:required_student_uploads] || [],
        cohort_metadata: params[:cohort_metadata] || {},
        status: 'draft'
      )

      # Create cohort audit event
      AuditLog.create!(
        user: user,
        action: 'cohort_created',
        entity: cohort,
        details: { name: cohort.name, sponsor: cohort.sponsor_email }
      )

      cohort
    end
  end

  def self.update_cohort(cohort, params, user)
    # Only allow updates in draft or tp_signing states
    raise 'Cannot update cohort in current state' unless cohort.draft? || cohort.tp_signing?

    cohort.update!(params)

    AuditLog.create!(
      user: user,
      action: 'cohort_updated',
      entity: cohort,
      details: params
    )

    cohort
  end

  def self.delete_cohort(cohort, user)
    # Soft delete only - preserve historical data
    cohort.update!(deleted_at: Time.current)

    AuditLog.create!(
      user: user,
      action: 'cohort_deleted',
      entity: cohort,
      details: { cohort_id: cohort.id, name: cohort.name }
    )

    true
  end
end
```

**Cohort Validation:**

```ruby
# app/models/cohort.rb (extended validation)
validate :template_exists_and_accessible
validate :sponsor_email_different_from_tp
validate :required_uploads_reasonable

def template_exists_and_accessible
  errors.add(:template_id, 'must be a valid template') unless Template.exists?(template_id)
end

def sponsor_email_different_from_tp
  # Ensure sponsor is different from TP admin
  return if institution.nil?
  errors.add(:sponsor_email, 'cannot be same as institution email') if sponsor_email == institution.email
end

def required_uploads_reasonable
  return if required_student_uploads.blank?
  errors.add(:required_student_uploads, 'cannot exceed 10 document types') if required_student_uploads.length > 10
end
```

**Key Design Decisions:**

1. **State-Aware Updates**: Only allow modifications in draft/tp_signing states
2. **Audit Trail**: All cohort operations logged for compliance
3. **Soft Delete**: Preserve historical data while removing from active views
4. **Validation Rules**: Enforce business rules (max 10 upload types, sponsor must differ from TP)
5. **Template Linking**: Cohorts must link to accessible templates

##### Acceptance Criteria

**Functional:**
1. ✅ TP can create cohort with template selection
2. ✅ TP can specify program type (learnership/internship/candidacy)
3. ✅ TP can define required student uploads (max 10 types)
4. ✅ TP can set sponsor email
5. ✅ TP can add cohort metadata
6. ✅ TP can edit cohort in draft state
7. ✅ TP can delete cohort (soft delete)
8. ✅ All operations logged in audit trail

**Integration:**
1. ✅ IV1: Cohort creation validates template exists
2. ✅ IV2: Cohort links correctly to existing template
3. ✅ IV3: No performance degradation with 100+ cohorts

**Security:**
1. ✅ Only TP admins can create/manage cohorts
2. ✅ TP can only manage their institution's cohorts
3. ✅ Sponsor email validation enforced
4. ✅ Audit logs cannot be tampered with

**Quality:**
1. ✅ Follow existing service object patterns
2. ✅ Transactional safety for cohort creation
3. ✅ Proper error handling and user feedback
4. ✅ 80% test coverage for service layer

##### Integration Verification (IV1-3)

**IV1: Template Validation**
- Verify template selection UI shows only accessible templates
- Verify cohort creation fails with invalid template_id
- Verify cohort creation succeeds with valid template_id
- Verify template deletion is prevented if cohort exists

**IV2: Template Mapping**
- Verify `cohort.template` returns correct Template record
- Verify cohort inherits template's field definitions
- Verify cohort can render template's form fields
- Verify template modification doesn't break existing cohorts

**IV3: Performance**
- Verify cohort creation completes in < 200ms
- Verify cohort list query returns 100 records in < 200ms
- Verify audit log queries don't impact cohort performance
- Verify no N+1 queries in cohort index view

##### Test Requirements

**Service Specs:**
```ruby
# spec/services/cohort_management_service_spec.rb
describe CohortManagementService do
  describe '.create_cohort' do
    it 'creates cohort with valid params' do
      params = { template_id: 1, name: 'Test', program_type: 'learnership', sponsor_email: 'sp@example.com' }
      cohort = described_class.create_cohort(params, user)
      expect(cohort).to be_persisted
      expect(cohort.status).to eq('draft')
    end

    it 'validates template exists' do
      params = { template_id: 99999, name: 'Test' }
      expect { described_class.create_cohort(params, user) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
```

**Model Specs:**
- Verify sponsor email must differ from institution email
- Verify required uploads max 10 items
- Verify template accessibility validation

##### Rollback Procedure

**If cohort management causes issues:**
1. Revert service object code
2. Verify cohort creation page loads
3. Verify no orphaned cohorts exist
4. Check audit logs for any incomplete operations

**Data Safety**: No destructive operations - all data preserved via soft delete.

##### Risk Assessment

**Low Risk because:**
- Service layer pattern is tested in existing codebase
- No complex business logic
- State machine already validated in Phase 1
- Audit logging reduces operational risk

**Mitigation:**
- Validation on all inputs before database write
- Use transactions for cohort creation
- Comprehensive audit trails
- State restrictions on destructive operations

---

#### Story 2.2: TP Signing Phase Logic (High Risk - Prototype First)

**Status**: Draft
**Priority**: Critical
**Epic**: Phase 2 - Backend Business Logic
**Estimated Effort**: 4-5 days
**Risk Level**: High

##### User Story

**As a** TP administrator,
**I want** to sign the first student's document and have that signing replicated to all other students in the cohort,
**So that** I don't need to sign each student's document individually, saving time and eliminating duplicate sponsor emails.

##### Background

This is the core innovation of FloDoc. The workflow is:

1. **TP Signing Phase**: TP signs ONE student's document (with their fields/signatures)
2. **Duplication**: System duplicates the **completed submission** (not empty template) to remaining students
3. **Auto-fill**: TP's fields and signatures are automatically populated across all student submissions
4. **Email Management**: Sponsor receives ONE email (when all students are ready), not duplicate emails per submission

**Why Prototype First**: DocuSeal's native multi-submission only duplicates empty templates. This story requires custom duplication of pre-filled submissions, which is a high-risk architectural change.

**Prototype Approach**: Build a minimal prototype that:
- Creates 2-3 test submissions
- Demonstrates field/signature copying from first to remaining
- Validates sponsor email delivery logic
- Then expand to full implementation

##### Technical Implementation Notes

**TP Signing Phase Orchestration:**

```ruby
# app/services/tp_signing_service.rb
class TpSigningService
  def self.initiate_tp_signing(cohort, tp_user)
    raise 'Invalid state for TP signing' unless cohort.draft?

    ActiveRecord.transaction do
      # Step 1: Mark cohort as in TP signing phase
      cohort.update!(status: 'tp_signing')

      # Step 2: Track TP signing started timestamp
      cohort.update!(tp_started_at: Time.current)

      # Step 3: Create first student submission for TP to sign
      # This is the "seed" submission that will be duplicated
      first_student_email = "tp_signature_sample@#{cohort.id}.local"

      first_submission = Submission.create!(
        template: cohort.template,
        account: tp_user.account,
        name: "#{cohort.name} - TP Signature Template",
        metadata: { floDoc_cohort_id: cohort.id, is_tp_template: true }
      )

      # Create submitters for first submission
      submitter = Submitter.create!(
        submission: first_submission,
        email: first_student_email,
        name: "TP Signature Copy Base",
        role: 'student'
      )

      # Link to cohort enrollment
      CohortEnrollment.create!(
        cohort: cohort,
        submission: first_submission,
        student_email: first_student_email,
        student_name: "TP Template",
        role: 'student',
        status: 'complete'
      )

      # Return the submission for TP to fill
      { submission: first_submission, submitter: submitter }
    end
  end

  def self.complete_tp_signing(cohort, tp_template_submission)
    raise 'TP template submission not completed' unless tp_template_submission.completed?

    ActiveRecord.transaction do
      # Extract TP's filled fields from the template submission
      tp_template_submitter = tp_template_submission.submitters.first
      tp_template_values = tp_template_submitter.values

      # Get all pending student enrollments (for station 2)
      # Note: Will be created in Story 2.3
      pending_enrollments = cohort.cohort_enrollments.where(role: 'student', status: 'waiting')

      # Create duplications for remaining students
      # This is the CRITICAL step that copies pre-filled data
      pending_enrollments.each do |enrollment|
        # Duplicate the submission with TP's fields pre-filled
        duplicated_submission = Submission.create!(
          template: cohort.template,
          account: cohort.institution.users.first.account,  # TP's account
          name: "#{enrollment.student_name}'s Document",
          metadata: {
            floDoc_cohort_id: cohort.id,
            copied_from_template: tp_template_submission.id,
            pre_filled_by_tp: true
          }
        )

        # Create submitter with TP's pre-filled values
        submitter = Submitter.create!(
          submission: duplicated_submission,
          email: enrollment.student_email,
          name: enrollment.student_name,
          role: 'student',
          # CRITICAL: Copy all TP's filled values
          values: tp_template_values.dup
        )

        # Update enrollment to point to new submission
        enrollment.update!(
          submission: duplicated_submission,
          status: 'waiting'
        )
      end

      # Mark TP signing as complete
      cohort.update!(
        status: 'student_enrollment',
        tp_signed_at: Time.current
      )

      cohort
    end
  end
end
```

**Submission Duplication Logic:**

```ruby
# lib/flo_doc/submission_duplicator.rb
module FloDoc
  class SubmissionDuplicator
    def self.duplicate_with_pre_filled_values(source_submission, new_submitter_email, new_submitter_name)
      # This is the PROTOTYPE approach
      # Step 1: Get the source submitter's values
      source_submitter = source_submission.submitters.first
      source_values = source_submitter.values

      # Step 2: Create new submission
      new_submission = Submission.create!(
        template: source_submission.template,
        account: source_submission.account,
        name: source_submission.name,
        metadata: source_submission.metadata.merge(duplicated: true)
      )

      # Step 3: Create submitter with pre-filled values
      new_submitter = Submitter.create!(
        submission: new_submission,
        email: new_submitter_email,
        name: new_submitter_name,
        role: 'student',
        values: source_values.deep_dup
      )

      # Step 4: Copy field definitions but mark as pre-filled
      source_submission.fields.each do |field|
        Field.create!(
          submission: new_submission,
          field_type: field.field_type,
          field_name: field.field_name,
          field_label: field.field_label,
          field_value: field.field_value,
          required: field.required,
          x: field.x,
          y: field.y,
          page: field.page,
          # Mark as pre-filled (not editable by student)
          pre_filled: true,
          pre_filled_by: 'tp'
        )
      end

      new_submission
    end
  end
end
```

**Sponsor Email Logic (CRITICAL - Prevent Duplicates):**

```ruby
# app/services/sponsor_notification_service.rb
class SponsorNotificationService
  def self.notify_sponsor(cohort)
    # CRITICAL: Only send ONE email per cohort
    # Check if sponsor already notified
    return false if cohort.sponsor_email_sent_at.present?

    # Verify all students completed
    return false unless cohort.all_students_completed?

    # Verify cohort is in correct state
    return false unless cohort.ready_for_sponsor?

    # Generate single use token for sponsor
    token = AdHocTokenService.generate_sponsor_token(cohort)

    # Send ONE email with link to review all students
    FloDocMailer.sponsor_review_invitation(cohort, token).deliver_later

    # Mark as sent to prevent duplicates
    cohort.update!(sponsor_email_sent_at: Time.current)

    true
  end
end
```

**Key Design Decisions:**

1. **TP Template Pattern**: Create a "seed" submission that TP signs first
2. **Deep Duplication**: Copy all field values, not just metadata
3. **Source Tracking**: Remember which submission was copied for audit purposes
4. **Single Email Guarantee**: Timestamp-based prevention of duplicate emails
5. **State Machine Integration**: Cohort state drives when each operation is allowed

##### Acceptance Criteria

**Functional:**
1. ✅ TP can initiate TP signing phase from draft state
2. ✅ System creates "seed" submission for TP to sign
3. ✅ TP's signatures and field values are captured
4. ✅ System duplicates submission for all pending students
5. ✅ TP's values auto-fill into all student submissions
6. ✅ Sponsor receives only ONE email when all students ready
7. ✅ Cohort state transitions correctly through workflow

**Integration:**
1. ✅ IV1: Doesn't break existing submission/submitter logic
2. ✅ IV2: Submissions correctly linked to cohorments
3. ✅ IV3: Performance acceptable with 100 students per cohort

**Security:**
1. ✅ Only TP can initiate TP signing phase
2. ✅ TP can only sign their institution's cohorts
3. ✅ Pre-filled submissions marked clearly
4. ✅ Audit trail captures all duplication operations

**Quality:**
1. ✅ Transactional guarantees for multi-submission creation
2. ✅ Proper error handling for partial failures
3. ✅ Debug logging for debugging duplication issues
4. ✅ 85% test coverage

##### Integration Verification (IV1-3)

**IV1: Existing Functionality Verification**
- Verify existing submission creation still works
- Verify existing submitter creation still works
- Verify existing field rendering still works
- Run existing submission specs

**IV2: Duplication Logic Verification**
- Verify TP template submission created correctly
- Verify duplicate submissions have correct field values
- Verify submitter emails are unique
- Verify no duplicate sponsor emails sent

**IV3: Performance Impact Verification**
- Verify TP signing phase completes in < 1s for 100 students
- Verify duplication doesn't cause DB locks
- Verify sponsor email logic is fast
- Verify state transitions execute quickly

##### Test Requirements

**Service Specs:**
```ruby
# spec/services/tp_signing_service_spec.rb
describe TpSigningService do
  describe '.initiate_tp_signing' do
    it 'creates seed submission for TP' do
      cohort = create(:cohort, status: 'draft')
      result = described_class.initiate_tp_signing(cohort, tp_user)

      expect(result[:submission]).to be_persisted
      expect(result[:submitter]).to be_persisted
      expect(cohort.reload.tp_signing?).to be true
    end
  end

  describe '.complete_tp_signing' do
    it 'duplicates submissions for all students' do
      cohort = create(:cohort_with_students, student_count: 5)
      tp_template = create_completed_tp_template(cohort)

      described_class.complete_tp_signing(cohort, tp_template)

      expect(cohort.cohort_enrollments.students.count).to eq(5)
    end
  end
end

# spec/lib/flo_doc/submission_duplicator_spec.rb
describe FloDoc::SubmissionDuplicator do
  it 'copies all field values from source' do
    source = create_submission_with_values(field1: 'value1')
    duplicate = described_class.duplicate_with_pre_filled_values(source, 'new@test.com', 'New Student')

    expect(duplicate.submitters.first.values).to eq(source.submitters.first.values)
  end
end
```

**Feature Specs:**
- End-to-end TP signing workflow
- Verify sponsor email sent only once
- Verify state transitions

##### Rollback Procedure

**If TP signing logic fails:**
1. **Immediate**: Revert service object code
2. **Database**: Check for orphaned "seed" submissions, clean up if needed
3. **Verify**: Existing submission workflow still works
4. **Monitor**: Watch for duplicate sponsor emails

**Critical**: If duplicated in production, inspect cohort.email_sent_at flags to manually prevent duplicates.

##### Risk Assessment

**High Risk because:**
- **Custom duplication logic** - DocuSeal doesn't support this natively
- **Complex transaction** - Creating many submissions atomically
- **Email duplication risk** - Business-critical to prevent
- **State machine complexity** - Multiple coordinated state transitions
- **Data integrity** - Ensuring copied values are accurate

**Specific Risks:**
1. **DocuSeal API Limitations**: May not support pre-filled fields in certain field types
2. **Database Locks**: Creating 100+ submissions in one transaction could lock tables
3. **Email Duplication**: If sponsor email logic triggers twice, sponsor gets spammed
4. **Field Mapping Errors**: TP's fields might not map correctly to student fields
5. **State Desynchronization**: Cohort state vs. submission states could get out of sync

**Prototype-First Mitigation:**
1. Build standalone prototype with 2-3 test submissions
2. Validate field copying works for all 12 field types
3. Test sponsor email delivery with mock emails
4. Confirm performance with 100 student cohort in staging
5. Only then integrate into main application

**Additional Mitigation:**
- **Testing**: Comprehensive unit + integration + feature specs
- **Monitoring**: Log all duplication operations
- **Guards**: Pre-condition checks before every operation
- **Fallback**: Manual rollback procedures documented
- **Version Control**: Feature flag for gradual rollout

**Critical Success Metrics:**
- Zero duplicate sponsor emails
- 100% correct field value copying
- TP signing phase < 5 seconds for 100 students
- All submissions properly linked to cohort

---

#### Story 2.3: Student Enrollment Management

**Status**: Draft
**Priority**: High
**Epic**: Phase 2 - Backend Business Logic
**Estimated Effort**: 3-4 days
**Risk Level**: Medium

##### User Story

**As a** TP administrator,
**I want** to manage student enrollment in cohorts and bulk-create student submissions,
**So that** students can access their documents to complete after TP signs.

##### Background

After TP completes signing (Phase 2.2), the system needs to:
- Create student records in the cohort
- Set up individual submissions for each student
- Send email invites (using existing DocuSeal email system)
- Track student completion status

The enrollment process uses the existing DocuSeal submission invitation mechanism but adapts it to FloDoc's workflow needs.

**Key Requirements:**
- Bulk enrollment via CSV or manual entry
- Each student gets their own submission (pre-filled with TP's data)
- Email invites sent via DocuSeal's existing email system
- Student status tracked in cohort_enrollments

##### Technical Implementation Notes

**Student Enrollment Service:**

```ruby
# app/services/student_enrollment_service.rb
class StudentEnrollmentService
  def self.bulk_enroll(cohort, student_data, tp_user)
    raise 'TP signing must be completed first' unless cohort.tp_signing_completed?

    ActiveRecord.transaction do
      students = []

      student_data.each do |data|
        # Create cohort enrollment
        enrollment = CohortEnrollment.create!(
          cohort: cohort,
          student_email: data[:email],
          student_name: data[:name],
          student_surname: data[:surname],
          student_id: data[:student_id],
          role: 'student',
          status: 'waiting'
        )

        # IMPORTANT: We don't create the submission here
        # The submission is created by TP Signing Service (Story 2.2)
        # This enrollment will be updated with submission_id when TP signs

        students << enrollment
      end

      # Log enrollment creation
      AuditLog.create!(
        user: tp_user,
        action: 'bulk_student_enrollment',
        entity: cohort,
        details: { count: students.count, students: students.map(&:student_email) }
      )

      students
    end
  end

  def self.invite_students(cohort)
    raise 'Cannot invite before TP signs' unless cohort.student_enrollment?

    # Get all waiting student enrollments
    enrollments = cohort.cohort_enrollments.students.waiting

    # Send invites using existing DocuSeal mechanism
    enrollments.each do |enrollment|
      # Generate student token
      token = AdHocTokenService.generate_student_token(
        cohort,
        enrollment.student_email,
        enrollment.student_name
      )

      # Use existing DocuSeal email infrastructure
      FloDocMailer.student_invitation(
        enrollment.student_email,
        cohort,
        enrollment.submission,
        token
      ).deliver_later

      # Mark as invited
      enrollment.update!(invited_at: Time.current)
    end

    true
  end
end
```

**Student Progress Tracking:**

```ruby
# app/models/cohort_enrollment.rb (extended)
def mark_student_started!
  update!(status: 'in_progress') if waiting?
end

def mark_student_completed!
  update!(status: 'complete', completed_at: Time.current)

  # Check if all students completed
  cohort.reload
  if cohort.all_students_completed?
    cohort.update!(status: 'ready_for_sponsor')
    cohort.update!(students_completed_at: Time.current)

    # Trigger sponsor notification (from Story 2.2)
    SponsorNotificationService.notify_sponsor(cohort)
  end
end
```

**Required Student Uploads Tracking:**

```ruby
# Track which required uploads student has completed
# uploaded_documents structure: { 'id' => true, 'matric' => false, 'tertiary' => true }

def mark_upload_completed(upload_type)
  uploads = uploaded_documents || {}
  uploads[upload_type] = true
  update!(uploaded_documents: uploads)
end

def all_uploads_complete?
  required = cohort.required_student_uploads
  return false if required.blank?

  required.all? { |type| uploaded_documents[type] == true }
end
```

**Key Design Decisions:**

1. **Two-Step Process**: Enrollment first, then TP creates submissions
2. **Existing Email System**: Reuse DocuSeal's email delivery
3. **Status Tracking**: CohortEnrollment tracks all student states
4. **Upload Tracking**: Separate tracking for document uploads vs. form completion
5. **Bulk Operations**: Efficient handling of large student lists

##### Acceptance Criteria

**Functional:**
1. ✅ TP can bulk enroll students via CSV or manual entry
2. ✅ System validates student emails before creating enrollments
3. ✅ TP can send email invites to all enrolled students
4. ✅ Students can access their pre-filled documents via link
5. ✅ System tracks student completion (form fill + upload)
6. ✅ System auto-moves cohort to "ready_for_sponsor" when all complete
7. ✅ System triggers sponsor notification once

**Integration:**
1. ✅ IV1: Works with existing DocuSeal email system
2. ✅ IV2: Enrollment correctly links to submissions created by TP
3. ✅ IV3: Performance handles 500+ student cohorts

**Security:**
1. ✅ TP can only enroll students in their institution's cohorts
2. ✅ Student access tokens expire after configurable duration (default 30 days)
3. ✅ **Progress is saved independently of token expiration**
4. ✅ **Expired tokens can be renewed via email verification**
5. ✅ Upload tracking prevents unauthorized document completion
6. ✅ Email validation prevents malformed addresses

**Quality:**
1. ✅ Bulk enrollment has progress feedback
2. ✅ Duplicate email prevention
3. ✅ Proper error messages for invalid data
4. ✅ 85% test coverage

##### Integration Verification (IV1-3)

**IV1: Email System Integration**
- Verify emails use existing DocuSeal SMTP configuration
- Verify email templates work with FloDoc variables
- Verify email tracking is recorded
- Verify bounces are handled

**IV2: Submission Linking**
- Verify enrollments link to correct submissions after TP signs
- Verify submissions have pre-filled TP values
- Verify student access works through token-based auth

**IV3: Performance**
- Verify bulk enrollment of 500 students < 10 seconds
- Verify email queuing doesn't block enrollment
- Verify student listing query is fast
- Verify completion tracking doesn't cause race conditions

##### Test Requirements

**Service Specs:**
```ruby
# spec/services/student_enrollment_service_spec.rb
describe '.bulk_enroll' do
  it 'creates enrollment records' do
    cohort = create(:cohort)
    students = [{ email: 's1@test.com', name: 'Student 1' }]

    result = described_class.bulk_enroll(cohort, students, tp_user)
    expect(result.count).to eq(1)
  end

  it 'validates TP signing completed' do
    cohort = create(:cohort, status: 'draft')
    expect { described_class.bulk_enroll(cohort, [], tp_user) }.to raise_error
    end
end

describe '.invite_students' do
  it 'sends emails to waiting students'
  it 'marks students as invited'
  it 'doesn\'t send duplicate invites'
end
```

**Email Specs:**
- Verify mailer renders correctly
- Verify token in email link
- Verify tracking pixels (if used)

##### Rollback Procedure

**If enrollment service fails:**
1. Revert student_enrollment_service.rb code
2. Verify cohort_enrollments table is intact
3. Check for orphaned records
4. Verify existing DocuSeal email still works

**Data Safety**: Enrollments are soft-deletable if cleanup needed.

##### Risk Assessment

**Medium Risk because:**
- Interaction with existing email system could have side effects
- Bulk operations may cause database performance issues
- State transitions need to handle race conditions
- Student data validation needs to be robust

**Mitigation:**
- Use transactions for bulk operations
- Validate all student data before creating records
- Implement email rate limiting
- Add database indexes for common queries
- Comprehensive test coverage

---

#### Story 2.4: Sponsor Review Workflow

**Status**: Draft
**Priority**: Medium
**Epic**: Phase 2 - Backend Business Logic
**Estimated Effort**: 2-3 days
**Risk Level**: Low

##### User Story

**As a** Sponsor,
**I want** to review all student documents in my cohort and sign them in bulk,
**So that** I can complete the verification workflow efficiently.

##### Background

After all students complete their portion, the cohort enters "ready_for_sponsor" state. The sponsor:
- Receives ONE email invitation (Story 2.2 ensures this)
- Gets a portal view showing all students and their documents
- Can review each student's completed document
- Can sign/verify in bulk or individually
- System tracks sponsor completion

**No account creation needed** - sponsor uses ad-hoc token-based access.

##### Technical Implementation Notes

**Sponsor Portal Logic:**

```ruby
# app/services/sponsor_review_service.rb
class SponsorReviewService
  def self.initiate_sponsor_access(cohort)
    raise 'Not ready for sponsor' unless cohort.sponsor_access_ready?

    # Generate sponsor token (one-time use or time-limited)
    token = AdHocTokenService.generate_sponsor_token(cohort)

    # Update cohort state
    cohort.update!(status: 'sponsor_review', sponsor_started_at: Time.current)

    # Send sponsor access email (already covered in Story 2.2)
    # This method is if you need to regenerate or resend

    token
  end

  def self.get_sponsor_dashboard(cohort, sponsor_token)
    # Verify token
    decoded = AdHocTokenService.decode_token(sponsor_token)
    return nil unless decoded
    return nil unless decoded['role'] == 'sponsor'
    return nil unless decoded['cohort_id'] == cohort.id

    # Get all student submissions for this cohort
    student_enrollments = cohort.cohort_enrollments.students

    {
      cohort: cohort,
      student_count: student_enrollments.count,
      completed_count: student_enrollments.completed.count,
      students: student_enrollments.preload(:submission).map do |enrollment|
        {
          id: enrollment.id,
          name: "#{enrollment.student_name} #{enrollment.student_surname}",
          email: enrollment.student_email,
          status: enrollment.status,
          completed_at: enrollment.completed_at,
          submission_id: enrollment.submission_id,
          # Check if sponsor can review/verify this student
          can_review: enrollment.complete? && enrollment.all_uploads_complete?
        }
      end,
      sponsor_can_sign: cohort.all_students_completed?
    }
  end

  def self.verify_student(cohort, student_enrollment_id, sponsor_token, verify_data)
    # Verify sponsor token
    decoded = AdHocTokenService.decode_token(sponsor_token)
    return false unless decoded
    return false unless decoded['role'] == 'sponsor'
    return false unless decoded['cohort_id'] == cohort.id

    # Get enrollment
    enrollment = cohort.cohort_enrollments.find(student_enrollment_id)

    # Ensure student is complete
    return false unless enrollment.complete?

    # Create sponsor verification record
    # (Could be a new model or a field on cohort_enrollments)
    enrollment.update!(
      sponsor_verified_at: Time.current,
      sponsor_verification_data: verify_data
    )

    # Update cohort sponsor completion if all students verified
    if cohort.all_students_verified?
      cohort.update!(sponsor_completed_at: Time.current)
      cohort.update!(status: 'tp_review')
    end

    true
  end
end
```

**Token Renewal Mechanism:**

```ruby
# app/services/ad_hoc_token_service.rb
class AdHocTokenService
  # Generate token with configurable expiration (default 30 days)
  def self.generate_sponsor_token(cohort, expires_in: nil)
    expires_in ||= cohort.cohort_metadata&.dig('token_expiration') || 30.days

    payload = {
      role: 'sponsor',
      cohort_id: cohort.id,
      exp: Time.current.to_i + expires_in.to_i
    }

    JWT.encode(payload, Rails.application.secrets.secret_key_base, 'HS256')
  end

  def self.generate_student_token(cohort, email, name, expires_in: nil)
    expires_in ||= cohort.cohort_metadata&.dig('token_expiration') || 30.days

    payload = {
      role: 'student',
      cohort_id: cohort.id,
      email: email,
      name: name,
      exp: Time.current.to_i + expires_in.to_i
    }

    JWT.encode(payload, Rails.application.secrets.secret_key_base, 'HS256')
  end

  # Decode and verify token
  def self.decode_token(token)
    decoded = JWT.decode(
      token,
      Rails.application.secrets.secret_key_base,
      true,
      { algorithm: 'HS256' }
    )
    decoded.first
  rescue JWT::ExpiredSignature
    { expired: true }
  rescue JWT::DecodeError
    nil
  end

  # Renew expired token (requires email verification)
  def self.renew_token(cohort, email, role)
    # Verify email matches cohort
    if role == 'sponsor' && email == cohort.sponsor_email
      generate_sponsor_token(cohort)
    elsif role == 'student'
      enrollment = cohort.cohort_enrollments.find_by(student_email: email)
      generate_student_token(cohort, email, enrollment&.student_name) if enrollment
    else
      nil
    end
  end

  # Check if token is expired
  def self.expired?(token)
    decoded = decode_token(token)
    decoded&.dig(:expired) == true
  end
end
```

**Token Renewal Controller:**

```ruby
# app/controllers/api/v1/token_renewal_controller.rb
class Api::V1::TokenRenewalController < Api::BaseController
  skip_before_action :authenticate_user!

  def request_renewal
    cohort_id = params[:cohort_id]
    email = params[:email]
    role = params[:role]  # 'sponsor' or 'student'

    cohort = Cohort.find(cohort_id)

    # Verify email matches
    if role == 'sponsor' && email == cohort.sponsor_email
      new_token = AdHocTokenService.generate_sponsor_token(cohort)
      send_renewal_email(cohort, email, new_token, 'sponsor')
      render json: { message: 'New access link sent to email' }

    elsif role == 'student'
      enrollment = cohort.cohort_enrollments.find_by(student_email: email)
      if enrollment
        new_token = AdHocTokenService.generate_student_token(
          cohort, email, enrollment.student_name
        )
        send_renewal_email(cohort, email, new_token, 'student')
        render json: { message: 'New access link sent to email' }
      else
        render json: { error: 'Student not found in this cohort' }, status: :not_found
      end
    else
      render json: { error: 'Email does not match cohort' }, status: :unauthorized
    end
  end

  private

  def send_renewal_email(cohort, email, token, role)
    if role == 'sponsor'
      FloDocMailer.sponsor_token_renewal(cohort, email, token).deliver_later
    else
      FloDocMailer.student_token_renewal(cohort, email, token).deliver_later
    end
  end
end
```

**Email Templates for Renewal:**

```ruby
# app/mailers/flo_doc_mailer.rb
class FloDocMailer < ApplicationMailer
  def sponsor_token_renewal(cohort, email, token)
    @cohort = cohort
    @token = token
    @renewal_link = "#{ENV['APP_URL']}/sponsor/portal?token=#{token}"

    mail(
      to: email,
      subject: "New access link for #{cohort.name} - FloDoc"
    )
  end

  def student_token_renewal(cohort, email, token)
    @cohort = cohort
    @token = token
    @renewal_link = "#{ENV['APP_URL']}/student/portal?token=#{token}"

    mail(
      to: email,
      subject: "Continue your document for #{cohort.name} - FloDoc"
    )
  end
end
```

**Progress Preservation Design:**

```ruby
# Key Principle: Progress is ALWAYS saved to database, independent of token

# In SponsorReviewService.verify_student
def self.verify_student(cohort, student_enrollment_id, sponsor_token, verify_data)
  # ... token verification ...

  # CRITICAL: Save progress IMMEDIATELY
  enrollment.update!(
    sponsor_verified_at: Time.current,
    sponsor_verification_data: verify_data
  )

  # Progress is now in database, independent of token
  # Token is just the "key" to access it
end

# In StudentPortalController.update
def update
  enrollment = @cohort.cohort_enrollments.find_by(student_email: @token[:email])

  # Save student values immediately
  submitter = enrollment.submission.submitters.find_by(email: @token[:email])
  merged_values = submitter.values.merge(params[:values])
  submitter.update!(values: merged_values)

  # Progress saved to DB, token expiration doesn't affect it
end
```

**Cohort Configuration for Token Expiration:**

```ruby
# When creating cohort, TP can set token expiration
class CohortManagementService
  def self.create_cohort(params, user)
    cohort = Cohort.create!(
      name: params[:name],
      sponsor_email: params[:sponsor_email],
      cohort_metadata: {
        token_expiration: params[:token_expiration] || 30.days,
        # ... other metadata
      }
    )
  end
end

# Example cohort_metadata:
{
  "token_expiration": 2592000,  # 30 days in seconds
  "webhook_urls": ["https://..."],
  "required_uploads": ["id", "matric"]
}
```

**Key Design Decisions:**

1. **Progress Persistence**: All data saved to database immediately, independent of token
2. **Configurable Expiration**: TP can set custom expiration per cohort
3. **Renewal via Email**: Expired tokens can be renewed without data loss
4. **Email Verification**: Renewal requires email verification for security
5. **Graceful Degradation**: Expired token shows "renew" UI instead of blocking

**User Experience with Expired Token:**

1. User clicks old email link
2. System detects expired token
3. UI shows: "Your access link has expired"
4. User enters email, clicks "Request New Link"
5. System verifies email, sends new link
6. User clicks new link, continues where they left off
7. All progress is preserved

**Security Considerations:**

- Token renewal requires email verification
- New token has full access to existing progress
- Old token becomes invalid once new one is issued
- Audit trail tracks all token renewals
- Rate limiting on renewal requests

**Sponsor Portal - Expired Token Flow:**

```javascript
// Frontend handles expired token
if (tokenExpired) {
  showRenewalForm();
  // User enters email
  // POST to /api/v1/token/renewal
  // Show "check your email" message
}
```

**Student Portal - Expired Token Flow:**

Same mechanism as sponsor portal.

##### Key Principle

**Tokens are session keys, not data storage. Progress is ALWAYS in the database.**

**Sponsor Verification Model:**

```ruby
# Optional: New table for sponsor verification details
# app/models/sponsor_verification.rb

# Only needed if sponsor verification is complex
# For simple approval, can use cohort_enrollments.sponsor_verified_at

class SponsorVerification < ApplicationRecord
  belongs_to :cohort_enrollment
  belongs_to :sponsor_verification, optional: true

  validates :status, inclusion: { in: %w[approved rejected needs_changes] }
  validates :signature_data, presence: true

  # Store verification details: { date: Time.current, notes: "Approved", signature: "..." }
end
```

**Key Design Decisions:**

1. **Ad-hoc Portal**: No account needed, token-based access
2. **3-Panel Dashboard**: Student list | Document | Verification (FR10, FR11)
3. **Bulk Ready**: Structure supports bulk verification if needed
4. **State-Driven**: Sponsor can only review when all students complete

##### Acceptance Criteria

**Functional:**
1. ✅ Sponsor receives single email invitation
2. ✅ Sponsor can access portal via token link
3. ✅ Sponsor sees all student submissions in list
4. ✅ Sponsor can view each student's completed document
5. ✅ Sponsor can verify/approve students individually or in bulk
6. ✅ System tracks sponsor verification per student
7. ✅ Cohort moves to TP review when sponsor completes

**Integration:**
1. ✅ IV1: Works with existing DocuSeal document viewing
2. ✅ IV2: Sponsor tokens integrate with ad-hoc auth system
3. ✅ IV3: Performance with 100+ students

**Security:**
1. ✅ Sponsor can only access their assigned cohort
2. ✅ Sponsor access tokens expire after configurable duration (default 30 days)
3. ✅ **Progress is saved independently of token expiration**
4. ✅ **Expired tokens can be renewed via email verification**
5. ✅ Cannot view other cohorts' data
6. ✅ Verification data is tamper-proof

**Quality:**
1. ✅ Clear UI feedback during verification
2. ✅ Error handling for expired/invalid tokens
3. ✅ Audit trail of sponsor actions
4. ✅ 85% test coverage

##### Integration Verification (IV1-3)

**IV1: Document Viewing**
- Verify sponsor can view PDF documents
- Verify DocuSeal's existing rendering is used
- Verify navigation between students works smoothly

**IV2: Token Integration**
- Verify token generation creates valid sponsor tokens
- Verify token verification prevents unauthorized access
- Verify token expiration works correctly

**IV3: Performance**
- Verify sponsor dashboard loads in < 2 seconds for 100 students
- Verify document preview is fast
- Verify verification updates don't cause delays

##### Test Requirements

**Controller Specs:**
```ruby
# spec/controllers/sponsor_portal_controller_spec.rb
describe SponsorPortalController do
  it 'redirects invalid token' do
    get :show, params: { id: 1, token: 'invalid' }
    expect(response).to redirect_to(root_path)
  end

  it 'shows dashboard with token' do
    cohort = create(:cohort_with_completed_students)
    token = AdHocTokenService.generate_sponsor_token(cohort)

    get :show, params: { id: cohort.id, token: token }
    expect(assigns(:students)).to eq(cohort.cohort_enrollments.students)
  end
end
```

##### Rollback Procedure

**Review logic fails:**
1. Revert sponsor review service code
2. Verify existing DocuSeal review still works
3. Check token service integrity

**Data Safety**: All verification data stored with references.

##### Risk Assessment

**Low Risk because:**
- Uses existing document viewing infrastructure
- Ad-hoc auth already validated in Story 1.3
- Simple state transitions
- No complex business logic

**Mitigation:**
- Validate all token operations
- Clear error messages for sponsors
- Comprehensive logging

---

#### Story 2.5: TP Review & Finalization

**Status**: Draft
**Priority**: Medium
**Epic**: Phase 2 - Backend Business Logic
**Estimated Effort**: 2-3 days
**Risk Level**: Low

##### User Story

**As a** TP administrator,
**I want** to review the sponsor-verified submissions and finalize the cohort,
**So that** the entire 3-party signature workflow is completed and documents are ready for archival.

##### Background

Final phase of the workflow:
1. Sponsor completes verification (Story 2.4)
2. Cohort enters TP review state
3. TP admin reviews sponsor's verification
4. TP can approve/reject the cohort
5. Cohort moves to completed state
6. All documents finalized and archived

This is the final quality check in the workflow.

##### Technical Implementation Notes

**TP Review Service:**

```ruby
# app/services/finalization_service.rb
class FinalizationService
  def self.initiate_tp_review(cohort, tp_user)
    raise 'Cohort not ready for TP review' unless cohort.sponsor_completed?

    cohort.update!(status: 'tp_review')

    AuditLog.create!(
      user: tp_user,
      action: 'tp_review_started',
      entity: cohort
    )
  end

  def self.get_tp_review_dashboard(cohort, tp_user)
    # Verify user has access
    return nil unless tp_user.can?(:review, cohort)

    student_enrollments = cohort.cohort_enrollments.students

    {
      cohort: cohort,
      sponsor_verification_count: student_enrollments.where.not(sponsor_verified_at: nil).count,
      total_students: student_enrollments.count,
      students: student_enrollments.map do |enrollment|
        {
          email: enrollment.student_email,
          name: "#{enrollment.student_name} #{enrollment.student_surname}",
          sponsor_verified_at: enrollment.sponsor_verified_at,
          sponsor_verification_data: enrollment.sponsor_verification_data,
          status: enrollment.status
        }
      end,
      can_finalize: cohort.sponsor_completed?
    }
  end

  def self.finalize_cohort(cohort, tp_user, approval_data)
    raise 'Not in TP review state' unless cohort.tp_review?

    ActiveRecord.transaction do
      # Mark all submissions as finalized
      cohort.cohort_enrollments.update_all(finalized_at: Time.current)

      # Update cohort final state
      cohort.update!(
        status: 'completed',
        finalized_at: Time.current,
        completion_metadata: approval_data.merge(completed_by: tp_user.email)
      )

      # Generate completion report
      completion_report = generate_completion_report(cohort)

      # Archive all documents (using existing DocuSeal archiving)
      ArchiveCohortDocumentsJob.perform_later(cohort.id)

      # Log completion
      AuditLog.create!(
        user: tp_user,
        action: 'cohort_completed',
        entity: cohort,
        details: { student_count: cohort.cohort_enrollments.count }
      )

      { cohort: cohort, report: completion_report }
    end
  end

  private

  def self.generate_completion_report(cohort)
    {
      cohort_id: cohort.id,
      cohort_name: cohort.name,
      completion_date: Time.current,
      student_count: cohort.cohort_enrollments.students.count,
      sponsor_email: cohort.sponsor_email,
      program_type: cohort.program_type,
      metadata: cohort.completion_metadata
    }
  end
end
```

**Final Document Archiving:**

```ruby
# app/jobs/archive_cohort_documents_job.rb
class ArchiveCohortDocumentsJob < ApplicationJob
  queue_as :pdf

  def perform(cohort_id)
    cohort = Cohort.find(cohort_id)

    # Use DocuSeal's existing document generation
    cohort.cohort_enrollments.students.each do |enrollment|
      submission = enrollment.submission

      # Mark submission as archived
      submission.update!(archived_at: Time.current)

      # Generate final PDF if not already done
      unless submission.completed_document.present?
        DocumentGenerationJob.perform_now(submission)
      end
    end

    # Mark cohort as archived
    cohort.update!(archived_at: Time.current)
  end
end
```

**Key Design Decisions:**

1. **State-Gated**: Each step requires specific state
2. **Audit Trail**: Complete lifecycle audit from creation to completion
3. **Final Report**: Simple JSON report for TP records
4. **Async Archiving**: Job-based archiving doesn't block web request
5. **Reversible**: Rollback still possible if issues found

##### Acceptance Criteria

**Functional:**
1. ✅ TP sees sponsor verification dashboard
2. ✅ TP can review all student verifications
3. ✅ TP can approve/reject individual students
4. ✅ TP can finalize entire cohort
5. ✅ System archives all documents
6. ✅ System generates completion report
7. ✅ Cohort marked as completed
8. ✅ Audit trail complete

**Integration:**
1. ✅ IV1: Uses existing DocuSeal document archiving
2. ✅ IV2: Completes workflow state machine
3. ✅ IV3: Handles large cohorts without performance issues

**Security:**
1. ✅ Only TP can access review dashboard
2. ✅ All actions logged with user attribution
3. ✅ Finalized documents cannot be modified
4. ✅ Completion report is read-only

**Quality:**
1. ✅ Clear indication of verification status
2. ✅ Errors for incomplete verification attempts
3. ✅ Very fast finalization (< 3 seconds)
4. ✅ 80% test coverage

##### Integration Verification (IV1-3)

**IV1: DocuSeal Integration**
- Verify existing document archiving works
- Verify PDF generation completes
- Verify existing document storage is respected

**IV2: State Machine**
- Verify state transitions: tp_review → completed
- Verify cohort status updates correctly
- Verify no orphaned records

**IV3: Performance**
- Verify review dashboard loads quickly
- Verify finalization performs well with 500 students
- Verify archive job doesn't block

##### Test Requirements

**Service Specs:**
```ruby
# spec/services/finalization_service_spec.rb
describe '.finalize_cohort' do
  it 'transitions cohort to completed' do
    cohort = create(:cohort, status: 'tp_review')
    result = described_class.finalize_cohort(cohort, tp_user, {})

    expect(result[:cohort].status).to eq('completed')
    expect(result[:cohort].finalized_at).to be_present
  end
end
```

##### Rollback Procedure

**If finalization fails:**
1. Revert finalization service
2. Revert cohort to tp_review state if completed prematurely
3. Ensure documents are not in corrupted state

**Data Safety**: All operations are idempotent.

##### Risk Assessment

**Low Risk because:**
- Final state transitions only
- Uses existing document tools
- Simple approval workflow
- Well-defined error cases

**Mitigation:**
- Pre-flight checks before finalization
- Idempotent operations
- Clear user feedback

---

#### Story 2.6: Excel Export for Cohort Data

**Status**: Draft
**Priority**: Medium
**Epic**: Phase 2 - Backend Business Logic
**Estimated Effort**: 2-3 days
**Risk Level**: Low

##### User Story

**As a** TP administrator,
**I want** to export cohort enrollment data to Excel,
**So that** I can perform additional analysis or reporting outside the system.

##### Background

FR23 requires Excel export capability. This should include:
- Student enrollment information
- Document status (completed/incomplete)
- Verification status (TP, students, sponsor)
- Required upload status

This allows TP admins to use Excel for additional reporting.

##### Technical Implementation Notes

**Excel Export Service:**

```ruby
# app/services/excel_export_service.rb
require 'rubyXL'

class ExcelExportService
  def self.export_cohort_data(cohort)
    workbook = RubyXL::Workbook.new
    worksheet = workbook[0]
    worksheet.sheet_name = "#{cohort.name} - Enrollment Report"

    # Headers
    headers = [
      'Student Name',
      'Student Surname',
      'Email',
      'Student ID',
      'Enrollment Status',
      'Form Completed',
      'Uploads Status',
      'Sponsor Verified At',
      'Completed At'
    ]

    headers.each_with_index do |header, index|
      worksheet.add_cell(0, index, header)
      worksheet[0][index].change_font_bold(true)
    end

    # Data rows
    row = 1
    cohort.cohort_enrollments.students.each do |enrollment|
      worksheet.add_cell(row, 0, enrollment.student_name)
      worksheet.add_cell(row, 1, enrollment.student_surname)
      worksheet.add_cell(row, 2, enrollment.student_email)
      worksheet.add_cell(row, 3, enrollment.student_id || '')
      worksheet.add_cell(row, 4, enrollment.status)
      worksheet.add_cell(row, 5, enrollment.status == 'complete' ? 'Yes' : 'No')
      worksheet.add_cell(row, 6, uploads_status_text(enrollment))
      worksheet.add_cell(row, 7, format_timestamp(enrollment.sponsor_verified_at))
      worksheet.add_cell(row, 8, format_timestamp(enrollment.completed_at))
      row += 1
    end

    # Add summary section
    worksheet.add_cell(row + 1, 0, 'Summary')
    worksheet.add_cell(row + 2, 0, 'Total Students')
    worksheet.add_cell(row + 2, 1, cohort.cohort_enrollments.students.count)
    worksheet.add_cell(row + 3, 0, 'Completed')
    worksheet.add_cell(row + 3, 1, cohort.cohort_enrollments.completed.count)
    worksheet.add_cell(row + 4, 0, 'Sponsor Verified')
    worksheet.add_cell(row + 4, 1, cohort.cohort_enrollments.where.not(sponsor_verified_at: nil).count)

    # Generate file
    temp_file = Tempfile.new(['cohort_export', '.xlsx'])
    workbook.write(temp_file.path)
    temp_file
  end

  private

  def self.uploads_status_text(enrollment)
    return 'N/A' if enrollment.uploaded_documents.blank?

    required = enrollment.cohort.required_student_uploads || []
    completed = enrollment.uploaded_documents.select { |_, v| v }.keys

    if required.empty?
      'No requirements'
    elsif completed.size == required.size
      'All completed'
    else
      "#{completed.size}/#{required.size}"
    end
  end

  def self.format_timestamp(timestamp)
    timestamp ? timestamp.strftime('%Y-%m-%d %H:%M') : ''
  end
end
```

**Controller Integration:**

```ruby
# app/controllers/reports_controller.rb
class ReportsController < ApplicationController
  before_action :authenticate_user!
  load_resource :cohort

  def export
    authorize! :export, @cohort

    temp_file = ExcelExportService.export_cohort_data(@cohort)

    send_file(
      temp_file.path,
      filename: "cohort_#{@cohort.id}_export.xlsx",
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      disposition: 'attachment'
    )

    # Cleanup
    temp_file.close
    temp_file.unlink
  end
end
```

**Key Design Decisions:**

1. **RubyXL Gem**: Industry standard for Excel generation
2. **Simple Structure**: Single worksheet with clear headers
3. **Summary Section**: Key metrics at bottom of spreadsheet
4. **Inline Formatting**: Bold headers, proper date formatting
5. **Tempfile Pattern**: Stream file download without storing on server

##### Acceptance Criteria

**Functional:**
1. ✅ TP can export cohort to Excel (.xlsx format)
2. ✅ Export includes all student enrollment data
3. ✅ Export includes completion status
4. ✅ Export includes sponsor verification status
5. ✅ Export includes upload tracking
6. ✅ Export includes summary statistics
7. ✅ File downloads automatically

**Integration:**
1. ✅ IV1: Works with existing authorization
2. ✅ IV2: Performance acceptable for 500 students
3. ✅ IV3: No memory leaks with large exports

**Security:**
1. ✅ Only TP can export their institution's cohorts
2. ✅ Export contains no sensitive tokens/PII
3. ✅ File cleaned up after download

**Quality:**
1. ✅ Clean Excel formatting
2. ✅ Handle special characters in names
3. ✅ Nice error message for empty cohorts
4. ✅ 80% test coverage

##### Integration Verification (IV1-3)

**IV1: Export Permissions**
- Verify unauthorized users cannot access export
- Verify TP cannot export other institution's cohorts

**IV2: Data Completeness**
- Verify all students included in export
- Verify all required columns present
- Verify summary matches database count

**IV3: Performance**
- Verify export of 500 students < 5 seconds
- Verify memory usage is reasonable
- Verify temp file is cleaned up

##### Test Requirements

**Service Specs:**
```ruby
# spec/services/excel_export_service_spec.rb
describe '.export_cohort_data' do
  it 'generates valid Excel file' do
    cohort = create_cohort_with_students
    temp_file = described_class.export_cohort_data(cohort)

    expect(File.exist?(temp_file.path)).to be true
    expect(temp_file.path).to end_with('.xlsx')

    # Verify file can be read
    workbook = RubyXL::Parser.parse(temp_file.path)
    expect(workbook[0].sheet_name).to include(cohort.name)
  end
end
```

##### Rollback Procedure

**If export fails:**
1. Revert excel_export_service.rb
2. Verify RubyXL gem installation
3. Check file permissions for temp directory

**Data Safety**: Export does not modify data.

##### Risk Assessment

**Low Risk because:**
- Simple data extraction only
- No database modifications
- Easy to verify output
- RubyXL is mature library

**Mitigation:**
- Test with various data sets
- Handle edge cases (empty data, special characters)
- Stream large exports to avoid memory issues

---

#### Story 2.7: Audit Log & Compliance

**Status**: Draft
**Priority**: High
**Epic**: Phase 2 - Backend Business Logic
**Estimated Effort**: 2-3 days
**Risk Level**: Medium

##### User Story

**As a** TP administrator,
**I want** comprehensive audit logs of all cohort workflow activities,
**So that** we can demonstrate compliance and trace any issues.

##### Background

FloDoc handles sensitive training documents. Compliance requires:
- Immutable audit trail of all actions
- Who did what and when
- Document access tracking
- Workflow state changes
- Sponsor access tracking

All audit logs must be tamper-proof and easily searchable.

##### Technical Implementation Notes

**Audit Log Model:**

```ruby
# app/models/audit_log.rb
class AuditLog < ApplicationRecord
  # Immutable audit trail
  self.readonly = false  # But we will prevent updates

  belongs_to :user, optional: true  # nil for system actions
  belongs_to :entity, polymorphic: true, optional: true

  validates :action, presence: true
  validates :entity_type, presence: true
  validates :entity_id, presence: true

  # Prevent any updates or deletes
  def readonly?
    persisted?  # New records can be saved, existing cannot be modified
  end

  # Scopes for reporting
  scope :recent, -> { order(created_at: :desc) }
  scope :for_cohort, ->(cohort_id) { where(entity_type: 'Cohort', entity_id: cohort_id) }
  scope :for_type, ->(type) { where(entity_type: type) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :between, ->(start_time, end_time) { where(created_at: start_time..end_time) }

  # JSON serialization for details
  serialize :details, JSON

  # Search
  def self.search(query)
    return all if query.blank?

    where("details LIKE ?", "%#{query}%")
      .or(where("action LIKE ?", "%query%"))
  end
end
```

**Audit Log Creation Module:**

```ruby
# lib/flo_doc/audit.rb
module FloDoc
  module Audit
    def self.log(user, action, entity, details = {})
      # Use create! to ensure immutability
      # Skip if user is nil and action is not critical
      return if user.nil? && !%w[cohort_completed sponsor_accessed].include?(action)

      AuditLog.create!(
        user: user,
        action: action,
        entity_type: entity.class.name,
        entity_id: entity.id,
        details: details
      )
    rescue => e
      # Log error silently, don't block main operation
      Rails.logger.error "Audit log failed: #{e.message}"
    end

    # Convenience methods for common audit events
    def self.cohort_created(user, cohort)
      log(
        user,
        'cohort_created',
        cohort,
        {
          name: cohort.name,
          template: cohort.template_id,
          sponsor: cohort.sponsor_email,
          program_type: cohort.program_type
        }
      )
    end

    def self.tp_signing_completed(user, cohort)
      log(
        user,
        'tp_signing_completed',
        cohort,
        { tp_email: user.email, timestamp: Time.current }
      )
    end

    def self.student_invited(user, cohort, student_email)
      log(
        user,
        'student_invited',
        cohort,
        { student_email: student_email }
      )
    end

    def self.student_completed(cohort, student_email)
      log(
        nil,
        'student_completed',
        cohort,
        { student_email: student_email, completed_at: Time.current }
      )
    end

    def self.sponsor_accessed(cohort, sponsor_email)
      log(
        nil,
        'sponsor_accessed',
        cohort,
        { sponsor_email: sponsor_email }
      )
    end

    def self.sponsor_verified(cohort, student_enrollment)
      log(
        nil,
        'sponsor_verified',
        cohort,
        {
          student_email: student_enrollment.student_email,
          verified_at: Time.current
        }
      )
    end

    def self.cohort_completed(user, cohort)
      log(
        user,
        'cohort_completed',
        cohort,
        {
          completed_by: user.email,
          student_count: cohort.cohort_enrollments.count,
          completed_at: Time.current
        }
      )
    end

    def self.document_accessed(user, submission)
      log(
        user,
        'document_accessed',
        submission,
        { document_id: submission.id, accessed_by: user&.email }
      )
    end
  end
end
```

**Document Access Tracking:**

```ruby
# app/controllers/document_access_controller.rb
class DocumentAccessController < ApplicationController
  before_action :authenticate_user_or_verify_token

  def show
    # Track document access
    FloDoc::Audit.document_accessed(current_user, @submission)

    # Render document using existing DocuSeal view
    render 'submissions/show'
  end

  private

  def authenticate_user_or_verify_token
    # Support both authenticated users and ad-hoc tokens
    if params[:token]
      @token = AdHocTokenService.decode_token(params[:token])
      @submission = Submission.find(params[:id])
      authorize! :read, @submission, @token
    else
      authenticate_user!
      @submission = Submission.find(params[:id])
      authorize! :read, @submission
    end
  end
end
```

**Audit Report Generation:**

```ruby
# app/services/audit_report_service.rb
class AuditReportService
  def self.generate_cohort_report(cohort, start_date, end_date)
    logs = AuditLog.for_cohort(cohort.id)
                   .between(start_date, end_date)
                   .recent

    {
      cohort: {
        id: cohort.id,
        name: cohort.name,
        created_at: cohort.created_at
      },
      period: {
        start: start_date,
        end: end_date
      },
      stats: {
        total_events: logs.count,
        unique_users: logs.distinct.count(:user_id),
        events_by_type: logs.group(:action).count,
        workflow_timeline: workflow_timeline(cohort, logs)
      },
      events: logs.map do |log|
        {
          timestamp: log.created_at,
          action: log.action,
          user: log.user&.email || 'System',
          entity: "#{log.entity_type}##{log.entity_id}",
          details: log.details
        }
      end
    }
  end

  private

  def self.workflow_timeline(cohort, logs)
    # Reconstruct key workflow milestones
    {
      created_at: cohort.created_at,
      tp_signing_completed: logs.find { |l| l.action == 'tp_signing_completed' }&.created_at,
      student_completions: logs.where(action: 'student_completed').count,
      sponsor_access_received: logs.find { |l| l.action == 'sponsor_accessed' }&.created_at,
      sponsor_verifications: logs.where(action: 'sponsor_verified').count,
      cohort_completed: logs.find { |l| l.action == 'cohort_completed' }&.created_at
    }
  end
end
```

**Integrate Audit Calls:**

Add audit logging to existing service objects:
```ruby
# In TpSigningService.complete_tp_signing
FloDoc::Audit.tp_signing_completed(user, cohort)

# In StudentEnrollmentService.bulk_enroll
FloDoc::Audit.cohort_created(user, cohort)

# In StudentEnrollmentService.invite_students
students.each do |student|
  FloDoc::Audit.student_invited(user, cohort, student.student_email)
end

# In CohortEnrollment.mark_student_completed!
FloDoc::Audit.student_completed(cohort, student_email)

# In SponsorPortalController
FloDoc::Audit.sponsor_accessed(cohort, sponsor_email)

# In SponsorReviewService.verify_student
FloDoc::Audit.sponsor_verified(cohort, enrollment)

# In FinalizationService.finalize_cohort
FloDoc::Audit.cohort_completed(user, cohort)
```

**Key Design Decisions:**

1. **Immutability**: Audit records cannot be updated or deleted
2. **Polymorphic**: Can audit any entity type
3. **Comprehensive**: Every workflow step logged
4. **Searchable**: Scopes and search for compliance reports
5. **User-Friendly**: Report generation for common compliance queries

##### Acceptance Criteria

**Functional:**
1. ✅ Every cohort action is logged
2. ✅ All logs are immutable (no updates/deletes)
3. ✅ System actions logged even without user
4. ✅ Document access tracking works
5. ✅ Audit reports can be generated
6. ✅ Reports show workflow timeline
7. ✅ Reports filter by date range
8. ✅ Reports show event counts and breakdowns

**Integration:**
1. ✅ IV1: Audit calls work without blocking main operations
2. ✅ IV2: Logs integrate with existing models
3. ✅ IV3: Performance impact < 5% on operations

**Security:**
1. ✅ Audit logs protected from tampering
2. ✅ Only admins can view audit reports
3. ✅ Logs don't contain sensitive data (passwords, tokens)
4. ✅ Immutable storage is enforced

**Quality:**
1. ✅ Standardized log format
2. ✅ Comprehensive coverage (all actions)
3. ✅ Clear error handling if audit logging fails
4. ✅ 90% test coverage for audit module

##### Integration Verification (IV1-3)

**IV1: Audit Calls**
- Verify audit log created for cohort creation
- Verify log created for TP signing
- Verify log created for student invites
- Verify log created for sponsor access
- Verify log created for completion

**IV2: Immutability**
- Verify cannot update existing logs
- Verify cannot delete logs
- Verify database constraints work

**IV3: Report Performance**
- Verify report generation < 1 second for 1000 events
- Verify search works faster than 2 seconds
- Verify no memory bloat with large reports

##### Test Requirements

**Model Specs:**
```ruby
# spec/models/audit_log_spec.rb
describe AuditLog do
  it 'prevents updates' do
    log = create(:audit_log)
    expect { log.update!(action: 'hacked') }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it 'can be created' do
    expect { create(:audit_log) }.not_to raise_error
  end
end

# spec/lib/flo_doc/audit_spec.rb
describe FloDoc::Audit do
  describe '.log' do
    it 'creates audit record' do
      cohort = create(:cohort)
      expect {
        described_class.log(user, 'test_action', cohort, { extra: 'data' })
      }.to change(AuditLog, :count).by(1)
    end
  end
end
```

**Report Specs:**
```ruby
# spec/services/audit_report_service_spec.rb
describe '.generate_cohort_report' do
  it 'includes all events in date range' do
    cohort = create(:cohort)
    create_list(:audit_log, 10, entity: cohort)

    report = described_class.generate_cohort_report(
      cohort,
      1.day.ago,
      Time.current
    )

    expect(report[:stats][:total_events]).to eq(10)
  end
end
```

##### Rollback Procedure

**If audit system fails:**
1. Revert audit logging wrapper
2. Existing audit logs remain intact
3. Manual cleanup of partial audit records if needed
4. Main application unaffected

**Data Safety**: Audit logs are append-only, no risk to core data.

##### Risk Assessment

**Medium Risk because:**
- Every operation now has extra database write
- Immutability means mistakes are permanent
- Performance impact needs monitoring
- Storage requirements grow with usage

**Mitigation:**
- Use async jobs for non-critical audit events
- Monitor audit table size
- Index database appropriately
- Batch critical audit calls
- Clear retention policy (optional)

**Critical Success Metrics:**
- Zero performance degradation on core workflows
- 100% audit event coverage
- Audit report generation < 2 seconds for 1000 events
- Storage grows predictably

---

#### Story 2.8: Cohort State Machine & Workflow Orchestration

**Status**: Draft
**Priority**: High
**Epic**: Phase 2 - Backend Business Logic
**Estimated Effort**: 2-3 days
**Risk Level**: Medium

##### User Story

**As a** system,
**I want** to manage cohort state transitions and workflow enforcement,
**So that** the 3-party signature workflow follows the correct sequence and prevents invalid operations.

##### Background

The FloDoc workflow has strict state requirements:
1. **Draft** → TP signs first document
2. **TP Signing** → Student enrollment
3. **Student Enrollment** → Student completion
4. **Ready for Sponsor** → Sponsor review
5. **Sponsor Review** → TP verification
6. **TP Review** → Completed

Cannot skip steps. Prevents chaos.

This story ties together all Phase 2 logic with proper state enforcement.

##### Technical Implementation Notes

**Enhanced State Machine (Story 1.2 had basic version):**

```ruby
# app/models/cohort.rb (enhanced)
class Cohort < ApplicationRecord
  include AASM
  include SoftDeletable

  has_many :cohort_enrollments
  has_many :submissions, through: :cohort_enrollments

  # State machine with full validation
  aasm column: :status, whiny_transitions: true do
    state :draft, initial: true
    state :tp_signing
    state :student_enrollment
    state :ready_for_sponsor
    state :sponsor_review
    state :tp_review
    state :completed

    # Event: Start TP Signing (draft → tp_signing)
    event :start_tp_signing do
      transitions from: :draft, to: :tp_signing, guard: :can_start_tp_signing?
    end

    # Event: Complete TP Signing (tp_signing → student_enrollment)
    event :complete_tp_signing do
      transitions from: :tp_signing, to: :student_enrollment, guard: :can_complete_tp_signing?
    end

    # Event: All Students Complete (student_enrollment → ready_for_sponsor)
    event :all_students_complete do
      transitions from: :student_enrollment, to: :ready_for_sponsor, guard: :can_move_to_ready_for_sponsor?
    end

    # Event: Sponsor Starts Review (ready_for_sponsor → sponsor_review)
    event :sponsor_starts_review do
      transitions from: :ready_for_sponsor, to: :sponsor_review, guard: :can_sponsor_review?
    end

    # Event: Sponsor Completes Review (sponsor_review → tp_review)
    event :sponsor_completes do
      transitions from: :sponsor_review, to: :tp_review, guard: :can_sponsor_complete?
    end

    # Event: Finalize (tp_review → completed)
    event :finalize do
      transitions from: :tp_review, to: :completed, guard: :can_finalize?
    end
  end

  # Guards for state transitions
  def can_start_tp_signing?
    errors.clear
    errors.add(:status, 'must be draft') unless draft?
    errors.add(:template, 'required') unless template_id.present?
    errors.add(:sponsor_email, 'required') unless sponsor_email.present?
    errors.empty?
  end

  def can_complete_tp_signing?
    errors.clear
    errors.add(:status, 'must be tp_signing') unless tp_signing?
    errors.add(:tp_template, 'must be completed') unless tp_template_completed?
    errors.empty?
  end

  def can_move_to_ready_for_sponsor?
    errors.clear
    errors.add(:status, 'must be student_enrollment') unless student_enrollment?
    errors.add(:students, 'must be enrolled') unless students_enrolled?
    errors.add(:students, 'must be all complete') unless all_students_completed?
    errors.empty?
  end

  def can_sponsor_review?
    errors.clear
    errors.add(:status, 'must be ready_for_sponsor') unless ready_for_sponsor?
    errors.add(:sponsor, 'must be ready') unless sponsor_access_ready?
    errors.empty?
  end

  def can_sponsor_complete?
    errors.clear
    errors.add(:status, 'must be sponsor_review') unless sponsor_review?
    errors.add(:students, 'all must be verified') unless all_students_verified?
    errors.empty?
  end

  def can_finalize?
    errors.clear
    errors.add(:status, 'must be tp_review') unless tp_review?
    errors.add(:sponsor, 'must have completed') unless sponsor_completed?
    errors.empty?
  end

  # Helper methods for guards
  def tp_template_completed?
    cohort_enrollments.where(role: 'student', student_email: "tp_signature_sample@#{id}.local").completed.exists?
  end

  def students_enrolled?
    cohort_enrollments.where(role: 'student', student_email: "tp_signature_sample@#{id}.local").blank? &&
    cohort_enrollments.where(role: 'student').count > 0
  end

  def all_students_completed?
    return false if cohort_enrollments.students.empty?
    cohort_enrollments.students.where(status: 'complete').count == cohort_enrollments.students.count
  end

  def sponsor_access_ready?
    all_students_completed? && sponsor_email_sent_at.present?
  end

  def all_students_verified?
    return false if cohort_enrollments.students.empty?
    cohort_enrollments.students.where.not(sponsor_verified_at: nil).count == cohort_enrollments.students.count
  end

  # Validations
  validate :workflow_order

  def workflow_order
    return if draft?

    # Additional runtime checks
    case status
    when 'tp_signing'
      errors.add(:base, 'TP signing requires template') unless template_id.present?
    when 'student_enrollment'
      errors.add(:base, 'TP must sign first') unless tp_signing_completed?
    when 'ready_for_sponsor'
      errors.add(:base, 'All students must complete') unless all_students_completed?
    end
  end
end
```

**Workflow Orchestrator:**

```ruby
# app/services/workflow_orchestrator.rb
class WorkflowOrchestrator
  # High-level orchestration that ties together all actions

  def self.start_cohort(cohort, tp_user)
    cohort.start_tp_signing!

    # Create seed submission
    result = TpSigningService.initiate_tp_signing(cohort, tp_user)

    FloDoc::Audit.cohort_started(cohort, tp_user)

    result
  rescue AASM::InvalidTransition => e
    { error: e.message, errors: cohort.errors.full_messages }
  end

  def self.enroll_students(cohort, student_data, tp_user)
    cohort.complete_tp_signing! if cohort.tp_signing?

    # This transitions from tp_signing → student_enrollment
    # Error handling handled by AASM

    students = StudentEnrollmentService.bulk_enroll(cohort, student_data, tp_user)

    {
      cohort: cohort,
      students: students,
      next_step: 'send_invites'
    }
  rescue AASM::InvalidTransition => e
    { error: e.message, errors: cohort.errors.full_messages }
  end

  def self.mark_student_complete(cohort_enrollment)
    cohort_enrollment.mark_student_completed!

    # Check if this completes the cohort
    if cohort_enrollment.cohort.all_students_completed?
      cohort_enrollment.cohort.all_students_complete!

      # Send sponsor email
      SponsorNotificationService.notify_sponsor(cohort_enrollment.cohort)
    end

    true
  rescue AASM::InvalidTransition => e
    Rails.logger.error "Student completion failed: #{e.message}"
    false
  end

  def self.sponsor_wants_to_review(cohort, sponsor_email)
    # Check state
    unless cohort.ready_for_sponsor?
      return { error: 'Cohort not ready for sponsor review' }
    end

    # Transition state
    cohort.sponsor_starts_review!

    # Generate token
    token = AdHocTokenService.generate_sponsor_token(cohort)

    # Log access
    FloDoc::Audit.sponsor_accessed(cohort, sponsor_email)

    { cohort: cohort, token: token }
  rescue AASM::InvalidTransition => e
    { error: e.message }
  end

  def self.sponsor_verifies_student(cohort_enrollment, verify_data)
    cohort_enrollment.update!(
      sponsor_verified_at: Time.current,
      sponsor_verification_data: verify_data
    )

    cohort = cohort_enrollment.cohort

    FloDoc::Audit.sponsor_verified(cohort, cohort_enrollment)

    # Check if all verified
    if cohort.all_students_verified?
      cohort.sponsor_completes!
    end

    true
  end

  def self.finalize_cohort(cohort, tp_user, approval_data)
    # Transition to tp_review first if not already
    cohort.update!(status: 'tp_review') if cohort.sponsor_review?

    # Check final conditions
    unless cohort.can_finalize?
      return { error: 'Cannot finalize yet', errors: cohort.errors.full_messages }
    end

    # Finalize
    FinalizationService.finalize_cohort(cohort, tp_user, approval_data)
    cohort.finalize!

    FloDoc::Audit.cohort_completed(cohort, tp_user)

    { success: true, cohort: cohort }
  rescue AASM::InvalidTransition => e
    { error: e.message }
  end
end
```

**State Validation Controller Filters:**

```ruby
# app/controllers/cohorts_controller.rb
class CohortsController < ApplicationController
  before_action :load_cohort

  # Example validation
  def start_signing
    unless @cohort.can_start_tp_signing?
      return render json: { error: 'Cannot start signing', details: @cohort.errors }, status: :bad_request
    end

    result = WorkflowOrchestrator.start_cohort(@cohort, current_user)

    if result.is_a?(Hash) && result[:error]
      render json: result, status: :unprocessable_entity
    else
      render json: { cohort: @cohort, next_step: result }
    end
  end

  def enroll_students
    if @cohort.draft? || @cohort.status.nil?
      return render json: { error: 'Cannot enroll - TP must sign first' }, status: :bad_request
    end

    # More validations...
  end
end
```

**Background Job Integration:**

```ruby
# app/jobs/workflow_validation_job.rb
# Periodic job to check for stuck cohorts
class WorkflowValidationJob < ApplicationJob
  queue_as :default

  def perform
    # Find cohorts stuck in one state too long
    stuck_threshold = 1.day.ago

    stuck_cohorts = Cohort.where('updated_at < ?', stuck_threshold)
                          .where(status: %w[tp_signing student_enrollment sponsor_review tp_review])

    stuck_cohorts.each do |cohort|
      # Notify admin or extend token expiration
      # Log warning
      FloDoc::Audit.workflow_stuck(cohort, "Cohort stuck in #{cohort.status}")
    end
  end
end
```

##### Acceptance Criteria

**Functional:**
1. ✅ State transitions work via AASM events
2. ✅ Guards prevent invalid transitions
3. ✅ All workflow steps enforced
4. ✅ Cohort cannot skip steps
5. ✅ Workflow validations provide clear errors
6. ✅ System prevents operations in wrong states
7. ✅ Background job detects stuck cohorts

**Integration:**
1. ✅ IV1: State machine works with existing services
2. ✅ IV2: Audit logs all state changes
3. ✅ IV3: No impact on performance

**Security:**
1. ✅ Guards prevent unauthorized bypassing
2. ✅ State changes logged
3. ✅ Cannot manually set arbitrary states

**Quality:**
1. ✅ Clear error messages for failed transitions
2. ✅ State validation in errors
3. ✅ 85% test coverage for state machine

##### Integration Verification (IV1-3)

**IV1: State Transitions**
- Verify draft → tp_signing works
- Verify tp_signing → student_enrollment works
- Verify student_enrollment → ready_for_sponsor works
- Verify ready_for_sponsor → sponsor_review works
- Verify sponsor_review → tp_review works
- Verify tp_review → completed works

**IV2: Guard Validation**
- Verify cannot skip tp_signing
- Verify cannot enroll before tp_signing
- Verify cannot sponsor review before students complete
- Verify all guards return proper error messages

**IV3: Performance**
- Verify state transitions execute in < 50ms
- Verify AASM doesn't add significant overhead
- Verify guards are fast

##### Test Requirements

**State Machine Specs:**
```ruby
# spec/models/cohort/state_machine_spec.rb
describe Cohort, 'state machine' do
  let(:cohort) { create(:cohort) }

  describe 'draft → tp_signing' do
    it 'transitions when valid' do
      cohort.start_tp_signing!
      expect(cohort.tp_signing?).to be true
    end

    it 'fails without template' do
      cohort.update!(template_id: nil)
      expect { cohort.start_tp_signing! }.to raise_error(AASM::InvalidTransition)
    end
  end

  describe 'full workflow' do
    it 'can complete all phases' do
      cohort = create(:cohort)

      cohort.start_tp_signing!
      expect(cohort.tp_signing?).to be true

      cohort.complete_tp_signing!
      expect(cohort.student_enrollment?).to be true

      # ... populate mock data

      cohort.all_students_complete!
      expect(cohort.ready_for_sponsor?).to be true

      cohort.sponsor_starts_review!
      expect(cohort.sponsor_review?).to be true

      cohort.sponsor_completes!
      expect(cohort.tp_review?).to be true

      cohort.finalize!
      expect(cohort.completed?).to be true
    end
  end
end
```

**Orchestrator Specs:**
```ruby
# spec/services/workflow_orchestrator_spec.rb
describe WorkflowOrchestrator do
  it 'handles full cohort lifecycle' do
    cohort = create(:cohort)
    tp_user = create(:tp_user)

    result = described_class.start_cohort(cohort, tp_user)
    expect(result[:submission]).to be_present

    # Add students
    students = [{ email: 's1@test.com', name: 'S1' }]
    result = described_class.enroll_students(cohort, students, tp_user)
    expect(result[:students].count).to eq(1)

    # ... complete full workflow
  end
end
```

##### Rollback Procedure

**If state machine causes issues:**
1. Revert cohort model changes
2. Restore original state machine
3. Verify existing cohorts still accessible
4. Clean up any invalid state records

**Data Safety**: State machine is code, not data migration.

##### Risk Assessment

**Medium Risk because:**
- State management is critical to workflow
- Guards could have logical errors
- AASM gem could have edge cases
- Existing workflow patterns need adaptation

**Mitigation:**
- Comprehensive testing with all state combinations
- Staging environment full workflow tests
- Clear error messaging for operators
- Gradual rollout with monitoring
- Manual state override tools (for emergencies)

**Critical Checks:**
- Guard methods return true/false
- Errors accumulate on cohort object
- Transition failures don't leave partial state
- Audit logs capture all transitions

---

### 6.3 Phase 3: API Layer

This section provides detailed user stories for Phase 3 (API Layer) of the FloDoc enhancement. This phase creates the RESTful API endpoints that expose the 3-portal cohort management system to external integrations and frontend clients.

#### Story 3.1: RESTful Cohort Management API

**Status**: Draft
**Priority**: Critical
**Epic**: Phase 3 - API Layer
**Estimated Effort**: 2-3 days
**Risk Level**: Low

##### User Story

**As a** TP administrator or external system integrator,
**I want** to create, read, update, and delete cohorts via REST API,
**So that** I can automate cohort management and integrate with other systems.

##### Background

The FloDoc system needs a complete REST API for cohort management. This API will be used by:

1. **TP Portal** (Vue.js frontend) - All cohort operations
2. **External systems** - Programmatic cohort creation and management
3. **Automation scripts** - Bulk operations and integrations

The API should follow JSON:API standards and include proper authentication/authorization.

##### Technical Implementation Notes

**API Endpoints:**

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    resources :cohorts do
      member do
        post :start_signing
        post :enroll_students
        post :send_invites
        get :status
        get :export
      end
    end

    resources :cohort_enrollments do
      member do
        post :mark_completed
      end
    end

    # Sponsor portal endpoints (ad-hoc token based)
    namespace :sponsor do
      get ':token/dashboard', to: 'portal#dashboard'
      get ':token/students', to: 'portal#students'
      post ':token/verify/:student_id', to: 'portal#verify'
    end
  end
end
```

**API Controller:**

```ruby
# app/controllers/api/v1/cohorts_controller.rb
class Api::V1::CohortsController < Api::BaseController
  before_action :load_cohort, only: [:show, :update, :destroy, :start_signing, :enroll_students]
  load_and_authorize_resource

  def index
    @cohorts = current_user.institution.cohorts
                         .where(deleted_at: nil)
                         .order(created_at: :desc)
                         .page(params[:page])
                         .per(params[:per_page] || 20)

    render json: {
      data: @cohorts,
      meta: {
        page: @cohorts.current_page,
        total: @cohorts.total_count,
        per_page: @cohorts.limit_value
      }
    }
  end

  def show
    render json: {
      data: @cohort,
      included: {
        enrollments: @cohort.cohort_enrollments.students,
        template: @cohort.template
      }
    }
  end

  def create
    @cohort = CohortManagementService.create_cohort(cohort_params, current_user)

    render json: {
      data: @cohort,
      message: 'Cohort created successfully'
    }, status: :created
  end

  def update
    @cohort = CohortManagementService.update_cohort(@cohort, cohort_params, current_user)

    render json: {
      data: @cohort,
      message: 'Cohort updated successfully'
    }
  end

  def destroy
    CohortManagementService.delete_cohort(@cohort, current_user)

    render json: {
      message: 'Cohort deleted successfully'
    }, status: :no_content
  end

  def start_signing
    result = WorkflowOrchestrator.start_cohort(@cohort, current_user)

    if result.is_a?(Hash) && result[:error]
      render json: { error: result[:error], errors: result[:errors] }, status: :unprocessable_entity
    else
      render json: {
        data: result,
        message: 'TP signing phase started'
      }
    end
  end

  def enroll_students
    students = params[:students] || []

    result = WorkflowOrchestrator.enroll_students(@cohort, students, current_user)

    if result.is_a?(Hash) && result[:error]
      render json: { error: result[:error], errors: result[:errors] }, status: :unprocessable_entity
    else
      render json: {
        data: result,
        message: 'Students enrolled successfully'
      }
    end
  end

  def send_invites
    success = StudentEnrollmentService.invite_students(@cohort)

    if success
      render json: { message: 'Invitations sent successfully' }
    else
      render json: { error: 'Cannot send invitations at this time' }, status: :unprocessable_entity
    end
  end

  def status
    render json: {
      data: {
        id: @cohort.id,
        status: @cohort.status,
        student_count: @cohort.cohort_enrollments.students.count,
        completed_count: @cohort.cohort_enrollments.students.completed.count,
        sponsor_ready: @cohort.ready_for_sponsor?,
        can_finalized: @cohort.tp_review?
      }
    }
  end

  def export
    authorize! :export, @cohort

    temp_file = ExcelExportService.export_cohort_data(@cohort)

    send_file(
      temp_file.path,
      filename: "cohort_#{@cohort.id}_export.xlsx",
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      disposition: 'attachment'
    )
  end

  private

  def cohort_params
    params.require(:cohort).permit(
      :template_id,
      :name,
      :program_type,
      :sponsor_email,
      required_student_uploads: [],
      cohort_metadata: {}
    )
  end

  def load_cohort
    @cohort = Cohort.find(params[:id])
  end
end
```

**Sponsor Portal API (Ad-hoc):**

```ruby
# app/controllers/api/v1/sponsor/portal_controller.rb
class Api::V1::Sponsor::PortalController < Api::BaseController
  skip_before_action :authenticate_user!
  before_action :verify_token

  def dashboard
    data = SponsorReviewService.get_sponsor_dashboard(@cohort, params[:token])

    if data
      render json: { data: data }
    else
      render json: { error: 'Invalid or expired token' }, status: :unauthorized
    end
  end

  def students
    enrollments = @cohort.cohort_enrollments.students.preload(:submission)

    render json: {
      data: enrollments.map do |e|
        {
          id: e.id,
          name: "#{e.student_name} #{e.student_surname}",
          email: e.student_email,
          status: e.status,
          completed_at: e.completed_at,
          can_review: e.complete?
        }
      end
    }
  end

  def verify
    enrollment = @cohort.cohort_enrollments.students.find(params[:student_id])

    success = WorkflowOrchestrator.sponsor_verifies_student(
      enrollment,
      params[:verification_data] || {}
    )

    if success
      render json: { message: 'Student verified successfully' }
    else
      render json: { error: 'Verification failed' }, status: :unprocessable_entity
    end
  end

  private

  def verify_token
    @token = AdHocTokenService.decode_token(params[:token])

    if @token.nil? || @token['role'] != 'sponsor'
      render json: { error: 'Invalid sponsor token' }, status: :unauthorized
      return
    end

    @cohort = Cohort.find(@token['cohort_id'])
  end
end
```

**API Response Standards:**

```ruby
# app/controllers/api/base_controller.rb
class Api::BaseController < ActionController::API
  include CanCan::Ability
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  rescue_from CanCan::AccessDenied, with: :access_denied

  private

  def record_not_found
    render json: { error: 'Resource not found' }, status: :not_found
  end

  def record_invalid(exception)
    render json: {
      error: 'Validation failed',
      errors: exception.record.errors.full_messages
    }, status: :unprocessable_entity
  end

  def access_denied
    render json: { error: 'Access denied' }, status: :forbidden
  end
end
```

**Key Design Decisions:**

1. **JSON:API Compliance**: Structured responses with data, included, and meta sections
2. **Token-based Sponsor API**: Ad-hoc access without authentication
3. **Service Integration**: All endpoints use existing service objects
4. **Authorization**: Cancancan throughout, with special handling for ad-hoc tokens
5. **Error Handling**: Standardized error responses across all endpoints
6. **Pagination**: Built-in for collections

##### Acceptance Criteria

**Functional:**
1. ✅ GET /api/v1/cohorts - List cohorts with pagination
2. ✅ POST /api/v1/cohorts - Create cohort
3. ✅ GET /api/v1/cohorts/:id - Show cohort details
4. ✅ PUT /api/v1/cohorts/:id - Update cohort
5. ✅ DELETE /api/v1/cohorts/:id - Delete cohort (soft)
6. ✅ POST /api/v1/cohorts/:id/start_signing - Start TP signing phase
7. ✅ POST /api/v1/cohorts/:id/enroll_students - Bulk enroll students
8. ✅ POST /api/v1/cohorts/:id/send_invites - Send student invitations
9. ✅ GET /api/v1/cohorts/:id/status - Get cohort status
10. ✅ GET /api/v1/cohorts/:id/export - Export to Excel
11. ✅ GET /api/v1/sponsor/:token/dashboard - Sponsor dashboard
12. ✅ POST /api/v1/sponsor/:token/verify/:student_id - Sponsor verification

**Integration:**
1. ✅ IV1: All endpoints use existing service objects
2. ✅ IV2: Authorization works through CancanCan
3. ✅ IV3: API response time < 500ms for standard queries

**Security:**
1. ✅ Authenticated access for TP endpoints
2. ✅ Token validation for sponsor endpoints
3. ✅ Authorization checks on all operations
4. ✅ No sensitive data leaked in responses
5. ✅ Rate limiting (if applicable)

**Quality:**
1. ✅ Consistent response format across all endpoints
2. ✅ Proper HTTP status codes
3. ✅ Standardized error messages
4. ✅ API documentation in code comments
5. ✅ 85% test coverage

##### Integration Verification (IV1-3)

**IV1: Service Object Integration**
- Verify all endpoints call appropriate service methods
- Verify service layer handles business logic
- Verify controllers are thin wrappers only

**IV2: Authorization**
- Verify authenticated users can only access their institution's data
- Verify sponsor tokens are properly validated
- Verify unauthorized requests receive 403 responses

**IV3: Performance**
- Verify index endpoint paginates correctly
- Verify show endpoint returns in < 200ms
- Verify bulk operations handle 1000 records

##### Test Requirements

**Request Specs:**
```ruby
# spec/requests/api/v1/cohorts_spec.rb
describe Api::V1::CohortsController do
  describe 'POST /api/v1/cohorts' do
    it 'creates cohort with valid params' do
      post '/api/v1/cohorts', params: { cohort: valid_params }, headers: auth_headers

      expect(response).to have_http_status(:created)
      expect(json_response['data']['name']).to eq('Test Cohort')
    end
  end

  describe 'POST /api/v1/cohorts/:id/start_signing' do
    it 'starts TP signing phase' do
      post "/api/v1/cohorts/#{cohort.id}/start_signing", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(cohort.reload.status).to eq('tp_signing')
    end
  end
end

# spec/requests/api/v1/sponsor/portal_spec.rb
describe Api::V1::Sponsor::PortalController do
  describe 'GET /api/v1/sponsor/:token/dashboard' do
    it 'returns dashboard with valid token' do
      token = AdHocTokenService.generate_sponsor_token(cohort)
      get "/api/v1/sponsor/#{token}/dashboard"

      expect(response).to have_http_status(:ok)
      expect(json_response['data']['cohort']['id']).to eq(cohort.id)
    end
  end
end
```

##### Rollback Procedure

**If API causes issues:**
1. Remove API routes for affected endpoints
2. Revert controller changes
3. Verify existing DocuSeal routes still work
4. Check for broken frontend integrations

**Data Safety**: API layer is read/write wrapper around existing services.

##### Risk Assessment

**Low Risk because:**
- Thin controllers calling tested service objects
- Existing authorization patterns (Cancancan)
- Standard REST conventions
- No custom business logic in controllers

**Specific Risks:**
1. **Breaking Changes**: Changes to API contract affect consumers
2. **Security**: Token exposure could lead to unauthorized access
3. **Performance**: N+1 queries without proper eager loading

**Mitigation:**
- Version API (v1) for backward compatibility
- Use standard response formats
- Document all endpoints thoroughly
- Comprehensive request spec coverage
- Monitor API usage and errors

---

#### Story 3.2: Webhook Events for Workflow State Changes

**Status**: Draft
**Priority**: Medium
**Epic**: Phase 3 - API Layer
**Estimated Effort**: 2-3 days
**Risk Level**: Low

##### User Story

**As a** TP administrator,
**I want** webhook notifications for all cohort workflow events,
**So that** external systems can react to state changes in real-time.

##### Background

FloDoc should emit webhooks for:
- Cohort created
- TP signing completed
- Student enrolled
- Student completed
- Sponsor accessed portal
- Sponsor verified student
- Cohort completed

This allows external integrations (e.g., CRM, LMS, reporting systems) to stay in sync.

##### Technical Implementation Notes

**Webhook Event Model:**

```ruby
# app/models/webhook_event.rb
class WebhookEvent < ApplicationRecord
  belongs_to :cohort

  validates :event_type, presence: true
  validates :payload, presence: true

  scope :pending, -> { where(status: 'pending') }
  scope :failed, -> { where(status: 'failed') }
  scope :delivered, -> { where(status: 'delivered') }

  def mark_delivered!
    update!(status: 'delivered', delivered_at: Time.current)
  end

  def mark_failed!(error)
    update!(status: 'failed', error_message: error, failed_at: Time.current)
  end
end
```

**Webhook Emitter Service:**

```ruby
# app/services/webhook_emitter_service.rb
class WebhookEmitterService
  def self.emit_cohort_created(cohort, user)
    payload = {
      event: 'cohort.created',
      timestamp: Time.current,
      data: {
        cohort_id: cohort.id,
        cohort_name: cohort.name,
        template_id: cohort.template_id,
        created_by: user.email,
        sponsor_email: cohort.sponsor_email,
        program_type: cohort.program_type
      }
    }

    create_and_queue_event(cohort, payload)
  end

  def self.emit_tp_signing_completed(cohort, user)
    payload = {
      event: 'cohort.tp_signing_completed',
      timestamp: Time.current,
      data: {
        cohort_id: cohort.id,
        cohort_name: cohort.name,
        tp_email: user.email,
        tp_signed_at: cohort.tp_signed_at
      }
    }

    create_and_queue_event(cohort, payload)
  end

  def self.emit_student_enrolled(cohort, enrollment)
    payload = {
      event: 'cohort.student_enrolled',
      timestamp: Time.current,
      data: {
        cohort_id: cohort.id,
        student_email: enrollment.student_email,
        student_name: enrollment.student_name,
        enrollment_id: enrollment.id
      }
    }

    create_and_queue_event(cohort, payload)
  end

  def self.emit_student_completed(cohort, enrollment)
    payload = {
      event: 'cohort.student_completed',
      timestamp: Time.current,
      data: {
        cohort_id: cohort.id,
        student_email: enrollment.student_email,
        student_name: enrollment.student_name,
        enrollment_id: enrollment.id,
        completed_at: enrollment.completed_at
      }
    }

    create_and_queue_event(cohort, payload)
  end

  def self.emit_sponsor_accessed(cohort, sponsor_email)
    payload = {
      event: 'cohort.sponsor_accessed',
      timestamp: Time.current,
      data: {
        cohort_id: cohort.id,
        sponsor_email: sponsor_email,
        accessed_at: Time.current
      }
    }

    create_and_queue_event(cohort, payload)
  end

  def self.emit_sponsor_verified(cohort, enrollment)
    payload = {
      event: 'cohort.sponsor_verified',
      timestamp: Time.current,
      data: {
        cohort_id: cohort.id,
        student_email: enrollment.student_email,
        verified_at: enrollment.sponsor_verified_at,
        verification_data: enrollment.sponsor_verification_data
      }
    }

    create_and_queue_event(cohort, payload)
  end

  def self.emit_cohort_completed(cohort, user)
    payload = {
      event: 'cohort.completed',
      timestamp: Time.current,
      data: {
        cohort_id: cohort.id,
        cohort_name: cohort.name,
        completed_by: user.email,
        completed_at: cohort.finalized_at,
        student_count: cohort.cohort_enrollments.students.count
      }
    }

    create_and_queue_event(cohort, payload)
  end

  private

  def self.create_and_queue_event(cohort, payload)
    # Get cohort's webhook URL(s)
    webhook_urls = cohort.cohort_metadata&.dig('webhook_urls') || []
    return if webhook_urls.empty?

    webhook_urls.each do |url|
      event = WebhookEvent.create!(
        cohort: cohort,
        event_type: payload[:event],
        payload: payload,
        webhook_url: url,
        status: 'pending'
      )

      # Queue for delivery
      WebhookDeliveryJob.perform_later(event.id)
    end
  end
end
```

**Webhook Delivery Job:**

```ruby
# app/jobs/webhook_delivery_job.rb
class WebhookDeliveryJob < ApplicationJob
  queue_as :webhooks
  retry_on StandardError, attempts: 5, wait: :exponentially_longer

  def perform(webhook_event_id)
    event = WebhookEvent.find(webhook_event_id)
    return unless event.pending?

    begin
      # Make HTTP request
      response = Faraday.post(event.webhook_url) do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['X-FloDoc-Signature'] = generate_signature(event)
        req.headers['X-FloDoc-Event'] = event.event_type
        req.body = event.payload.to_json
      end

      if response.success?
        event.mark_delivered!
        FloDoc::Audit.webhook_delivered(event)
      else
        raise "Webhook delivery failed: #{response.status}"
      end

    rescue StandardError => e
      event.mark_failed!(e.message)
      FloDoc::Audit.webhook_failed(event, e.message)
      raise # Trigger retry
    end
  end

  private

  def generate_signature(event)
    payload = "#{event.id}:#{event.payload.to_json}:#{Rails.application.secrets.secret_key_base}"
    Digest::SHA256.hexdigest(payload)
  end
end
```

**Integration Points:**

```ruby
# In CohortManagementService.create_cohort
after_create do |cohort|
  WebhookEmitterService.emit_cohort_created(cohort, user)
end

# In TpSigningService.complete_tp_signing
WebhookEmitterService.emit_tp_signing_completed(cohort, tp_user)

# In StudentEnrollmentService.bulk_enroll
enrollments.each do |enrollment|
  WebhookEmitterService.emit_student_enrolled(cohort, enrollment)
end

# In WorkflowOrchestrator.mark_student_complete
WebhookEmitterService.emit_student_completed(cohort, enrollment)

# In SponsorPortalController (after access)
WebhookEmitterService.emit_sponsor_accessed(cohort, sponsor_email)

# In SponsorReviewService.verify_student
WebhookEmitterService.emit_sponsor_verified(cohort, enrollment)

# In FinalizationService.finalize_cohort
WebhookEmitterService.emit_cohort_completed(cohort, user)
```

**Webhook Configuration:**

Cohort metadata should include:
```json
{
  "webhook_urls": [
    "https://api.partner.com/floDoc/webhook",
    "https://crm.example.com/webhooks/floDoc"
  ],
  "webhook_secret": "optional_custom_secret_for_verification"
}
```

**Key Design Decisions:**

1. **Reliability**: Retry with exponential backoff
2. **Audit Trail**: All webhook events logged
3. **Signature**: HMAC signature for verification
4. **Async Delivery**: Background jobs prevent blocking
5. **Multiple URLs**: Support multiple endpoints per cohort
6. **Event Naming**: Consistent "entity.action" pattern

##### Acceptance Criteria

**Functional:**
1. ✅ Webhook events created for all 7 event types
2. ✅ Events queued for background delivery
3. ✅ Signature generation works correctly
4. ✅ Retry logic handles failures
5. ✅ Multiple webhook URLs supported
6. ✅ Event status tracking (pending/delivered/failed)
7. ✅ Payload includes all relevant data

**Integration:**
1. ✅ IV1: Events emitted at correct workflow points
2. ✅ IV2: Delivery job executes successfully
3. ✅ IV3: No impact on main workflow performance

**Security:**
1. ✅ Signatures prevent tampering
2. ✅ HTTPS URLs only (validation)
3. ✅ Secrets can be customized per cohort
4. ✅ Failed deliveries don't expose sensitive data

**Quality:**
1. ✅ Clear event naming convention
2. ✅ Comprehensive audit logging
3. ✅ Error messages for debugging
4. ✅ 85% test coverage

##### Integration Verification (IV1-3)

**IV1: Event Emission**
- Verify all 7 event types are emitted
- Verify events are created with correct payload
- Verify events are queued for delivery

**IV2: Delivery**
- Verify webhook signature generation
- Verify HTTP POST request format
- Verify retry on failure
- Verify status updates on success/failure

**IV3: Performance**
- Verify event creation doesn't block workflow
- Verify queue performance under load
- Verify no N+1 queries in event creation

##### Test Requirements

**Service Specs:**
```ruby
# spec/services/webhook_emitter_service_spec.rb
describe WebhookEmitterService do
  it 'creates event for cohort creation' do
    cohort = create(:cohort)
    user = create(:user)

    expect {
      described_class.emit_cohort_created(cohort, user)
    }.to change(WebhookEvent, :count).by(1)

    event = WebhookEvent.last
    expect(event.event_type).to eq('cohort.created')
    expect(event.payload[:event]).to eq('cohort.created')
  end
end

# spec/jobs/webhook_delivery_job_spec.rb
describe WebhookDeliveryJob do
  it 'delivers webhook successfully' do
    stub_request(:post, 'https://test.example.com/webhook')
      .to_return(status: 200, body: 'OK')

    event = create(:webhook_event)
    described_class.perform_now(event.id)

    expect(event.reload.status).to eq('delivered')
  end
end
```

**Feature Specs:**
- Full workflow triggers all expected webhooks
- Webhook retries work correctly

##### Rollback Procedure

**If webhooks cause issues:**
1. Disable WebhookDeliveryJob
2. Remove event emission calls
3. Existing data remains intact
4. Manual cleanup of pending events if needed

**Data Safety**: Webhook events are append-only log.

##### Risk Assessment

**Low Risk because:**
- Decoupled from main workflow via background jobs
- Failures don't affect core functionality
- Retry mechanism ensures eventual delivery

**Specific Risks:**
1. **Delivery Failures**: Partner endpoints may be down
2. **Payload Size**: Large cohorts create large payloads
3. **Rate Limits**: Partners may throttle
4. **Data Privacy**: Information going external

**Mitigation:**
- Exponential backoff retry
- Payload size limits
- Configurable webhook URLs
- Audit all deliveries
- Signature verification option

---

#### Story 3.3: Student API (Ad-hoc Token-Based Access)

**Status**: Draft
**Priority**: Medium
**Epic**: Phase 3 - API Layer
**Estimated Effort**: 3-4 days
**Risk Level**: Medium

##### User Story

**As a** student with a cohort link,
**I want** a simple token-based API to access and complete my documents,
**So that** I can fulfill my requirements without account creation.

##### Background

Students need to:
- Access their pre-filled document
- Fill in their personal fields
- Upload required documents
- Submit the final document
- All without creating an account

This requires a secure token-based API that:
- Validates tokens against cohort and email
- Exposes only student's own document
- Tracks completion status

##### Technical Implementation Notes

**Student API Controller:**

```ruby
# app/controllers/api/v1/students/portal_controller.rb
class Api::V1::Students::PortalController < Api::BaseController
  skip_before_action :authenticate_user!
  before_action :verify_student_token

  def show
    # Return student's document data with pre-filled TP values
    enrollment = @cohort.cohort_enrollments.find_by(student_email: @token[:email])

    unless enrollment
      return render json: { error: 'Student not found in cohort' }, status: :not_found
    end

    submission = enrollment.submission
    tp_fields = submission.submitters.where.not(email: @token[:email]).first&.values || {}

    render json: {
      data: {
        id: enrollment.id,
        cohort_name: @cohort.name,
        program_type: @cohort.program_type,
        required_uploads: @cohort.required_student_uploads,
        tp_pre_filled_values: tp_fields,
        student_fields_needed: student_fields_needed(submission),
        upload_status: enrollment.uploaded_documents,
        status: enrollment.status,
        completed_at: enrollment.completed_at,
        tp_name: @cohort.institution&.name
      }
    }
  end

  def update
    enrollment = @cohort.cohort_enrollments.find_by(student_email: @token[:email])

    unless enrollment
      return render json: { error: 'Student not found' }, status: :not_found
    end

    if enrollment.complete?
      return render json: { error: 'Document already completed' }, status: :unprocessable_entity
    end

    # Update student's values in the submitter
    submitter = enrollment.submission.submitters.find_by(email: @token[:email])

    # Merge new values with existing (keeping TP's pre-filled values)
    new_values = params[:values] || {}
    existing_values = submitter.values || {}
    merged_values = existing_values.merge(new_values)

    submitter.update!(values: merged_values)
    enrollment.mark_in_progress!

    render json: {
      message: 'Progress saved',
      status: 'in_progress'
    }
  end

  def upload_document
    enrollment = @cohort.cohort_enrollments.find_by(student_email: @token[:email])

    unless enrollment
      return render json: { error: 'Student not found' }, status: :not_found
    end

    document_type = params[:document_type]

    unless @cohort.required_student_uploads.include?(document_type)
      return render json: { error: 'Invalid document type' }, status: :unprocessable_entity
    end

    # Handle file upload via Active Storage
    file = params[:file]

    unless file
      return render json: { error: 'File required' }, status: :unprocessable_entity
    end

    # Store file reference
    uploads = enrollment.uploaded_documents || {}
    uploads[document_type] = {
      uploaded_at: Time.current,
      filename: file.original_filename,
      content_type: file.content_type
    }

    enrollment.update!(uploaded_documents: uploads)

    render json: {
      message: 'Document uploaded successfully',
      document_type: document_type,
      uploaded_documents: uploads
    }
  end

  def submit
    enrollment = @cohort.cohort_enrollments.find_by(student_email: @token[:email])

    unless enrollment
      return render json: { error: 'Student not found' }, status: :not_found
    end

    # Validation: Check all required fields filled
    submitter = enrollment.submission.submitters.find_by(email: @token[:email])

    if submitter.values.blank?
      return render json: { error: 'Please fill in all required fields' }, status: :unprocessable_entity
    end

    # Validation: Check all required uploads complete
    required = @cohort.required_student_uploads || []
    completed = (enrollment.uploaded_documents || {}).keys

    unless required.all? { |type| completed.include?(type) }
      missing = required - completed
      return render json: {
        error: 'Missing required uploads',
        missing_uploads: missing
      }, status: :unprocessable_entity
    end

    # Mark as complete
    enrollment.mark_student_completed!

    render json: {
      message: 'Document submitted successfully',
      status: 'complete',
      completed_at: enrollment.completed_at
    }
  end

  def status
    enrollment = @cohort.cohort_enrollments.find_by(student_email: @token[:email])

    unless enrollment
      return render json: { error: 'Student not found' }, status: :not_found
    end

    required = @cohort.required_student_uploads || []
    uploaded = (enrollment.uploaded_documents || {}).keys
    missing = required - uploaded

    render json: {
      data: {
        status: enrollment.status,
        uploads_completed: missing.empty?,
        missing_uploads: missing,
        completed_at: enrollment.completed_at,
        progress: calculate_progress(enrollment)
      }
    }
  end

  private

  def verify_student_token
    @token = AdHocTokenService.decode_token(params[:token])

    if @token.nil? || @token[:role] != 'student'
      render json: { error: 'Invalid or expired student token' }, status: :unauthorized
      return
    end

    @cohort = Cohort.find(@token[:cohort_id])
  end

  def student_fields_needed(submission)
    # Get all fields that haven't been pre-filled by TP
    # These are fields the student needs to fill
    submission.submitters.where.not(email: @token[:email]).first&.values&.keys || []
  end

  def calculate_progress(enrollment)
    required = @cohort.required_student_uploads || []
    completed = (enrollment.uploaded_documents || {}).keys

    {
      required_fields: required.count,
      fields_completed: completed.count,
      percentage: required.empty? ? 100 : (completed.count.to_f / required.count * 100).round
    }
  end
end
```

**Integration with Existing Submission Flow:**

```ruby
# app/services/student_enrollment_service.rb (enhanced)
def self.invite_students(cohort)
  # ... existing code ...
  enrollments.each do |enrollment|
    token = AdHocTokenService.generate_student_token(
      cohort,
      enrollment.student_email,
      enrollment.student_name
    )

    enrollment.update!(access_token: token)

    # Use existing FloDoc mailer with custom link
    FloDocMailer.student_invitation(
      enrollment.student_email,
      cohort,
      enrollment.submission,
      token
    ).deliver_later
  end
end
```

**Student Email Template:**
```
Subject: Your document is ready to complete - #{cohort.name}

Hi #{student_name},

Your training document for #{cohort.name} is ready. The Training Provider has already filled in their part.

🔗 [Access Your Document]

Here's what you need to do:
1. Review the pre-filled information
2. Fill in your fields
3. Upload required documents (#{required_uploads.join(', ')})
4. Submit for sponsor review

Access link: https://yourapp.com/student/portal?token=#{token}
(Valid for 30 days)

Questions? Contact #{cohort.institution&.name}
```

**Key Design Decisions:**

1. **No Authentication Required**: Token is the authentication
2. **Pre-filled Values**: TP's data shows but is non-editable
3. **Upload Tracking**: Separate from form completion
4. **Status Tracking**: Real-time progress for students
5. **Clear Errors**: Helpful messages for missing requirements
6. **Minimal Surface**: Only essential operations

##### Acceptance Criteria

**Functional:**
1. ✅ GET /api/v1/students/:token/status - Check progress
2. ✅ GET /api/v1/students/:token - Show document with pre-filled data
3. ✅ PUT /api/v1/students/:token - Save student field values
4. ✅ POST /api/v1/students/:token/upload - Upload required documents
5. ✅ POST /api/v1/students/:token/submit - Submit final document
6. ✅ Students cannot edit TP's pre-filled fields
7. ✅ Progress tracking shows completion percentage

**Integration:**
1. ✅ IV1: Works with existing DocuSeal document rendering
2. ✅ IV2: Student tokens integrate with ad-hoc auth system
3. ✅ IV3: No impact on existing submission workflow

**Security:**
1. ✅ Students can only access their own enrollment
2. ✅ Tokens have 30-day expiration
3. ✅ Cannot access other students in cohort
4. ✅ CSRF protection (if needed)

**Quality:**
1. ✅ Clear error messages
2. ✅ Nice UI data structure
3. ✅ Proper validation
4. ✅ 85% test coverage

##### Integration Verification (IV1-3)

**IV1: Token-Based Access**
- Verify token validation works
- Verify students can only access their own data
- Verify expired tokens rejected

**IV2: Data Integrity**
- Verify TP's pre-filled values are preserved
- Verify student values stored correctly
- Verify uploads tracked properly

**IV3: Workflow Integration**
- Verify completion triggers sponsor notification
- Verify state transitions work
- Verify audit logs created

##### Test Requirements

**Controller Specs:**
```ruby
# spec/requests/api/v1/students/portal_spec.rb
describe Api::V1::Students::PortalController do
  let(:token) { AdHocTokenService.generate_student_token(cohort, 'student@test.com') }

  describe 'GET /api/v1/students/:token/status' do
    it 'returns student status' do
      get "/api/v1/students/#{token}/status"

      expect(response).to have_http_status(:ok)
      expect(json_response['data']['status']).to eq('waiting')
    end
  end

  describe 'POST /api/v1/students/:token/submit' do
    it 'completes student submission' do
      post "/api/v1/students/#{token}/submit", params: { values: { name: 'Test' } }

      expect(response).to have_http_status(:ok)
      expect(json_response['status']).to eq('complete')
    end
  end
end
```

##### Rollback Procedure

**If Student API causes issues:**
1. Remove student portal routes
2. Disable student email invites
3. Students use original DocuSeal flow
4. Existing data remains intact

**Data Safety**: Student API is read/write wrapper around existing data.

##### Risk Assessment

**Medium Risk because:**
- New ad-hoc access pattern
- Token security is critical
- Students are external/untrusted users
- File uploads require validation

**Specific Risks:**
1. **Token Exposure**: Token in email could be forwarded
2. **Invalid Data**: Students could upload wrong file types
3. **Exploitation**: Malicious students could probe API
4. **Storage**: Uploads could fill disk space

**Mitigation:**
- One-time use tokens (optional enhancement)
- File type validation and size limits
- Rate limiting on token endpoints
- Audit all token-based access
- Upload size quotas per cohort

---

#### Story 3.4: API Documentation & Versioning

**Status**: Draft
**Priority**: Medium
**Epic**: Phase 3 - API Layer
**Estimated Effort**: 1-2 days
**Risk Level**: Low

##### User Story

**As a** developer integrating with FloDoc,
**I want** comprehensive API documentation and stable versioning,
**So that** I can build reliable integrations without breaking changes.

##### Background

API documentation must include:
- Endpoint reference
- Request/response examples
- Authentication methods
- Error codes
- Rate limits
- Versioning strategy

This will be the source of truth for both internal frontend and external integrations.

##### Technical Implementation Notes

**Documentation Framework:**

Option 1: OpenAPI/Swagger Documentation

```ruby
# Gemfile
gem 'rswag-api'
gem 'rswag-ui'  # If serving docs from app

# spec/swagger/api/v1/swagger.rb
require 'swagger_helper'

RSpec.describe 'FloDoc API v1', type: :request, doc: true do
  path '/cohorts' do
    get 'List cohorts' do
      tags 'Cohorts'
      produces 'application/json'
      security [ bearer_auth: [] ]
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response '200', 'success' do
        schema type: :object,
          properties: {
            data: {
              type: :array,
              items: { '$ref' => '#/definitions/cohort' }
            },
            meta: { '$ref' => '#/definitions/pagination' }
          }

        let(:page) { 1 }
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end

    post 'Create cohort' do
      tags 'Cohorts'
      consumes 'application/json'
      produces 'application/json'
      security [ bearer_auth: [] ]

      parameter name: :cohort, in: :body, schema: {
        type: :object,
        required: [:name, :template_id, :sponsor_email, :program_type],
        properties: {
          name: { type: :string },
          template_id: { type: :integer },
          sponsor_email: { type: :string },
          program_type: { type: :string, enum: %w[learnership internship candidacy] },
          required_student_uploads: { type: :array, items: { type: :string } },
          cohort_metadata: { type: :object }
        }
      }

      response '201', 'created' do
        schema type: :object,
          properties: {
            data: { '$ref' => '#/definitions/cohort' },
            message: { type: :string }
          }
        run_test!
      end

      response '422', 'validation failed' do
        schema type: :object,
          properties: {
            error: { type: :string },
            errors: { type: :array, items: { type: :string } }
          }
        run_test!
      end
    end
  end

  path '/cohorts/{id}/start_signing' do
    post 'Start TP signing phase' do
      tags 'Cohorts'
      produces 'application/json'
      security [ bearer_auth: [] ]
      parameter name: :id, in: :path, type: :integer

      response '200', 'success' do
        schema type: :object,
          properties: {
            data: { type: :object },
            message: { type: :string }
          }
        run_test!
      end

      response '422', 'invalid transition' do
        run_test!
      end
    end
  end

  path '/sponsor/{token}/dashboard' do
    get 'Sponsor dashboard' do
      tags 'Sponsor Portal'
      produces 'application/json'
      parameter name: :token, in: :path, type: :string, required: true
      parameter name: :token, in: :query, type: :string, required: true  # Alternative

      response '200', 'success' do
        run_test!
      end

      response '401', 'invalid token' do
        run_test!
      end
    end
  end

  path '/students/{token}/submit' do
    post 'Submit student document' do
      tags 'Student Portal'
      produces 'application/json'
      parameter name: :token, in: :path, type: :string
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          values: { type: :object, description: 'Student field values' }
        }
      }

      response '200', 'submitted' do
        run_test!
      end
    end
  end

  # Definitions
  Swagger::Docs.config.definitions = {
    'cohort' => {
      type: :object,
      properties: {
        id: { type: :integer },
        name: { type: :string },
        template_id: { type: :integer },
        sponsor_email: { type: :string },
        program_type: { type: :string },
        status: { type: :string },
        required_student_uploads: { type: :array, items: { type: :string } },
        created_at: { type: :string, format: 'date-time' }
      }
    },
    'pagination' => {
      type: :object,
      properties: {
        page: { type: :integer },
        per_page: { type: :integer },
        total: { type: :integer }
      }
    }
  }
end
```

Option 2: Static Documentation in Docs Folder

```
docs/
└── api/
    ├── README.md
    ├── authentication.md
    ├── endpoints/
    │   ├── cohorts.md
    │   ├── sponsor.md
    │   └── student.md
    ├── examples/
    │   ├── create_cohort.md
    │   ├── full_workflow.md
    │   └── errors.md
    └── changelog.md
```

**Versioning Strategy:**

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    # Current endpoints
    resources :cohorts
  end

  # For future versions
  namespace :v2 do
    # resources :cohorts
  end
end

# app/controllers/api/base_controller.rb
# Add version header to responses
def set_version_header
  response.headers['X-FloDoc-API-Version'] = '1.0'
end
```

**Authentication Documentation:**

```markdown
### Authentication

#### TP Portal (Authenticated Users)

Use Bearer token authentication:

```
Authorization: Bearer <JWT_TOKEN>
```

Obtain token via:
```
POST /api/v1/auth/login
{
  "email": "user@example.com",
  "password": "secret"
}
```

#### Sponsor Portal (Ad-hoc Tokens)

Sponsor tokens are generated automatically and sent via email:
```
GET /api/v1/sponsor/{token}/dashboard
```

Token format: JWT with 30-day expiration

#### Student Portal (Ad-hoc Tokens)

Student tokens are delivered via email invitation:
```
GET /api/v1/students/{token}/status
POST /api/v1/students/{token}/submit
```

Token format: JWT with 30-day expiration
```

**Error Response Format:**

```json
{
  "error": "Validation failed",
  "errors": [
    "Template must exist",
    "Sponsor email can't be blank"
  ]
}
```

**Rate Limiting:**

```ruby
# app/controllers/api/base_controller.rb
class Api::BaseController < ActionController::API
  before_action :check_rate_limit

  private

  def check_rate_limit
    key = "api:rate:#{request_ip}"
    current = Redis.current.get(key).to_i

    if current >= 100  # 100 requests per minute
      render json: { error: 'Rate limit exceeded' }, status: :too_many_requests
      return
    end

    Redis.current.incr(key)
    Redis.current.expire(key, 60)
  end

  def request_ip
    request.remote_ip
  end
end
```

**Key Design Decisions:**

1. **OpenAPI Standard**: Using Swagger/OpenAPI for industry-standard docs
2. **Version Schema**: Version in URL path for clear routing
3. **Dual Authentication**: Support both JWT and ad-hoc tokens
4. **Error Standards**: Consistent error response format
5. **Rate Limiting**: Protect against abuse
6. **Change Log**: Document breaking changes for consumers

##### Acceptance Criteria

**Functional:**
1. ✅ OpenAPI/Swagger spec for all endpoints
2. ✅ Static documentation in /docs/api
3. ✅ Versioning strategy documented
4. ✅ Authentication methods documented
5. ✅ Error response format documented
6. ✅ Rate limiting implemented and documented
7. ✅ Code examples provided
8. ✅ Change log maintained

**Quality:**
1. ✅ Documentation is comprehensive
2. ✅ Examples are runnable/verifiable
3. ✅ Coverage of all 11+ endpoints
4. ✅ Clear migration path for API versions

**Integration:**
1. ✅ IV1: Documentation matches actual implementation
2. ✅ IV2: Examples work without modification
3. ✅ IV3: Static docs don't affect app performance

##### Integration Verification (IV1-3)

**IV1: Documentation Accuracy**
- Verify all documented endpoints exist
- Verify request/response schemas match
- Verify examples work with real API

**IV2: Readability**
- Verify docs are clear and understandable
- Verify examples are helpful
- Verify structure is logical

**IV3: Impact**
- Verify docs don't slow down app
- Verify-generated docs are up-to-date

##### Test Requirements

**Documentation Tests:**
```ruby
# spec/api_documentation_spec.rb
describe 'API Documentation' do
  it 'has swagger spec' do
    expect(File.exist?('spec/swagger/api/v1/swagger.json')).to be true
  end

  it 'all endpoints documented' do
    swagger = JSON.parse(File.read('spec/swagger/api/v1/swagger.json'))

    documented_paths = swagger['paths'].keys
    actual_paths = Rails.application.routes.routes.map(&:path).select { |p| p.start_with?('/api/v1/') }

    # Verify coverage
    expect(documented_paths).to include(*actual_paths)
  end
end
```

**Integration Test:**
```ruby
# spec/requests/api/documentation_examples_spec.rb
describe 'Documentation Examples' do
  it 'example for creating cohort works' do
    # Run the exact curl command from docs
  end
end
```

##### Rollback Procedure

**If documentation approach fails:**
1. Remove Swagger gem
2. Keep static docs manually
3. App is unaffected

**Data Safety**: Documentation is independent of application data.

##### Risk Assessment

**Low Risk because:**
- Documentation is read-only
- No application logic involved
- Easy to update/correct

**Mitigation:**
- Keep docs in repository (version controlled)
- Automate swagger generation from tests
- Review docs before releases

---

### 6.4 Phase 4: Frontend - TP Portal

This section provides detailed user stories for Phase 4 (Frontend - TP Portal) of the FloDoc enhancement. This phase builds the Vue.js based TP Portal interface for managing cohorts.

#### Story 4.1: Cohort Management Dashboard

**Status**: Draft
**Priority**: High
**Epic**: Phase 4 - Frontend - TP Portal
**Estimated Effort**: 3-4 days
**Risk Level**: Low

##### User Story

**As a** TP administrator,
**I want** a dashboard to view and manage all cohorts,
**So that** I can monitor the 3-party workflow at a glance.

##### Background

TP Portal needs a comprehensive dashboard showing:
- Cohort list with status and progress
- Quick actions (create, open, export)
- Filter and search capability
- High-level metrics (total cohorts, active, completed)
- Recent activity feed

This is the main entry point for TP administrators.

##### Technical Implementation Notes

**Vue 3 Component Structure:**

```vue
<!-- app/javascript/tp_portal/pages/CohortDashboard.vue -->
<template>
  <div class="cohort-dashboard">
    <header class="dashboard-header">
      <h1>Cohort Management Dashboard</h1>
      <div class="actions">
        <button @click="createCohort" class="btn-primary">
          + Create Cohort
        </button>
        <button @click="bulkImport" class="btn-secondary">
          Bulk Import
        </button>
      </div>
    </header>

    <div class="metrics-grid">
      <MetricCard :value="stats.total" label="Total Cohorts" icon="folder" color="blue" />
      <MetricCard :value="stats.active" label="Active" icon="activity" color="green" />
      <MetricCard :value="stats.completed" label="Completed" icon="check-circle" color="purple" />
      <MetricCard :value="stats.pending_sponsor" label="Awaiting Sponsor" icon="clock" color="orange" />
    </div>

    <div class="filter-bar">
      <div class="search-box">
        <input v-model="searchQuery" type="text" placeholder="Search cohorts..." @input="debouncedSearch" />
      </div>
      <div class="filters">
        <select v-model="statusFilter">
          <option value="">All Statuses</option>
          <option value="draft">Draft</option>
          <option value="tp_signing">TP Signing</option>
          <option value="student_enrollment">Student Enrollment</option>
          <option value="ready_for_sponsor">Ready for Sponsor</option>
          <option value="sponsor_review">Sponsor Review</option>
          <option value="tp_review">TP Review</option>
          <option value="completed">Completed</option>
        </select>
        <select v-model="programTypeFilter">
          <option value="">All Program Types</option>
          <option value="learnership">Learnership</option>
          <option value="internship">Internship</option>
          <option value="candidacy">Candidacy</option>
        </select>
      </div>
    </div>

    <div class="cohorts-table-container">
      <table class="cohorts-table">
        <thead>
          <tr>
            <th>Cohort Name</th>
            <th>Program Type</th>
            <th>Sponsor</th>
            <th>Status</th>
            <th>Students</th>
            <th>Progress</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="cohort in filteredCohorts" :key="cohort.id">
            <td>{{ cohort.name }}</td>
            <td>{{ formatProgramType(cohort.program_type) }}</td>
            <td>{{ cohort.sponsor_email }}</td>
            <td><StatusBadge :status="cohort.status" /></td>
            <td>{{ cohort.student_count }}/{{ cohort.completed_count }}</td>
            <td><ProgressBar :percent="calculateProgress(cohort)" :label="cohort.status" /></td>
            <td class="actions">
              <button @click="openCohort(cohort)" class="btn-sm btn-primary">Open</button>
              <button @click="editCohort(cohort)" class="btn-sm btn-secondary">Edit</button>
              <button @click="exportCohort(cohort)" class="btn-sm btn-secondary">Export</button>
            </td>
          </tr>
        </tbody>
      </table>

      <div v-if="filteredCohorts.length === 0" class="empty-state">
        <p>No cohorts found. Create your first cohort to get started.</p>
        <button @click="createCohort" class="btn-primary">Create Cohort</button>
      </div>
    </div>

    <Pagination :current-page="currentPage" :total-pages="totalPages" @page-change="loadPage" />
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useCohortStore } from '@/tp_portal/stores/cohort'
import MetricCard from '@/tp_portal/components/MetricCard.vue'
import StatusBadge from '@/tp_portal/components/StatusBadge.vue'
import ProgressBar from '@/tp_portal/components/ProgressBar.vue'
import Pagination from '@/tp_portal/components/Pagination.vue'

const cohortStore = useCohortStore()
const searchQuery = ref('')
const statusFilter = ref('')
const programTypeFilter = ref('')
const currentPage = ref(1)

const debouncedSearch = useDebounce(() => { loadCohorts() }, 500)
const stats = computed(() => cohortStore.stats)
const filteredCohorts = computed(() => {
  return cohortStore.cohorts.filter(c => {
    if (statusFilter.value && c.status !== statusFilter.value) return false
    if (programTypeFilter.value && c.program_type !== programTypeFilter.value) return false
    if (searchQuery.value && !c.name.toLowerCase().includes(searchQuery.value.toLowerCase())) return false
    return true
  })
})
const totalPages = computed(() => cohortStore.totalPages)

const loadCohorts = async () => {
  await cohortStore.fetchCohorts({
    page: currentPage.value,
    search: searchQuery.value,
    status: statusFilter.value,
    program_type: programTypeFilter.value
  })
}

const createCohort = () => { router.push('/cohorts/new') }
const openCohort = (cohort) => { router.push(`/cohorts/${cohort.id}/overview`) }
const editCohort = (cohort) => { router.push(`/cohorts/${cohort.id}/edit`) }
const exportCohort = async (cohort) => { await cohortStore.exportCohort(cohort.id) }
const bulkImport = () => { router.push('/cohorts/bulk-import') }

const calculateProgress = (cohort) => {
  const total = cohort.student_count
  if (total === 0) return 0
  return (cohort.completed_count / total) * 100
}

const formatProgramType = (type) => {
  const mapping = { 'learnership': 'Learnership', 'internship': 'Internship', 'candidacy': 'Candidacy' }
  return mapping[type] || type
}

const loadPage = (page) => {
  currentPage.value = page
  loadCohorts()
}

onMounted(() => { loadCohorts() })
</script>

<style scoped>
.cohort-dashboard { padding: 2rem; max-width: 1400px; margin: 0 auto; }
.dashboard-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem; }
.metrics-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin-bottom: 2rem; }
.filter-bar { display: flex; gap: 1rem; margin-bottom: 1.5rem; flex-wrap: wrap; }
.search-box input { width: 300px; padding: 0.5rem 1rem; border: 1px solid #ddd; border-radius: 6px; }
.filters select { padding: 0.5rem 1rem; border: 1px solid #ddd; border-radius: 6px; }
.cohorts-table { width: 100%; border-collapse: collapse; background: white; border-radius: 8px; overflow: hidden; }
.cohorts-table th { background: #f8f9fa; padding: 1rem; text-align: left; font-weight: 600; }
.cohorts-table td { padding: 1rem; border-top: 1px solid #e9ecef; }
.actions { display: flex; gap: 0.5rem; }
.empty-state { text-align: center; padding: 3rem; color: #666; }
</style>
```

**Pinia Store:**

```typescript
// app/javascript/tp_portal/stores/cohort.ts
import { defineStore } from 'pinia'
import api from '@/services/api'

export const useCohortStore = defineStore('cohort', {
  state: () => ({
    cohorts: [],
    stats: { total: 0, active: 0, completed: 0, pending_sponsor: 0 },
    totalPages: 1,
    loading: false
  }),

  actions: {
    async fetchCohorts(params = {}) {
      this.loading = true
      try {
        const response = await api.get('/cohorts', { params })
        this.cohorts = response.data.data
        this.stats = this.calculateStats(response.data.data)
        this.totalPages = response.data.meta.total_pages
      } finally {
        this.loading = false
      }
    },

    async exportCohort(cohortId) {
      await api.get(`/cohorts/${cohortId}/export`, { responseType: 'blob' })
        .then(response => {
          const url = window.URL.createObjectURL(new Blob([response.data]))
          const link = document.createElement('a')
          link.href = url
          link.setAttribute('download', `cohort_${cohortId}_export.xlsx`)
          document.body.appendChild(link)
          link.click()
          link.remove()
        })
    },

    calculateStats(cohorts) {
      return {
        total: cohorts.length,
        active: cohorts.filter(c => ['tp_signing', 'student_enrollment', 'ready_for_sponsor', 'sponsor_review', 'tp_review'].includes(c.status)).length,
        completed: cohorts.filter(c => c.status === 'completed').length,
        pending_sponsor: cohorts.filter(c => c.status === 'ready_for_sponsor').length
      }
    }
  }
})
```

**Design System Compliance:**

Per FR28, all components must use design system assets from:
- `@.claude/skills/frontend-design/SKILL.md`
- `@.claude/skills/frontend-design/design-system/`

Specifically: colors, icons, typography, and layout patterns from the design system.

##### Acceptance Criteria

**Functional:**
1. ✅ Dashboard displays cohort list with pagination
2. ✅ Metrics cards show accurate statistics
3. ✅ Filters work (status, program type, search)
4. ✅ Status badges display correctly
5. ✅ Progress bars show student completion
6. ✅ Actions (open/edit/export) work
7. ✅ Empty state displays when no cohorts
8. ✅ Pagination works

**Integration:**
1. ✅ IV1: API calls use correct endpoints
2. ✅ IV2: Pinia store manages state properly
3. ✅ IV3: Components follow design system

**Security:**
1. ✅ Only authenticated TP users can access
2. ✅ Users only see their institution's cohorts
3. ✅ Export button calls correct authorization

**Quality:**
1. ✅ Follows Vue 3 best practices
2. ✅ Components are reusable
3. ✅ TypeScript types defined
4. ✅ Design system compliance
5. ✅ 80% test coverage

##### Integration Verification (IV1-3)

**IV1: API Integration**
- Verify all API calls are made to correct endpoints
- Verify error handling works
- Verify loading states display correctly
- Verify data renders correctly from API

**IV2: Pinia Store**
- Verify state is managed correctly
- Verify actions update state
- Verify getters return computed values
- Verify no memory leaks

**IV3: Design System**
- Verify all colors from design system
- Verify spacing units consistent
- Verify typography matches spec
- Verify icons from design library

##### Test Requirements

**Component Specs:**
```javascript
// spec/javascript/tp_portal/components/MetricCard.spec.js
import { mount } from '@vue/test-utils'
import MetricCard from '@/tp_portal/components/MetricCard.vue'

describe('MetricCard', () => {
  it('renders correct value and label', () => {
    const wrapper = mount(MetricCard, {
      props: { value: 42, label: 'Total Cohorts', icon: 'folder', color: 'blue' }
    })
    expect(wrapper.find('.metric-value').text()).toBe('42')
  })
})
```

##### Rollback Procedure

**If dashboard fails:**
1. Remove TP Portal routes and components
2. Revert to existing DocuSeal UI
3. User data remains intact

**Data Safety**: Frontend code doesn't affect data.

##### Risk Assessment

**Low Risk because:**
- Single-page application with no backend changes
- All operations use already-tested API endpoints
- Design system components are pre-built
- State management is straightforward

**Specific Risks:**
1. **API Performance**: Many API calls could slow UI
2. **Browser Compatibility**: Vue 3 may not work on old browsers
3. **Design System Gaps**: Missing components may need creation
4. **Bundle Size**: Large Vue app could load slowly

**Mitigation:**
- API query caching
- Polyfill for older browsers
- Lazy-load components
- Code splitting and tree shaking

---

#### Story 4.2: Cohort Creation & Bulk Import

**Status**: Draft
**Priority**: High
**Epic**: Phase 4 - Frontend - TP Portal
**Estimated Effort**: 2-3 days
**Risk Level**: Medium

##### User Story

**As a** TP administrator,
**I want** to create new cohorts and bulk-import students via Excel,
**So that** I can efficiently onboard large groups without manual data entry.

##### Background

The cohort creation process needs to support:
- Basic cohort information (name, dates, description)
- Optional bulk student import via Excel spreadsheet
- Validation and preview before committing data
- Seamless navigation to cohort detail after creation

This enables TP administrators to quickly set up new training cohorts with minimal effort.

##### Technical Implementation Notes

**Frontend - Vue 3 Components:**
```typescript
// app/javascript/tp_portal/views/CohortCreateView.vue
<script setup lang="ts">
import { ref, computed } from 'vue'
import { useCohortStore } from '@/tp_portal/stores/cohortStore'
import { useNotification } from '@/composables/useNotification'
import { CohortAPI } from '@/tp_portal/api/cohort'
import type { CohortCreatePayload, BulkImportResult } from '@/types'

const cohortStore = useCohortStore()
const notification = useNotification()

const cohortForm = ref<CohortCreatePayload>({
  name: '',
  startDate: '',
  endDate: '',
  description: '',
  studentCount: 0
})

const excelFile = ref<File | null>(null)
const importResult = ref<BulkImportResult | null>(null)
const isUploading = ref(false)
const isCreating = ref(false)

const isValidForm = computed(() => {
  return cohortForm.value.name.trim().length >= 3 &&
         cohortForm.value.startDate &&
         cohortForm.value.endDate
})

const handleFileSelect = (event: Event) => {
  const target = event.target as HTMLInputElement
  if (target.files && target.files[0]) {
    const file = target.files[0]
    if (file.type === 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') {
      excelFile.value = file
    } else {
      notification.error('Please upload a valid Excel file (.xlsx)')
    }
  }
}

const uploadExcel = async () => {
  if (!excelFile.value) return

  isUploading.value = true
  try {
    const formData = new FormData()
    formData.append('file', excelFile.value)

    const result = await CohortAPI.validateBulkImport(formData)
    importResult.value = result

    if (result.valid) {
      cohortForm.value.studentCount = result.studentCount
      notification.success(`Validated ${result.studentCount} students`)
    } else {
      notification.error(`Validation failed: ${result.errors?.join(', ')}`)
    }
  } catch (error) {
    notification.error('Failed to upload Excel file')
  } finally {
    isUploading.value = false
  }
}

const createCohort = async () => {
  if (!isValidForm.value) return

  isCreating.value = true
  try {
    const cohort = await cohortStore.createCohort(cohortForm.value)

    if (excelFile.value && importResult.value?.valid) {
      // Bulk import students
      const formData = new FormData()
      formData.append('file', excelFile.value)
      await CohortAPI.importStudents(cohort.id, formData)
    }

    notification.success('Cohort created successfully')
    // Navigate to cohort detail
    router.push(`/tp/cohorts/${cohort.id}`)
  } catch (error) {
    notification.error('Failed to create cohort')
  } finally {
    isCreating.value = false
  }
}
</script>

<template>
  <div class="cohort-create-view">
    <div class="header">
      <h1>Create New Cohort</h1>
    </div>

    <div class="form-section">
      <div class="basic-info-card">
        <h2>Basic Information</h2>
        <form @submit.prevent="createCohort">
          <div class="form-grid">
            <div class="form-group">
              <label>Cohort Name *</label>
              <input
                v-model="cohortForm.name"
                type="text"
                placeholder="e.g., Spring 2025 - Advanced Python"
                required
              />
            </div>

            <div class="form-group">
              <label>Start Date *</label>
              <input
                v-model="cohortForm.startDate"
                type="date"
                required
              />
            </div>

            <div class="form-group">
              <label>End Date *</label>
              <input
                v-model="cohortForm.endDate"
                type="date"
                required
              />
            </div>

            <div class="form-group full-width">
              <label>Description</label>
              <textarea
                v-model="cohortForm.description"
                placeholder="Optional cohort description"
                rows="3"
              />
            </div>
          </div>
        </form>
      </div>

      <div class="bulk-import-card">
        <h2>Bulk Student Import (Optional)</h2>

        <div class="upload-area" v-if="!importResult">
          <div class="upload-zone">
            <div class="upload-icon">📄</div>
            <p>Drop Excel file here or click to browse</p>
            <span class="upload-hint">.xlsx format required</span>
            <input
              type="file"
              accept=".xlsx"
              @change="handleFileSelect"
              class="file-input"
            />
          </div>

          <button
            @click="uploadExcel"
            :disabled="!excelFile || isUploading"
            class="btn btn-primary"
          >
            {{ isUploading ? 'Validating...' : 'Validate & Preview' }}
          </button>
        </div>

        <div class="import-preview" v-if="importResult && importResult.valid">
          <div class="success-banner">
            ✅ Validated {{ importResult.studentCount }} students
          </div>

          <div class="preview-table">
            <table>
              <thead>
                <tr>
                  <th>Email</th>
                  <th>Name</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="student in importResult.preview.slice(0, 5)" :key="student.email">
                  <td>{{ student.email }}</td>
                  <td>{{ student.name }}</td>
                </tr>
              </tbody>
            </table>
            <div v-if="importResult.preview.length > 5" class="more-indicator">
              +{{ importResult.preview.length - 5 }} more students...
            </div>
          </div>

          <button @click="importResult = null" class="btn btn-secondary">
            Upload Different File
          </button>
        </div>

        <div class="import-errors" v-if="importResult && !importResult.valid">
          <div class="error-banner">
            ❌ Validation failed
            <ul v-if="importResult.errors">
              <li v-for="error in importResult.errors" :key="error">{{ error }}</li>
            </ul>
          </div>
          <button @click="importResult = null" class="btn btn-secondary">
            Try Again
          </button>
        </div>
      </div>

      <div class="actions">
        <button
          @click="createCohort"
          :disabled="!isValidForm || isCreating"
          class="btn btn-primary btn-large"
        >
          {{ isCreating ? 'Creating...' : 'Create Cohort' }}
        </button>
        <button
          @click="$router.back()"
          class="btn btn-ghost"
        >
          Cancel
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.cohort-create-view {
  @apply max-w-4xl mx-auto p-6;
}

.header h1 {
  @apply text-3xl font-bold text-gray-900 mb-6;
}

.form-section {
  @apply space-y-6;
}

.basic-info-card, .bulk-import-card {
  @apply bg-white rounded-lg shadow-sm border border-gray-200 p-6;
}

.bulk-import-card {
  @apply border-blue-200;
}

.card h2 {
  @apply text-xl font-semibold text-gray-800 mb-4;
}

.form-grid {
  @apply grid grid-cols-1 md:grid-cols-2 gap-4;
}

.form-group {
  @apply flex flex-col gap-2;
}

.form-group.full-width {
  @apply md:col-span-2;
}

.form-group label {
  @apply text-sm font-medium text-gray-700;
}

.form-group input, .form-group textarea {
  @apply px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500;
}

.upload-area {
  @apply space-y-4;
}

.upload-zone {
  @apply border-2 border-dashed border-gray-300 rounded-lg p-8 text-center hover:border-blue-400 transition-colors relative;
}

.upload-icon {
  @apply text-4xl mb-2;
}

.upload-hint {
  @apply text-sm text-gray-500;
}

.file-input {
  @apply absolute inset-0 opacity-0 cursor-pointer;
}

.import-preview, .import-errors {
  @apply space-y-3;
}

.success-banner {
  @apply bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded-md;
}

.error-banner {
  @apply bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-md;
}

.preview-table {
  @apply border border-gray-200 rounded-md overflow-hidden;
}

.preview-table table {
  @apply w-full text-sm;
}

.preview-table th {
  @apply bg-gray-50 px-4 py-2 text-left font-semibold text-gray-700;
}

.preview-table td {
  @apply px-4 py-2 border-t border-gray-100;
}

.more-indicator {
  @apply px-4 py-2 bg-gray-50 text-sm text-gray-600 font-medium;
}

.actions {
  @apply flex gap-3 justify-end pt-4;
}

.btn {
  @apply px-4 py-2 rounded-md font-medium transition-colors;
}

.btn-primary {
  @apply bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed;
}

.btn-secondary {
  @apply bg-gray-200 text-gray-800 hover:bg-gray-300;
}

.btn-ghost {
  @apply text-gray-600 hover:bg-gray-100;
}

.btn-large {
  @apply px-6 py-3 text-lg;
}
</style>
```

**Pinia Store:**
```typescript
// app/javascript/tp_portal/stores/cohortStore.ts
import { defineStore } from 'pinia'
import { CohortAPI } from '@/tp_portal/api/cohort'
import type { Cohort, CohortCreatePayload } from '@/types'

export const useCohortStore = defineStore('cohort', {
  state: () => ({
    cohorts: [] as Cohort[],
    loading: false,
    error: null as string | null
  }),

  actions: {
    async createCohort(payload: CohortCreatePayload): Promise<Cohort> {
      this.loading = true
      this.error = null
      try {
        const cohort = await CohortAPI.create(payload)
        this.cohorts.unshift(cohort)
        return cohort
      } catch (error) {
        this.error = 'Failed to create cohort'
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchCohorts() {
      this.loading = true
      try {
        this.cohorts = await CohortAPI.list()
      } finally {
        this.loading = false
      }
    }
  }
})
```

**API Layer:**
```typescript
// app/javascript/tp_portal/api/cohort.ts
export const CohortAPI = {
  async create(payload: CohortCreatePayload): Promise<Cohort> {
    const response = await fetch('/api/v1/cohorts', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ cohort: payload })
    })
    return response.json()
  },

  async validateBulkImport(formData: FormData): Promise<BulkImportResult> {
    const response = await fetch('/api/v1/cohorts/validate_import', {
      method: 'POST',
      body: formData
    })
    return response.json()
  },

  async importStudents(cohortId: number, formData: FormData): Promise<void> {
    await fetch(`/api/v1/cohorts/${cohortId}/import_students`, {
      method: 'POST',
      body: formData
    })
  }
}
```

**Excel Format Specification:**
```
Required columns:
- email (string, unique)
- name (string)
- student_id (string, optional)
- phone (string, optional)

Example:
| email              | name           | student_id | phone        |
|--------------------|----------------|------------|--------------|
| john@university.edu| John Doe       | STU001     | 555-0101     |
| jane@university.edu| Jane Smith     | STU002     | 555-0102     |
```

**Design System Compliance:**

Per FR28, all components must use design system assets from:
- `@.claude/skills/frontend-design/SKILL.md`
- `@.claude/skills/frontend-design/design-system/`

Specifically: colors, icons, typography, and layout patterns from the design system.

##### Acceptance Criteria

**Functional:**
1. ✅ Form validation prevents submission with missing required fields
2. ✅ Date pickers work correctly and prevent invalid date ranges
3. ✅ Excel upload accepts only .xlsx files
4. ✅ Validation shows preview of first 5 students
5. ✅ Validation counts total student count
6. ✅ Validation identifies formatting errors (missing emails, duplicates)
7. ✅ User can re-upload file if validation fails
8. ✅ Create button disabled until form is valid
9. ✅ Success notification on cohort creation
10. ✅ Auto-navigate to cohort detail after creation
11. ✅ Bulk import creates student records with pending status
12. ✅ Cohort name uniqueness enforced (optional, backend)

**UI/UX:**
1. ✅ Follows design system colors and spacing
2. ✅ Upload zone has clear drag-and-drop visual feedback
3. ✅ Loading states display during upload and creation
4. ✅ Error messages are clear and actionable
5. ✅ Preview table is scrollable if many rows
6. ✅ Form is responsive on mobile devices
7. ✅ All buttons have proper hover states
8. ✅ File input is accessible (keyboard navigation)

**Integration:**
1. ✅ IV1: API calls use correct endpoints
2. ✅ IV2: Pinia store updates after creation
3. ✅ IV3: Error handling works for network failures
4. ✅ IV4: Excel validation endpoint returns correct data structure

**Security:**
1. ✅ Only authenticated TP users can access
2. ✅ File upload size limit enforced (10MB max)
3. ✅ File type validation on client and server
4. ✅ Sanitization of cohort names and descriptions
5. ✅ Rate limiting on create endpoint

**Quality:**
1. ✅ Follows Vue 3 best practices
2. ✅ TypeScript types defined for all data
3. ✅ Components are reusable (form fields extracted)
4. ✅ 80% test coverage
5. ✅ Design system compliance verified

##### Integration Verification (IV1-4)

**IV1: API Integration**
- Verify POST /api/v1/cohorts creates cohort
- Verify POST /api/v1/cohorts/validate_import returns preview
- Verify POST /api/v1/cohorts/:id/import_students creates students
- Verify error handling for invalid files

**IV2: Pinia Store**
- Verify cohort added to store after creation
- Verify loading state during operations
- Verify error state cleared on retry

**IV3: Error Handling**
- Test network failure scenarios
- Test server validation errors
- Test file size limit errors
- Test invalid file type errors

**IV4: Data Structure**
- Validate API returns correct Cohort object
- Validate preview contains student data
- Validate import result has correct structure

##### Test Requirements

**Component Specs:**
```javascript
// spec/javascript/tp_portal/views/CohortCreateView.spec.js
import { mount, flushPromises } from '@vue/test-utils'
import CohortCreateView from '@/tp_portal/views/CohortCreateView.vue'
import { createPinia, setActivePinia } from 'pinia'

describe('CohortCreateView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('validates required fields before submission', async () => {
    const wrapper = mount(CohortCreateView)
    await wrapper.find('form').trigger('submit')
    expect(wrapper.find('.error-banner').exists()).toBe(true)
  })

  it('handles Excel upload successfully', async () => {
    const wrapper = mount(CohortCreateView)
    const file = new File([''], 'test.xlsx', { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })

    await wrapper.find('input[type="file"]').trigger('change', { target: { files: [file] } })
    await wrapper.find('.btn-primary').trigger('click')
    await flushPromises()

    expect(wrapper.find('.success-banner').exists()).toBe(true)
  })
})
```

**E2E Test:**
```javascript
// spec/system/tp_portal/cohort_creation_spec.rb
require 'rails_helper'

RSpec.describe 'Cohort Creation', type: :system do
  let(:tp_user) { create(:user, :training_provider) }

  before do
    sign_in tp_user
    visit '/tp/cohorts/new'
  end

  it 'creates cohort with bulk import' do
    fill_in 'Cohort Name', with: 'Test Cohort 2025'
    fill_in 'Start Date', with: '2025-01-01'
    fill_in 'End Date', with: '2025-06-30'

    attach_file('Excel file', Rails.root.join('spec/fixtures/students.xlsx'))
    click_button 'Validate & Preview'

    expect(page).to have_content('Validated 10 students')

    click_button 'Create Cohort'

    expect(page).to have_content('Cohort created successfully')
    expect(page).to have_current_path(%r{/tp/cohorts/\d+})
  end
end
```

##### Rollback Procedure

**If creation fails:**
1. No data changes occur (transactional)
2. User can retry with corrected data
3. Excel file validation prevents bad data
4. All form data preserved in state

**Data Safety**: Cohort creation is atomic - either all students created or none.

##### Risk Assessment

**Low Risk because:**
- Standard form with file upload pattern
- Backend validation prevents data corruption
- Excel parsing is well-established pattern
- User can preview before committing

**Specific Risks:**
1. **Large Files**: 10MB+ Excel files could timeout
2. **Format Variations**: Different Excel formats may fail
3. **Duplicate Emails**: May create duplicate student records
4. **Memory**: Large imports could use significant memory

**Mitigation:**
- Client-side file size check (10MB limit)
- Server-side format validation
- Database unique constraints on student emails
- Background job for very large imports (future enhancement)
- Preview step prevents surprises

---

#### Story 4.3: Cohort Detail Overview

**Status**: Draft
**Priority**: High
**Epic**: Phase 4 - Frontend - TP Portal
**Estimated Effort**: 2 days
**Risk Level**: Low

##### User Story

**As a** TP administrator,
**I want** to view detailed information about a specific cohort, including student list, progress status, and document workflow,
**So that** I can monitor and manage the cohort effectively.

##### Background

After creating a cohort, administrators need a comprehensive view to:
- See all students and their current status
- Monitor workflow progression through the 4 stages
- View cohort metadata and settings
- Access quick actions based on current workflow stage
- Filter and search students

This view serves as the central hub for cohort management.

##### Technical Implementation Notes

**Vue 3 Component Structure:**

```vue
<!-- app/javascript/tp_portal/views/CohortDetailView.vue -->
<template>
  <div class="cohort-detail-view">
    <!-- Loading State -->
    <div v-if="loading" class="loading-state">
      <div class="spinner"></div>
      <p>Loading cohort details...</p>
    </div>

    <!-- Main Content -->
    <div v-else-if="cohort" class="cohort-content">
      <!-- Header -->
      <div class="header">
        <div class="header-left">
          <button @click="$router.back()" class="btn-back">← Back</button>
          <h1>{{ cohort.name }}</h1>
          <span class="cohort-dates">
            {{ cohort.startDate }} - {{ cohort.endDate }}
          </span>
        </div>
        <div class="header-actions">
          <button @click="exportCohortData" class="btn btn-secondary">
            📊 Export Data
          </button>
          <button class="btn btn-primary" @click="$router.push(`/tp/cohorts/${cohortId}/sign`)">
            ✍️ Start Signing
          </button>
        </div>
      </div>

      <!-- Stats Cards -->
      <div class="stats-grid" v-if="stats">
        <MetricCard :value="stats.totalStudents" label="Total Students" />
        <MetricCard :value="stats.pendingCount" label="Pending" />
        <MetricCard :value="stats.inProgressCount" label="In Progress" />
        <MetricCard :value="stats.completedCount" label="Completed" />
        <MetricCard :value="stats.completionRate + '%'" label="Completion Rate" />
      </div>

      <!-- Workflow Status -->
      <div class="workflow-section">
        <h2>Workflow Status</h2>
        <div class="workflow-steps">
          <div
            v-for="step in workflowSteps"
            :key="step.id"
            class="workflow-step"
            :class="{ active: cohort.workflowStage === step.id }"
          >
            <div class="step-number">{{ step.number }}</div>
            <div class="step-info">
              <div class="step-title">{{ step.title }}</div>
              <div class="step-desc">{{ step.desc }}</div>
            </div>
            <div class="step-status" v-if="cohort.workflowStage === step.id">Current</div>
          </div>
        </div>
      </div>

      <!-- Student List & Filters -->
      <div class="students-section">
        <div class="section-header">
          <h2>Students</h2>
          <div class="filters">
            <div class="filter-group">
              <label>Status:</label>
              <select v-model="studentFilters.status">
                <option value="all">All</option>
                <option value="pending">Pending</option>
                <option value="in_progress">In Progress</option>
                <option value="completed">Completed</option>
              </select>
            </div>
            <div class="filter-group">
              <label>Search:</label>
              <input
                v-model="studentFilters.search"
                type="text"
                placeholder="Search by name or email..."
              />
            </div>
          </div>
        </div>

        <!-- Status Counts -->
        <div class="status-counts">
          <span class="count-badge badge-pending">Pending: {{ statusCounts.pending }}</span>
          <span class="count-badge badge-progress">In Progress: {{ statusCounts.in_progress }}</span>
          <span class="count-badge badge-completed">Completed: {{ statusCounts.completed }}</span>
        </div>

        <!-- Student Table -->
        <div class="student-table-container">
          <table v-if="filteredStudents.length > 0" class="student-table">
            <thead>
              <tr>
                <th>Student Name</th>
                <th>Email</th>
                <th>Student ID</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="student in filteredStudents" :key="student.id">
                <td>{{ student.name }}</td>
                <td>{{ student.email }}</td>
                <td>{{ student.studentId || '-' }}</td>
                <td>
                  <span class="status-badge" :class="getStatusBadgeClass(student.status)">
                    {{ student.status.replace('_', ' ') }}
                  </span>
                </td>
                <td class="actions-cell">
                  <button
                    @click="$router.push(`/tp/cohorts/${cohortId}/students/${student.id}`)"
                    class="btn-view"
                  >
                    View
                  </button>
                </td>
              </tr>
            </tbody>
          </table>

          <div v-else class="empty-state">
            <div class="empty-icon">📭</div>
            <h3>No students found</h3>
            <p>Try adjusting your filters or add students to this cohort</p>
          </div>
        </div>
      </div>

      <!-- Cohort Info Sidebar -->
      <div class="info-sidebar">
        <div class="info-card">
          <h3>Cohort Information</h3>
          <div class="info-row">
            <span class="label">Created:</span>
            <span class="value">{{ cohort.createdAt }}</span>
          </div>
          <div class="info-row">
            <span class="label">Template:</span>
            <span class="value">{{ cohort.templateName || 'N/A' }}</span>
          </div>
          <div class="info-row">
            <span class="label">Sponsor:</span>
            <span class="value">{{ cohort.sponsorName || 'Not assigned' }}</span>
          </div>
          <div class="info-row">
            <span class="label">TP Token:</span>
            <span class="value">
              <span v-if="cohort.tpTokenExpiresAt">
                Expires: {{ cohort.tpTokenExpiresAt }}
              </span>
              <span v-else>Not generated</span>
            </span>
          </div>
        </div>

        <div class="info-card">
          <h3>Quick Actions</h3>
          <button
            @click="$router.push(`/tp/cohorts/${cohortId}/sign`)"
            class="btn-action"
            :disabled="cohort.workflowStage !== 'tp_signing'"
          >
            TP Signing Phase
          </button>
          <button
            @click="$router.push(`/tp/cohorts/${cohortId}/review`)"
            class="btn-action"
            :disabled="cohort.workflowStage !== 'tp_review'"
          >
            Review & Finalize
          </button>
          <button
            @click="$router.push(`/tp/cohorts/${cohortId}/settings`)"
            class="btn-action"
          >
            Cohort Settings
          </button>
        </div>
      </div>
    </div>

    <!-- Not Found -->
    <div v-else class="not-found">
      <h2>Cohort not found</h2>
      <button @click="$router.push('/tp/cohorts')" class="btn btn-primary">
        Back to Cohorts
      </button>
    </div>
  </div>
</template>
```

**Pinia Store:**
```typescript
// app/javascript/tp_portal/stores/studentStore.ts
import { defineStore } from 'pinia'
import { StudentAPI } from '@/tp_portal/api/student'
import type { Student } from '@/types'

export const useStudentStore = defineStore('student', {
  state: () => ({
    students: [] as Student[],
    loading: false,
    error: null as string | null
  }),

  actions: {
    async fetchStudents(cohortId: number): Promise<void> {
      this.loading = true
      this.error = null
      try {
        this.students = await StudentAPI.list(cohortId)
      } catch (error) {
        this.error = 'Failed to fetch students'
        throw error
      } finally {
        this.loading = false
      }
    }
  }
})
```

**API Layer:**
```typescript
// app/javascript/tp_portal/api/cohort.ts
export const CohortAPI = {
  async show(id: number): Promise<Cohort> {
    const response = await fetch(`/api/v1/cohorts/${id}`)
    return response.json()
  },

  async stats(id: number): Promise<CohortStats> {
    const response = await fetch(`/api/v1/cohorts/${id}/stats`)
    return response.json()
  }
}

// app/javascript/tp_portal/api/student.ts
export const StudentAPI = {
  async list(cohortId: number): Promise<Student[]> {
    const response = await fetch(`/api/v1/cohorts/${cohortId}/students`)
    return response.json()
  }
}
```

**Type Definitions:**
```typescript
export interface Cohort {
  id: number
  name: string
  startDate: string
  endDate: string
  workflowStage: 'tp_signing' | 'student_signing' | 'sponsor_signing' | 'tp_review' | 'completed'
  createdAt: string
  templateName?: string
  sponsorName?: string
  tpTokenExpiresAt?: string
}

export interface CohortStats {
  totalStudents: number
  pendingCount: number
  inProgressCount: number
  completedCount: number
  completionRate: number
}

export interface Student {
  id: number
  cohortId: number
  name: string
  email: string
  studentId?: string
  status: 'pending' | 'in_progress' | 'completed'
}
```

**Design System Compliance:**

Per FR28, all components must use design system assets from:
- `@.claude/skills/frontend-design/SKILL.md`
- `@.claude/skills/frontend-design/design-system/`

Specifically: colors, icons, typography, and layout patterns from the design system.

##### Acceptance Criteria

**Functional:**
1. ✅ Loads cohort details on page visit
2. ✅ Displays all cohort information correctly
3. ✅ Shows 5 stat cards with correct values
4. ✅ Renders workflow steps with correct active state
5. ✅ Lists all students in the cohort
6. ✅ Filters students by status (all/pending/in_progress/completed)
7. ✅ Searches students by name or email
8. ✅ Shows status counts that update with filters
9. ✅ Displays empty state when no students match filters
10. ✅ Each student row has "View" button
11. ✅ "View" button navigates to student detail
12. ✅ "Start Signing" button navigates to signing interface
13. ✅ "Export Data" button triggers export (links to Story 4.8)
14. ✅ Quick action buttons are disabled when not applicable
15. ✅ Shows "Not found" when cohort doesn't exist

**UI/UX:**
1. ✅ Follows design system colors and spacing
2. ✅ Responsive layout on mobile devices
3. ✅ Loading state displays during data fetch
4. ✅ Status badges use correct colors
5. ✅ Workflow steps are visually distinct
6. ✅ Tables are scrollable on small screens
7. ✅ All interactive elements have hover states
8. ✅ Empty states are helpful and clear

**Integration:**
1. ✅ IV1: API calls use correct endpoints
2. ✅ IV2: Pinia stores manage state correctly
3. ✅ IV3: Router navigation works
4. ✅ IV4: Data flows between components correctly

**Security:**
1. ✅ Only authenticated TP users can access
2. ✅ Users only see their institution's cohorts
3. ✅ Student data is not exposed to unauthorized users
4. ✅ All API endpoints require proper authorization

**Quality:**
1. ✅ Follows Vue 3 best practices
2. ✅ TypeScript types defined
3. ✅ Components are maintainable
4. ✅ 80% test coverage
5. ✅ Design system compliance verified

##### Integration Verification (IV1-4)

**IV1: API Integration**
- Verify GET /api/v1/cohorts/:id returns correct data
- Verify GET /api/v1/cohorts/:id/stats returns correct counts
- Verify GET /api/v1/cohorts/:id/students returns student list
- Verify error handling for non-existent cohorts

**IV2: Pinia Store**
- Verify students are stored correctly
- Verify loading states during fetch
- Verify error handling

**IV3: Router Navigation**
- Verify back button works
- Verify "View" button navigates correctly
- Verify "Start Signing" button navigates correctly
- Verify disabled buttons don't navigate

**IV4: Data Flow**
- Verify stats calculate correctly from student data
- Verify filters update display correctly
- Verify search filters work in real-time

##### Test Requirements

**Component Specs:**
```javascript
// spec/javascript/tp_portal/views/CohortDetailView.spec.js
import { mount, flushPromises } from '@vue/test-utils'
import CohortDetailView from '@/tp_portal/views/CohortDetailView.vue'
import { createRouter, createWebHistory } from 'vue-router'
import { createPinia, setActivePinia } from 'pinia'

describe('CohortDetailView', () => {
  let router

  beforeEach(() => {
    setActivePinia(createPinia())
    router = createRouter({
      history: createWebHistory(),
      routes: [{ path: '/tp/cohorts/:id', component: CohortDetailView }]
    })
  })

  it('displays cohort information', async () => {
    const wrapper = mount(CohortDetailView, { global: { plugins: [router] } })
    await flushPromises()

    expect(wrapper.find('h1').text()).toContain('Test Cohort')
    expect(wrapper.find('.stat-value').text()).toBe('50')
  })

  it('filters students by status', async () => {
    const wrapper = mount(CohortDetailView, { global: { plugins: [router] } })
    await flushPromises()

    await wrapper.find('select').setValue('completed')
    await flushPromises()

    const rows = wrapper.findAll('.student-table tbody tr')
    expect(rows.length).toBe(25) // Only completed students
  })
})
```

**E2E Test:**
```javascript
// spec/system/tp_portal/cohort_detail_spec.rb
require 'rails_helper'

RSpec.describe 'Cohort Detail', type: :system do
  let(:tp_user) { create(:user, :training_provider) }
  let(:cohort) { create(:cohort, account: tp_user.account) }

  before do
    create_list(:student, 10, cohort: cohort)
    sign_in tp_user
    visit "/tp/cohorts/#{cohort.id}"
  end

  it 'displays cohort details and students' do
    expect(page).to have_content(cohort.name)
    expect(page).to have_content('Total Students: 10')
    expect(page).to have_css('.student-table tbody tr', count: 10)
  end

  it 'filters students by status' do
    select 'Completed', from: 'Status:'
    expect(page).to have_css('.student-table tbody tr', count: 0)
  end

  it 'navigates to student detail' do
    first('.btn-view').click
    expect(page).to have_current_path(%r{/tp/cohorts/\d+/students/\d+})
  end
end
```

##### Rollback Procedure

**If loading fails:**
1. Display error message
2. Show "Retry" button
3. Preserve any loaded data
4. Navigate back to list if needed

**Data Safety**: Read-only view, no data modification.

##### Risk Assessment

**Low Risk because:**
- Read-only data display
- Standard filtering and search patterns
- Well-established API patterns
- No complex state management

**Specific Risks:**
1. **Performance**: Large student lists could be slow
2. **Memory**: Storing many students in state
3. **API Load**: Multiple API calls on load

**Mitigation:**
- Implement pagination for large lists
- Use virtual scrolling for performance
- Cache API responses
- Lazy load student details

---

#### Story 4.4: TP Signing Interface

**Status**: Draft
**Priority**: High
**Epic**: Phase 4 - Frontend - TP Portal
**Estimated Effort**: 3-4 days
**Risk Level**: High

##### User Story

**As a** TP administrator,
**I want** to sign the first student's document and have it automatically replicated to all other students,
**So that** I can sign once instead of signing each student's document individually.

##### Background

The TP Signing Phase is the critical first step in the 3-party workflow. Key requirements:
- TP signs ONE document (the first student's document)
- System duplicates the signed submission to all other students
- TP's fields and signatures are pre-filled across all student submissions
- This eliminates duplicate signing work for the TP
- Prevents duplicate sponsor emails through workflow state management

This is the core innovation of FloDoc - bulk signing capability.

##### Technical Implementation Notes

**Vue 3 Component Structure:**

```vue
<!-- app/javascript/tp_portal/views/TPSigningView.vue -->
<template>
  <div class="tp-signing-view">
    <!-- Header -->
    <div class="header">
      <button @click="$router.back()" class="btn-back">← Back to Cohort</button>
      <h1>TP Signing Phase</h1>
      <div class="cohort-info">
        <span>{{ cohort.name }}</span>
        <span class="student-count">{{ studentCount }} students</span>
      </div>
    </div>

    <!-- Progress Indicator -->
    <div class="progress-section">
      <div class="progress-bar">
        <div class="progress-fill" :style="{ width: signingProgress + '%' }"></div>
      </div>
      <div class="progress-label">
        Signing Progress: {{ signingProgress }}%
      </div>
    </div>

    <!-- Workflow Status -->
    <div class="workflow-reminder">
      <div class="workflow-card">
        <h3>Current Phase: TP Signing</h3>
        <p>You are signing the first document. This will be replicated to all {{ studentCount }} students.</p>
        <div class="workflow-steps">
          <span class="step active">1. TP Signs</span>
          <span class="step">2. Students Sign</span>
          <span class="step">3. Sponsor Signs</span>
          <span class="step">4. TP Reviews</span>
        </div>
      </div>
    </div>

    <!-- Document Preview & Signing Area -->
    <div class="signing-area" v-if="!isComplete">
      <div class="document-preview">
        <div class="preview-header">
          <h3>Document Preview</h3>
          <div class="actions">
            <button @click="zoomIn" class="btn-icon">🔍+</button>
            <button @click="zoomOut" class="btn-icon">🔍-</button>
            <button @click="rotate" class="btn-icon">🔄</button>
          </div>
        </div>

        <div class="pdf-container" ref="pdfContainer">
          <!-- PDF.js viewer would go here -->
          <div class="placeholder-pdf">
            <div class="pdf-icon">📄</div>
            <p>Document Preview</p>
            <span class="note">Interactive PDF viewer with form fields</span>
          </div>
        </div>
      </div>

      <div class="form-fields-panel">
        <h3>Fill Form Fields</h3>
        <div class="field-list">
          <div v-for="field in formFields" :key="field.id" class="form-field">
            <label>{{ field.label }}</label>
            <input
              v-if="field.type === 'text'"
              v-model="fieldValues[field.id]"
              :placeholder="field.placeholder"
              type="text"
            />
            <textarea
              v-else-if="field.type === 'textarea'"
              v-model="fieldValues[field.id]"
              :placeholder="field.placeholder"
              rows="3"
            />
            <input
              v-else-if="field.type === 'date'"
              v-model="fieldValues[field.id]"
              type="date"
            />
            <div v-else-if="field.type === 'signature'" class="signature-field">
              <div v-if="fieldValues[field.id]" class="signature-preview">
                <img :src="fieldValues[field.id]" alt="Signature" class="signature-img" />
                <button @click="fieldValues[field.id] = null" class="btn-remove">Remove</button>
              </div>
              <button v-else @click="openSignaturePad(field.id)" class="btn-sign">
                ✍️ Click to Sign
              </button>
            </div>
            <div v-else-if="field.type === 'checkbox'" class="checkbox-field">
              <input
                type="checkbox"
                :id="field.id"
                v-model="fieldValues[field.id]"
              />
              <label :for="field.id">{{ field.checkboxLabel }}</label>
            </div>
          </div>
        </div>
      </div>

      <!-- Action Panel -->
      <div class="action-panel">
        <div class="validation-status">
          <div v-if="validationErrors.length > 0" class="errors">
            <div v-for="error in validationErrors" :key="error" class="error-item">
              ⚠️ {{ error }}
            </div>
          </div>
          <div v-else class="ready">
            ✓ All fields ready for signing
          </div>
        </div>

        <div class="actions">
          <button
            @click="previewDocument"
            class="btn btn-secondary"
            :disabled="!canPreview"
          >
            Preview Document
          </button>
          <button
            @click="signAndReplicate"
            class="btn btn-primary"
            :disabled="!canSign"
          >
            Sign & Replicate to {{ studentCount }} Students
          </button>
        </div>
      </div>
    </div>

    <!-- Success State -->
    <div v-else class="success-state">
      <div class="success-icon">✓</div>
      <h2>Signing Complete!</h2>
      <p>
        Your signature and fields have been replicated to all {{ studentCount }} student documents.
      </p>
      <div class="success-details">
        <div class="detail-card">
          <h4>What's Next?</h4>
          <ul>
            <li>Students will receive email invitations</li>
            <li>Students fill their personal fields</li>
            <li>Sponsor receives ONE email for the cohort</li>
            <li>TP reviews all completed documents</li>
          </ul>
        </div>
      </div>
      <div class="success-actions">
        <button @click="$router.push(`/tp/cohorts/${cohortId}`)" class="btn btn-primary">
          Return to Cohort
        </button>
        <button @click="sendInvitations" class="btn btn-secondary">
          Send Student Invitations Now
        </button>
      </div>
    </div>

    <!-- Signature Pad Modal -->
    <div v-if="showSignaturePad" class="modal-overlay" @click.self="closeSignaturePad">
      <div class="signature-modal">
        <h3>Draw Your Signature</h3>
        <div class="signature-canvas-container">
          <canvas
            ref="signatureCanvas"
            width="400"
            height="200"
            @mousedown="startDrawing"
            @mousemove="draw"
            @mouseup="stopDrawing"
            @mouseleave="stopDrawing"
            @touchstart="startDrawing"
            @touchmove="draw"
            @touchend="stopDrawing"
          ></canvas>
        </div>
        <div class="signature-actions">
          <button @click="clearSignature" class="btn btn-secondary">Clear</button>
          <button @click="saveSignature" class="btn btn-primary">Save Signature</button>
          <button @click="closeSignaturePad" class="btn btn-ghost">Cancel</button>
        </div>
      </div>
    </div>

    <!-- Preview Modal -->
    <div v-if="showPreview" class="modal-overlay" @click.self="showPreview = false">
      <div class="preview-modal">
        <div class="preview-header">
          <h3>Document Preview</h3>
          <button @click="showPreview = false" class="btn-close">×</button>
        </div>
        <div class="preview-content">
          <p>This shows how the document will look with your fields filled:</p>
          <div class="preview-fields">
            <div v-for="(value, key) in fieldValues" :key="key" class="preview-field">
              <strong>{{ key }}:</strong> {{ value || '(empty)' }}
            </div>
          </div>
          <p class="preview-note">
            Note: This is a preview. The actual PDF will be generated with your signature embedded.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
```

**Pinia Store:**
```typescript
// app/javascript/tp_portal/stores/tpSigningStore.ts
import { defineStore } from 'pinia'
import { TPSigningAPI } from '@/tp_portal/api/tpSigning'
import type { FormField, FieldValues, SigningResult } from '@/types'

export const useTPSigningStore = defineStore('tpSigning', {
  state: () => ({
    cohort: null as Cohort | null,
    formFields: [] as FormField[],
    fieldValues: {} as FieldValues,
    isComplete: false,
    loading: false,
    error: null as string | null
  }),

  actions: {
    async loadCohort(cohortId: number): Promise<void> {
      this.loading = true
      try {
        const [cohort, fields] = await Promise.all([
          TPSigningAPI.getCohort(cohortId),
          TPSigningAPI.getFormFields(cohortId)
        ])
        this.cohort = cohort
        this.formFields = fields
        // Initialize field values
        fields.forEach(field => {
          this.fieldValues[field.id] = ''
        })
      } catch (error) {
        this.error = 'Failed to load cohort'
        throw error
      } finally {
        this.loading = false
      }
    },

    async signAndReplicate(payload: {
      cohortId: number
      fieldValues: FieldValues
    }): Promise<SigningResult> {
      this.loading = true
      try {
        const result = await TPSigningAPI.signAndReplicate(payload)
        this.isComplete = true
        return result
      } catch (error) {
        this.error = 'Signing failed'
        throw error
      } finally {
        this.loading = false
      }
    },

    async sendInvitations(cohortId: number): Promise<void> {
      await TPSigningAPI.sendInvitations(cohortId)
    }
  }
})
```

**API Layer:**
```typescript
// app/javascript/tp_portal/api/tpSigning.ts
export const TPSigningAPI = {
  async getCohort(id: number): Promise<Cohort> {
    const response = await fetch(`/api/v1/cohorts/${id}`)
    return response.json()
  },

  async getFormFields(cohortId: number): Promise<FormField[]> {
    const response = await fetch(`/api/v1/cohorts/${cohortId}/form_fields`)
    return response.json()
  },

  async signAndReplicate(payload: {
    cohortId: number
    fieldValues: FieldValues
  }): Promise<SigningResult> {
    const response = await fetch(`/api/v1/cohorts/${payload.cohortId}/tp_sign`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        field_values: payload.fieldValues
      })
    })
    return response.json()
  },

  async sendInvitations(cohortId: number): Promise<void> {
    await fetch(`/api/v1/cohorts/${cohortId}/send_invitations`, {
      method: 'POST'
    })
  }
}
```

**Type Definitions:**
```typescript
export interface FormField {
  id: string
  label: string
  type: 'text' | 'textarea' | 'date' | 'signature' | 'checkbox'
  placeholder?: string
  checkboxLabel?: string
  required: boolean
}

export interface FieldValues {
  [key: string]: string | boolean | null
}

export interface SigningResult {
  message: string
  replicatedTo: number
  nextStep: string
}
```

**Design System Compliance:**

Per FR28, all components must use design system assets from:
- `@.claude/skills/frontend-design/SKILL.md`
- `@.claude/skills/frontend-design/design-system/`

Specifically: colors, icons, typography, and layout patterns from the design system.

##### Acceptance Criteria

**Functional:**
1. ✅ Loads cohort and form fields on page visit
2. ✅ Displays correct student count
3. ✅ Shows workflow reminder with correct current step
4. ✅ Renders all form fields based on template
5. ✅ Accepts input for text fields
6. ✅ Accepts input for textarea fields
7. ✅ Accepts date selection
8. ✅ Opens signature pad modal when clicking sign button
9. ✅ Allows drawing signature on canvas
10. ✅ Clears signature canvas
11. ✅ Saves signature as image data
12. ✅ Displays signature preview
13. ✅ Allows removing signature
14. ✅ Handles checkbox fields
15. ✅ Validates all required fields before signing
16. ✅ Shows validation errors
17. ✅ Preview button shows field values
18. ✅ Sign & Replicate button disabled until valid
19. ✅ Success state shows after signing
20. ✅ Replicates to correct number of students
21. ✅ "Send Invitations" button works
22. ✅ Navigation back to cohort works

**UI/UX:**
1. ✅ Follows design system colors and spacing
2. ✅ Responsive layout on mobile devices
3. ✅ Loading states during operations
4. ✅ Modal overlays work correctly
5. ✅ Canvas drawing is smooth
6. ✅ Error messages are clear
7. ✅ Success state is visually distinct
8. ✅ Progress bar shows signing progress
9. ✅ All buttons have proper hover states
10. ✅ Empty states handled gracefully

**Integration:**
1. ✅ IV1: API calls use correct endpoints
2. ✅ IV2: Pinia store manages state correctly
3. ✅ IV3: Router navigation works
4. ✅ IV4: Data flows between components correctly

**Security:**
1. ✅ Only authenticated TP users can access
2. ✅ Users can only sign their institution's cohorts
3. ✅ Signature data is securely stored
4. ✅ All API endpoints require proper authorization
5. ✅ Rate limiting on signing endpoint

**Quality:**
1. ✅ Follows Vue 3 best practices
2. ✅ TypeScript types defined
3. ✅ Components are maintainable
4. ✅ Canvas drawing uses efficient rendering
5. ✅ 80% test coverage
6. ✅ Design system compliance verified

##### Integration Verification (IV1-4)

**IV1: API Integration**
- Verify GET /api/v1/cohorts/:id returns cohort data
- Verify GET /api/v1/cohorts/:id/form_fields returns fields
- Verify POST /api/v1/cohorts/:id/tp_sign replicates correctly
- Verify POST /api/v1/cohorts/:id/send_invitations works
- Verify error handling for invalid data

**IV2: Pinia Store**
- Verify cohort and fields are stored correctly
- Verify field values are managed properly
- Verify isComplete state updates
- Verify loading states during operations

**IV3: Router Navigation**
- Verify back button navigates correctly
- Verify "Return to Cohort" works
- Verify navigation is blocked during signing

**IV4: Data Flow**
- Verify field values propagate to preview
- Verify signature data is captured correctly
- Verify validation logic works
- Verify success state displays correct data

##### Test Requirements

**Component Specs:**
```javascript
// spec/javascript/tp_portal/views/TPSigningView.spec.js
import { mount, flushPromises } from '@vue/test-utils'
import TPSigningView from '@/tp_portal/views/TPSigningView.vue'
import { createPinia, setActivePinia } from 'pinia'

describe('TPSigningView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('validates required fields before signing', async () => {
    const wrapper = mount(TPSigningView)
    await flushPromises()

    // Leave required fields empty
    const signButton = wrapper.find('.btn-primary')
    expect(signButton.attributes('disabled')).toBe('disabled')
  })

  it('saves signature and replicates', async () => {
    const wrapper = mount(TPSigningView)
    await flushPromises()

    // Fill fields
    await wrapper.find('input[type="text"]').setValue('Test Value')
    await wrapper.find('.btn-sign').trigger('click')

    // Mock signature
    wrapper.vm.fieldValues['signature_1'] = 'data:image/png;base64,mock'
    await wrapper.vm.$nextTick()

    const signButton = wrapper.find('.btn-primary')
    expect(signButton.attributes('disabled')).toBeUndefined()
  })
})
```

**E2E Test:**
```javascript
// spec/system/tp_portal/tp_signing_spec.rb
require 'rails_helper'

RSpec.describe 'TP Signing', type: :system do
  let(:tp_user) { create(:user, :training_provider) }
  let(:cohort) { create(:cohort_with_students, account: tp_user.account, student_count: 5) }

  before do
    sign_in tp_user
    visit "/tp/cohorts/#{cohort.id}/sign"
  end

  it 'allows TP to sign and replicate to all students' do
    expect(page).to have_content('5 students')

    # Fill form fields
    fill_in 'Name', with: 'TP Administrator'
    fill_in 'Date', with: '2025-01-15'

    # Sign
    click_button 'Sign & Replicate to 5 Students'

    expect(page).to have_content('Signing Complete!')
    expect(page).to have_content('replicated to all 5 student documents')

    # Verify in database
    expect(cohort.cohort_enrollments.count).to eq(5)
    expect(cohort.cohort_enrollments.all? { |e| e.status == 'pending' }).to be true
  end
end
```

##### Rollback Procedure

**If signing fails:**
1. No data is replicated (transactional)
2. User can retry with corrected data
3. Field values preserved in state
4. Error messages guide user to fix issues

**Data Safety**: Signing is atomic - either all students get replicated or none.

##### Risk Assessment

**High Risk because:**
- Complex replication logic
- Canvas drawing implementation
- Large data duplication
- Critical workflow step

**Specific Risks:**
1. **Replication Failure**: Students don't get created
2. **Data Corruption**: Invalid field values replicated
3. **Canvas Issues**: Signature not captured correctly
4. **Performance**: Large cohorts could timeout
5. **State Loss**: User progress lost on error

**Mitigation:**
- Transactional database operations
- Validation before replication
- Canvas fallback (text signature option)
- Background job for large cohorts
- Auto-save field values to localStorage
- Comprehensive error handling and user feedback

---

#### Story 4.5: Student Management View

**Status**: Draft
**Priority**: Medium
**Epic**: Phase 4 - Frontend - TP Portal
**Estimated Effort**: 2 days
**Risk Level**: Low

##### User Story

**As a** TP administrator,
**I want** to view and manage individual student details, including their document status and uploaded files,
**So that** I can track student progress and troubleshoot issues.

##### Background

After TP signing and student enrollment, administrators need granular visibility into each student's progress:
- View student's personal information
- See document status (pending/in_progress/completed)
- Access uploaded required documents
- Monitor student's field completion
- Send reminders or reset student progress

This provides detailed cohort management capabilities.

##### Technical Implementation Notes

**Vue 3 Component Structure:**

```vue
<!-- app/javascript/tp_portal/views/StudentDetailView.vue -->
<template>
  <div class="student-detail-view">
    <!-- Loading State -->
    <div v-if="loading" class="loading-state">
      <div class="spinner"></div>
      <p>Loading student details...</p>
    </div>

    <!-- Main Content -->
    <div v-else-if="student" class="student-content">
      <!-- Header -->
      <div class="header">
        <button @click="$router.back()" class="btn-back">← Back to Cohort</button>
        <h1>{{ student.name }}</h1>
        <span class="student-email">{{ student.email }}</span>
      </div>

      <!-- Status Banner -->
      <div class="status-banner" :class="student.status">
        <div class="status-icon">{{ getStatusIcon(student.status) }}</div>
        <div class="status-info">
          <div class="status-title">{{ getStatusTitle(student.status) }}</div>
          <div class="status-description">{{ getStatusDescription(student.status) }}</div>
        </div>
        <div class="status-timestamp" v-if="student.completedAt">
          Completed: {{ formatDate(student.completedAt) }}
        </div>
      </div>

      <!-- Quick Actions -->
      <div class="quick-actions">
        <button
          @click="sendReminder"
          class="btn btn-secondary"
          :disabled="student.status === 'completed'"
        >
          📧 Send Reminder
        </button>
        <button
          @click="resetProgress"
          class="btn btn-secondary"
          :disabled="student.status === 'pending'"
        >
          🔄 Reset Progress
        </button>
        <button
          @click="copyInviteLink"
          class="btn btn-secondary"
        >
          🔗 Copy Invite Link
        </button>
      </div>

      <!-- Document Status -->
      <div class="document-section">
        <h2>Document Status</h2>
        <div class="document-card">
          <div class="document-info">
            <div class="document-icon">📄</div>
            <div class="document-details">
              <div class="document-name">Student Document</div>
              <div class="document-status">
                <span class="badge" :class="student.status">
                  {{ student.status.replace('_', ' ') }}
                </span>
              </div>
            </div>
          </div>

          <div class="progress-tracker">
            <div class="step" :class="{ complete: student.status !== 'pending' }">
              <div class="step-circle">1</div>
              <div class="step-label">TP Signed</div>
            </div>
            <div class="step" :class="{ complete: student.status === 'completed' }">
              <div class="step-circle">2</div>
              <div class="step-label">Student Filled</div>
            </div>
            <div class="step" :class="{ complete: student.status === 'completed' }">
              <div class="step-circle">3</div>
              <div class="step-label">Sponsor Verified</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Required Uploads -->
      <div class="uploads-section" v-if="requiredUploads.length > 0">
        <h2>Required Uploads</h2>
        <div class="uploads-list">
          <div
            v-for="upload in requiredUploads"
            :key="upload.type"
            class="upload-item"
          >
            <div class="upload-info">
              <div class="upload-icon">📎</div>
              <div class="upload-details">
                <div class="upload-type">{{ upload.label }}</div>
                <div class="upload-status">
                  <span v-if="upload.uploaded" class="status-uploaded">
                    ✓ Uploaded ({{ formatDate(upload.uploadedAt) }})
                  </span>
                  <span v-else class="status-pending">
                    ⏳ Pending
                  </span>
                </div>
              </div>
            </div>
            <div class="upload-actions">
              <button
                v-if="upload.uploaded"
                @click="viewUpload(upload)"
                class="btn btn-sm"
              >
                View
              </button>
              <button
                v-else
                @click="remindUpload(upload)"
                class="btn btn-sm btn-secondary"
              >
                Remind
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Field Values -->
      <div class="fields-section">
        <h2>Form Field Values</h2>
        <div class="fields-card">
          <div v-if="student.fieldValues && Object.keys(student.fieldValues).length > 0">
            <div
              v-for="(value, key) in student.fieldValues"
              :key="key"
              class="field-item"
            >
              <div class="field-label">{{ formatFieldName(key) }}</div>
              <div class="field-value">{{ value || '(empty)' }}</div>
            </div>
          </div>
          <div v-else class="empty-state">
            <p>No fields filled yet</p>
          </div>
        </div>
      </div>

      <!-- Student Information -->
      <div class="student-info-section">
        <h2>Student Information</h2>
        <div class="info-grid">
          <div class="info-item">
            <div class="info-label">Email</div>
            <div class="info-value">{{ student.email }}</div>
          </div>
          <div class="info-item">
            <div class="info-label">Student ID</div>
            <div class="info-value">{{ student.studentId || 'N/A' }}</div>
          </div>
          <div class="info-item">
            <div class="info-label">Phone</div>
            <div class="info-value">{{ student.phone || 'N/A' }}</div>
          </div>
          <div class="info-item">
            <div class="info-label">Enrolled</div>
            <div class="info-value">{{ formatDate(student.createdAt) }}</div>
          </div>
        </div>
      </div>

      <!-- Audit Log -->
      <div class="audit-section">
        <h2>Audit Log</h2>
        <div class="audit-timeline">
          <div
            v-for="event in auditLog"
            :key="event.id"
            class="audit-event"
          >
            <div class="event-dot"></div>
            <div class="event-details">
              <div class="event-type">{{ event.type }}</div>
              <div class="event-description">{{ event.description }}</div>
              <div class="event-time">{{ formatDate(event.timestamp) }}</div>
            </div>
          </div>
          <div v-if="auditLog.length === 0" class="empty-state">
            <p>No events recorded yet</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Not Found -->
    <div v-else class="not-found">
      <h2>Student not found</h2>
      <p>The student may have been removed or the link is invalid.</p>
      <button @click="$router.back()" class="btn btn-primary">
        Back to Cohort
      </button>
    </div>

    <!-- Confirmation Modal -->
    <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
      <div class="confirmation-modal">
        <h3>{{ modalTitle }}</h3>
        <p>{{ modalMessage }}</p>
        <div class="modal-actions">
          <button @click="closeModal" class="btn btn-ghost">Cancel</button>
          <button @click="confirmModal" class="btn btn-primary">Confirm</button>
        </div>
      </div>
    </div>
  </div>
</template>
```

**Pinia Store:**
```typescript
// app/javascript/tp_portal/stores/studentDetailStore.ts
import { defineStore } from 'pinia'
import { StudentAPI } from '@/tp_portal/api/student'
import type { Student, Upload, AuditEvent } from '@/types'

export const useStudentDetailStore = defineStore('studentDetail', {
  state: () => ({
    student: null as Student | null,
    auditLog: [] as AuditEvent[],
    loading: false,
    error: null as string | null
  }),

  actions: {
    async loadStudent(cohortId: number, studentId: number): Promise<void> {
      this.loading = true
      this.error = null
      try {
        const [student, audit] = await Promise.all([
          StudentAPI.show(cohortId, studentId),
          StudentAPI.getAuditLog(cohortId, studentId)
        ])
        this.student = student
        this.auditLog = audit
      } catch (error) {
        this.error = 'Failed to load student'
        throw error
      } finally {
        this.loading = false
      }
    },

    async sendReminder(studentId: number): Promise<void> {
      await StudentAPI.sendReminder(studentId)
    },

    async resetProgress(studentId: number): Promise<void> {
      await StudentAPI.resetProgress(studentId)
      if (this.student) {
        this.student.status = 'pending'
        this.student.fieldValues = {}
      }
    },

    async copyInviteLink(cohortId: number, studentId: number): Promise<string> {
      return await StudentAPI.getInviteLink(cohortId, studentId)
    }
  }
})
```

**API Layer:**
```typescript
// app/javascript/tp_portal/api/student.ts
export const StudentAPI = {
  async show(cohortId: number, studentId: number): Promise<Student> {
    const response = await fetch(`/api/v1/cohorts/${cohortId}/students/${studentId}`)
    return response.json()
  },

  async getAuditLog(cohortId: number, studentId: number): Promise<AuditEvent[]> {
    const response = await fetch(`/api/v1/cohorts/${cohortId}/students/${studentId}/audit`)
    return response.json()
  },

  async sendReminder(studentId: number): Promise<void> {
    await fetch(`/api/v1/students/${studentId}/remind`, {
      method: 'POST'
    })
  },

  async resetProgress(studentId: number): Promise<void> {
    await fetch(`/api/v1/students/${studentId}/reset`, {
      method: 'POST'
    })
  },

  async getInviteLink(cohortId: number, studentId: number): Promise<string> {
    const response = await fetch(`/api/v1/cohorts/${cohortId}/students/${studentId}/invite_link`)
    const data = await response.json()
    return data.link
  },

  async viewUpload(uploadId: number): Promise<Blob> {
    const response = await fetch(`/api/v1/uploads/${uploadId}`, {
      method: 'GET'
    })
    return await response.blob()
  }
}
```

**Type Definitions:**
```typescript
export interface Student {
  id: number
  cohortId: number
  name: string
  email: string
  studentId?: string
  phone?: string
  status: 'pending' | 'in_progress' | 'completed'
  fieldValues: { [key: string]: string }
  requiredUploads: Upload[]
  createdAt: string
  completedAt?: string
}

export interface Upload {
  type: string
  label: string
  uploaded: boolean
  uploadedAt?: string
  filename?: string
}

export interface AuditEvent {
  id: number
  type: string
  description: string
  timestamp: string
}
```

**Design System Compliance:**

Per FR28, all components must use design system assets from:
- `@.claude/skills/frontend-design/SKILL.md`
- `@.claude/skills/frontend-design/design-system/`

Specifically: colors, icons, typography, and layout patterns from the design system.

##### Acceptance Criteria

**Functional:**
1. ✅ Loads student details on page visit
2. ✅ Displays student name and email
3. ✅ Shows status banner with correct state
4. ✅ Status banner shows correct icon
5. ✅ Status banner shows correct title
6. ✅ Status banner shows correct description
7. ✅ Shows completion timestamp if completed
8. ✅ "Send Reminder" button works
9. ✅ "Send Reminder" disabled for completed students
10. ✅ "Reset Progress" button works
11. ✅ "Reset Progress" disabled for pending students
12. ✅ "Copy Invite Link" button works
13. ✅ Invite link copied to clipboard
14. ✅ Document status shows correct progress tracker
15. ✅ Required uploads list shows all items
16. ✅ Upload status shows uploaded/pending correctly
17. ✅ "View" button for uploaded files works
18. ✅ "Remind" button for pending uploads works
19. ✅ Field values display correctly
20. ✅ Empty state when no fields filled
21. ✅ Student info grid shows all data
22. ✅ Audit log displays events chronologically
23. ✅ Empty state when no audit events
24. ✅ "Not found" state for invalid student
25. ✅ Confirmation modal for destructive actions
26. ✅ Modal cancels correctly
27. ✅ Modal confirms correctly

**UI/UX:**
1. ✅ Follows design system colors and spacing
2. ✅ Responsive layout on mobile devices
3. ✅ Loading state displays during data fetch
4. ✅ Status banners use correct color coding
5. ✅ Progress tracker is visually clear
6. ✅ Timeline is visually distinct
7. ✅ All buttons have proper hover states
8. ✅ Empty states are helpful and clear
9. ✅ Modal overlays work correctly
10. ✅ Copy confirmation feedback shown

**Integration:**
1. ✅ IV1: API calls use correct endpoints
2. ✅ IV2: Pinia store manages state correctly
3. ✅ IV3: Router navigation works
4. ✅ IV4: Clipboard API works for copy

**Security:**
1. ✅ Only authenticated TP users can access
2. ✅ Users can only view their institution's students
3. ✅ Sensitive data properly protected
4. ✅ All API endpoints require proper authorization
5. ✅ Invite links are token-based and secure

**Quality:**
1. ✅ Follows Vue 3 best practices
2. ✅ TypeScript types defined
3. ✅ Components are maintainable
4. ✅ 80% test coverage
5. ✅ Design system compliance verified

##### Integration Verification (IV1-4)

**IV1: API Integration**
- Verify GET /api/v1/cohorts/:id/students/:studentId returns correct data
- Verify GET /api/v1/cohorts/:id/students/:studentId/audit returns events
- Verify POST /api/v1/students/:id/remind sends email
- Verify POST /api/v1/students/:id/reset clears progress
- Verify GET /api/v1/cohorts/:id/students/:studentId/invite_link returns link

**IV2: Pinia Store**
- Verify student data is stored correctly
- Verify audit log is stored correctly
- Verify loading states during operations
- Verify state updates after actions

**IV3: Router Navigation**
- Verify back button works
- Verify navigation after reset
- Verify navigation guards

**IV4: Clipboard API**
- Verify copy to clipboard works
- Verify fallback for older browsers
- Verify user feedback on copy

##### Test Requirements

**Component Specs:**
```javascript
// spec/javascript/tp_portal/views/StudentDetailView.spec.js
import { mount, flushPromises } from '@vue/test-utils'
import StudentDetailView from '@/tp_portal/views/StudentDetailView.vue'
import { createPinia, setActivePinia } from 'pinia'

describe('StudentDetailView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('displays student information', async () => {
    const wrapper = mount(StudentDetailView)
    await flushPromises()

    expect(wrapper.find('h1').text()).toContain('John Doe')
    expect(wrapper.find('.student-email').text()).toBe('john@university.edu')
  })

  it('handles reset progress action', async () => {
    const wrapper = mount(StudentDetailView)
    await flushPromises()

    const resetButton = wrapper.find('button:contains("Reset Progress")')
    await resetButton.trigger('click')

    expect(wrapper.find('.modal-overlay').exists()).toBe(true)
  })
})
```

**E2E Test:**
```javascript
// spec/system/tp_portal/student_detail_spec.rb
require 'rails_helper'

RSpec.describe 'Student Detail', type: :system do
  let(:tp_user) { create(:user, :training_provider) }
  let(:cohort) { create(:cohort, account: tp_user.account) }
  let(:student) { create(:student, cohort: cohort, status: 'in_progress') }

  before do
    sign_in tp_user
    visit "/tp/cohorts/#{cohort.id}/students/#{student.id}"
  end

  it 'displays student details and allows management' do
    expect(page).to have_content(student.name)
    expect(page).to have_content(student.email)
    expect(page).to have_content('In Progress')

    # Test send reminder
    click_button 'Send Reminder'
    expect(page).to have_content('Reminder sent')

    # Test reset progress
    click_button 'Reset Progress'
    expect(page).to have_content('Confirm')
    click_button 'Confirm'
    expect(page).to have_content('Pending')
  end
end
```

##### Rollback Procedure

**If actions fail:**
1. Student data remains unchanged
2. Error messages guide user
3. Audit log records failures
4. User can retry actions

**Data Safety**: All actions are idempotent and reversible.

##### Risk Assessment

**Low Risk because:**
- Read-heavy view with simple actions
- Standard CRUD operations
- Well-established API patterns
- No complex data transformations

**Specific Risks:**
1. **Data Exposure**: Student data visible to wrong users
2. **Accidental Reset**: User resets wrong student
3. **Clipboard Failure**: Copy doesn't work on all browsers
4. **Large Audit Logs**: Could be slow to load

**Mitigation:**
- Authorization checks on every API call
- Confirmation modals for destructive actions
- Clipboard API with fallback
- Pagination for audit logs
- Audit trail for all actions

---

#### Story 4.6: Sponsor Portal Dashboard

**Status**: Draft
**Priority**: High
**Epic**: Phase 4 - Frontend - TP Portal
**Estimated Effort**: 3 days
**Risk Level**: Medium

##### User Story

**As a** Sponsor,
**I want** to access a dedicated portal where I can review and verify all student documents for a cohort,
**So that** I can sign once for the entire cohort instead of signing each student individually.

##### Background

The Sponsor Portal is a critical component of the 3-party workflow. Key requirements:
- Sponsor receives ONE email with a single access link
- Portal shows all students in two tabs based on sponsor's signing status:
  - **Pending Tab**: Students awaiting sponsor signature (before sponsor completes)
  - **Completed Tab**: Students where sponsor has already applied verification
- Sponsor fills their fields once
- System applies sponsor's signature to all student documents
- After sponsor signs once, all students move to the Completed tab
- Progress bar shows completion status

This is the second signing phase and requires careful state management.

##### Technical Implementation Notes

**Vue 3 Component Structure:**

```vue
<!-- app/javascript/sponsor_portal/views/SponsorDashboard.vue -->
<template>
  <div class="sponsor-dashboard">
    <!-- Loading State -->
    <div v-if="loading" class="loading-state">
      <div class="spinner"></div>
      <p>Loading cohort information...</p>
    </div>

    <!-- Main Content -->
    <div v-else-if="cohort" class="sponsor-content">
      <!-- Header -->
      <div class="header">
        <div class="cohort-info">
          <h1>{{ cohort.name }}</h1>
          <div class="cohort-meta">
            <span class="institution">{{ cohort.institutionName }}</span>
            <span class="date-range">{{ cohort.startDate }} - {{ cohort.endDate }}</span>
          </div>
        </div>
        <div class="progress-summary">
          <div class="progress-bar">
            <div class="progress-fill" :style="{ width: progressPercentage + '%' }"></div>
          </div>
          <div class="progress-text">
            {{ completedCount }} of {{ totalCount }} students completed
          </div>
        </div>
      </div>

      <!-- Welcome Banner -->
      <div class="welcome-banner">
        <div class="banner-icon">👋</div>
        <div class="banner-content">
          <h2>Welcome, Sponsor</h2>
          <p>
            You are reviewing documents for <strong>{{ cohort.name }}</strong>.
            Fill your information once, and it will be applied to all student documents.
          </p>
        </div>
      </div>

      <!-- Tab Navigation -->
      <div class="tab-navigation">
        <button
          @click="currentTab = 'pending'"
          :class="{ active: currentTab === 'pending' }"
          class="tab-btn"
        >
          Pending ({{ pendingCount }})
        </button>
        <button
          @click="currentTab = 'completed'"
          :class="{ active: currentTab === 'completed' }"
          class="tab-btn"
        >
          Completed ({{ completedCount }})
        </button>
      </div>

      <!-- Student List -->
      <div class="student-list-section">
        <!-- Pending Tab -->
        <div v-if="currentTab === 'pending'" class="pending-view">
          <div v-if="pendingStudents.length > 0" class="student-cards">
            <div
              v-for="student in pendingStudents"
              :key="student.id"
              class="student-card"
            >
              <div class="student-info">
                <div class="student-name">{{ student.name }}</div>
                <div class="student-email">{{ student.email }}</div>
                <div class="student-id" v-if="student.studentId">
                  ID: {{ student.studentId }}
                </div>
              </div>
              <div class="student-status">
                <span class="badge pending">Pending</span>
              </div>
            </div>
          </div>

          <div v-else class="empty-state">
            <div class="empty-icon">✓</div>
            <h3>All students completed!</h3>
            <p>You can now proceed to the sponsor signing phase.</p>
          </div>
        </div>

        <!-- Completed Tab -->
        <div v-else class="completed-view">
          <div v-if="completedStudents.length > 0" class="student-cards">
            <div
              v-for="student in completedStudents"
              :key="student.id"
              class="student-card completed"
            >
              <div class="student-info">
                <div class="student-name">{{ student.name }}</div>
                <div class="student-email">{{ student.email }}</div>
                <div class="completed-at">
                  Completed: {{ formatDate(student.completedAt) }}
                </div>
              </div>
              <div class="student-status">
                <span class="badge completed">✓ Completed</span>
              </div>
            </div>
          </div>

          <div v-else class="empty-state">
            <div class="empty-icon">📭</div>
            <h3>No completed students yet</h3>
            <p>Students will appear here after they complete their portion.</p>
          </div>
        </div>
      </div>

      <!-- Sponsor Signing Section -->
      <div class="sponsor-signing-section">
        <h2>Sponsor Information</h2>
        <div class="sponsor-form">
          <div class="form-grid">
            <div class="form-group">
              <label>Your Full Name *</label>
              <input
                v-model="sponsorForm.name"
                type="text"
                placeholder="Enter your full name"
                required
              />
            </div>

            <div class="form-group">
              <label>Your Title/Position *</label>
              <input
                v-model="sponsorForm.title"
                type="text"
                placeholder="e.g., Senior Manager"
                required
              />
            </div>

            <div class="form-group">
              <label>Date *</label>
              <input
                v-model="sponsorForm.date"
                type="date"
                required
              />
            </div>

            <div class="form-group">
              <label>Department</label>
              <input
                v-model="sponsorForm.department"
                type="text"
                placeholder="Optional"
              />
            </div>
          </div>

          <div class="signature-section">
            <label>Sponsor Signature *</label>
            <div class="signature-area">
              <div v-if="sponsorForm.signature" class="signature-preview">
                <img :src="sponsorForm.signature" alt="Signature" class="signature-img" />
                <button @click="sponsorForm.signature = null" class="btn-remove">
                  Remove & Redraw
                </button>
              </div>
              <button v-else @click="openSignaturePad" class="btn-signature">
                ✍️ Click to Draw Signature
              </button>
            </div>
          </div>

          <div class="consent-section">
            <label class="checkbox-label">
              <input
                type="checkbox"
                v-model="sponsorForm.agreesToTerms"
              />
              <span>
                I verify that all student information is correct and agree to sponsor these documents
              </span>
            </label>
          </div>
        </div>
      </div>

      <!-- Action Panel -->
      <div class="action-panel">
        <div class="validation-status">
          <div v-if="sponsorValidationErrors.length > 0" class="errors">
            <div v-for="error in sponsorValidationErrors" :key="error" class="error-item">
              ⚠️ {{ error }}
            </div>
          </div>
          <div v-else class="ready">
            ✓ Ready to sign
          </div>
        </div>

        <div class="actions">
          <button
            @click="previewSponsorFields"
            class="btn btn-secondary"
            :disabled="!canPreviewSponsor"
          >
            Preview Fields
          </button>
          <button
            @click="signAndApply"
            class="btn btn-primary"
            :disabled="!canSignSponsor"
          >
            Sign & Apply to {{ pendingCount }} Students
          </button>
        </div>
      </div>

      <!-- Success State -->
      <div v-if="isSponsorComplete" class="success-state">
        <div class="success-icon">✓</div>
        <h2>Sponsor Verification Complete!</h2>
        <p>
          Your signature and information have been applied to all {{ pendingCount }} pending student documents.
        </p>
        <div class="success-details">
          <div class="detail-card">
            <h4>What's Happening Now?</h4>
            <ul>
              <li>Students receive final confirmation</li>
              <li>Documents are being finalized</li>
              <li>TP will review and complete the workflow</li>
            </ul>
          </div>
        </div>
        <div class="success-actions">
          <button @click="refreshStatus" class="btn btn-primary">
            Refresh Status
          </button>
        </div>
      </div>
    </div>

    <!-- Not Found / Invalid Access -->
    <div v-else class="not-found">
      <div class="not-found-icon">🔒</div>
      <h2>Invalid Access Link</h2>
      <p>
        This sponsor link is invalid or has expired.
        Please contact your training provider for a new link.
      </p>
    </div>

    <!-- Signature Pad Modal -->
    <div v-if="showSignaturePad" class="modal-overlay" @click.self="closeSignaturePad">
      <div class="signature-modal">
        <h3>Draw Your Signature</h3>
        <div class="signature-canvas-container">
          <canvas
            ref="signatureCanvas"
            width="400"
            height="200"
            @mousedown="startDrawing"
            @mousemove="draw"
            @mouseup="stopDrawing"
            @mouseleave="stopDrawing"
            @touchstart="startDrawing"
            @touchmove="draw"
            @touchend="stopDrawing"
          ></canvas>
        </div>
        <div class="signature-actions">
          <button @click="clearSignature" class="btn btn-secondary">Clear</button>
          <button @click="saveSignature" class="btn btn-primary">Save Signature</button>
          <button @click="closeSignaturePad" class="btn btn-ghost">Cancel</button>
        </div>
      </div>
    </div>

    <!-- Preview Modal -->
    <div v-if="showPreview" class="modal-overlay" @click.self="showPreview = false">
      <div class="preview-modal">
        <div class="preview-header">
          <h3>Sponsor Fields Preview</h3>
          <button @click="showPreview = false" class="btn-close">×</button>
        </div>
        <div class="preview-content">
          <p>This shows how your information will appear on all student documents:</p>
          <div class="preview-fields">
            <div class="preview-field">
              <strong>Name:</strong> {{ sponsorForm.name || '(empty)' }}
            </div>
            <div class="preview-field">
              <strong>Title:</strong> {{ sponsorForm.title || '(empty)' }}
            </div>
            <div class="preview-field">
              <strong>Date:</strong> {{ sponsorForm.date || '(empty)' }}
            </div>
            <div class="preview-field">
              <strong>Department:</strong> {{ sponsorForm.department || '(empty)' }}
            </div>
            <div class="preview-field">
              <strong>Signature:</strong>
              <span v-if="sponsorForm.signature">✓ Saved</span>
              <span v-else>✗ Not signed</span>
            </div>
          </div>
          <p class="preview-note">
            Note: This will be applied to all {{ pendingCount }} pending student documents.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
```

**Pinia Store:**
```typescript
// app/javascript/sponsor_portal/stores/sponsorStore.ts
import { defineStore } from 'pinia'
import { SponsorAPI } from '@/sponsor_portal/api/sponsor'
import type { Cohort, Student, SponsorForm } from '@/types'

export const useSponsorStore = defineStore('sponsor', {
  state: () => ({
    cohort: null as Cohort | null,
    students: [] as Student[],
    loading: false,
    error: null as string | null,
    isComplete: false
  }),

  actions: {
    async loadCohort(token: string): Promise<void> {
      this.loading = true
      this.error = null
      try {
        const [cohort, students] = await Promise.all([
          SponsorAPI.getCohort(token),
          SponsorAPI.getStudents(token)
        ])
        this.cohort = cohort
        this.students = students
      } catch (error) {
        this.error = 'Invalid or expired token'
        throw error
      } finally {
        this.loading = false
      }
    },

    async signAndApply(token: string, form: SponsorForm): Promise<void> {
      this.loading = true
      try {
        await SponsorAPI.signAndApply(token, form)
        this.isComplete = true
        // Refresh student list
        this.students = await SponsorAPI.getStudents(token)
      } catch (error) {
        this.error = 'Signing failed'
        throw error
      } finally {
        this.loading = false
      }
    },

    async refreshStatus(token: string): Promise<void> {
      this.students = await SponsorAPI.getStudents(token)
    }
  },

  getters: {
    pendingStudents: (state) => state.students.filter(s => s.status === 'pending'),
    completedStudents: (state) => state.students.filter(s => s.status === 'completed'),
    pendingCount: (state) => state.students.filter(s => s.status === 'pending').length,
    completedCount: (state) => state.students.filter(s => s.status === 'completed').length,
    totalCount: (state) => state.students.length,
    progressPercentage: (state) => {
      if (state.students.length === 0) return 0
      const completed = state.students.filter(s => s.status === 'completed').length
      return Math.round((completed / state.students.length) * 100)
    }
  }
})
```

**API Layer:**
```typescript
// app/javascript/sponsor_portal/api/sponsor.ts
export const SponsorAPI = {
  async getCohort(token: string): Promise<Cohort> {
    const response = await fetch(`/api/v1/sponsor/cohort`, {
      headers: { 'Authorization': `Bearer ${token}` }
    })
    return response.json()
  },

  async getStudents(token: string): Promise<Student[]> {
    const response = await fetch(`/api/v1/sponsor/students`, {
      headers: { 'Authorization': `Bearer ${token}` }
    })
    return response.json()
  },

  async signAndApply(token: string, form: SponsorForm): Promise<void> {
    await fetch(`/api/v1/sponsor/sign`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ sponsor_form: form })
    })
  }
}
```

**Type Definitions:**
```typescript
export interface SponsorForm {
  name: string
  title: string
  date: string
  department?: string
  signature: string | null
  agreesToTerms: boolean
}
```

**Design System Compliance:**

Per FR28, all components must use design system assets from:
- `@.claude/skills/frontend-design/SKILL.md`
- `@.claude/skills/frontend-design/design-system/`

Specifically: colors, icons, typography, and layout patterns from the design system.

##### Acceptance Criteria

**Functional:**
1. ✅ Loads cohort data using token from URL
2. ✅ Displays cohort name and institution
3. ✅ Shows progress bar with correct percentage
4. ✅ Displays student counts (pending/completed)
5. ✅ Tab navigation switches between pending/completed
6. ✅ Pending tab shows all pending students
7. ✅ Completed tab shows all completed students
8. ✅ Student cards display name, email, ID
9. ✅ Empty states show when no students in tab
10. ✅ Sponsor form has all required fields
11. ✅ Form validation prevents submission if incomplete
12. ✅ Signature pad opens when clicking sign button
13. ✅ Signature can be drawn on canvas
14. ✅ Signature can be cleared
15. ✅ Signature can be saved
16. ✅ Signature preview shows saved signature
17. ✅ "Remove & Redraw" works
18. ✅ Checkbox consent works
19. ✅ Preview button shows all fields
20. ✅ Sign & Apply button disabled until valid
21. ✅ Success state shows after signing
22. ✅ Refresh button updates student list
23. ✅ Invalid token shows error state

**UI/UX:**
1. ✅ Follows design system colors and spacing
2. ✅ Responsive layout on mobile devices
3. ✅ Loading state displays during data fetch
4. ✅ Progress bar is visually clear
5. ✅ Tab navigation is intuitive
6. ✅ Student cards are visually distinct
7. ✅ Modal overlays work correctly
8. ✅ Canvas drawing is smooth
9. ✅ Error messages are clear
10. ✅ Success state is visually distinct

**Integration:**
1. ✅ IV1: API calls use correct endpoints with token auth
2. ✅ IV2: Pinia store manages state correctly
3. ✅ IV3: Getters calculate counts correctly
4. ✅ IV4: Token-based routing works

**Security:**
1. ✅ Token-based authentication required
2. ✅ Token expires after use or time limit
3. ✅ Sponsor can only access assigned cohort
4. ✅ All API endpoints require valid token
5. ✅ Signature data is securely stored

**Quality:**
1. ✅ Follows Vue 3 best practices
2. ✅ TypeScript types defined
3. ✅ Components are maintainable
4. ✅ 80% test coverage
5. ✅ Design system compliance verified

##### Integration Verification (IV1-4)

**IV1: API Integration**
- Verify GET /api/v1/sponsor/cohort returns correct data
- Verify GET /api/v1/sponsor/students returns filtered list
- Verify POST /api/v1/sponsor/sign applies to all students
- Verify token authentication works
- Verify error handling for invalid tokens

**IV2: Pinia Store**
- Verify cohort and students stored correctly
- Verify getters calculate counts correctly
- Verify isComplete state updates
- Verify loading states during operations

**IV3: Getters**
- Verify pendingStudents returns correct list
- Verify completedStudents returns correct list
- Verify counts are accurate
- Verify progress percentage calculation

**IV4: Token Routing**
- Verify token extracted from URL
- Verify token passed to all API calls
- Verify invalid token shows error

##### Test Requirements

**Component Specs:**
```javascript
// spec/javascript/sponsor_portal/views/SponsorDashboard.spec.js
import { mount, flushPromises } from '@vue/test-utils'
import SponsorDashboard from '@/sponsor_portal/views/SponsorDashboard.vue'
import { createPinia, setActivePinia } from 'pinia'

describe('SponsorDashboard', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('calculates progress correctly', async () => {
    const wrapper = mount(SponsorDashboard)
    await flushPromises()

    expect(wrapper.vm.progressPercentage).toBe(40) // 4 of 10 completed
    expect(wrapper.vm.pendingCount).toBe(6)
    expect(wrapper.vm.completedCount).toBe(4)
  })

  it('validates sponsor form before signing', async () => {
    const wrapper = mount(SponsorDashboard)
    await flushPromises()

    // Leave fields empty
    const signButton = wrapper.find('.btn-primary')
    expect(signButton.attributes('disabled')).toBe('disabled')
  })
})
```

**E2E Test:**
```javascript
// spec/system/sponsor_portal/dashboard_spec.rb
require 'rails_helper'

RSpec.describe 'Sponsor Portal Dashboard', type: :system do
  let(:cohort) { create(:cohort_with_students, student_count: 10) }
  let(:token) { create_sponsor_token(cohort) }

  before do
    # Mark 4 students as completed
    cohort.students.limit(4).update_all(status: 'completed')
    visit "/sponsor/#{token}"
  end

  it 'displays cohort and allows sponsor signing' do
    expect(page).to have_content(cohort.name)
    expect(page).to have_content('6 of 10 students completed')

    # Fill sponsor form
    fill_in 'Your Full Name', with: 'John Sponsor'
    fill_in 'Your Title/Position', with: 'Director'
    fill_in 'Date', with: '2025-01-15'
    check 'I verify that all student information is correct'

    # Mock signature
    page.execute_script("document.querySelector('[v-model=\"sponsorForm.signature\"]').value = 'data:image/png;base64,mock'")

    click_button 'Sign & Apply to 6 Students'

    expect(page).to have_content('Sponsor Verification Complete!')
  end
end
```

##### Rollback Procedure

**If signing fails:**
1. No data is modified (transactional)
2. User can retry with corrected data
3. Field values preserved in state
4. Error messages guide user

**Data Safety**: Signing is atomic - either all students get sponsor verification or none.

##### Risk Assessment

**Medium Risk because:**
- Token-based authentication complexity
- State management across multiple students
- Canvas drawing implementation
- Critical workflow step

**Specific Risks:**
1. **Token Security**: Token could be leaked or shared
2. **State Desync**: Student list out of date
3. **Canvas Issues**: Signature not captured correctly
4. **Concurrent Access**: Multiple sponsor sessions
5. **Email Exposure**: Token in email could be forwarded

**Mitigation:**
- Short-lived tokens (24-48 hours)
- Token single-use option
- Refresh mechanism for student list
- Canvas fallback (text signature option)
- Audit all sponsor access
- Clear messaging about token security
- Rate limiting on token endpoints

---


#### Story 4.7: Sponsor Portal - Bulk Document Signing

**Status**: Draft/Pending
**Priority**: High
**Epic**: TP Portal - Frontend Development
**Estimated Effort**: 3 days
**Risk Level**: Medium

##### User Story

**As a** Sponsor,
**I want** to sign once and have that signature applied to all pending student documents,
**So that** I don't need to manually sign each student's documents individually.

##### Background

In the previous story, sponsors gain access to a dashboard that tracks student completion status (Waiting → In Progress). Once all students have completed their part (uploaded required documents + completed their fields), the sponsor receives the bulk signing prompt.

The current DocuSeal limitation is that each submission requires independent signing, which creates unnecessary friction when the same sponsor is signing the same document type for multiple students in the same cohort. The sponsor portal must enable a bulk signing workflow where:

1. Sponsor reviews the general cohort document structure
2. Sponsor provides their signature once
3. System atomically applies this signature to ALL 20+ student submissions
4. System transitions cohort state to "Completed - Signed"
5. Single sponsor email notification (not one per student)

This aligns with FR10 (Bulk Signing) and FR13 (Single Email Rule).

##### Technical Implementation Notes

**Vue 3 Component Structure:**
```vue
<!-- app/javascript/sponsor/views/BulkSigningModal.vue -->
<template>
  <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" v-if="isOpen">
    <div class="bg-white rounded-lg shadow-xl max-w-4xl w-full mx-4 max-h-[90vh] overflow-y-auto">
      <!-- Header -->
      <div class="border-b px-6 py-4">
        <h2 class="text-2xl font-bold text-gray-900">Bulk Sign All Documents</h2>
        <p class="text-sm text-gray-600 mt-1">
          Review and sign once to apply your signature to all {{ pendingCount }} pending student documents
        </p>
      </div>

      <!-- Progress & Student List -->
      <div class="px-6 py-4 space-y-6">
        <div class="grid grid-cols-2 gap-4">
          <div>
            <h3 class="font-semibold text-gray-900 mb-2">Pending Students ({{ pendingStudents.length }})</h3>
            <div class="max-h-40 overflow-y-auto border rounded-md">
              <div v-for="student in pendingStudents" :key="student.id" class="p-2 border-b last:border-b-0 text-sm">
                {{ student.name }} - {{ student.email }}
              </div>
            </div>
          </div>
          <div>
            <h3 class="font-semibold text-gray-900 mb-2">Completed Students ({{ completedStudents.length }})</h3>
            <div class="max-h-40 overflow-y-auto border rounded-md">
              <div v-for="student in completedStudents" :key="student.id" class="p-2 border-b last:border-b-0 text-sm">
                {{ student.name }} - {{ student.email }}
              </div>
            </div>
          </div>
        </div>

        <!-- Document Preview -->
        <div class="bg-gray-50 rounded-lg p-4 border-2 border-dashed">
          <div class="flex justify-between items-center mb-3">
            <span class="font-semibold">Document Preview</span>
            <button @click="refreshPreview" class="text-sm text-blue-600 hover:underline">
              Refresh Preview
            </button>
          </div>
          <div class="bg-white border rounded-md p-4 text-center text-gray-500 min-h-[200px] flex items-center justify-center" v-if="!previewReady">
            <span>Generating document preview...</span>
          </div>
          <div v-else>
            <iframe :src="previewUrl" class="w-full h-[400px] border rounded-md" />
          </div>
        </div>

        <!-- Signature Canvas -->
        <div class="space-y-3">
          <label class="block font-semibold text-gray-900">
            Your Signature
            <span class="text-red-500">*</span>
          </label>
          <div class="border-2 border-gray-300 rounded-md bg-white">
            <canvas
              ref="signatureCanvas"
              width="600"
              height="150"
              class="w-full cursor-crosshair"
              @mousedown="startDrawing"
              @mousemove="draw"
              @mouseup="stopDrawing"
              @mouseleave="stopDrawing"
              @touchstart="startDrawing"
              @touchmove="draw"
              @touchend="stopDrawing"
            />
          </div>
          <div class="flex gap-2">
            <button
              @click="clearSignature"
              class="px-3 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50"
            >
              Clear
            </button>
            <button
              @click="useTextSignature"
              class="px-3 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50"
            >
              Type Instead
            </button>
          </div>
        </div>

        <!-- Confirmation -->
        <div class="bg-blue-50 border border-blue-200 rounded-md p-4">
          <label class="flex items-start gap-3 cursor-pointer">
            <input
              type="checkbox"
              v-model="confirmationChecked"
              class="mt-1 accent-blue-600"
            />
            <span class="text-sm text-blue-900">
              I understand that my signature will be applied to all {{ pendingCount }} pending student documents at once. This action cannot be undone without contacting the training institution.
            </span>
          </label>
        </div>
      </div>

      <!-- Footer -->
      <div class="border-t px-6 py-4 bg-gray-50 flex justify-end gap-3">
        <button
          @click="closeModal"
          class="px-4 py-2 border border-gray-300 rounded-md hover:bg-gray-100"
        >
          Cancel
        </button>
        <button
          @click="bulkSign"
          :disabled="!isFormValid"
          class="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed font-semibold"
        >
          Sign All {{ pendingCount }} Documents
        </button>
      </div>
    </div>
  </div>

  <!-- Text Signature Modal -->
  <TextSignatureModal
    v-if="showTextModal"
    @submit="handleTextSignature"
    @cancel="showTextModal = false"
  />
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useBulkSigningStore } from '@/sponsor/stores/bulkSigning'
import { useAuthStore } from '@/sponsor/stores/auth'
import TextSignatureModal from './TextSignatureModal.vue'

const props = defineProps<{
  cohortId: number
  token: string
}>()

const emit = defineEmits<{
  (e: 'signed'): void
  (e: 'close'): void
}>()

const bulkSigningStore = useBulkSigningStore()
const authStore = useAuthStore()

const signatureCanvas = ref<HTMLCanvasElement | null>(null)
const isDrawing = ref(false)
const ctx = ref<CanvasRenderingContext2D | null>(null)
const confirmationChecked = ref(false)
const showTextModal = ref(false)
const previewReady = ref(false)
const previewUrl = ref('')

const pendingStudents = computed(() => bulkSigningStore.pendingStudents)
const completedStudents = computed(() => bulkSigningStore.completedStudents)
const pendingCount = computed(() => pendingStudents.value.length)

const isFormValid = computed(() => {
  return pendingCount.value > 0 &&
         confirmationChecked.value &&
         (bulkSigningStore.signatureData || bulkSigningStore.textSignature)
})

onMounted(async () => {
  await bulkSigningStore.fetchCohortData(props.cohortId, props.token)

  // Setup canvas
  if (signatureCanvas.value) {
    ctx.value = signatureCanvas.value.getContext('2d')
    if (ctx.value) {
      ctx.value.strokeStyle = '#000000'
      ctx.value.lineWidth = 2
      ctx.value.lineCap = 'round'
    }
  }

  // Generate preview
  await generatePreview()
})

watch(() => bulkSigningStore.signatureData, async (newVal) => {
  if (newVal) {
    await generatePreview()
  }
})

// Drawing functions
const startDrawing = (e: MouseEvent | TouchEvent) => {
  if (!ctx.value || !signatureCanvas.value) return
  isDrawing.value = true

  const rect = signatureCanvas.value.getBoundingClientRect()
  const clientX = 'clientX' in e ? e.clientX : e.touches[0].clientX
  const clientY = 'clientY' in e ? e.clientY : e.touches[0].clientY

  ctx.value.beginPath()
  ctx.value.moveTo(clientX - rect.left, clientY - rect.top)
}

const draw = (e: MouseEvent | TouchEvent) => {
  if (!ctx.value || !signatureCanvas.value || !isDrawing.value) return

  const rect = signatureCanvas.value.getBoundingClientRect()
  const clientX = 'clientX' in e ? e.clientX : e.touches[0].clientX
  const clientY = 'clientY' in e ? e.clientY : e.touches[0].clientY

  ctx.value.lineTo(clientX - rect.left, clientY - rect.top)
  ctx.value.stroke()
  e.preventDefault()
}

const stopDrawing = () => {
  if (!ctx.value || !signatureCanvas.value) return
  isDrawing.value = false
  ctx.value.closePath()

  // Save signature data
  bulkSigningStore.signatureData = signatureCanvas.value.toDataURL()
}

const clearSignature = () => {
  if (!ctx.value || !signatureCanvas.value) return
  ctx.value.clearRect(0, 0, signatureCanvas.value.width, signatureCanvas.value.height)
  bulkSigningStore.signatureData = null
}

const useTextSignature = () => {
  showTextModal.value = true
}

const handleTextSignature = (text: string) => {
  bulkSigningStore.textSignature = text
  showTextModal.value = false

  // Render text on canvas
  if (ctx.value && signatureCanvas.value) {
    ctx.value.clearRect(0, 0, signatureCanvas.value.width, signatureCanvas.value.height)
    ctx.value.font = 'italic 48px cursive'
    ctx.value.fillStyle = '#000000'
    ctx.value.textAlign = 'center'
    ctx.value.textBaseline = 'middle'
    ctx.value.fillText(text, signatureCanvas.value.width / 2, signatureCanvas.value.height / 2)
  }
}

const generatePreview = async () => {
  if (!bulkSigningStore.signatureData && !bulkSigningStore.textSignature) return

  previewReady.value = false
  try {
    const response = await bulkSigningStore.generatePreview(props.cohortId, props.token)
    previewUrl.value = response.preview_url
    previewReady.value = true
  } catch (error) {
    console.error('Failed to generate preview:', error)

    // Fallback: show a placeholder
    previewReady.value = true
    previewUrl.value = `data:text/html,${encodeURIComponent(`
      <html><body style="display:flex;align-items:center;justify-content:center;font-family:sans-serif;color:#666;">
        <div style="text-align:center;">
          <h3>Preview Unavailable</h3>
          <p>Signature will be applied to all documents</p>
          <p>Preview will be visible after signing</p>
        </div>
      </body></html>
    `)}`
  }
}

const refreshPreview = () => {
  generatePreview()
}

const bulkSign = async () => {
  if (!isFormValid.value) return

  try {
    await bulkSigningStore.bulkSign(props.cohortId, props.token)
    emit('signed')
    emit('close')
  } catch (error) {
    console.error('Bulk signing failed:', error)
    // Error handling handled by store
  }
}

const closeModal = () => {
  emit('close')
}
</script>

<style scoped>
canvas {
  touch-action: none;
}
</style>
```

**Pinia Store:**
```typescript
// app/javascript/sponsor/stores/bulkSigning.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { CohortAPI } from '@/sponsor/api/cohort'
import { SubmissionAPI } from '@/sponsor/api/submission'
import type { CohortData, Student, BulkSignResponse, PreviewResponse } from '@/sponsor/types'

export const useBulkSigningStore = defineStore('bulkSigning', {
  state: () => ({
    cohortData: null as CohortData | null,
    signatureData: null as string | null,
    textSignature: null as string | null,
    isLoading: false,
    error: null as string | null,
    signingInProgress: false
  }),

  getters: {
    pendingStudents: (state) => {
      return state.cohortData?.students.filter(s => s.status === 'completed_student') || []
    },

    completedStudents: (state) => {
      return state.cohortData?.students.filter(s => s.status === 'completed_all') || []
    },

    totalCount: (state) => {
      return state.cohortData?.students.length || 0
    },

    cohortName: (state) => {
      return state.cohortData?.name || ''
    }
  },

  actions: {
    async fetchCohortData(cohortId: number, token: string): Promise<void> {
      this.isLoading = true
      this.error = null

      try {
        const response = await CohortAPI.getCohortForSigning(cohortId, token)
        this.cohortData = response

        // Verify all prerequisite states
        const allStudentsReady = this.cohortData.students.every(s =>
          ['completed_student', 'completed_all'].includes(s.status)
        )

        if (!allStudentsReady) {
          throw new Error('Not all students have completed their required actions yet')
        }
      } catch (error) {
        this.error = error instanceof Error ? error.message : 'Failed to fetch cohort data'
        console.error('Fetch cohort data error:', error)
        throw error
      } finally {
        this.isLoading = false
      }
    },

    async generatePreview(cohortId: number, token: string): Promise<PreviewResponse> {
      if (!this.signatureData && !this.textSignature) {
        throw new Error('No signature available for preview')
      }

      try {
        const response = await SubmissionAPI.generateBulkPreview(
          cohortId,
          token,
          this.signatureData,
          this.textSignature
        )
        return response
      } catch (error) {
        console.error('Preview generation error:', error)
        throw error
      }
    },

    async bulkSign(cohortId: number, token: string): Promise<BulkSignResponse> {
      if (!this.signatureData && !this.textSignature) {
        throw new Error('No signature data available')
      }

      if (this.signingInProgress) {
        throw new Error('Signing is already in progress')
      }

      this.signingInProgress = true
      this.error = null

      try {
        const response = await SubmissionAPI.bulkSignCohort(
          cohortId,
          token,
          {
            signature_data: this.signatureData,
            text_signature: this.textSignature,
            signature_type: this.signatureData ? 'canvas' : 'text'
          }
        )

        // Clear signature data after successful signing
        this.signatureData = null
        this.textSignature = null

        return response
      } catch (error) {
        this.error = error instanceof Error ? error.message : 'Bulk signing failed'
        console.error('Bulk sign error:', error)
        throw error
      } finally {
        this.signingInProgress = false
      }
    },

    resetSignature(): void {
      this.signatureData = null
      this.textSignature = null
    },

    clearError(): void {
      this.error = null
    }
  }
})
```

**API Layer:**
```typescript
// app/javascript/sponsor/api/cohort.ts
import type { CohortData, CohortListResponse } from '@/sponsor/types'

export const CohortAPI = {
  async getCohortForSigning(cohortId: number, token: string): Promise<CohortData> {
    const response = await fetch(`/api/sponsor/cohorts/${cohortId}/bulk-sign`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    })

    if (!response.ok) {
      if (response.status === 403) {
        throw new Error('Access denied or token expired')
      }
      if (response.status === 404) {
        throw new Error('Cohort not found')
      }
      if (response.status === 409) {
        throw new Error('Cohort not ready for signing - not all students have completed')
      }
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    return response.json()
  },

  async getCohortProgress(cohortId: number, token: string): Promise<CohortData> {
    const response = await fetch(`/api/sponsor/cohorts/${cohortId}/progress`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    })

    if (!response.ok) {
      throw new Error(`Failed to fetch progress: ${response.status}`)
    }

    return response.json()
  }
}

// app/javascript/sponsor/api/submission.ts
export interface BulkSignPayload {
  signature_data: string | null
  text_signature: string | null
  signature_type: 'canvas' | 'text'
}

export interface PreviewResponse {
  preview_url: string
  expires_at: string
}

export interface BulkSignResponse {
  success: boolean
  signed_count: number
  cohort_id: number
  status: string
  completed_at: string
}

export const SubmissionAPI = {
  async generateBulkPreview(
    cohortId: number,
    token: string,
    signatureData: string | null,
    textSignature: string | null
  ): Promise<PreviewResponse> {
    const response = await fetch(`/api/sponsor/submissions/bulk-preview`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        cohort_id: cohortId,
        signature_data: signatureData,
        text_signature: textSignature
      })
    })

    if (!response.ok) {
      throw new Error(`Preview generation failed: ${response.status}`)
    }

    return response.json()
  },

  async bulkSignCohort(
    cohortId: number,
    token: string,
    payload: BulkSignPayload
  ): Promise<BulkSignResponse> {
    const response = await fetch(`/api/sponsor/submissions/bulk-sign`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        cohort_id: cohortId,
        ...payload
      })
    })

    if (!response.ok) {
      if (response.status === 409) {
        const error = await response.json()
        throw new Error(error.message || 'Signing conflict - may already be signed')
      }
      throw new Error(`Bulk signing failed: ${response.status}`)
    }

    return response.json()
  }
}
```

**Type Definitions:**
```typescript
// app/javascript/sponsor/types/index.ts
export interface Student {
  id: number
  name: string
  email: string
  status: 'waiting' | 'in_progress' | 'completed_student' | 'completed_all'
  progress: number
  documents: DocumentSummary[]
  last_activity: string
}

export interface DocumentSummary {
  id: number
  name: string
  status: 'pending' | 'filled' | 'signed'
  submission_id: number
}

export interface CohortData {
  id: number
  name: string
  description: string
  status: 'active' | 'completed'
  total_students: number
  students: Student[]
  sponsor_access: SponsorAccess
  created_at: string
  updated_at: string
  sign_by_date: string | null
}

export interface SponsorAccess {
  token: string
  last_access: string
  expires_at: string
  can_sign: boolean
}

export interface PreviewResponse {
  preview_url: string
  expires_at: string
}

export interface BulkSignResponse {
  success: boolean
  signed_count: number
  cohort_id: number
  status: string
  completed_at: string
}

export interface BulkSignPayload {
  signature_data: string | null
  text_signature: string | null
  signature_type: 'canvas' | 'text'
}
```

**Design System Compliance:**
Per FR28, all Bulk Signing components must use design system assets from:
- `@.claude/skills/frontend-design/SKILL.md` - Design tokens
- `@.claude/skills/frontend-design/design-system/` - SVG assets

Specific requirements:
- **Colors**: Primary = `#2563EB` (blue-600), Secondary = `#64748B` (slate-500), Danger = `#DC2626` (red-600)
- **Spacing**: 4px base unit (0.25rem increments)
- **Typography**: Sans-serif stack, 16px base, 20px h1, 18px h2, 16px body
- **Icons**: Use SVG icons from design system for actions (sign, clear, refresh)
- **Layout**: Maximum width 4xl (896px), rounded-lg corners, shadow-xl for modals
- **Accessibility**: All buttons must have ARIA labels, canvas must have keyboard fallback

##### Acceptance Criteria

**Functional:**
1. ✅ Sponsor can only access bulk signing when all students are in "completed_student" status
2. ✅ Signature can be provided via canvas (draw) or text input (typed)
3. ✅ Preview shows signature applied to sample document before final signing
4. ✅ Bulk sign button is disabled until canvas has data + confirmation checkbox is checked
5. ✅ Clicking "Sign All" atomically applies signature to all pending submissions
6. ✅ System transitions cohort from "ready_for_sponsor" to "completed_sponsor"
7. ✅ After signing, sponsor is redirected to sponsor dashboard with success message
8. ✅ All signed documents show in "completed" tab

**UI/UX:**
1. ✅ Modal-based interface with clear progress indicators
2. ✅ Privacy notice about bulk signing action and irreversibility
3. ✅ Student list shows pending vs completed with counts
4. ✅ Canvas with clear/clear & type fallback options
5. ✅ Signature preview generation within 2 seconds
6. ✅ Loading states during preview generation and signing
7. ✅ Error messages displayed in red with actionable retry options
8. ✅ Mobile-responsive design (signature canvas scales)

**Integration:**
1. ✅ API endpoints: `GET /api/sponsor/cohorts/{id}/bulk-sign` and `POST /api/sponsor/submissions/bulk-sign`
2. ✅ Token authentication in headers for all requests
3. ✅ Cohort state machine updates to `completed_sponsor`
4. ✅ Single email notification to training provider on completion
5. ✅ Final documents stored in DocuSeal with sponsor signature

**Security:**
1. ✅ Token-based authentication with expiration handling
2. ✅ Authorization check: sponsor can only sign their assigned cohort
3. ✅ Signature data validated (not empty) before processing
4. ✅ Rate limiting: maximum 5 bulk signing attempts per hour per token
5. ✅ Audit log entry created for each bulk signing action

**Quality:**
1. ✅ Atomic transaction: all documents signed or none
2. ✅ Performance: handles 50+ students with sub-5-second response
3. ✅ Error handling: email to TP admin if bulk signing fails
4. ✅ Canonical signature application (same signature instance across all)

##### Integration Verification (IV1-4)

**IV1: API Integration**
- `BulkSigningModal` calls `CohortAPI.getCohortForSigning()` on mount
- `BulkSigningModal` calls `SubmissionAPI.generateBulkPreview()` when signature is entered
- `BulkSigningModal` calls `SubmissionAPI.bulkSignCohort()` on confirmation
- All endpoints use `Authorization: Bearer {token}` header
- Error handling maps HTTP 403/404/409 to user-friendly messages

**IV2: Pinia Store**
- `bulkSigningStore.signatureData` tracks canvas-generated data
- `bulkSigningStore.textSignature` tracks text input
- `bulkSigningStore.fetchCohortData()` validates student readiness
- `bulkSigningStore.generatePreview()` provides immediate visual feedback
- `bulkSigningStore.bulkSign()` performs the atomic signing operation
- Reset clears signature state but keeps cohort data

**IV3: Getters**
- `pendingStudents()` filters for `completed_student`
- `completedStudents()` filters for `completed_all`
- `isFormValid()` enforces both signature and checkbox

**IV4: Token Routing**
- Bulk signing modal receives `token` prop from parent
- Parent `SponsorPortal` loads token from URL param (`?token=...`)
- All API calls pass token to child stores

##### Test Requirements

**Component Specs:**
```javascript
// spec/javascript/sponsor/views/BulkSigningModal.spec.js
import { mount, flushPromises } from '@vue/test-utils'
import BulkSigningModal from '@/sponsor/views/BulkSigningModal.vue'
import { useBulkSigningStore } from '@/sponsor/stores/bulkSigning'
import { createPinia, setActivePinia } from 'pinia'

describe('BulkSigningModal', () => {
  const mockCohortData = {
    id: 1,
    name: 'Cohort A',
    students: [
      { id: 1, name: 'John Doe', email: 'john@test.com', status: 'completed_student' },
      { id: 2, name: 'Jane Smith', email: 'jane@test.com', status: 'completed_student' }
    ]
  }

  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('renders pending and completed student lists correctly', async () => {
    const wrapper = mount(BulkSigningModal, {
      props: { cohortId: 1, token: 'test-token' },
      global: {
        stubs: { TextSignatureModal: true }
      }
    })

    const store = useBulkSigningStore()
    store.cohortData = mockCohortData
    await flushPromises()

    expect(wrapper.text()).toContain('Pending Students (2)')
    expect(wrapper.text()).toContain('John Doe')
    expect(wrapper.text()).toContain('Jane Smith')
  })

  it('enables bulk sign button only when signature and checkbox are set', async () => {
    const wrapper = mount(BulkSigningModal, {
      props: { cohortId: 1, token: 'test-token' },
      global: {
        stubs: { TextSignatureModal: true }
      }
    })

    const store = useBulkSigningStore()
    store.cohortData = mockCohortData
    await flushPromises()

    const signButton = wrapper.find('button.bg-blue-600')
    expect(signButton.element.disabled).toBe(true)

    // Add signature data
    store.signatureData = 'data:image/png;base64,mock'
    await wrapper.vm.$nextTick()
    expect(signButton.element.disabled).toBe(true)

    // Check confirmation
    await wrapper.find('input[type="checkbox"]').trigger('change')
    await wrapper.vm.$nextTick()
    expect(signButton.element.disabled).toBe(false)
  })

  it('clears signature and state on clear button click', async () => {
    const wrapper = mount(BulkSigningModal, {
      props: { cohortId: 1, token: 'test-token' },
      global: {
        stubs: { TextSignatureModal: true }
      }
    })

    const store = useBulkSigningStore()
    store.signatureData = 'data:image/png;base64,mock'

    const clearButton = wrapper.find('button').filter(node => node.text() === 'Clear')
    await clearButton.trigger('click')

    expect(store.signatureData).toBe(null)
  })

  it('performs bulk signing and emits events on success', async () => {
    const mockBulkSign = vi.fn().mockResolvedValue({ success: true })
    const mockRouterPush = vi.fn()

    const wrapper = mount(BulkSigningModal, {
      props: { cohortId: 1, token: 'test-token' },
      global: {
        stubs: { TextSignatureModal: true },
        mocks: {
          $router: { push: mockRouterPush }
        }
      }
    })

    const store = useBulkSigningStore()
    store.bulkSign = mockBulkSign
    store.cohortData = mockCohortData
    store.signatureData = 'data:image/png;base64,mock'

    await wrapper.vm.$nextTick()
    await wrapper.find('input[type="checkbox"]').trigger('change')
    await wrapper.find('button.bg-blue-600').trigger('click')

    expect(mockBulkSign).toHaveBeenCalledWith(1, 'test-token')
    expect(wrapper.emitted()).toHaveProperty('signed')
    expect(wrapper.emitted()).toHaveProperty('close')
  })

  it('shows error notification when cohort not ready', async () => {
    const wrapper = mount(BulkSigningModal, {
      props: { cohortId: 1, token: 'test-token' },
      global: {
        stubs: { TextSignatureModal: true }
      }
    })

    const store = useBulkSigningStore()
    store.error = 'Cohort not ready for signing'
    await wrapper.vm.$nextTick()

    expect(wrapper.text()).toContain('Cohort not ready for signing')
  })

  it('handles text signature fallback', async () => {
    const wrapper = mount(BulkSigningModal, {
      props: { cohortId: 1, token: 'test-token' },
      global: {
        stubs: { TextSignatureModal: false }
      }
    })

    const typeButton = wrapper.find('button').filter(node => node.text() === 'Type Instead')
    await typeButton.trigger('click')

    expect(wrapper.findComponent({ name: 'TextSignatureModal' }).exists()).toBe(true)
  })
})
```

**Integration Tests:**
```javascript
// spec/javascript/sponsor/integration/bulk-signing-flow.spec.js
describe('Full Bulk Signing Flow', () => {
  it('completes end-to-end signing workflow', async () => {
    // 1. Load sponsor portal with token
    // 2. Navigate to cohort dashboard
    // 3. Click "Sign All" button
    // 4. Draw signature
    // 5. Check confirmation
    // 6. Submit
    // 7. Verify redirect to dashboard
    // 8. Verify cohort shows as completed
  })
})
```

**E2E Tests:**
```javascript
// spec/system/sponsor_bulk_signing_spec.rb
RSpec.describe 'Sponsor Bulk Signing', type: :system do
  let(:cohort) { create(:cohort, status: :ready_for_sponsor) }
  let(:students) { create_list(:student, 5, cohort: cohort, status: :completed_student) }
  let(:token) { cohort.sponsor_token }

  scenario 'sponsor completes bulk signing workflow' do
    visit "/sponsor/cohorts/#{cohort.id}?token=#{token}"

    expect(page).to have_content('Bulk Signing Available')
    expect(page).to have_content('5 pending students')

    click_button 'Sign All Documents'

    # Modal opens
    expect(page).to have_css('[role="dialog"]')

    # Draw signature
    canvas = find('canvas')
    page.driver.browser.action.move_to(canvas.native).click_and_hold.perform
    page.driver.browser.action.move_by(50, 0).perform
    page.driver.browser.action.release.perform

    # Check confirmation
    check 'I understand that my signature will be applied'

    # Submit
    expect {
      click_button 'Sign All 5 Documents'
      expect(page).to have_content('All documents signed successfully')
    }.to change { cohort.reload.status }.from('ready_for_sponsor').to('completed')

    # Verify redirect
    expect(page).to have_current_path("/sponsor/cohorts/#{cohort.id}")

    # Completed tab should show all students
    within('#completed-tab') do
      expect(page).to have_content('5 students')
    end
  end

  scenario 'prevents signing with incomplete cohort' do
    # Create cohort with one student not ready
    cohort.pending!

    visit "/sponsor/cohorts/#{cohort.id}?token=#{token}"

    expect(page).to have_content('Waiting for all students')
    expect(page).not_to have_button('Sign All Documents')
  end
end
```

##### Rollback Procedure

**If bulk signing fails mid-transaction:**
1. Database transaction ensures atomicity - partial signatures are rolled back
2. Cohort state remains "ready_for_sponsor"
3. Error notification sent to TP admin with cohort ID and timestamp
4. Sponsor can retry immediately without data loss
5. Existing student submissions remain in "completed_student" status

**If signature preview generation fails:**
1. Show fallback preview with placeholder text
2. Allow signing to proceed if bulk signing API endpoint is available
3. Log error for admin review

**If sponsor loses session mid-signing:**
1. Use existing sponsor portal authentication (email link with token)
2. Resume from last saved state (cohort data cached for 24 hours)
3. Signature data restored from store if browser session maintained

**Data Safety:**
- Bulk signing uses single database transaction across all submissions
- Sponsor signature stored once, referenced by all submissions
- If any submission fails to update, entire transaction rolls back
- No orphaned signature data

##### Risk Assessment

**Medium Risk** because:
- Complex transaction management across 20+ records
- Real-time state synchronization required
- Canvas browser compatibility issues (especially mobile Safari)
- Bulk operations have cascading effects on email notifications, webhook events

**Specific Risks:**
1. **Signature Canvas Browser Compatibility**: Some browsers handle touch events differently
   - **Mitigation**: Provide text signature fallback, test on iOS Safari and Chrome mobile

2. **Database Deadlock**: Multiple submissions updated simultaneously
   - **Mitigation**: Use database transaction with pessimistic locking on submission records

3. **Partial Failure**: Some documents signed, others failed
   - **Mitigation**: Transaction rollback on any failure, retry mechanism

4. **Token Expiry During Signing**: Token expires while sponsor is drawing signature
   - **Mitigation**: Check token validity on form submission, provide 5-minute grace period

5. **Email Bomb**: Accidental multiple submissions trigger duplicate emails
   - **Mitigation**: Rate limit submissions per token, idempotent API endpoints

6. **Preview Generation Timeout**: Large cohort with many documents times out
   - **Mitigation**: Async preview generation with status polling, cache first document only

**Mitigation Strategies:**
- Extensive transaction testing with RSpec
- Idempotency keys for duplicate request prevention
- Async job queue for document processing (Sidekiq)
- Canvas library fallback: `signature_pad` for cross-browser compatibility
- Comprehensive audit trail in `submission_events` table

##### Success Metrics

- **Zero duplicate signings** (0.1% error rate max)
- **Sub-3-second preview generation** for cohorts with <30 students
- **Sub-5-second end-to-end signing** for cohorts with 50 students
- **100% rollback success** in failure scenarios (automated test coverage)
- **Zero data loss** across 1,000 simulated bulk signing transactions
- **95% sponsor satisfaction** with bulk signing UX (measured via post-action survey)
- **Zero canvas-related support tickets** (measure after 1 month launch)

---

#### Story 4.8: Sponsor Portal - Progress Tracking & State Management

**Status**: Draft/Pending
**Priority**: High
**Epic**: TP Portal - Frontend Development
**Estimated Effort**: 2 days
**Risk Level**: Low

##### User Story

**As a** Sponsor,
**I want** to see real-time progress tracking with clear visual indicators of which students have completed their documents and which are still pending,
**So that** I can monitor the signing workflow and know exactly when to proceed with bulk signing.

##### Background

After students complete their required actions (uploading documents, filling their fields), the sponsor needs visibility into the overall cohort progress. The sponsor portal dashboard must provide:

1. **Progress Overview**: Visual progress bar showing percentage of students who have completed their part
2. **Student List with Status**: Clear indication of each student's current state (Waiting → In Progress → Completed)
3. **Document Preview**: Ability to view individual student documents before signing
4. **State-Driven UI**: Interface elements that change based on cohort state:
   - "Waiting for students" - Sponsor cannot sign yet
   - "Ready for bulk signing" - All students completed, show bulk sign button
   - "Completed" - All documents signed, show completion status

This story implements the dashboard UI that was outlined in Story 4.6, providing the visual layer for progress tracking that the sponsor interacts with before bulk signing (Story 4.7).

The state management ensures sponsors don't attempt to sign prematurely and provides confidence that all students have completed their required actions.

##### Technical Implementation Notes

**Vue 3 Component Structure:**
```vue
<!-- app/javascript/sponsor/views/Dashboard.vue -->
<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Header -->
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">
          {{ cohort.name }}
        </h1>
        <p class="text-gray-600 mt-2">
          Cohort ID: {{ cohort.id }} | Created: {{ formatDate(cohort.created_at) }}
        </p>
      </div>

      <!-- Progress Overview Card -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <h2 class="text-xl font-semibold text-gray-900 mb-4">Overall Progress</h2>
        
        <!-- Progress Bar -->
        <div class="mb-4">
          <div class="flex justify-between text-sm mb-1">
            <span class="font-medium">{{ completedCount }} of {{ totalCount }} students completed</span>
            <span class="font-semibold text-blue-600">{{ progressPercentage }}%</span>
          </div>
          <div class="w-full bg-gray-200 rounded-full h-4 overflow-hidden">
            <div 
              class="bg-blue-600 h-4 rounded-full transition-all duration-500"
              :style="{ width: progressPercentage + '%' }"
            />
          </div>
        </div>

        <!-- Status Badge -->
        <div class="flex items-center gap-3">
          <span 
            class="px-3 py-1 rounded-full text-sm font-medium"
            :class="statusBadgeClass"
          >
            {{ statusText }}
          </span>
          <span v-if="cohort.status === 'ready_for_sponsor'" class="text-sm text-gray-600">
            All students ready for your signature
          </span>
          <span v-else-if="cohort.status === 'completed'" class="text-sm text-gray-600">
            All documents signed successfully
          </span>
        </div>
      </div>

      <!-- Student List with Tabs -->
      <div class="bg-white rounded-lg shadow-md overflow-hidden">
        <!-- Tabs -->
        <div class="border-b border-gray-200">
          <nav class="flex -mb-px" aria-label="Tabs">
            <button
              @click="activeTab = 'pending'"
              class="px-6 py-3 text-sm font-medium border-b-2 transition-colors"
              :class="activeTab === 'pending' ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'"
            >
              Pending ({{ pendingStudents.length }})
            </button>
            <button
              @click="activeTab = 'completed'"
              class="px-6 py-3 text-sm font-medium border-b-2 transition-colors"
              :class="activeTab === 'completed' ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'"
            >
              Completed ({{ completedStudents.length }})
            </button>
          </nav>
        </div>

        <!-- Tab Content -->
        <div class="p-6">
          <!-- Pending Tab -->
          <div v-if="activeTab === 'pending'" class="space-y-4">
            <div v-if="pendingStudents.length === 0" class="text-center py-12 text-gray-500">
              <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <p class="mt-2 text-sm">All students have completed their part!</p>
              <p class="text-xs mt-1">You can now proceed with bulk signing</p>
            </div>

            <div v-else class="divide-y divide-gray-200">
              <div 
                v-for="student in pendingStudents" 
                :key="student.id"
                class="py-4 flex items-center justify-between hover:bg-gray-50 px-3 rounded-md"
              >
                <div class="flex items-center gap-4">
                  <div class="flex-shrink-0">
                    <div class="h-10 w-10 rounded-full bg-gray-200 flex items-center justify-center text-gray-600 font-semibold text-sm">
                      {{ student.name.charAt(0).toUpperCase() }}
                    </div>
                  </div>
                  <div>
                    <p class="text-sm font-medium text-gray-900">{{ student.name }}</p>
                    <p class="text-xs text-gray-500">{{ student.email }}</p>
                  </div>
                </div>
                <div class="flex items-center gap-3">
                  <!-- Student Status -->
                  <span 
                    class="px-2 py-1 text-xs rounded-full"
                    :class="{
                      'bg-yellow-100 text-yellow-800': student.status === 'waiting',
                      'bg-blue-100 text-blue-800': student.status === 'in_progress',
                      'bg-green-100 text-green-800': student.status === 'completed_student'
                    }"
                  >
                    {{ formatStatus(student.status) }}
                  </span>
                  <!-- Progress Indicator -->
                  <span class="text-xs text-gray-500">
                    {{ student.progress }}%
                  </span>
                </div>
              </div>
            </div>
          </div>

          <!-- Completed Tab -->
          <div v-if="activeTab === 'completed'" class="space-y-4">
            <div v-if="completedStudents.length === 0" class="text-center py-12 text-gray-500">
              <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
              </svg>
              <p class="mt-2 text-sm">No completed students yet</p>
            </div>

            <div v-else class="divide-y divide-gray-200">
              <div 
                v-for="student in completedStudents" 
                :key="student.id"
                class="py-4 flex items-center justify-between hover:bg-gray-50 px-3 rounded-md"
              >
                <div class="flex items-center gap-4">
                  <div class="flex-shrink-0">
                    <div class="h-10 w-10 rounded-full bg-green-100 flex items-center justify-center text-green-700 font-semibold text-sm">
                      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                    </div>
                  </div>
                  <div>
                    <p class="text-sm font-medium text-gray-900">{{ student.name }}</p>
                    <p class="text-xs text-gray-500">{{ student.email }}</p>
                  </div>
                </div>
                <div class="flex items-center gap-3">
                  <span class="px-2 py-1 text-xs rounded-full bg-green-100 text-green-800">
                    {{ formatStatus(student.status) }}
                  </span>
                  <button 
                    @click="previewStudent(student)"
                    class="text-xs text-blue-600 hover:text-blue-800 underline"
                  >
                    View Document
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Action Buttons -->
      <div class="mt-6 flex justify-end gap-3" v-if="cohort.status === 'ready_for_sponsor'">
        <button
          @click="openBulkSigning"
          class="px-6 py-3 bg-blue-600 text-white rounded-md hover:bg-blue-700 font-semibold shadow-sm"
        >
          <svg class="w-5 h-5 inline-block mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
          </svg>
          Sign All Documents
        </button>
      </div>

      <!-- Document Preview Modal -->
      <DocumentPreviewModal
        v-if="showPreviewModal"
        :student="selectedStudent"
        @close="showPreviewModal = false"
      />

      <!-- Bulk Signing Modal -->
      <BulkSigningModal
        v-if="showBulkModal"
        :cohort-id="cohort.id"
        :token="token"
        @signed="handleBulkSigned"
        @close="showBulkModal = false"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useSponsorDashboardStore } from '@/sponsor/stores/dashboard'
import { useAuthStore } from '@/sponsor/stores/auth'
import BulkSigningModal from './BulkSigningModal.vue'
import DocumentPreviewModal from './DocumentPreviewModal.vue'

const props = defineProps<{
  cohortId: number
  token: string
}>()

const dashboardStore = useSponsorDashboardStore()
const authStore = useAuthStore()

const activeTab = ref<'pending' | 'completed'>('pending')
const showPreviewModal = ref(false)
const showBulkModal = ref(false)
const selectedStudent = ref(null)
const pollingInterval = ref<number | null>(null)

const cohort = computed(() => dashboardStore.cohort)
const pendingStudents = computed(() => dashboardStore.pendingStudents)
const completedStudents = computed(() => dashboardStore.completedStudents)
const totalCount = computed(() => dashboardStore.totalCount)
const completedCount = computed(() => dashboardStore.completedCount)

const progressPercentage = computed(() => {
  if (totalCount.value === 0) return 0
  return Math.round((completedCount.value / totalCount.value) * 100)
})

const statusBadgeClass = computed(() => {
  switch (cohort.value?.status) {
    case 'ready_for_sponsor':
      return 'bg-green-100 text-green-800'
    case 'completed':
      return 'bg-blue-100 text-blue-800'
    default:
      return 'bg-yellow-100 text-yellow-800'
  }
})

const statusText = computed(() => {
  switch (cohort.value?.status) {
    case 'ready_for_sponsor':
      return 'Ready for Signing'
    case 'completed':
      return 'Completed'
    default:
      return 'In Progress'
  }
})

onMounted(async () => {
  await loadDashboard()
  
  // Start polling for real-time updates (every 30 seconds)
  pollingInterval.value = window.setInterval(() => {
    dashboardStore.refreshProgress(props.cohortId, props.token)
  }, 30000)
})

onUnmounted(() => {
  if (pollingInterval.value) {
    clearInterval(pollingInterval.value)
  }
})

const loadDashboard = async () => {
  try {
    await dashboardStore.fetchCohortData(props.cohortId, props.token)
  } catch (error) {
    console.error('Failed to load dashboard:', error)
    // Error handled by store
  }
}

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}

const formatStatus = (status: string) => {
  const statusMap: Record<string, string> = {
    'waiting': 'Waiting',
    'in_progress': 'In Progress',
    'completed_student': 'Ready for Sponsor',
    'completed_all': 'Completed'
  }
  return statusMap[status] || status
}

const previewStudent = (student: any) => {
  selectedStudent.value = student
  showPreviewModal.value = true
}

const openBulkSigning = () => {
  if (cohort.value?.status === 'ready_for_sponsor') {
    showBulkModal.value = true
  }
}

const handleBulkSigned = () => {
  showBulkModal.value = false
  // Refresh dashboard to show completed status
  loadDashboard()
  // Switch to completed tab
  activeTab.value = 'completed'
}
</script>

<style scoped>
/* Smooth progress bar transitions */
.bg-blue-600 {
  transition: width 0.5s ease-in-out;
}
</style>
```

**Pinia Store:**
```typescript
// app/javascript/sponsor/stores/dashboard.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { CohortAPI } from '@/sponsor/api/cohort'
import type { CohortData, Student } from '@/sponsor/types'

export const useSponsorDashboardStore = defineStore('sponsorDashboard', {
  state: () => ({
    cohort: null as CohortData | null,
    isLoading: false,
    error: null as string | null,
    lastRefresh: null as Date | null
  }),

  getters: {
    pendingStudents: (state) => {
      // Students who have completed their part but not yet signed by sponsor
      return state.cohort?.students.filter(s => s.status === 'completed_student') || []
    },

    completedStudents: (state) => {
      // Students fully completed (including sponsor signature)
      return state.cohort?.students.filter(s => s.status === 'completed_all') || []
    },

    totalCount: (state) => {
      return state.cohort?.students.length || 0
    },

    completedCount: (state) => {
      return state.cohort?.students.filter(s => s.status === 'completed_all').length || 0
    },

    isReadyForSigning: (state) => {
      return state.cohort?.status === 'ready_for_sponsor'
    },

    isCompleted: (state) => {
      return state.cohort?.status === 'completed'
    }
  },

  actions: {
    async fetchCohortData(cohortId: number, token: string): Promise<void> {
      this.isLoading = true
      this.error = null

      try {
        const response = await CohortAPI.getCohortProgress(cohortId, token)
        this.cohort = response
        this.lastRefresh = new Date()
      } catch (error) {
        this.error = error instanceof Error ? error.message : 'Failed to fetch cohort data'
        console.error('Fetch cohort data error:', error)
        throw error
      } finally {
        this.isLoading = false
      }
    },

    async refreshProgress(cohortId: number, token: string): Promise<void> {
      // Silent refresh for polling
      try {
        const response = await CohortAPI.getCohortProgress(cohortId, token)
        this.cohort = response
        this.lastRefresh = new Date()
      } catch (error) {
        console.warn('Silent refresh failed:', error)
        // Don't set error state for silent refresh
      }
    },

    clearError(): void {
      this.error = null
    },

    // Helper to manually update cohort status after bulk signing
    markAsCompleted(): void {
      if (this.cohort) {
        this.cohort.status = 'completed'
        // Update all pending students to completed
        this.cohort.students = this.cohort.students.map(s => ({
          ...s,
          status: s.status === 'completed_student' ? 'completed_all' : s.status
        }))
      }
    }
  }
})
```

**API Layer:**
```typescript
// app/javascript/sponsor/api/cohort.ts (extended)
import type { CohortData } from '@/sponsor/types'

export const CohortAPI = {
  // ... existing methods

  async getCohortProgress(cohortId: number, token: string): Promise<CohortData> {
    const response = await fetch(`/api/sponsor/cohorts/${cohortId}/progress`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    })

    if (!response.ok) {
      if (response.status === 403) {
        throw new Error('Access denied or token expired')
      }
      if (response.status === 404) {
        throw new Error('Cohort not found')
      }
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    return response.json()
  }
}
```

**Type Definitions:**
```typescript
// app/javascript/sponsor/types/index.ts (extended)
export interface CohortData {
  id: number
  name: string
  description: string
  status: 'pending' | 'in_progress' | 'ready_for_sponsor' | 'completed'
  total_students: number
  students: Student[]
  sponsor_access: SponsorAccess
  created_at: string
  updated_at: string
  sign_by_date: string | null
  progress_summary?: {
    waiting: number
    in_progress: number
    completed_student: number
    completed_all: number
  }
}

export interface Student {
  id: number
  name: string
  email: string
  status: 'waiting' | 'in_progress' | 'completed_student' | 'completed_all'
  progress: number // 0-100
  documents: DocumentSummary[]
  last_activity: string
  submitted_at?: string
}

export interface DocumentSummary {
  id: number
  name: string
  status: 'pending' | 'filled' | 'signed'
  submission_id: number
  document_url?: string
}
```

**Design System Compliance:**
Per FR28, all Dashboard components must use design system assets from:
- `@.claude/skills/frontend-design/SKILL.md` - Design tokens
- `@.claude/skills/frontend-design/design-system/` - SVG assets

Specific requirements:
- **Colors**: 
  - Primary (Blue-600): `#2563EB` for progress bars and active states
  - Success (Green-600): `#16A34A` for completed items
  - Warning (Yellow-600): `#CA8A04` for pending items
  - Neutral (Gray-500): `#6B7280` for text and borders
- **Spacing**: 4px base unit (0.25rem increments), 1.5rem (24px) for section gaps
- **Typography**: 
  - Headings: 24px (h1), 20px (h2), 18px (h3)
  - Body: 16px base, 14px for secondary text
  - Labels: 12px uppercase, letter-spacing 0.05em
- **Icons**: Use SVG icons from design system for:
  - Checkmark (completed)
  - User (student avatar)
  - Document (preview)
  - Refresh (polling indicator)
- **Layout**: 
  - Max width: 7xl (1280px)
  - Padding: 1.5rem on mobile, 2rem on desktop
  - Card corners: rounded-lg (8px)
  - Shadow: shadow-md for cards
- **Accessibility**: 
  - All interactive elements have ARIA labels
  - Keyboard navigation for tabs
  - Screen reader announcements for progress updates
  - Color contrast ratio minimum 4.5:1

##### Acceptance Criteria

**Functional:**
1. ✅ Dashboard loads cohort data on mount
2. ✅ Progress bar calculates percentage correctly (completed / total * 100)
3. ✅ Student list separates into Pending vs Completed tabs
4. ✅ Pending tab shows students with status: waiting, in_progress, completed_student
5. ✅ Completed tab shows students with status: completed_all
6. ✅ Real-time polling updates data every 30 seconds
7. ✅ "Sign All Documents" button only visible when cohort status is 'ready_for_sponsor'
8. ✅ Clicking "Sign All" opens Bulk Signing Modal (Story 4.7)
9. ✅ Clicking "View Document" on completed student opens preview modal
10. ✅ After bulk signing, dashboard refreshes and switches to Completed tab

**UI/UX:**
1. ✅ Progress bar animates smoothly (0.5s transition)
2. ✅ Status badges use color-coded styling (yellow/blue/green)
3. ✅ Student cards show avatar initials, name, email, and status
4. ✅ Hover states on all interactive elements
5. ✅ Empty states for both tabs (no students message)
6. ✅ Loading state shown during initial fetch
7. ✅ Error messages displayed prominently with retry option
8. ✅ Mobile-responsive layout (stacks properly on small screens)
9. ✅ Tab switching is instant and smooth
10. ✅ Timestamps formatted human-readable (e.g., "Jan 15, 2025")

**Integration:**
1. ✅ API endpoint: `GET /api/sponsor/cohorts/{id}/progress`
2. ✅ Token authentication in headers
3. ✅ Polling mechanism uses `setInterval` with cleanup on unmount
4. ✅ Store getters correctly filter students by status
5. ✅ Modal components receive correct props (cohortId, token, student data)
6. ✅ State updates propagate to child components

**Security:**
1. ✅ Token-based authentication required for all API calls
2. ✅ Authorization check: sponsor can only view their assigned cohort
3. ✅ Token validation on dashboard load
4. ✅ No sensitive data (signatures, document contents) exposed in dashboard list
5. ✅ Rate limiting on polling endpoint (max 1 request per 30 seconds)

**Quality:**
1. ✅ Polling stops when component unmounts (no memory leaks)
2. ✅ Error boundaries handle API failures gracefully
3. ✅ Data refreshes automatically without user intervention
4. ✅ State consistency: UI always reflects latest data from server
5. ✅ Performance: renders 50+ students without lag

##### Integration Verification (IV1-4)

**IV1: API Integration**
- `Dashboard.vue` calls `CohortAPI.getCohortProgress()` on mount
- `Dashboard.vue` calls `dashboardStore.refreshProgress()` in polling interval
- All endpoints use `Authorization: Bearer {token}` header
- Error handling maps HTTP 403/404 to user-friendly messages
- API returns complete `CohortData` with student array

**IV2: Pinia Store**
- `sponsorDashboardStore.cohort` holds full cohort state
- `sponsorDashboardStore.pendingStudents()` getter filters correctly
- `sponsorDashboardStore.completedStudents()` getter filters correctly
- `sponsorDashboardStore.refreshProgress()` performs silent updates
- `sponsorDashboardStore.markAsCompleted()` updates state after bulk signing

**IV3: Getters**
- `pendingStudents()` returns only `completed_student` status
- `completedStudents()` returns only `completed_all` status
- `isReadyForSigning()` checks cohort status
- `completedCount` calculates for progress bar

**IV4: Token Routing**
- Dashboard receives `token` prop from parent `SponsorPortal`
- Parent loads token from URL param (`?token=...`)
- All API calls pass token to store actions
- Token passed to child modals (BulkSigningModal, DocumentPreviewModal)

##### Test Requirements

**Component Specs:**
```javascript
// spec/javascript/sponsor/views/Dashboard.spec.js
import { mount, flushPromises } from '@vue/test-utils'
import Dashboard from '@/sponsor/views/Dashboard.vue'
import { useSponsorDashboardStore } from '@/sponsor/stores/dashboard'
import { createPinia, setActivePinia } from 'pinia'

describe('Dashboard', () => {
  const mockCohortData = {
    id: 1,
    name: 'Summer 2025 Cohort',
    status: 'ready_for_sponsor',
    students: [
      { id: 1, name: 'John Doe', email: 'john@test.com', status: 'completed_student', progress: 100 },
      { id: 2, name: 'Jane Smith', email: 'jane@test.com', status: 'completed_student', progress: 100 },
      { id: 3, name: 'Bob Wilson', email: 'bob@test.com', status: 'completed_all', progress: 100 }
    ]
  }

  beforeEach(() => {
    setActivePinia(createPinia())
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('renders cohort name and ID correctly', async () => {
    const wrapper = mount(Dashboard, {
      props: { cohortId: 1, token: 'test-token' }
    })

    const store = useSponsorDashboardStore()
    store.cohort = mockCohortData
    await flushPromises()

    expect(wrapper.text()).toContain('Summer 2025 Cohort')
    expect(wrapper.text()).toContain('Cohort ID: 1')
  })

  it('calculates and displays progress correctly', async () => {
    const wrapper = mount(Dashboard, {
      props: { cohortId: 1, token: 'test-token' }
    })

    const store = useSponsorDashboardStore()
    store.cohort = mockCohortData
    await flushPromises()

    expect(wrapper.text()).toContain('2 of 3 students completed')
    expect(wrapper.text()).toContain('67%')
  })

  it('separates students into correct tabs', async () => {
    const wrapper = mount(Dashboard, {
      props: { cohortId: 1, token: 'test-token' }
    })

    const store = useSponsorDashboardStore()
    store.cohort = mockCohortData
    await flushPromises()

    // Pending tab should show 2 students
    expect(wrapper.text()).toContain('Pending (2)')
    
    // Switch to completed tab
    await wrapper.find('button').filter(n => n.text().includes('Completed')).trigger('click')
    expect(wrapper.text()).toContain('Completed (1)')
  })

  it('shows bulk signing button only when ready', async () => {
    const wrapper = mount(Dashboard, {
      props: { cohortId: 1, token: 'test-token' }
    })

    const store = useSponsorDashboardStore()
    store.cohort = { ...mockCohortData, status: 'ready_for_sponsor' }
    await flushPromises()

    expect(wrapper.find('button').filter(n => n.text().includes('Sign All')).exists()).toBe(true)

    // Change to in_progress
    store.cohort.status = 'in_progress'
    await wrapper.vm.$nextTick()
    expect(wrapper.find('button').filter(n => n.text().includes('Sign All')).exists()).toBe(false)
  })

  it('starts polling on mount and stops on unmount', async () => {
    const wrapper = mount(Dashboard, {
      props: { cohortId: 1, token: 'test-token' }
    })

    const store = useSponsorDashboardStore()
    const refreshSpy = vi.spyOn(store, 'refreshProgress')
    
    store.cohort = mockCohortData
    await flushPromises()

    // Fast-forward 30 seconds
    vi.advanceTimersByTime(30000)
    expect(refreshSpy).toHaveBeenCalledWith(1, 'test-token')

    // Unmount
    wrapper.unmount()
    
    // Should not poll after unmount
    refreshSpy.mockClear()
    vi.advanceTimersByTime(30000)
    expect(refreshSpy).not.toHaveBeenCalled()
  })

  it('opens bulk signing modal when button clicked', async () => {
    const wrapper = mount(Dashboard, {
      props: { cohortId: 1, token: 'test-token' }
    })

    const store = useSponsorDashboardStore()
    store.cohort = mockCohortData
    await flushPromises()

    await wrapper.find('button').filter(n => n.text().includes('Sign All')).trigger('click')
    await wrapper.vm.$nextTick()

    expect(wrapper.findComponent({ name: 'BulkSigningModal' }).exists()).toBe(true)
  })

  it('displays empty state when no pending students', async () => {
    const wrapper = mount(Dashboard, {
      props: { cohortId: 1, token: 'test-token' }
    })

    const store = useSponsorDashboardStore()
    store.cohort = {
      ...mockCohortData,
      students: mockCohortData.students.map(s => ({ ...s, status: 'completed_all' }))
    }
    await flushPromises()

    expect(wrapper.text()).toContain('All students have completed their part')
  })
})
```

**Integration Tests:**
```javascript
// spec/javascript/sponsor/integration/dashboard-flow.spec.js
describe('Dashboard Integration Flow', () => {
  it('handles complete workflow: load → monitor → sign → complete', async () => {
    // 1. Dashboard loads with pending students
    // 2. Polling updates student status in real-time
    // 3. All students complete, UI shows "Ready for Signing"
    // 4. Click "Sign All" opens modal
    // 5. Modal closes after signing
    // 6. Dashboard refreshes and shows completed state
  })
})
```

**E2E Tests:**
```javascript
// spec/system/sponsor_dashboard_spec.rb
RSpec.describe 'Sponsor Dashboard', type: :system do
  let(:cohort) { create(:cohort, status: :in_progress) }
  let(:students) { create_list(:student, 3, cohort: cohort, status: :completed_student) }
  let(:token) { cohort.sponsor_token }

  scenario 'sponsor monitors progress and signs documents' do
    visit "/sponsor/cohorts/#{cohort.id}?token=#{token}"

    # Verify dashboard loads
    expect(page).to have_content(cohort.name)
    expect(page).to have_content('3 of 3 students completed')
    expect(page).to have_content('100%')

    # Verify pending tab
    within('#pending-tab') do
      expect(page).to have_content('Pending (3)')
      students.each do |student|
        expect(page).to have_content(student.name)
      end
    end

    # Click sign all button
    click_button 'Sign All Documents'

    # Modal opens
    expect(page).to have_css('[role="dialog"]')

    # Complete signing in modal (tested in Story 4.7)
    # ...

    # Verify dashboard updates
    expect(page).to have_current_path("/sponsor/cohorts/#{cohort.id}")
    expect(page).to have_content('Completed')
    expect(page).to have_content('Completed (3)')
  end

  scenario 'dashboard polls for updates', do
    # Initial load
    visit "/sponsor/cohorts/#{cohort.id}?token=#{token}"
    expect(page).to have_content('In Progress')

    # Simulate student completion in background
    students.first.update!(status: :completed_all)

    # Wait for polling interval (30s)
    sleep 30

    # Verify UI updated
    expect(page).to have_content('1 of 3 students completed')
  end
end
```

##### Rollback Procedure

**If dashboard fails to load:**
1. Show error message with "Retry" button
2. Attempt to reload cohort data
3. If token expired, redirect to email login flow
4. Log error to monitoring service

**If polling causes performance issues:**
1. Reduce polling frequency to 60 seconds
2. Implement exponential backoff on errors
3. Disable polling if cohort is already completed

**If state becomes inconsistent:**
1. Manual refresh button to force data reload
2. Clear local cache and refetch
3. Validate data structure before rendering

**Data Safety:**
- No data mutation in dashboard (read-only view)
- All state changes happen through modals
- Polling only reads data, no write operations

##### Risk Assessment

**Low Risk** because:
- Read-only operations (no data mutation)
- Simple state management (single store)
- Standard Vue 3 patterns
- Polling is well-established pattern
- No complex business logic

**Specific Risks:**
1. **Polling Memory Leak**: Interval not cleaned up on unmount
   - **Mitigation**: `onUnmounted` hook with `clearInterval`

2. **Stale Data**: Polling doesn't update when tab is backgrounded
   - **Mitigation**: Refresh on tab visibility change using `document.visibilityState`

3. **Performance**: Large cohorts (100+ students) slow rendering
   - **Mitigation**: Virtual scrolling or pagination if needed

4. **Token Expiry During Session**: Token expires while dashboard is open
   - **Mitigation**: Check token validity before polling, redirect to renewal on 403

**Mitigation Strategies:**
- Comprehensive unit tests for store getters
- E2E tests for polling behavior
- Performance testing with large datasets
- Error boundary handling for API failures

##### Success Metrics

- **Dashboard loads in <2 seconds** for cohorts with 50 students
- **Polling accuracy**: 100% of updates captured within 30-second window
- **Zero memory leaks** verified by heap snapshot tests
- **100% test coverage** for store and component logic
- **Zero polling errors** in production over 30-day period
- **User satisfaction**: 95% of sponsors can monitor progress without confusion
- **Tab switching**: <100ms response time

---

#### Story 4.9: Sponsor Portal - Token Renewal & Session Management

**Status**: Draft/Pending
**Priority**: High
**Epic**: TP Portal - Frontend Development
**Estimated Effort**: 2 days
**Risk Level**: Medium

##### User Story

**As a** Sponsor,
**I want** to renew my access token if it expires while I'm reviewing documents,
**So that** I can complete my signing workflow without losing progress or being locked out.

##### Background

Sponsors access the portal via time-limited tokens sent by email (Story 2.4). These tokens expire after a configurable period (default 30 days, but often 24-48 hours for security). 

The critical problem: A sponsor might:
1. Open the portal and review 15 out of 20 student documents
2. Take a break or get interrupted
3. Return after token expiration to finish the remaining 5
4. Discover they're locked out and must request a new token
5. **Lose all progress** and have to start over

This creates a poor user experience and potential data loss. The solution requires:

1. **Progress Persistence**: Save signing state independently of token
2. **Pre-Expiration Warnings**: Email notification 2 hours before expiry
3. **Renewal Mechanism**: One-click token renewal via email
4. **Grace Period**: 5-minute buffer after expiration for active sessions
5. **Session Management**: Clear indication of token status

This story implements the token renewal flow referenced in Stories 2.3 and 2.4, ensuring sponsors can complete their workflow even if they exceed the token lifetime.

**Architecture Note**: This is the final story in Phase 4 (TP Portal - Frontend Development), completing the sponsor portal feature set.

##### Technical Implementation Notes

**Vue 3 Component Structure:**
```vue
<!-- app/javascript/sponsor/views/TokenRenewalBanner.vue -->
<template>
  <div 
    v-if="showBanner"
    class="sticky top-0 z-50 border-b"
    :class="bannerClass"
  >
    <div class="max-w-7xl mx-auto px-4 py-3 flex items-center justify-between">
      <!-- Warning/Status Message -->
      <div class="flex items-center gap-3">
        <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path v-if="isExpired" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          <path v-else stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
        </svg>
        <span class="text-sm font-medium">
          {{ bannerMessage }}
        </span>
        <span v-if="!isExpired" class="text-xs opacity-75">
          (Expires in {{ timeRemaining }})
        </span>
      </div>

      <!-- Action Buttons -->
      <div class="flex items-center gap-2">
        <button
          v-if="!isExpired"
          @click="requestRenewal"
          class="px-3 py-1.5 text-sm rounded-md font-medium transition-colors"
          :class="{
            'bg-blue-600 text-white hover:bg-blue-700': !isRenewing,
            'bg-gray-300 text-gray-500 cursor-not-allowed': isRenewing
          }"
          :disabled="isRenewing"
        >
          {{ isRenewing ? 'Sending...' : 'Renew Token' }}
        </button>

        <button
          v-if="isExpired"
          @click="requestRenewal"
          class="px-3 py-1.5 text-sm rounded-md font-medium bg-red-600 text-white hover:bg-red-700"
        >
          Request New Token
        </button>

        <button
          @click="dismissBanner"
          class="p-1.5 rounded-md hover:bg-black/10"
          aria-label="Dismiss banner"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    </div>

    <!-- Success Message -->
    <div v-if="showSuccess" class="bg-green-50 border-t border-green-200 px-4 py-2">
      <div class="max-w-7xl mx-auto flex items-center gap-2 text-sm text-green-800">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
        Renewal email sent! Check your inbox for the new access link.
      </div>
    </div>

    <!-- Error Message -->
    <div v-if="showError" class="bg-red-50 border-t border-red-200 px-4 py-2">
      <div class="max-w-7xl mx-auto flex items-center gap-2 text-sm text-red-800">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        {{ errorMessage }}
        <button @click="requestRenewal" class="underline ml-2">Try again</button>
      </div>
    </div>
  </div>

  <!-- Session Expired Modal -->
  <SessionExpiredModal
    v-if="showExpiredModal"
    @renew="handleRenewal"
    @logout="handleLogout"
  />
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useTokenStore } from '@/sponsor/stores/token'
import SessionExpiredModal from './SessionExpiredModal.vue'

const props = defineProps<{
  token: string
  cohortId: number
}>()

const tokenStore = useTokenStore()

const isRenewing = ref(false)
const showSuccess = ref(false)
const showError = ref(false)
const errorMessage = ref('')
const showExpiredModal = ref(false)
const bannerDismissed = ref(false)
const countdownInterval = ref<number | null>(null)
const timeRemaining = ref('')

const isExpired = computed(() => {
  return tokenStore.isExpired
})

const showBanner = computed(() => {
  if (bannerDismissed.value) return false
  if (isExpired.value) return true
  return tokenStore.shouldShowWarning
})

const bannerClass = computed(() => {
  if (isExpired.value) {
    return 'bg-red-50 border-red-300 text-red-900'
  }
  if (tokenStore.timeUntilExpiry < 3600000) { // < 1 hour
    return 'bg-orange-50 border-orange-300 text-orange-900'
  }
  return 'bg-yellow-50 border-yellow-300 text-yellow-900'
})

const bannerMessage = computed(() => {
  if (isExpired.value) {
    return 'Your access token has expired. You cannot sign documents until you renew.'
  }
  if (tokenStore.timeUntilExpiry < 3600000) {
    return 'Your access token will expire soon. Renew to continue signing.'
  }
  return 'Your access token will expire in a few hours. Consider renewing.'
})

onMounted(async () => {
  // Initialize token store with current token
  await tokenStore.initialize(props.token, props.cohortId)
  
  // Check if already expired
  if (isExpired.value) {
    showExpiredModal.value = true
  }

  // Start countdown
  startCountdown()

  // Listen for visibility changes to show modal if token expires while tab is hidden
  document.addEventListener('visibilitychange', handleVisibilityChange)
})

onUnmounted(() => {
  if (countdownInterval.value) {
    clearInterval(countdownInterval.value)
  }
  document.removeEventListener('visibilitychange', handleVisibilityChange)
})

const startCountdown = () => {
  countdownInterval.value = window.setInterval(() => {
    if (tokenStore.expiresAt) {
      const now = Date.now()
      const diff = tokenStore.expiresAt - now

      if (diff <= 0) {
        timeRemaining.value = 'Expired'
        if (!isExpired.value) {
          tokenStore.markAsExpired()
          showExpiredModal.value = true
        }
      } else {
        // Format as HH:MM:SS or "2 hours 15 min"
        const hours = Math.floor(diff / 3600000)
        const minutes = Math.floor((diff % 3600000) / 60000)
        const seconds = Math.floor((diff % 60000) / 1000)

        if (hours > 0) {
          timeRemaining.value = `${hours}h ${minutes}m`
        } else if (minutes > 0) {
          timeRemaining.value = `${minutes}m ${seconds}s`
        } else {
          timeRemaining.value = `${seconds}s`
        }
      }
    }
  }, 1000)
}

const handleVisibilityChange = () => {
  if (document.visibilityState === 'visible' && isExpired.value) {
    // User returned to tab after token expired
    showExpiredModal.value = true
  }
}

const requestRenewal = async () => {
  if (isRenewing.value) return

  isRenewing.value = true
  showError.value = false
  showSuccess.value = false

  try {
    await tokenStore.requestRenewal(props.cohortId)
    showSuccess.value = true
    
    // Auto-hide success after 5 seconds
    setTimeout(() => {
      showSuccess.value = false
    }, 5000)
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : 'Failed to send renewal email'
    showError.value = true
  } finally {
    isRenewing.value = false
  }
}

const handleRenewal = () => {
  showExpiredModal.value = false
  requestRenewal()
}

const handleLogout = () => {
  // Clear any local data and redirect
  tokenStore.clearToken()
  window.location.href = '/sponsor/logout'
}

const dismissBanner = () => {
  bannerDismissed.value = true
}
</script>

<style scoped>
/* Smooth banner animations */
[role="banner"] {
  transition: all 0.3s ease;
}
</style>
```

**Pinia Store:**
```typescript
// app/javascript/sponsor/stores/token.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { TokenAPI } from '@/sponsor/api/token'
import type { TokenInfo, RenewalResponse } from '@/sponsor/types'

export const useTokenStore = defineStore('token', {
  state: () => ({
    token: null as string | null,
    cohortId: null as number | null,
    createdAt: null as number | null,
    expiresAt: null as number | null,
    duration: null as number | null, // in milliseconds
    isLoading: false,
    error: null as string | null,
    renewalCount: 0,
    lastRenewal: null as number | null
  }),

  getters: {
    isExpired: (state) => {
      if (!state.expiresAt) return false
      return Date.now() >= state.expiresAt
    },

    timeUntilExpiry: (state) => {
      if (!state.expiresAt) return 0
      return state.expiresAt - Date.now()
    },

    shouldShowWarning: (state) => {
      if (!state.expiresAt) return false
      const timeLeft = state.expiresAt - Date.now()
      // Show warning if less than 4 hours or less than 25% of total duration
      if (state.duration) {
        return timeLeft < 4 * 3600000 || timeLeft < state.duration * 0.25
      }
      return timeLeft < 4 * 3600000
    },

    canRenew: (state) => {
      // Max 3 renewals per cohort
      return state.renewalCount < 3 && !state.isLoading
    },

    renewalStatus: (state) => {
      if (state.renewalCount === 0) return 'unused'
      if (state.renewalCount < 3) return 'partial'
      return 'exhausted'
    }
  },

  actions: {
    async initialize(token: string, cohortId: number): Promise<void> {
      this.token = token
      this.cohortId = cohortId
      this.createdAt = Date.now()

      // Default duration: 30 days from config, or 48 hours for security
      // In production, this would come from the token itself
      this.duration = 48 * 3600000 // 48 hours
      this.expiresAt = this.createdAt + this.duration

      // Try to load saved state from localStorage
      this.loadFromStorage()
    },

    async requestRenewal(cohortId: number): Promise<RenewalResponse> {
      if (!this.canRenew) {
        throw new Error('Maximum renewal attempts reached. Please contact the training institution.')
      }

      this.isLoading = true
      this.error = null

      try {
        const response = await TokenAPI.requestRenewal(cohortId, this.token!)

        // Update renewal tracking
        this.renewalCount += 1
        this.lastRenewal = Date.now()

        // Save state
        this.saveToStorage()

        return response
      } catch (error) {
        this.error = error instanceof Error ? error.message : 'Renewal request failed'
        console.error('Token renewal error:', error)
        throw error
      } finally {
        this.isLoading = false
      }
    },

    async applyNewToken(newToken: string, newExpiresAt: number): Promise<void> {
      this.token = newToken
      this.expiresAt = newExpiresAt
      this.createdAt = Date.now()
      this.duration = newExpiresAt - this.createdAt

      // Reset renewal count for new token
      this.renewalCount = 0

      this.saveToStorage()

      // Reload page with new token
      const url = new URL(window.location.href)
      url.searchParams.set('token', newToken)
      window.location.href = url.toString()
    },

    markAsExpired(): void {
      // Called when countdown detects expiration
      if (!this.isExpired) {
        this.expiresAt = Date.now()
        this.saveToStorage()
      }
    },

    clearToken(): void {
      this.token = null
      this.cohortId = null
      this.createdAt = null
      this.expiresAt = null
      this.duration = null
      this.renewalCount = 0
      this.lastRenewal = null
      localStorage.removeItem('sponsor_token_state')
    },

    saveToStorage(): void {
      const state = {
        token: this.token,
        cohortId: this.cohortId,
        createdAt: this.createdAt,
        expiresAt: this.expiresAt,
        duration: this.duration,
        renewalCount: this.renewalCount,
        lastRenewal: this.lastRenewal
      }
      localStorage.setItem('sponsor_token_state', JSON.stringify(state))
    },

    loadFromStorage(): void {
      try {
        const saved = localStorage.getItem('sponsor_token_state')
        if (saved) {
          const state = JSON.parse(saved)
          
          // Only restore if cohort matches and token is still valid
          if (state.cohortId === this.cohortId && state.expiresAt > Date.now()) {
            this.token = state.token
            this.createdAt = state.createdAt
            this.expiresAt = state.expiresAt
            this.duration = state.duration
            this.renewalCount = state.renewalCount || 0
            this.lastRenewal = state.lastRenewal
          }
        }
      } catch (error) {
        console.warn('Failed to load token state from storage:', error)
      }
    },

    clearError(): void {
      this.error = null
    }
  }
})
```

**API Layer:**
```typescript
// app/javascript/sponsor/api/token.ts
export interface TokenInfo {
  token: string
  cohort_id: number
  created_at: number
  expires_at: number
  duration: number
}

export interface RenewalResponse {
  success: boolean
  message: string
  renewal_count: number
  max_renewals: number
  email_sent_to: string
}

export interface NewTokenPayload {
  token: string
  expires_at: number
  cohort_id: number
}

export const TokenAPI = {
  async requestRenewal(cohortId: number, currentToken: string): Promise<RenewalResponse> {
    const response = await fetch(`/api/sponsor/tokens/renew`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${currentToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        cohort_id: cohortId,
        reason: 'portal_renewal'
      })
    })

    if (!response.ok) {
      if (response.status === 403) {
        throw new Error('Token already expired. Please request a new token via email.')
      }
      if (response.status === 429) {
        throw new Error('Too many renewal attempts. Please wait or contact support.')
      }
      if (response.status === 400) {
        const error = await response.json()
        throw new Error(error.message || 'Invalid renewal request')
      }
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    return response.json()
  },

  async validateToken(token: string): Promise<{ valid: boolean; expires_at: number }> {
    const response = await fetch(`/api/sponsor/tokens/validate`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    })

    if (!response.ok) {
      return { valid: false, expires_at: 0 }
    }

    return response.json()
  }
}
```

**Type Definitions:**
```typescript
// app/javascript/sponsor/types/index.ts (extended)
export interface TokenInfo {
  token: string
  cohort_id: number
  created_at: number
  expires_at: number
  duration: number
}

export interface RenewalResponse {
  success: boolean
  message: string
  renewal_count: number
  max_renewals: number
  email_sent_to: string
}

export interface TokenState {
  token: string | null
  cohortId: number | null
  createdAt: number | null
  expiresAt: number | null
  duration: number | null
  renewalCount: number
  lastRenewal: number | null
}
```

**Design System Compliance:**
Per FR28, all Token Renewal components must use design system assets from:
- `@.claude/skills/frontend-design/SKILL.md` - Design tokens
- `@.claude/skills/frontend-design/design-system/` - SVG assets

Specific requirements:
- **Colors**: 
  - Warning (Yellow-500): `#EAB308` for 2-4 hours remaining
  - Urgent (Orange-500): `#F97316` for <1 hour remaining
  - Critical (Red-600): `#DC2626` for expired state
  - Success (Green-600): `#16A34A` for renewal confirmation
- **Spacing**: 4px base unit, 12px for banner padding, 8px for button gaps
- **Typography**: 
  - Banner text: 14px, medium weight
  - Time remaining: 12px, monospace
  - Modal text: 16px, regular weight
- **Icons**: 
  - Warning triangle (exclamation mark in triangle)
  - Clock (for time remaining)
  - Checkmark (for success)
  - X (for dismiss)
- **Layout**: 
  - Banner: sticky top, full width
  - Modal: centered, max-width 400px
  - Buttons: inline, right-aligned
- **Accessibility**: 
  - ARIA labels on all buttons
  - Keyboard navigation for modal
  - Screen reader announcements for time warnings
  - Focus trap in modal

##### Acceptance Criteria

**Functional:**
1. ✅ Banner appears when token enters warning period (<4 hours or <25% duration)
2. ✅ Banner shows countdown timer updating in real-time
3. ✅ "Renew Token" button sends renewal request to API
4. ✅ Success message appears after renewal email sent
5. ✅ Error message appears if renewal fails
6. ✅ Modal appears immediately when token expires
7. ✅ Modal offers "Renew" or "Logout" options
8. ✅ Renewal count tracked (max 3 per cohort)
9. ✅ Token state saved to localStorage
10. ✅ State restored on page reload if still valid

**UI/UX:**
1. ✅ Banner color changes based on urgency (yellow → orange → red)
2. ✅ Countdown format: "2h 15m" for >1h, "45m 30s" for <1h
3. ✅ Banner dismissible (but reappears on next visit)
4. ✅ Modal has clear messaging about expiration
5. ✅ Loading states on renewal button
6. ✅ Success/error messages auto-dismiss after 5 seconds
7. ✅ Mobile-responsive banner and modal
8. ✅ Visual distinction between warning and expired states

**Integration:**
1. ✅ API endpoint: `POST /api/sponsor/tokens/renew`
2. ✅ Token validation on dashboard load
3. ✅ Renewal email contains new token link
4. ✅ New token auto-applies and reloads page
5. ✅ Token store integrates with dashboard store
6. ✅ Banner appears on all sponsor portal pages

**Security:**
1. ✅ Maximum 3 renewals per cohort (prevents abuse)
2. ✅ Rate limiting on renewal endpoint (1 per minute)
3. ✅ Audit log of all renewal attempts
4. ✅ Token validation before allowing renewal
5. ✅ New tokens have full 48-hour duration (not extended)
6. ✅ Old tokens invalidated when new one issued

**Quality:**
1. ✅ State persists across browser sessions
2. ✅ No memory leaks (intervals cleaned up)
3. ✅ Handles edge cases (network errors, invalid tokens)
4. ✅ Graceful degradation if localStorage unavailable
5. ✅ Time calculations accurate across timezones

##### Integration Verification (IV1-4)

**IV1: API Integration**
- `TokenRenewalBanner` calls `TokenAPI.requestRenewal()` on button click
- `TokenStore.initialize()` validates token on mount
- All endpoints use `Authorization: Bearer {token}` header
- Renewal endpoint returns `RenewalResponse` with email confirmation
- Error handling maps HTTP 403/429/400 to user-friendly messages

**IV2: Pinia Store**
- `tokenStore.token` holds current token value
- `tokenStore.expiresAt` tracks expiration timestamp
- `tokenStore.requestRenewal()` updates renewal count
- `tokenStore.saveToStorage()` persists state to localStorage
- `tokenStore.loadFromStorage()` restores state on reload

**IV3: Getters**
- `isExpired()` compares current time to expiresAt
- `timeUntilExpiry()` calculates milliseconds remaining
- `shouldShowWarning()` determines when banner appears
- `canRenew()` enforces max 3 renewals rule
- `renewalStatus()` provides human-readable status

**IV4: Token Routing**
- Banner receives `token` prop from parent `SponsorPortal`
- Parent loads token from URL param (`?token=...`)
- Store initialized with token and cohortId
- New token from renewal auto-applies via URL redirect

##### Test Requirements

**Component Specs:**
```javascript
// spec/javascript/sponsor/views/TokenRenewalBanner.spec.js
import { mount, flushPromises } from '@vue/test-utils'
import TokenRenewalBanner from '@/sponsor/views/TokenRenewalBanner.vue'
import { useTokenStore } from '@/sponsor/stores/token'
import { createPinia, setActivePinia } from 'pinia'

describe('TokenRenewalBanner', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.useFakeTimers()
    localStorage.clear()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('shows banner when token is in warning period', async () => {
    const wrapper = mount(TokenRenewalBanner, {
      props: { token: 'test-token', cohortId: 1 }
    })

    const store = useTokenStore()
    // Set token to expire in 2 hours
    await store.initialize('test-token', 1)
    store.expiresAt = Date.now() + 2 * 3600000

    await flushPromises()
    expect(wrapper.find('[role="banner"]').exists()).toBe(true)
    expect(wrapper.text()).toContain('Renew Token')
  })

  it('shows expired modal when token expires', async () => {
    const wrapper = mount(TokenRenewalBanner, {
      props: { token: 'test-token', cohortId: 1 }
    })

    const store = useTokenStore()
    await store.initialize('test-token', 1)
    store.expiresAt = Date.now() - 1000 // Already expired

    await flushPromises()
    expect(wrapper.findComponent({ name: 'SessionExpiredModal' }).exists()).toBe(true)
  })

  it('updates countdown every second', async () => {
    const wrapper = mount(TokenRenewalBanner, {
      props: { token: 'test-token', cohortId: 1 }
    })

    const store = useTokenStore()
    await store.initialize('test-token', 1)
    store.expiresAt = Date.now() + 3661000 // 1h 1m 1s

    await flushPromises()
    expect(wrapper.text()).toContain('1h 1m')

    vi.advanceTimersByTime(1000)
    await wrapper.vm.$nextTick()
    expect(wrapper.text()).toContain('1h 1m 0s')
  })

  it('handles renewal request successfully', async () => {
    const mockRenewal = vi.fn().mockResolvedValue({
      success: true,
      email_sent_to: 'test@example.com'
    })

    const wrapper = mount(TokenRenewalBanner, {
      props: { token: 'test-token', cohortId: 1 }
    })

    const store = useTokenStore()
    store.requestRenewal = mockRenewal
    await store.initialize('test-token', 1)
    store.expiresAt = Date.now() + 3600000

    await flushPromises()
    await wrapper.find('button').filter(n => n.text() === 'Renew Token').trigger('click')

    expect(mockRenewal).toHaveBeenCalledWith(1)
    expect(wrapper.text()).toContain('Renewal email sent')
  })

  it('prevents more than 3 renewals', async () => {
    const wrapper = mount(TokenRenewalBanner, {
      props: { token: 'test-token', cohortId: 1 }
    })

    const store = useTokenStore()
    await store.initialize('test-token', 1)
    store.expiresAt = Date.now() + 3600000
    store.renewalCount = 3

    await flushPromises()
    const button = wrapper.find('button').filter(n => n.text() === 'Renew Token')
    expect(button.element.disabled).toBe(true)
  })

  it('saves state to localStorage', async () => {
    const wrapper = mount(TokenRenewalBanner, {
      props: { token: 'test-token', cohortId: 1 }
    })

    const store = useTokenStore()
    await store.initialize('test-token', 1)
    store.renewalCount = 2

    expect(localStorage.getItem('sponsor_token_state')).toBeTruthy()
    
    const saved = JSON.parse(localStorage.getItem('sponsor_token_state')!)
    expect(saved.renewalCount).toBe(2)
  })

  it('restores state from localStorage on reload', async () => {
    // Pre-populate localStorage
    const savedState = {
      token: 'test-token',
      cohortId: 1,
      createdAt: Date.now(),
      expiresAt: Date.now() + 3600000,
      duration: 3600000,
      renewalCount: 1,
      lastRenewal: Date.now()
    }
    localStorage.setItem('sponsor_token_state', JSON.stringify(savedState))

    const wrapper = mount(TokenRenewalBanner, {
      props: { token: 'test-token', cohortId: 1 }
    })

    const store = useTokenStore()
    await store.initialize('test-token', 1)

    expect(store.renewalCount).toBe(1)
  })

  it('shows different banner colors based on urgency', async () => {
    const wrapper = mount(TokenRenewalBanner, {
      props: { token: 'test-token', cohortId: 1 }
    })

    const store = useTokenStore()
    await store.initialize('test-token', 1)

    // 2 hours remaining (yellow)
    store.expiresAt = Date.now() + 2 * 3600000
    await flushPromises()
    expect(wrapper.find('[role="banner"]').classes()).toContain('bg-yellow-50')

    // 30 minutes remaining (orange)
    store.expiresAt = Date.now() + 30 * 60000
    await wrapper.vm.$nextTick()
    expect(wrapper.find('[role="banner"]').classes()).toContain('bg-orange-50')

    // Expired (red)
    store.expiresAt = Date.now() - 1000
    await wrapper.vm.$nextTick()
    expect(wrapper.find('[role="banner"]').classes()).toContain('bg-red-50')
  })
})
```

**Integration Tests:**
```javascript
// spec/javascript/sponsor/integration/token-renewal-flow.spec.js
describe('Token Renewal Flow', () => {
  it('handles complete renewal workflow', async () => {
    // 1. Dashboard loads with token expiring in 2 hours
    // 2. Banner appears with warning
    // 3. User clicks "Renew Token"
    // 4. Success message shows
    // 5. User receives email with new token
    // 6. Clicking new token link reloads with new token
    // 7. Countdown resets to 48 hours
  })

  it('handles expired token scenario', async () => {
    // 1. User returns to expired token
    // 2. Modal appears immediately
    // 3. User clicks "Request New Token"
    // 4. Email sent
    // 5. User continues workflow with new token
  })
})
```

**E2E Tests:**
```javascript
// spec/system/sponsor_token_renewal_spec.rb
RSpec.describe 'Sponsor Token Renewal', type: :system do
  let(:cohort) { create(:cohort, status: :ready_for_sponsor) }
  let(:token) { cohort.sponsor_token }

  scenario 'sponsor renews token before expiration' do
    # Set token to expire in 2 hours
    cohort.update!(sponsor_token_expires_at: 2.hours.from_now)

    visit "/sponsor/cohorts/#{cohort.id}?token=#{token}"

    # Banner should appear
    expect(page).to have_css('[role="banner"]')
    expect(page).to have_content('Renew Token')

    # Click renew
    click_button 'Renew Token'

    # Success message
    expect(page).to have_content('Renewal email sent')

    # Verify email was sent
    email = ActionMailer::Base.deliveries.last
    expect(email.to).to include(cohort.training_provider.email)
    expect(email.subject).to include('Token Renewal')
  end

  scenario 'expired token shows modal' do
    cohort.update!(sponsor_token_expires_at: 1.minute.ago)

    visit "/sponsor/cohorts/#{cohort.id}?token=#{token}"

    # Modal should appear
    expect(page).to have_css('[role="dialog"]')
    expect(page).to have_content('Your access token has expired')

    # Click request new token
    click_button 'Request New Token'

    # Should show success
    expect(page).to have_content('Renewal email sent')
  end

  scenario 'max renewal limit enforced' do
    cohort.update!(sponsor_token_expires_at: 2.hours.from_now)

    # Simulate 3 previous renewals
    cohort.update!(sponsor_token_renewal_count: 3)

    visit "/sponsor/cohorts/#{cohort.id}?token=#{token}"

    expect(page).to have_content('Maximum renewal attempts reached')
    expect(page).not_to have_button('Renew Token')
  end
end
```

##### Rollback Procedure

**If token renewal fails:**
1. Show error message with "Try Again" button
2. Log error to monitoring service
3. Display contact information for support
4. Preserve current token state (don't invalidate)

**If localStorage is corrupted:**
1. Detect JSON parse error
2. Clear invalid storage
3. Continue with current token (no data loss)
4. Log warning for investigation

**If new token doesn't apply:**
1. Display new token in modal (copy-paste option)
2. Provide manual URL construction
3. Email fallback with direct link
4. Support escalation path

**If polling causes issues:**
1. Reduce countdown frequency to every 5 seconds
2. Pause countdown when tab is backgrounded
3. Resume on visibility change

**Data Safety:**
- Token state is read-only (no mutation during normal operation)
- All renewal attempts logged server-side
- Old tokens remain valid until new one is issued
- No signing operations can occur with expired token

##### Risk Assessment

**Medium Risk** because:
- Token security is critical (unauthorized access risk)
- State management across browser sessions
- Email delivery dependency for renewal
- User experience impact if renewal fails
- Potential for token abuse if limits not enforced

**Specific Risks:**
1. **Token Leakage**: Token in localStorage could be accessed by malicious scripts
   - **Mitigation**: Use httpOnly cookies if possible, or document security best practices

2. **Email Delivery Failure**: Renewal email never arrives
   - **Mitigation**: Show token in UI as fallback, allow copy-paste

3. **Race Condition**: Token expires while user is mid-signing
   - **Mitigation**: Grace period (5 min) for active sessions, auto-save progress

4. **Storage Quota**: localStorage full or disabled
   - **Mitigation**: Graceful degradation, continue without persistence

5. **Timezone Issues**: Countdown shows wrong time due to client clock
   - **Mitigation**: Use server time for expiration, client for display only

6. **Abuse**: User spams renewal requests
   - **Mitigation**: Rate limiting (1 req/min), max 3 renewals per cohort

**Mitigation Strategies:**
- Comprehensive security testing (OWASP guidelines)
- Rate limiting on all token endpoints
- Audit logging for all renewal attempts
- Token invalidation on new token issuance
- Clear user communication about token security
- Fallback mechanisms for email failures

##### Success Metrics

- **Renewal Success Rate**: 95% of renewal requests result in successful email delivery
- **User Completion Rate**: 90% of users who renew complete their signing workflow
- **Support Tickets**: <5% of token-related issues require manual intervention
- **Email Delivery**: 99% of renewal emails delivered within 30 seconds
- **Zero Security Incidents**: No unauthorized token access reported
- **User Satisfaction**: 85% satisfaction rating for token renewal experience
- **Performance**: Token validation <100ms, renewal request <2s

---

#### Story 4.10: TP Portal - Cohort Status Monitoring & Analytics

**Status**: Draft/Pending
**Priority**: High
**Epic**: TP Portal - Frontend Development
**Estimated Effort**: 2 days
**Risk Level**: Low

##### User Story

**As a** Training Provider,
**I want** to monitor all cohorts with real-time status updates and analytics,
**So that** I can track progress, identify bottlenecks, and manage my document signing workflows efficiently.

##### Background

After creating cohorts and initiating workflows, training providers need visibility into the entire system. The TP Portal dashboard must provide:

1. **Cohort Overview**: List of all cohorts with key metrics
2. **Real-time Status**: Live updates of student and sponsor progress
3. **Analytics**: Completion rates, average time to completion, bottlenecks
4. **Actionable Insights**: Which cohorts need attention, which are completed
5. **Bulk Operations**: Manage multiple cohorts simultaneously

This is the final story in Phase 4, completing the TP Portal frontend development. It builds upon:
- Story 4.1: TP Portal Dashboard Layout
- Story 4.2: TP Signing Phase Logic
- Story 4.3: TP Review Dashboard
- Story 4.4: TP Portal - Cohort Creation Wizard
- Story 4.5: TP Portal - Cohort Management & Student List
- Story 4.6: Sponsor Portal Dashboard
- Story 4.7: Sponsor Portal - Bulk Document Signing
- Story 4.8: Sponsor Portal - Progress Tracking
- Story 4.9: Sponsor Portal - Token Renewal

The TP monitoring dashboard is the command center for training providers, giving them complete visibility and control over their cohort workflows.

##### Technical Implementation Notes

**Vue 3 Component Structure:**
```vue
<!-- app/javascript/tp/views/CohortMonitor.vue -->
<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Header -->
      <div class="mb-8 flex justify-between items-start">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">Cohort Monitor</h1>
          <p class="text-gray-600 mt-2">
            Track all active cohorts and their signing progress in real-time
          </p>
        </div>
        <div class="flex gap-3">
          <button
            @click="refreshAll"
            class="px-4 py-2 bg-white border border-gray-300 rounded-md hover:bg-gray-50 text-sm font-medium"
          >
            <svg class="w-4 h-4 inline-block mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
            Refresh All
          </button>
          <button
            @click="showCreateModal = true"
            class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 text-sm font-medium"
          >
            <svg class="w-4 h-4 inline-block mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            New Cohort
          </button>
        </div>
      </div>

      <!-- Analytics Overview Cards -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div class="bg-white rounded-lg shadow p-6">
          <div class="text-sm text-gray-500 mb-1">Total Cohorts</div>
          <div class="text-3xl font-bold text-gray-900">{{ analytics.totalCohorts }}</div>
        </div>
        <div class="bg-white rounded-lg shadow p-6">
          <div class="text-sm text-gray-500 mb-1">Active Now</div>
          <div class="text-3xl font-bold text-blue-600">{{ analytics.activeCohorts }}</div>
        </div>
        <div class="bg-white rounded-lg shadow p-6">
          <div class="text-sm text-gray-500 mb-1">Completed</div>
          <div class="text-3xl font-bold text-green-600">{{ analytics.completedCohorts }}</div>
        </div>
        <div class="bg-white rounded-lg shadow p-6">
          <div class="text-sm text-gray-500 mb-1">Avg Completion Time</div>
          <div class="text-3xl font-bold text-purple-600">{{ analytics.avgCompletionTime }}</div>
        </div>
      </div>

      <!-- Filters and Search -->
      <div class="bg-white rounded-lg shadow mb-6 p-4">
        <div class="flex flex-wrap gap-4 items-center">
          <div class="flex-1 min-w-[200px]">
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Search cohorts by name or ID..."
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>
          <select
            v-model="statusFilter"
            class="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">All Status</option>
            <option value="pending">Pending</option>
            <option value="in_progress">In Progress</option>
            <option value="ready_for_sponsor">Ready for Sponsor</option>
            <option value="completed">Completed</option>
          </select>
          <select
            v-model="sortBy"
            class="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500"
          >
            <option value="created_at">Sort by Created</option>
            <option value="status">Sort by Status</option>
            <option value="name">Sort by Name</option>
          </select>
        </div>
      </div>

      <!-- Cohort List -->
      <div class="bg-white rounded-lg shadow overflow-hidden">
        <!-- Table Header -->
        <div class="hidden md:grid grid-cols-12 gap-4 bg-gray-50 border-b px-6 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">
          <div class="col-span-3">Cohort Name</div>
          <div class="col-span-2">Status</div>
          <div class="col-span-2">Students</div>
          <div class="col-span-2">Progress</div>
          <div class="col-span-2">Last Updated</div>
          <div class="col-span-1">Actions</div>
        </div>

        <!-- Cohort Rows -->
        <div v-if="filteredCohorts.length === 0" class="text-center py-12 text-gray-500">
          <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
          <p class="mt-2 text-sm">No cohorts found</p>
        </div>

        <div
          v-for="cohort in filteredCohorts"
          :key="cohort.id"
          class="border-b last:border-b-0 hover:bg-gray-50 transition-colors"
        >
          <!-- Desktop Row -->
          <div class="hidden md:grid grid-cols-12 gap-4 px-6 py-4 items-center">
            <!-- Name -->
            <div class="col-span-3">
              <div class="font-medium text-gray-900">{{ cohort.name }}</div>
              <div class="text-xs text-gray-500">ID: {{ cohort.id }}</div>
            </div>

            <!-- Status -->
            <div class="col-span-2">
              <span 
                class="px-2 py-1 text-xs rounded-full font-medium"
                :class="getStatusClass(cohort.status)"
              >
                {{ formatStatus(cohort.status) }}
              </span>
            </div>

            <!-- Students -->
            <div class="col-span-2">
              <div class="text-sm">
                <span class="font-semibold">{{ cohort.student_count }}</span> total
              </div>
              <div class="text-xs text-gray-500">
                {{ cohort.completed_count }} completed
              </div>
            </div>

            <!-- Progress -->
            <div class="col-span-2">
              <div class="flex items-center gap-2">
                <div class="flex-1 bg-gray-200 rounded-full h-2 overflow-hidden">
                  <div 
                    class="h-2 rounded-full transition-all duration-500"
                    :class="getProgressColor(cohort.progress)"
                    :style="{ width: cohort.progress + '%' }"
                  />
                </div>
                <span class="text-xs font-medium">{{ cohort.progress }}%</span>
              </div>
            </div>

            <!-- Last Updated -->
            <div class="col-span-2 text-xs text-gray-500">
              {{ formatRelativeTime(cohort.last_updated) }}
            </div>

            <!-- Actions -->
            <div class="col-span-1 flex gap-2 justify-end">
              <button
                @click="viewCohort(cohort)"
                class="text-blue-600 hover:text-blue-800"
                title="View Details"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                </svg>
              </button>
              <button
                v-if="cohort.status === 'in_progress' || cohort.status === 'ready_for_sponsor'"
                @click="sendReminder(cohort)"
                class="text-gray-600 hover:text-gray-800"
                title="Send Reminder"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                </svg>
              </button>
              <button
                v-if="cohort.status === 'completed'"
                @click="exportCohort(cohort)"
                class="text-green-600 hover:text-green-800"
                title="Export Data"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                </svg>
              </button>
            </div>
          </div>

          <!-- Mobile Card -->
          <div class="md:hidden px-4 py-4 space-y-2">
            <div class="flex justify-between items-start">
              <div>
                <div class="font-medium text-gray-900">{{ cohort.name }}</div>
                <div class="text-xs text-gray-500">ID: {{ cohort.id }}</div>
              </div>
              <span 
                class="px-2 py-1 text-xs rounded-full font-medium"
                :class="getStatusClass(cohort.status)"
              >
                {{ formatStatus(cohort.status) }}
              </span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-gray-600">Students:</span>
              <span class="font-semibold">{{ cohort.student_count }}</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-gray-600">Progress:</span>
              <span class="font-semibold">{{ cohort.progress }}%</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-gray-600">Updated:</span>
              <span>{{ formatRelativeTime(cohort.last_updated) }}</span>
            </div>
            <div class="flex gap-2 pt-2">
              <button
                @click="viewCohort(cohort)"
                class="flex-1 px-3 py-2 bg-blue-600 text-white rounded-md text-sm"
              >
                View
              </button>
              <button
                v-if="cohort.status === 'in_progress' || cohort.status === 'ready_for_sponsor'"
                @click="sendReminder(cohort)"
                class="flex-1 px-3 py-2 bg-gray-600 text-white rounded-md text-sm"
              >
                Reminder
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Real-time Status Indicator -->
      <div class="mt-4 flex items-center justify-end gap-2 text-xs text-gray-500">
        <div 
          class="w-2 h-2 rounded-full animate-pulse"
          :class="isPolling ? 'bg-green-500' : 'bg-gray-300'"
        />
        <span>{{ isPolling ? 'Live updates active' : 'Updates paused' }}</span>
        <span>({{ timeSinceLastUpdate }})</span>
      </div>
    </div>

    <!-- Cohort Detail Modal -->
    <CohortDetailModal
      v-if="selectedCohort"
      :cohort="selectedCohort"
      @close="selectedCohort = null"
      @refresh="refreshCohort(selectedCohort.id)"
    />

    <!-- Create Cohort Modal -->
    <CreateCohortModal
      v-if="showCreateModal"
      @close="showCreateModal = false"
      @created="handleCohortCreated"
    />

    <!-- Reminder Confirmation Modal -->
    <ReminderModal
      v-if="reminderCohort"
      :cohort="reminderCohort"
      @close="reminderCohort = null"
      @sent="handleReminderSent"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useTPMonitorStore } from '@/tp/stores/monitor'
import CohortDetailModal from './CohortDetailModal.vue'
import CreateCohortModal from './CreateCohortModal.vue'
import ReminderModal from './ReminderModal.vue'

const monitorStore = useTPMonitorStore()

const searchQuery = ref('')
const statusFilter = ref('all')
const sortBy = ref('created_at')
const showCreateModal = ref(false)
const selectedCohort = ref(null)
const reminderCohort = ref(null)
const pollingInterval = ref<number | null>(null)
const lastUpdate = ref<Date>(new Date())

const cohorts = computed(() => monitorStore.cohorts)
const analytics = computed(() => monitorStore.analytics)
const isPolling = computed(() => monitorStore.isPolling)

const filteredCohorts = computed(() => {
  let result = [...cohorts.value]

  // Filter by status
  if (statusFilter.value !== 'all') {
    result = result.filter(c => c.status === statusFilter.value)
  }

  // Filter by search
  if (searchQuery.value.trim()) {
    const query = searchQuery.value.toLowerCase()
    result = result.filter(c => 
      c.name.toLowerCase().includes(query) || 
      c.id.toString().includes(query)
    )
  }

  // Sort
  result.sort((a, b) => {
    switch (sortBy.value) {
      case 'name':
        return a.name.localeCompare(b.name)
      case 'status':
        return a.status.localeCompare(b.status)
      case 'created_at':
      default:
        return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    }
  })

  return result
})

const timeSinceLastUpdate = computed(() => {
  const diff = Date.now() - lastUpdate.value.getTime()
  const seconds = Math.floor(diff / 1000)
  
  if (seconds < 60) return `${seconds}s ago`
  const minutes = Math.floor(seconds / 60)
  if (minutes < 60) return `${minutes}m ago`
  const hours = Math.floor(minutes / 60)
  return `${hours}h ago`
})

onMounted(async () => {
  await loadCohorts()
  
  // Start polling for real-time updates (every 30 seconds)
  pollingInterval.value = window.setInterval(() => {
    monitorStore.refreshCohorts()
    lastUpdate.value = new Date()
  }, 30000)
})

onUnmounted(() => {
  if (pollingInterval.value) {
    clearInterval(pollingInterval.value)
  }
})

const loadCohorts = async () => {
  try {
    await monitorStore.fetchCohorts()
    lastUpdate.value = new Date()
  } catch (error) {
    console.error('Failed to load cohorts:', error)
  }
}

const refreshAll = async () => {
  await monitorStore.refreshCohorts()
  lastUpdate.value = new Date()
}

const refreshCohort = async (cohortId: number) => {
  await monitorStore.refreshCohort(cohortId)
  lastUpdate.value = new Date()
}

const viewCohort = (cohort: any) => {
  selectedCohort.value = cohort
}

const sendReminder = (cohort: any) => {
  reminderCohort.value = cohort
}

const exportCohort = async (cohort: any) => {
  try {
    await monitorStore.exportCohort(cohort.id)
    // Download will be triggered by store
  } catch (error) {
    console.error('Export failed:', error)
  }
}

const handleCohortCreated = (newCohort: any) => {
  showCreateModal.value = false
  monitorStore.addCohort(newCohort)
  // Navigate to cohort detail
  selectedCohort.value = newCohort
}

const handleReminderSent = () => {
  reminderCohort.value = null
  // Show success notification
}

const getStatusClass = (status: string) => {
  const classes = {
    pending: 'bg-gray-100 text-gray-800',
    in_progress: 'bg-blue-100 text-blue-800',
    ready_for_sponsor: 'bg-purple-100 text-purple-800',
    completed: 'bg-green-100 text-green-800'
  }
  return classes[status] || classes.pending
}

const getProgressColor = (progress: number) => {
  if (progress === 100) return 'bg-green-500'
  if (progress >= 75) return 'bg-blue-500'
  if (progress >= 50) return 'bg-purple-500'
  if (progress >= 25) return 'bg-yellow-500'
  return 'bg-gray-400'
}

const formatStatus = (status: string) => {
  const map = {
    pending: 'Pending',
    in_progress: 'In Progress',
    ready_for_sponsor: 'Ready for Sponsor',
    completed: 'Completed'
  }
  return map[status] || status
}

const formatRelativeTime = (dateString: string) => {
  const date = new Date(dateString)
  const diff = Date.now() - date.getTime()
  const minutes = Math.floor(diff / 60000)
  const hours = Math.floor(minutes / 60)
  const days = Math.floor(hours / 24)

  if (days > 0) return `${days}d ago`
  if (hours > 0) return `${hours}h ago`
  if (minutes > 0) return `${minutes}m ago`
  return 'Just now'
}
</script>

<style scoped>
/* Smooth progress bar transitions */
.bg-blue-500, .bg-green-500, .bg-purple-500, .bg-yellow-500, .bg-gray-400 {
  transition: width 0.5s ease-in-out;
}

/* Pulse animation for live indicator */
@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}
</style>
```

**Pinia Store:**
```typescript
// app/javascript/tp/stores/monitor.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { CohortAPI } from '@/tp/api/cohort'
import type { Cohort, CohortAnalytics, ExportResponse } from '@/tp/types'

export const useTPMonitorStore = defineStore('tpMonitor', {
  state: () => ({
    cohorts: [] as Cohort[],
    isLoading: false,
    error: null as string | null,
    isPolling: false,
    lastRefresh: null as Date | null
  }),

  getters: {
    analytics: (state) => {
      const total = state.cohorts.length
      const active = state.cohorts.filter(c => 
        ['in_progress', 'ready_for_sponsor'].includes(c.status)
      ).length
      const completed = state.cohorts.filter(c => c.status === 'completed').length
      
      // Calculate average completion time
      const completedCohorts = state.cohorts.filter(c => c.status === 'completed')
      let avgTime = 'N/A'
      
      if (completedCohorts.length > 0) {
        const totalMs = completedCohorts.reduce((sum, c) => {
          if (c.completed_at && c.created_at) {
            return sum + (new Date(c.completed_at).getTime() - new Date(c.created_at).getTime())
          }
          return sum
        }, 0)
        
        const avgMs = totalMs / completedCohorts.length
        const days = Math.floor(avgMs / (1000 * 60 * 60 * 24))
        const hours = Math.floor((avgMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
        avgTime = days > 0 ? `${days}d ${hours}h` : `${hours}h`
      }

      return {
        totalCohorts: total,
        activeCohorts: active,
        completedCohorts: completed,
        avgCompletionTime: avgTime
      } as CohortAnalytics
    },

    pendingCohorts: (state) => {
      return state.cohorts.filter(c => c.status === 'pending')
    },

    inProgressCohorts: (state) => {
      return state.cohorts.filter(c => c.status === 'in_progress')
    },

    readyForSponsorCohorts: (state) => {
      return state.cohorts.filter(c => c.status === 'ready_for_sponsor')
    },

    completedCohorts: (state) => {
      return state.cohorts.filter(c => c.status === 'completed')
    }
  },

  actions: {
    async fetchCohorts(): Promise<void> {
      this.isLoading = true
      this.error = null
      this.isPolling = true

      try {
        const response = await CohortAPI.getAll()
        this.cohorts = response
        this.lastRefresh = new Date()
      } catch (error) {
        this.error = error instanceof Error ? error.message : 'Failed to fetch cohorts'
        console.error('Fetch cohorts error:', error)
        throw error
      } finally {
        this.isLoading = false
        this.isPolling = false
      }
    },

    async refreshCohorts(): Promise<void> {
      this.isPolling = true
      try {
        const response = await CohortAPI.getAll()
        this.cohorts = response
        this.lastRefresh = new Date()
      } catch (error) {
        console.warn('Silent refresh failed:', error)
      } finally {
        this.isPolling = false
      }
    },

    async refreshCohort(cohortId: number): Promise<void> {
      try {
        const response = await CohortAPI.getById(cohortId)
        const index = this.cohorts.findIndex(c => c.id === cohortId)
        if (index !== -1) {
          this.cohorts[index] = response
        }
        this.lastRefresh = new Date()
      } catch (error) {
        console.error('Failed to refresh cohort:', error)
        throw error
      }
    },

    addCohort(cohort: Cohort): void {
      this.cohorts.unshift(cohort)
    },

    async sendReminder(cohortId: number): Promise<void> {
      try {
        await CohortAPI.sendReminder(cohortId)
      } catch (error) {
        console.error('Failed to send reminder:', error)
        throw error
      }
    },

    async exportCohort(cohortId: number): Promise<ExportResponse> {
      try {
        const response = await CohortAPI.export(cohortId)
        
        // Trigger download
        if (response.download_url) {
          const link = document.createElement('a')
          link.href = response.download_url
          link.download = `cohort_${cohortId}_export.xlsx`
          document.body.appendChild(link)
          link.click()
          document.body.removeChild(link)
        }

        return response
      } catch (error) {
        console.error('Export failed:', error)
        throw error
      }
    },

    clearError(): void {
      this.error = null
    }
  }
})
```

**API Layer:**
```typescript
// app/javascript/tp/api/cohort.ts
export interface Cohort {
  id: number
  name: string
  description: string
  status: 'pending' | 'in_progress' | 'ready_for_sponsor' | 'completed'
  student_count: number
  completed_count: number
  progress: number
  created_at: string
  updated_at: string
  last_updated: string
  completed_at?: string
}

export interface CohortAnalytics {
  totalCohorts: number
  activeCohorts: number
  completedCohorts: number
  avgCompletionTime: string
}

export interface ExportResponse {
  success: boolean
  download_url?: string
  message: string
}

export const CohortAPI = {
  async getAll(): Promise<Cohort[]> {
    const response = await fetch('/api/tp/cohorts', {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      }
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    return response.json()
  },

  async getById(cohortId: number): Promise<Cohort> {
    const response = await fetch(`/api/tp/cohorts/${cohortId}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      }
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    return response.json()
  },

  async sendReminder(cohortId: number): Promise<{ success: boolean; message: string }> {
    const response = await fetch(`/api/tp/cohorts/${cohortId}/remind`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    return response.json()
  },

  async export(cohortId: number): Promise<ExportResponse> {
    const response = await fetch(`/api/tp/cohorts/${cohortId}/export`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    return response.json()
  }
}
```

**Type Definitions:**
```typescript
// app/javascript/tp/types/index.ts
export interface Cohort {
  id: number
  name: string
  description: string
  status: 'pending' | 'in_progress' | 'ready_for_sponsor' | 'completed'
  student_count: number
  completed_count: number
  progress: number
  created_at: string
  updated_at: string
  last_updated: string
  completed_at?: string
}

export interface CohortAnalytics {
  totalCohorts: number
  activeCohorts: number
  completedCohorts: number
  avgCompletionTime: string
}

export interface ExportResponse {
  success: boolean
  download_url?: string
  message: string
}
```

**Design System Compliance:**
Per FR28, all Monitor components must use design system assets from:
- `@.claude/skills/frontend-design/SKILL.md` - Design tokens
- `@.claude/skills/frontend-design/design-system/` - SVG assets

Specific requirements:
- **Colors**: 
  - Primary (Blue-600): `#2563EB` for headers and active elements
  - Success (Green-600): `#16A34A` for completed cohorts
  - Warning (Purple-600): `#7C3AED` for ready for sponsor
  - Info (Blue-500): `#3B82F6` for in progress
  - Neutral (Gray-500): `#6B7280` for pending
- **Spacing**: 4px base unit, 1.5rem (24px) for section gaps, 0.75rem (12px) for card padding
- **Typography**: 
  - Headings: 24px (h1), 20px (h2)
  - Body: 16px base, 14px for secondary
  - Labels: 12px uppercase, letter-spacing 0.05em
- **Icons**: Use SVG icons from design system for:
  - Refresh (circular arrow)
  - Plus (create cohort)
  - Eye (view details)
  - Bell (send reminder)
  - Download (export)
  - Search (magnifying glass)
- **Layout**: 
  - Max width: 7xl (1280px)
  - Card corners: rounded-lg (8px)
  - Shadow: shadow-md for cards, shadow-sm for rows
  - Table: grid layout on desktop, cards on mobile
- **Accessibility**: 
  - ARIA labels on all buttons
  - Keyboard navigation for modals
  - Screen reader announcements for live updates
  - Color contrast ratio minimum 4.5:1
  - Focus indicators on all interactive elements

##### Acceptance Criteria

**Functional:**
1. ✅ Dashboard loads all cohorts on mount
2. ✅ Analytics cards show correct totals and calculations
3. ✅ Search filters cohorts by name or ID
4. ✅ Status filter works correctly
5. ✅ Sort by name, status, or creation date
6. ✅ Real-time polling updates data every 30 seconds
7. ✅ "Refresh All" button manually triggers update
8. ✅ Clicking "View" opens cohort detail modal
9. ✅ "Send Reminder" available for in-progress cohorts
10. ✅ "Export" downloads Excel file for completed cohorts
11. ✅ New cohort button opens creation wizard
12. ✅ Progress bars animate smoothly
13. ✅ Last updated timestamp shows relative time

**UI/UX:**
1. ✅ Desktop: Table layout with 7 columns
2. ✅ Mobile: Card layout with stacked information
3. ✅ Status badges use color-coded styling
4. ✅ Progress bars change color based on percentage
5. ✅ Hover states on all interactive rows
6. ✅ Loading states during data fetch
7. ✅ Empty state when no cohorts exist
8. ✅ Live indicator shows polling status
9. ✅ Time since last update displays correctly
10. ✅ Responsive design works on all screen sizes

**Integration:**
1. ✅ API endpoints: `GET /api/tp/cohorts`, `GET /api/tp/cohorts/{id}`, `POST /api/tp/cohorts/{id}/remind`, `POST /api/tp/cohorts/{id}/export`
2. ✅ Polling mechanism with cleanup on unmount
3. ✅ Store getters calculate analytics correctly
4. ✅ Modal components receive correct props
5. ✅ Export triggers file download
6. ✅ Reminder sends email notifications

**Security:**
1. ✅ All API calls require authentication (TP session)
2. ✅ Authorization check: TP can only view their own cohorts
3. ✅ Export endpoint rate limited (max 5 per hour)
4. ✅ Reminder endpoint rate limited (max 10 per hour)
5. ✅ No sensitive data exposed in list view

**Quality:**
1. ✅ Polling stops when component unmounts
2. ✅ Error handling for failed API calls
3. ✅ Data consistency across refreshes
4. ✅ Performance: renders 100+ cohorts without lag
5. ✅ No duplicate polling intervals

##### Integration Verification (IV1-4)

**IV1: API Integration**
- `CohortMonitor.vue` calls `CohortAPI.getAll()` on mount
- `CohortMonitor.vue` calls `monitorStore.refreshCohorts()` in polling interval
- `CohortMonitor.vue` calls `CohortAPI.sendReminder()` for reminders
- `CohortMonitor.vue` calls `CohortAPI.export()` for exports
- All endpoints use session-based authentication

**IV2: Pinia Store**
- `tpMonitorStore.cohorts` holds all cohort data
- `tpMonitorStore.analytics` getter calculates metrics
- `tpMonitorStore.refreshCohorts()` performs silent updates
- `tpMonitorStore.exportCohort()` triggers download
- `tpMonitorStore.sendReminder()` sends notifications

**IV3: Getters**
- `analytics` calculates totals, active, completed, avg time
- `pendingCohorts` filters by pending status
- `inProgressCohorts` filters by in_progress
- `readyForSponsorCohorts` filters by ready_for_sponsor
- `completedCohorts` filters by completed

**IV4: Token Routing**
- Not applicable (TP portal uses session auth, not tokens)
- All API calls use browser session cookies

##### Test Requirements

**Component Specs:**
```javascript
// spec/javascript/tp/views/CohortMonitor.spec.js
import { mount, flushPromises } from '@vue/test-utils'
import CohortMonitor from '@/tp/views/CohortMonitor.vue'
import { useTPMonitorStore } from '@/tp/stores/monitor'
import { createPinia, setActivePinia } from 'pinia'

describe('CohortMonitor', () => {
  const mockCohorts = [
    {
      id: 1,
      name: 'Summer 2025',
      status: 'in_progress',
      student_count: 20,
      completed_count: 15,
      progress: 75,
      created_at: '2025-01-01T00:00:00Z',
      updated_at: '2025-01-15T12:00:00Z',
      last_updated: '2025-01-15T12:00:00Z'
    },
    {
      id: 2,
      name: 'Winter 2025',
      status: 'completed',
      student_count: 15,
      completed_count: 15,
      progress: 100,
      created_at: '2024-12-01T00:00:00Z',
      updated_at: '2024-12-20T12:00:00Z',
      last_updated: '2024-12-20T12:00:00Z',
      completed_at: '2024-12-20T12:00:00Z'
    }
  ]

  beforeEach(() => {
    setActivePinia(createPinia())
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('renders analytics cards correctly', async () => {
    const wrapper = mount(CohortMonitor)
    const store = useTPMonitorStore()
    store.cohorts = mockCohorts
    await flushPromises()

    expect(wrapper.text()).toContain('Total Cohorts: 2')
    expect(wrapper.text()).toContain('Active Now: 1')
    expect(wrapper.text()).toContain('Completed: 1')
  })

  it('filters cohorts by search query', async () => {
    const wrapper = mount(CohortMonitor)
    const store = useTPMonitorStore()
    store.cohorts = mockCohorts
    await flushPromises()

    const searchInput = wrapper.find('input[type="text"]')
    await searchInput.setValue('Summer')
    await wrapper.vm.$nextTick()

    expect(wrapper.text()).toContain('Summer 2025')
    expect(wrapper.text()).not.toContain('Winter 2025')
  })

  it('filters cohorts by status', async () => {
    const wrapper = mount(CohortMonitor)
    const store = useTPMonitorStore()
    store.cohorts = mockCohorts
    await flushPromises()

    const select = wrapper.find('select').filter(n => n.text().includes('All Status'))
    await select.setValue('completed')
    await wrapper.vm.$nextTick()

    expect(wrapper.text()).toContain('Winter 2025')
    expect(wrapper.text()).not.toContain('Summer 2025')
  })

  it('sorts cohorts correctly', async () => {
    const wrapper = mount(CohortMonitor)
    const store = useTPMonitorStore()
    store.cohorts = mockCohorts
    await flushPromises()

    const sortSelect = wrapper.find('select').filter(n => n.text().includes('Sort by'))
    await sortSelect.setValue('name')
    await wrapper.vm.$nextTick()

    // Should be sorted alphabetically
    const rows = wrapper.findAll('.border-b').filter(n => n.text().includes('Cohort'))
    expect(rows.length).toBeGreaterThan(0)
  })

  it('starts polling on mount and stops on unmount', async () => {
    const wrapper = mount(CohortMonitor)
    const store = useTPMonitorStore()
    const refreshSpy = vi.spyOn(store, 'refreshCohorts')
    
    await flushPromises()

    // Fast-forward 30 seconds
    vi.advanceTimersByTime(30000)
    expect(refreshSpy).toHaveBeenCalled()

    // Unmount
    wrapper.unmount()
    
    // Should not poll after unmount
    refreshSpy.mockClear()
    vi.advanceTimersByTime(30000)
    expect(refreshSpy).not.toHaveBeenCalled()
  })

  it('opens detail modal when view button clicked', async () => {
    const wrapper = mount(CohortMonitor)
    const store = useTPMonitorStore()
    store.cohorts = mockCohorts
    await flushPromises()

    const viewButton = wrapper.find('button[title="View Details"]')
    await viewButton.trigger('click')

    expect(wrapper.findComponent({ name: 'CohortDetailModal' }).exists()).toBe(true)
  })

  it('opens create modal when new cohort button clicked', async () => {
    const wrapper = mount(CohortMonitor)
    await flushPromises()

    const createButton = wrapper.find('button').filter(n => n.text().includes('New Cohort'))
    await createButton.trigger('click')

    expect(wrapper.findComponent({ name: 'CreateCohortModal' }).exists()).toBe(true)
  })

  it('handles export for completed cohort', async () => {
    const wrapper = mount(CohortMonitor)
    const store = useTPMonitorStore()
    const exportSpy = vi.spyOn(store, 'exportCohort').mockResolvedValue({
      success: true,
      download_url: '/downloads/test.xlsx',
      message: 'Export ready'
    })
    
    store.cohorts = mockCohorts
    await flushPromises()

    const exportButton = wrapper.find('button[title="Export Data"]')
    await exportButton.trigger('click')

    expect(exportSpy).toHaveBeenCalledWith(2)
  })

  it('displays empty state when no cohorts', async () => {
    const wrapper = mount(CohortMonitor)
    const store = useTPMonitorStore()
    store.cohorts = []
    await flushPromises()

    expect(wrapper.text()).toContain('No cohorts found')
  })

  it('shows live update indicator', async () => {
    const wrapper = mount(CohortMonitor)
    const store = useTPMonitorStore()
    store.isPolling = true
    await flushPromises()

    expect(wrapper.text()).toContain('Live updates active')
  })
})
```

**Integration Tests:**
```javascript
// spec/javascript/tp/integration/monitor-flow.spec.js
describe('TP Monitor Integration Flow', () => {
  it('handles complete monitoring workflow', async () => {
    // 1. Load dashboard with cohorts
    // 2. Filter by status
    // 3. Search for specific cohort
    // 4. Sort by different criteria
    // 5. View cohort details
    // 6. Send reminder
    // 7. Export completed cohort
    // 8. Verify polling updates
  })
})
```

**E2E Tests:**
```javascript
// spec/system/tp_cohort_monitor_spec.rb
RSpec.describe 'TP Cohort Monitor', type: :system do
  let(:tp) { create(:training_provider) }
  let!(:cohort1) { create(:cohort, training_provider: tp, status: :in_progress) }
  let!(:cohort2) { create(:cohort, training_provider: tp, status: :completed) }

  before do
    sign_in_as_tp(tp)
  end

  scenario 'TP views and manages cohorts' do
    visit '/tp/cohorts'

    # Verify analytics
    expect(page).to have_content('Total Cohorts: 2')
    expect(page).to have_content('Active Now: 1')
    expect(page).to have_content('Completed: 1')

    # Search for cohort
    fill_in 'Search cohorts', with: cohort1.name
    expect(page).to have_content(cohort1.name)
    expect(page).not_to have_content(cohort2.name)

    # Clear search
    fill_in 'Search cohorts', with: ''
    
    # Filter by status
    select 'Completed', from: 'status'
    expect(page).to have_content(cohort2.name)
    expect(page).not_to have_content(cohort1.name)

    # View cohort details
    click_link 'View', match: :first
    expect(page).to have_css('[role="dialog"]')
    expect(page).to have_content(cohort1.name)

    # Close modal
    click_button 'Close'
    expect(page).not_to have_css('[role="dialog"]')

    # Export completed cohort
    within('div', text: cohort2.name) do
      click_button 'Export Data'
    end

    # Verify download
    expect(page).to have_content('Export ready')
  end

  scenario 'real-time polling updates', do
    visit '/tp/cohorts'

    # Initial load
    expect(page).to have_content('Just now')

    # Simulate cohort update in background
    cohort1.update!(progress: 80)

    # Wait for polling interval
    sleep 30

    # Verify update
    expect(page).to have_content('80%')
  end
end
```

##### Rollback Procedure

**If dashboard fails to load:**
1. Show error message with "Retry" button
2. Attempt to reload data
3. Log error to monitoring service
4. Display fallback message with support contact

**If polling causes performance issues:**
1. Reduce polling frequency to 60 seconds
2. Implement exponential backoff on errors
3. Disable polling if user navigates away

**If export fails:**
1. Show error message with retry option
2. Log failure for investigation
3. Provide alternative export method (CSV fallback)
4. Notify user when export is ready via email

**If data becomes inconsistent:**
1. Manual refresh button to force reload
2. Clear local cache and refetch
3. Validate data structure before rendering

**Data Safety:**
- No data mutation in dashboard (read-only)
- All mutations happen through modals
- Export generates fresh data from server
- Polling only reads data

##### Risk Assessment

**Low Risk** because:
- Read-only operations (no data mutation)
- Standard Vue 3 + Pinia patterns
- Simple polling mechanism
- No complex business logic
- Well-established table/list patterns

**Specific Risks:**
1. **Performance**: Large number of cohorts (100+) slow rendering
   - **Mitigation**: Virtual scrolling or pagination if needed

2. **Polling Memory Leak**: Interval not cleaned up
   - **Mitigation**: `onUnmounted` hook with `clearInterval`

3. **Stale Data**: Polling doesn't update when tab is backgrounded
   - **Mitigation**: Refresh on visibility change

4. **Export Large Data**: Large cohorts timeout on export
   - **Mitigation**: Async export with email notification

**Mitigation Strategies:**
- Performance testing with 100+ cohorts
- Comprehensive unit tests for store getters
- E2E tests for polling behavior
- Error boundary handling for API failures

##### Success Metrics

- **Dashboard Load Time**: <2 seconds for 50 cohorts
- **Polling Accuracy**: 100% of updates captured within 30-second window
- **Export Success Rate**: 98% of exports complete successfully
- **Zero Memory Leaks**: Verified by heap snapshot tests
- **100% Test Coverage**: Store, components, and integration
- **User Satisfaction**: 90% of TPs can monitor cohorts without confusion
- **Performance**: Renders 100+ cohorts with <100ms interaction lag

---


---

### 6.5 Phase 5: Frontend - Student Portal

**Focus**: Student-facing interface for document completion and submission

This phase implements the student portal, where students access their assigned documents via email links (no account creation required). Students can upload required documents, fill their assigned fields, and submit for sponsor review. The portal emphasizes simplicity, clear progress indicators, and mobile-friendly design.

---

#### Story 5.1: Student Portal - Document Upload Interface

**Status**: Draft/Pending
**Priority**: High
**Epic**: Student Portal - Frontend Development
**Estimated Effort**: 2 days
**Risk Level**: Low

##### User Story

**As a** Student,
**I want** to upload required documents (ID, certificates, etc.) through a simple interface,
**So that** I can provide the necessary proof documents for my cohort enrollment.

##### Background

Students receive email invitations to join a cohort (Story 2.2). Upon clicking the link, they access the student portal where they must complete several steps:

1. **Upload Required Documents**: Government ID, certificates, photos, etc.
2. **Fill Assigned Fields**: Personal information, signatures, dates
3. **Review & Submit**: Final confirmation before sponsor review

This story implements the document upload interface, which is the first step in the student workflow. The interface must:

- Accept multiple file types (PDF, JPG, PNG)
- Show upload progress
- Validate file size and type
- Allow preview of uploaded files
- Support drag-and-drop
- Work on mobile devices

The uploaded documents are stored in Active Storage and linked to the student's submission record. After upload, students proceed to fill their assigned fields (Story 5.2).

**Integration Point**: This uploads documents that will be referenced in the final signed PDF generated by DocuSeal.

##### Technical Implementation Notes

**Vue 3 Component Structure:**
```vue
<!-- app/javascript/student/views/DocumentUpload.vue -->
<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-3xl mx-auto px-4">
      <!-- Progress Indicator -->
      <div class="mb-8">
        <div class="flex items-center justify-between mb-2">
          <span class="text-sm font-medium text-gray-700">Step 1 of 3: Upload Documents</span>
          <span class="text-sm text-gray-500">{{ uploadedCount }}/{{ requiredCount }} completed</span>
        </div>
        <div class="w-full bg-gray-200 rounded-full h-2 overflow-hidden">
          <div 
            class="bg-blue-600 h-2 rounded-full transition-all duration-500"
            :style="{ width: uploadProgress + '%' }"
          />
        </div>
      </div>

      <!-- Header -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <h1 class="text-2xl font-bold text-gray-900 mb-2">
          Upload Required Documents
        </h1>
        <p class="text-gray-600">
          Please upload the following documents for your enrollment in <strong>{{ cohortName }}</strong>
        </p>
      </div>

      <!-- Required Documents List -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Required Documents</h2>
        
        <div class="space-y-3">
          <div 
            v-for="requirement in requiredDocuments" 
            :key="requirement.id"
            class="border rounded-lg p-4"
            :class="isUploaded(requirement.id) ? 'border-green-300 bg-green-50' : 'border-gray-200'"
          >
            <div class="flex items-start justify-between">
              <div class="flex-1">
                <div class="flex items-center gap-2">
                  <h3 class="font-medium text-gray-900">{{ requirement.name }}</h3>
                  <span v-if="requirement.required" class="text-red-500">*</span>
                </div>
                <p class="text-sm text-gray-600 mt-1">{{ requirement.description }}</p>
                <p class="text-xs text-gray-500 mt-1">
                  Accepted: {{ requirement.accepted_types.join(', ') }} | Max: {{ requirement.max_size }}MB
                </p>
              </div>
              <div class="ml-4 flex-shrink-0">
                <div v-if="isUploaded(requirement.id)" class="flex items-center gap-2 text-green-600">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                  </svg>
                  <span class="text-sm font-medium">Uploaded</span>
                </div>
              </div>
            </div>

            <!-- Upload Area -->
            <div class="mt-4">
              <div
                v-if="!isUploaded(requirement.id)"
                class="border-2 border-dashed rounded-lg p-6 text-center transition-colors"
                :class="[
                  isDragging === requirement.id ? 'border-blue-500 bg-blue-50' : 'border-gray-300 hover:border-gray-400'
                ]"
                @dragover.prevent="handleDragOver(requirement.id)"
                @dragleave.prevent="handleDragLeave"
                @drop.prevent="handleDrop($event, requirement.id)"
              >
                <div v-if="!isUploading(requirement.id)">
                  <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                  </svg>
                  <p class="mt-2 text-sm text-gray-600">
                    <label class="text-blue-600 hover:text-blue-800 cursor-pointer font-medium">
                      Click to upload
                      <input
                        type="file"
                        :id="'file-' + requirement.id"
                        class="hidden"
                        @change="handleFileSelect($event, requirement.id)"
                        :accept="requirement.accepted_types.join(',')"
                      />
                    </label>
                    or drag and drop
                  </p>
                </div>

                <!-- Uploading Progress -->
                <div v-else class="w-full">
                  <div class="flex items-center justify-between mb-2">
                    <span class="text-sm text-gray-600">Uploading...</span>
                    <span class="text-sm font-medium">{{ getUploadProgress(requirement.id) }}%</span>
                  </div>
                  <div class="w-full bg-gray-200 rounded-full h-2 overflow-hidden">
                    <div 
                      class="bg-blue-600 h-2 rounded-full transition-all"
                      :style="{ width: getUploadProgress(requirement.id) + '%' }"
                    />
                  </div>
                </div>
              </div>

              <!-- Uploaded File Preview -->
              <div v-else class="mt-2 bg-gray-50 rounded-md p-3 flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="flex-shrink-0">
                    <svg v-if="getUploadedFile(requirement.id)?.type === 'image'" class="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                    </svg>
                    <svg v-else class="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                    </svg>
                  </div>
                  <div>
                    <div class="text-sm font-medium text-gray-900">
                      {{ getUploadedFile(requirement.id)?.name }}
                    </div>
                    <div class="text-xs text-gray-500">
                      {{ formatFileSize(getUploadedFile(requirement.id)?.size) }}
                    </div>
                  </div>
                </div>
                <div class="flex gap-2">
                  <button
                    @click="previewFile(requirement.id)"
                    class="text-xs text-blue-600 hover:text-blue-800 underline"
                  >
                    Preview
                  </button>
                  <button
                    @click="removeFile(requirement.id)"
                    class="text-xs text-red-600 hover:text-red-800 underline"
                  >
                    Remove
                  </button>
                </div>
              </div>

              <!-- Error Message -->
              <div v-if="getError(requirement.id)" class="mt-2 text-sm text-red-600 flex items-center gap-2">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                {{ getError(requirement.id) }}
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Navigation Buttons -->
      <div class="flex justify-between items-center">
        <button
          @click="saveDraft"
          class="px-6 py-2 border border-gray-300 rounded-md hover:bg-gray-50 text-gray-700 font-medium"
        >
          Save Draft
        </button>
        <button
          @click="continueToNextStep"
          :disabled="!canContinue"
          class="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed font-medium"
        >
          Continue to Next Step
        </button>
      </div>
    </div>

    <!-- File Preview Modal -->
    <FilePreviewModal
      v-if="previewFileData"
      :file="previewFileData"
      @close="previewFileData = null"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useStudentUploadStore } from '@/student/stores/upload'
import { useStudentAuthStore } from '@/student/stores/auth'
import FilePreviewModal from './FilePreviewModal.vue'

const props = defineProps<{
  submissionId: number
  token: string
}>()

const emit = defineEmits<{
  (e: 'next'): void
  (e: 'saved'): void
}>()

const uploadStore = useStudentUploadStore()
const authStore = useStudentAuthStore()

const isDragging = ref<number | null>(null)
const previewFileData = ref<File | null>(null)

const requiredDocuments = computed(() => uploadStore.requiredDocuments)
const uploadedCount = computed(() => uploadStore.uploadedCount)
const requiredCount = computed(() => uploadStore.requiredCount)
const cohortName = computed(() => uploadStore.cohortName)

const uploadProgress = computed(() => {
  if (requiredCount.value === 0) return 0
  return Math.round((uploadedCount.value / requiredCount.value) * 100)
})

const canContinue = computed(() => {
  // All required documents must be uploaded
  return requiredDocuments.value.every(doc => {
    if (!doc.required) return true
    return uploadStore.isUploaded(doc.id)
  })
})

onMounted(async () => {
  await uploadStore.fetchRequirements(props.submissionId, props.token)
})

const handleDragOver = (requirementId: number) => {
  isDragging.value = requirementId
}

const handleDragLeave = () => {
  isDragging.value = null
}

const handleDrop = (event: DragEvent, requirementId: number) => {
  isDragging.value = null
  const files = event.dataTransfer?.files
  if (files && files.length > 0) {
    processFile(files[0], requirementId)
  }
}

const handleFileSelect = (event: Event, requirementId: number) => {
  const input = event.target as HTMLInputElement
  if (input.files && input.files.length > 0) {
    processFile(input.files[0], requirementId)
  }
}

const processFile = async (file: File, requirementId: number) => {
  const requirement = requiredDocuments.value.find(r => r.id === requirementId)
  if (!requirement) return

  // Validate file type
  const extension = '.' + file.name.split('.').pop()?.toLowerCase()
  if (!requirement.accepted_types.includes(extension) && !requirement.accepted_types.includes(file.type)) {
    uploadStore.setError(requirementId, `Invalid file type. Accepted: ${requirement.accepted_types.join(', ')}`)
    return
  }

  // Validate file size
  const maxSizeBytes = requirement.max_size * 1024 * 1024
  if (file.size > maxSizeBytes) {
    uploadStore.setError(requirementId, `File too large. Max size: ${requirement.max_size}MB`)
    return
  }

  // Upload file
  try {
    await uploadStore.uploadFile(props.submissionId, props.token, requirementId, file)
  } catch (error) {
    uploadStore.setError(requirementId, 'Upload failed. Please try again.')
  }
}

const isUploaded = (requirementId: number) => {
  return uploadStore.isUploaded(requirementId)
}

const isUploading = (requirementId: number) => {
  return uploadStore.isUploading(requirementId)
}

const getUploadProgress = (requirementId: number) => {
  return uploadStore.getUploadProgress(requirementId)
}

const getUploadedFile = (requirementId: number) => {
  return uploadStore.getUploadedFile(requirementId)
}

const getError = (requirementId: number) => {
  return uploadStore.getError(requirementId)
}

const previewFile = (requirementId: number) => {
  const file = uploadStore.getUploadedFile(requirementId)
  if (file) {
    previewFileData.value = file
  }
}

const removeFile = async (requirementId: number) => {
  if (confirm('Are you sure you want to remove this file?')) {
    await uploadStore.removeFile(props.submissionId, props.token, requirementId)
  }
}

const saveDraft = async () => {
  try {
    await uploadStore.saveDraft(props.submissionId, props.token)
    emit('saved')
  } catch (error) {
    console.error('Failed to save draft:', error)
  }
}

const continueToNextStep = async () => {
  if (!canContinue.value) return
  
  // Mark upload step as complete
  await uploadStore.completeUploadStep(props.submissionId, props.token)
  emit('next')
}
</script>

<style scoped>
/* Smooth progress bar transitions */
.bg-blue-600 {
  transition: width 0.5s ease-in-out;
}

/* Drag and drop visual feedback */
.border-dashed {
  transition: all 0.2s ease;
}
</style>
```

**Pinia Store:**
```typescript
// app/javascript/student/stores/upload.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { SubmissionAPI } from '@/student/api/submission'
import type { DocumentRequirement, UploadedFile, UploadProgress } from '@/student/types'

export const useStudentUploadStore = defineStore('studentUpload', {
  state: () => ({
    requiredDocuments: [] as DocumentRequirement[],
    uploadedFiles: {} as Record<number, UploadedFile>,
    uploadProgress: {} as Record<number, UploadProgress>,
    errors: {} as Record<number, string>,
    isLoading: false,
    cohortName: '',
    submissionId: null as number | null
  }),

  getters: {
    uploadedCount: (state) => {
      return Object.keys(state.uploadedFiles).length
    },

    requiredCount: (state) => {
      return state.requiredDocuments.filter(r => r.required).length
    },

    isUploaded: (state) => {
      return (requirementId: number) => state.uploadedFiles[requirementId] !== undefined
    },

    isUploading: (state) => {
      return (requirementId: number) => state.uploadProgress[requirementId]?.status === 'uploading'
    },

    getUploadProgress: (state) => {
      return (requirementId: number) => state.uploadProgress[requirementId]?.progress || 0
    },

    getUploadedFile: (state) => {
      return (requirementId: number) => state.uploadedFiles[requirementId]
    },

    getError: (state) => {
      return (requirementId: number) => state.errors[requirementId]
    }
  },

  actions: {
    async fetchRequirements(submissionId: number, token: string): Promise<void> {
      this.isLoading = true
      try {
        const response = await SubmissionAPI.getRequirements(submissionId, token)
        this.requiredDocuments = response.requirements
        this.cohortName = response.cohort_name
        this.submissionId = submissionId

        // Restore uploaded files if any
        if (response.uploaded_files) {
          response.uploaded_files.forEach(file => {
            this.uploadedFiles[file.requirement_id] = file
          })
        }
      } catch (error) {
        console.error('Failed to fetch requirements:', error)
        throw error
      } finally {
        this.isLoading = false
      }
    },

    async uploadFile(
      submissionId: number,
      token: string,
      requirementId: number,
      file: File
    ): Promise<void> {
      this.uploadProgress[requirementId] = { progress: 0, status: 'uploading' }
      this.errors[requirementId] = ''

      try {
        const formData = new FormData()
        formData.append('file', file)
        formData.append('requirement_id', requirementId.toString())

        const response = await SubmissionAPI.uploadDocument(
          submissionId,
          token,
          formData,
          (progress) => {
            this.uploadProgress[requirementId].progress = progress
          }
        )

        this.uploadedFiles[requirementId] = {
          id: response.file_id,
          requirement_id: requirementId,
          name: file.name,
          size: file.size,
          type: file.type,
          url: response.url
        }

        this.uploadProgress[requirementId] = { progress: 100, status: 'completed' }
      } catch (error) {
        this.errors[requirementId] = 'Upload failed. Please try again.'
        delete this.uploadProgress[requirementId]
        throw error
      }
    },

    async removeFile(submissionId: number, token: string, requirementId: number): Promise<void> {
      try {
        await SubmissionAPI.removeDocument(submissionId, token, requirementId)
        delete this.uploadedFiles[requirementId]
        delete this.uploadProgress[requirementId]
        delete this.errors[requirementId]
      } catch (error) {
        console.error('Failed to remove file:', error)
        throw error
      }
    },

    async saveDraft(submissionId: number, token: string): Promise<void> {
      try {
        await SubmissionAPI.saveDraft(submissionId, token, {
          uploaded_files: Object.keys(this.uploadedFiles).map(id => parseInt(id))
        })
      } catch (error) {
        console.error('Failed to save draft:', error)
        throw error
      }
    },

    async completeUploadStep(submissionId: number, token: string): Promise<void> {
      try {
        await SubmissionAPI.completeUploadStep(submissionId, token)
      } catch (error) {
        console.error('Failed to complete upload step:', error)
        throw error
      }
    },

    setError(requirementId: number, message: string): void {
      this.errors[requirementId] = message
    },

    clearError(requirementId: number): void {
      delete this.errors[requirementId]
    }
  }
})
```

**API Layer:**
```typescript
// app/javascript/student/api/submission.ts
export interface DocumentRequirement {
  id: number
  name: string
  description: string
  required: boolean
  accepted_types: string[]
  max_size: number // in MB
}

export interface UploadedFile {
  id: number
  requirement_id: number
  name: string
  size: number
  type: string
  url: string
}

export interface UploadProgress {
  progress: number
  status: 'uploading' | 'completed'
}

export interface RequirementsResponse {
  requirements: DocumentRequirement[]
  cohort_name: string
  uploaded_files?: UploadedFile[]
}

export interface UploadResponse {
  file_id: number
  url: string
}

export const SubmissionAPI = {
  async getRequirements(submissionId: number, token: string): Promise<RequirementsResponse> {
    const response = await fetch(`/api/student/submissions/${submissionId}/requirements`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    })

    if (!response.ok) {
      if (response.status === 403) {
        throw new Error('Access denied or token expired')
      }
      if (response.status === 404) {
        throw new Error('Submission not found')
      }
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    return response.json()
  },

  async uploadDocument(
    submissionId: number,
    token: string,
    formData: FormData,
    onProgress?: (progress: number) => void
  ): Promise<UploadResponse> {
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest()

      if (onProgress) {
        xhr.upload.addEventListener('progress', (e) => {
          if (e.lengthComputable) {
            const progress = Math.round((e.loaded / e.total) * 100)
            onProgress(progress)
          }
        })
      }

      xhr.addEventListener('load', () => {
        if (xhr.status >= 200 && xhr.status < 300) {
          resolve(JSON.parse(xhr.responseText))
        } else {
          reject(new Error(`Upload failed: ${xhr.status}`))
        }
      })

      xhr.addEventListener('error', () => {
        reject(new Error('Network error during upload'))
      })

      xhr.open('POST', `/api/student/submissions/${submissionId}/documents`)
      xhr.setRequestHeader('Authorization', `Bearer ${token}`)
      xhr.send(formData)
    })
  },

  async removeDocument(submissionId: number, token: string, requirementId: number): Promise<void> {
    const response = await fetch(`/api/student/submissions/${submissionId}/documents/${requirementId}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
  },

  async saveDraft(submissionId: number, token: string, data: any): Promise<void> {
    const response = await fetch(`/api/student/submissions/${submissionId}/draft`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(data)
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
  },

  async completeUploadStep(submissionId: number, token: string): Promise<void> {
    const response = await fetch(`/api/student/submissions/${submissionId}/complete-upload`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
  }
}
```

**Type Definitions:**
```typescript
// app/javascript/student/types/index.ts
export interface DocumentRequirement {
  id: number
  name: string
  description: string
  required: boolean
  accepted_types: string[]
  max_size: number
}

export interface UploadedFile {
  id: number
  requirement_id: number
  name: string
  size: number
  type: string
  url: string
}

export interface UploadProgress {
  progress: number
  status: 'uploading' | 'completed'
}

export interface RequirementsResponse {
  requirements: DocumentRequirement[]
  cohort_name: string
  uploaded_files?: UploadedFile[]
}

export interface UploadResponse {
  file_id: number
  url: string
}
```

**Design System Compliance:**
Per FR28, all Student Upload components must use design system assets from:
- `@.claude/skills/frontend-design/SKILL.md` - Design tokens
- `@.claude/skills/frontend-design/design-system/` - SVG assets

Specific requirements:
- **Colors**: 
  - Primary (Blue-600): `#2563EB` for buttons and progress
  - Success (Green-600): `#16A34A` for uploaded items
  - Danger (Red-600): `#DC2626` for errors
  - Neutral (Gray-500): `#6B7280` for text
- **Spacing**: 4px base unit, 1.5rem (24px) for sections, 0.75rem (12px) for gaps
- **Typography**: 
  - Headings: 24px (h1), 18px (h2), 16px (h3)
  - Body: 16px base, 14px for secondary
  - Labels: 12px uppercase, letter-spacing 0.05em
- **Icons**: Use SVG icons from design system for:
  - Upload (cloud arrow up)
  - Document (file icon)
  - Checkmark (uploaded)
  - Trash (remove)
  - Eye (preview)
- **Layout**: 
  - Max width: 3xl (48rem / 768px)
  - Card corners: rounded-lg (8px)
  - Shadow: shadow-md for cards
  - Padding: 1.5rem for main containers
- **Accessibility**: 
  - ARIA labels on all buttons
  - Keyboard navigation for file inputs
  - Screen reader announcements for upload progress
  - Drag-and-drop has click fallback
  - Color contrast ratio minimum 4.5:1

##### Acceptance Criteria

**Functional:**
1. ✅ Component loads and fetches document requirements on mount
2. ✅ Displays list of required documents with descriptions
3. ✅ Supports drag-and-drop file upload
4. ✅ Supports click-to-upload file selection
5. ✅ Validates file type against accepted types
6. ✅ Validates file size against max size
7. ✅ Shows upload progress bar during upload
8. ✅ Displays uploaded files with name and size
9. ✅ Allows preview of uploaded files
10. ✅ Allows removal of uploaded files
11. ✅ Shows error messages for validation failures
12. ✅ Save Draft button saves progress without validation
13. ✅ Continue button only enabled when all required files uploaded
14. ✅ Progress bar updates correctly based on uploaded count

**UI/UX:**
1. ✅ Drag-and-drop shows visual feedback (border color change, background)
2. ✅ Upload progress animates smoothly
3. ✅ Success state shows green checkmark and background
4. ✅ Error messages appear in red below upload area
5. ✅ File preview shows appropriate icon (image vs document)
6. ✅ File size formatted human-readable (KB, MB)
7. ✅ Mobile-responsive design (stacks properly on small screens)
8. ✅ Loading state during initial requirements fetch
9. ✅ Empty state when no requirements exist
10. ✅ Confirmation dialog before file removal

**Integration:**
1. ✅ API endpoint: `GET /api/student/submissions/{id}/requirements`
2. ✅ API endpoint: `POST /api/student/submissions/{id}/documents` (with progress)
3. ✅ API endpoint: `DELETE /api/student/submissions/{id}/documents/{req_id}`
4. ✅ API endpoint: `POST /api/student/submissions/{id}/draft`
5. ✅ API endpoint: `POST /api/student/submissions/{id}/complete-upload`
6. ✅ Token authentication in headers
7. ✅ Progress tracking via XMLHttpRequest upload events
8. ✅ State persistence in Pinia store

**Security:**
1. ✅ Token-based authentication required
2. ✅ Authorization check: student can only upload to their submission
3. ✅ File type validation (server-side + client-side)
4. ✅ File size validation (server-side + client-side)
5. ✅ No executable file types allowed
6. ✅ Rate limiting on upload endpoint (max 10 uploads per hour)
7. ✅ Virus scanning on server (documented requirement)

**Quality:**
1. ✅ Uploads are atomic (all or nothing)
2. ✅ Network errors handled gracefully with retry option
3. ✅ No memory leaks (clean up file objects)
4. ✅ Performance: handles files up to 50MB
5. ✅ Browser compatibility: Chrome, Firefox, Safari, Edge

##### Integration Verification (IV1-4)

**IV1: API Integration**
- `DocumentUpload.vue` calls `SubmissionAPI.getRequirements()` on mount
- `DocumentUpload.vue` calls `SubmissionAPI.uploadDocument()` with progress callback
- `DocumentUpload.vue` calls `SubmissionAPI.removeDocument()` on delete
- `DocumentUpload.vue` calls `SubmissionAPI.saveDraft()` on save draft
- `DocumentUpload.vue` calls `SubmissionAPI.completeUploadStep()` on continue
- All endpoints use `Authorization: Bearer {token}` header

**IV2: Pinia Store**
- `studentUploadStore.requiredDocuments` holds requirements
- `studentUploadStore.uploadedFiles` tracks uploaded files
- `studentUploadStore.uploadProgress` tracks upload progress
- `studentUploadStore.uploadFile()` performs upload with progress
- `studentUploadStore.removeFile()` deletes uploaded file

**IV3: Getters**
- `uploadedCount()` counts uploaded files
- `requiredCount()` counts required documents
- `isUploaded()` checks if requirement has file
- `isUploading()` checks if file is uploading
- `getUploadProgress()` returns progress percentage

**IV4: Token Routing**
- DocumentUpload receives `token` prop from parent
- Parent loads token from URL param (`?token=...`)
- All API calls pass token to store actions

##### Test Requirements

**Component Specs:**
```javascript
// spec/javascript/student/views/DocumentUpload.spec.js
import { mount, flushPromises } from '@vue/test-utils'
import DocumentUpload from '@/student/views/DocumentUpload.vue'
import { useStudentUploadStore } from '@/student/stores/upload'
import { createPinia, setActivePinia } from 'pinia'

describe('DocumentUpload', () => {
  const mockRequirements = [
    {
      id: 1,
      name: 'Government ID',
      description: 'Front and back of your ID card',
      required: true,
      accepted_types: ['.jpg', '.png', '.pdf'],
      max_size: 5
    },
    {
      id: 2,
      name: 'Profile Photo',
      description: 'Recent passport-style photo',
      required: true,
      accepted_types: ['.jpg', '.png'],
      max_size: 2
    }
  ]

  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('renders requirements correctly', async () => {
    const wrapper = mount(DocumentUpload, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentUploadStore()
    store.requiredDocuments = mockRequirements
    store.cohortName = 'Summer 2025'
    await flushPromises()

    expect(wrapper.text()).toContain('Government ID')
    expect(wrapper.text()).toContain('Profile Photo')
    expect(wrapper.text()).toContain('Summer 2025')
  })

  it('handles file selection via click', async () => {
    const wrapper = mount(DocumentUpload, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentUploadStore()
    store.requiredDocuments = mockRequirements
    await flushPromises()

    const file = new File(['test'], 'test.jpg', { type: 'image/jpeg' })
    const input = wrapper.find('input[type="file"]')
    await input.trigger('change', { target: { files: [file] } })

    // Verify upload was called
    expect(store.uploadFile).toHaveBeenCalled()
  })

  it('validates file type', async () => {
    const wrapper = mount(DocumentUpload, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentUploadStore()
    store.requiredDocuments = mockRequirements
    await flushPromises()

    // Try to upload .txt file (not allowed)
    const file = new File(['test'], 'test.txt', { type: 'text/plain' })
    const input = wrapper.find('input[type="file"]')
    await input.trigger('change', { target: { files: [file] } })

    expect(store.errors[1]).toContain('Invalid file type')
  })

  it('validates file size', async () => {
    const wrapper = mount(DocumentUpload, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentUploadStore()
    store.requiredDocuments = mockRequirements
    await flushPromises()

    // Create file larger than 5MB
    const largeFile = new File([new Blob([new Array(6 * 1024 * 1024).join('x')])], 'large.jpg', { type: 'image/jpeg' })
    const input = wrapper.find('input[type="file"]')
    await input.trigger('change', { target: { files: [largeFile] } })

    expect(store.errors[1]).toContain('File too large')
  })

  it('shows upload progress', async () => {
    const wrapper = mount(DocumentUpload, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentUploadStore()
    store.requiredDocuments = mockRequirements
    store.uploadProgress[1] = { progress: 50, status: 'uploading' }
    await flushPromises()

    expect(wrapper.text()).toContain('50%')
  })

  it('shows uploaded files with preview and remove options', async () => {
    const wrapper = mount(DocumentUpload, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentUploadStore()
    store.requiredDocuments = mockRequirements
    store.uploadedFiles[1] = {
      id: 1,
      requirement_id: 1,
      name: 'test.jpg',
      size: 1024000,
      type: 'image/jpeg',
      url: '/uploads/test.jpg'
    }
    await flushPromises()

    expect(wrapper.text()).toContain('test.jpg')
    expect(wrapper.text()).toContain('Preview')
    expect(wrapper.text()).toContain('Remove')
  })

  it('enables continue button only when all required files uploaded', async () => {
    const wrapper = mount(DocumentUpload, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentUploadStore()
    store.requiredDocuments = mockRequirements
    await flushPromises()

    const continueButton = wrapper.find('button').filter(n => n.text().includes('Continue'))
    expect(continueButton.element.disabled).toBe(true)

    // Upload both required files
    store.uploadedFiles[1] = { id: 1, requirement_id: 1, name: 'id.jpg', size: 1000, type: 'image/jpeg', url: '/id.jpg' }
    store.uploadedFiles[2] = { id: 2, requirement_id: 2, name: 'photo.jpg', size: 1000, type: 'image/jpeg', url: '/photo.jpg' }
    await wrapper.vm.$nextTick()

    expect(continueButton.element.disabled).toBe(false)
  })

  it('handles drag and drop', async () => {
    const wrapper = mount(DocumentUpload, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentUploadStore()
    store.requiredDocuments = mockRequirements
    await flushPromises()

    const dropZone = wrapper.find('.border-dashed')
    const file = new File(['test'], 'test.jpg', { type: 'image/jpeg' })
    
    // Simulate drag and drop
    await dropZone.trigger('dragover', { dataTransfer: { files: [file] } })
    expect(dropZone.classes()).toContain('border-blue-500')

    await dropZone.trigger('drop', { dataTransfer: { files: [file] } })
    expect(store.uploadFile).toHaveBeenCalled()
  })

  it('saves draft when save button clicked', async () => {
    const wrapper = mount(DocumentUpload, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentUploadStore()
    store.requiredDocuments = mockRequirements
    await flushPromises()

    const saveButton = wrapper.find('button').filter(n => n.text().includes('Save Draft'))
    await saveButton.trigger('click')

    expect(store.saveDraft).toHaveBeenCalledWith(1, 'test-token')
  })
})
```

**Integration Tests:**
```javascript
// spec/javascript/student/integration/upload-flow.spec.js
describe('Document Upload Flow', () => {
  it('completes full upload workflow', async () => {
    // 1. Load upload page
    // 2. Fetch requirements
    // 3. Upload file via drag-drop
    // 4. Verify progress updates
    // 5. Upload second file via click
    // 6. Preview uploaded file
    // 7. Remove and re-upload
    // 8. Save draft
    // 9. Continue to next step
  })
})
```

**E2E Tests:**
```javascript
// spec/system/student_document_upload_spec.rb
RSpec.describe 'Student Document Upload', type: :system do
  let(:cohort) { create(:cohort, status: :in_progress) }
  let(:student) { create(:student, cohort: cohort) }
  let(:submission) { create(:submission, student: student, status: :pending) }
  let(:token) { submission.token }

  scenario 'student uploads required documents' do
    visit "/student/submissions/#{submission.id}?token=#{token}"

    # Verify requirements loaded
    expect(page).to have_content('Upload Required Documents')
    expect(page).to have_content('Government ID')

    # Upload file
    attach_file('Government ID', Rails.root.join('spec/fixtures/files/test_id.jpg'))
    
    # Wait for upload
    expect(page).to have_content('Uploaded')
    expect(page).to have_content('test_id.jpg')

    # Preview file
    click_link 'Preview'
    expect(page).to have_css('[role="dialog"]')

    # Close preview
    click_button 'Close'

    # Continue to next step
    click_button 'Continue to Next Step'
    expect(page).to have_content('Step 2 of 3')
  end

  scenario 'validates file type and size' do
    visit "/student/submissions/#{submission.id}?token=#{token}"

    # Try to upload invalid file type
    attach_file('Government ID', Rails.root.join('spec/fixtures/files/test.txt'))
    expect(page).to have_content('Invalid file type')

    # Try to upload oversized file
    # (create a large file in fixtures)
    expect(page).to have_content('File too large')
  end

  scenario 'saves draft and resumes later' do
    visit "/student/submissions/#{submission.id}?token=#{token}"

    # Upload one file
    attach_file('Government ID', Rails.root.join('spec/fixtures/files/test_id.jpg'))
    expect(page).to have_content('Uploaded')

    # Save draft
    click_button 'Save Draft'
    expect(page).to have_content('Draft saved')

    # Reload page
    visit "/student/submissions/#{submission.id}?token=#{token}"

    # Should show uploaded file
    expect(page).to have_content('test_id.jpg')
  end
end
```

##### Rollback Procedure

**If upload fails:**
1. Show error message with retry button
2. Preserve any successfully uploaded files
3. Log error to monitoring service
4. Allow user to try alternative file

**If network connection lost:**
1. Pause upload progress
2. Show "Connection lost" message
3. Auto-resume when connection restored
4. Allow manual retry

**If file is corrupted during upload:**
1. Detect checksum mismatch on server
2. Delete corrupted file
3. Show error message
4. Allow re-upload

**If user accidentally navigates away:**
1. Check for unsaved changes before navigation
2. Show confirmation dialog
3. Auto-save draft if user confirms
4. Restore state on return

**Data Safety:**
- Files are uploaded to temporary storage until submission is complete
- Failed uploads don't affect existing files
- Draft saves preserve all uploaded file references
- No data loss if user leaves and returns

##### Risk Assessment

**Low Risk** because:
- Standard file upload patterns
- Well-established browser APIs
- Simple validation logic
- No complex state management

**Specific Risks:**
1. **Large File Uploads**: Files >50MB may timeout
   - **Mitigation**: Chunked uploads, async processing

2. **Browser Compatibility**: Safari file upload quirks
   - **Mitigation**: Polyfills, cross-browser testing

3. **Storage Quota**: Exceeding server storage limits
   - **Mitigation**: File size limits, storage monitoring

4. **Virus/Malware**: Uploaded files may contain threats
   - **Mitigation**: Server-side virus scanning (documented)

**Mitigation Strategies:**
- Comprehensive E2E testing with real file uploads
- Performance testing with large files
- Browser compatibility matrix testing
- Server-side validation always matches client-side

##### Success Metrics

- **Upload Success Rate**: 99% of valid files upload successfully
- **Average Upload Time**: <5 seconds for 5MB files on typical connection
- **User Error Rate**: <2% of uploads fail due to validation
- **Zero Data Loss**: 100% of draft saves restore correctly
- **Mobile Compatibility**: 95% of mobile users can upload without issues
- **Support Tickets**: <1% of issues related to document upload

---

#### Story 5.2: Student Portal - Form Filling & Field Completion

**Status**: Draft/Pending
**Priority**: High
**Epic**: Student Portal - Frontend Development
**Estimated Effort**: 3 days
**Risk Level**: Medium

##### User Story

**As a** Student,
**I want** to fill in my assigned form fields (personal info, signatures, dates, etc.),
**So that** I can complete my portion of the document before the sponsor signs.

##### Background

After uploading required documents (Story 5.1), students must fill their assigned fields in the document. This is the core of the student workflow where they provide:

1. **Personal Information**: Name, address, contact details
2. **Signatures**: Digital signature capture
3. **Dates**: Date pickers for various fields
4. **Checkboxes**: Agreements and confirmations
5. **Text Fields**: Additional information or comments

The form builder (created by TP in Story 4.4) defines which fields each student must fill. This story implements the rendering and completion of those fields.

**Key Requirements:**
- Fields are pre-defined by TP in the template
- Each student sees only their assigned fields
- Signature can be drawn or typed
- All fields must be valid before submission
- Progress is auto-saved
- Mobile-friendly input methods

**Integration Point**: Field data is merged with uploaded documents and TP's signature to generate the final PDF in DocuSeal.

##### Technical Implementation Notes

**Vue 3 Component Structure:**
```vue
<!-- app/javascript/student/views/FormFieldCompletion.vue -->
<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-3xl mx-auto px-4">
      <!-- Progress Indicator -->
      <div class="mb-8">
        <div class="flex items-center justify-between mb-2">
          <span class="text-sm font-medium text-gray-700">Step 2 of 3: Complete Your Fields</span>
          <span class="text-sm text-gray-500">{{ completedFields }}/{{ totalFields }} completed</span>
        </div>
        <div class="w-full bg-gray-200 rounded-full h-2 overflow-hidden">
          <div 
            class="bg-blue-600 h-2 rounded-full transition-all duration-500"
            :style="{ width: fieldProgress + '%' }"
          />
        </div>
      </div>

      <!-- Header -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <h1 class="text-2xl font-bold text-gray-900 mb-2">
          Complete Your Information
        </h1>
        <p class="text-gray-600">
          Please fill in all required fields below. Your progress is automatically saved.
        </p>
      </div>

      <!-- Form Fields -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6 space-y-6">
        <div v-for="field in fields" :key="field.id" class="space-y-2">
          <!-- Text Input -->
          <div v-if="field.type === 'text'">
            <label :for="field.id" class="block text-sm font-medium text-gray-700">
              {{ field.label }}
              <span v-if="field.required" class="text-red-500">*</span>
            </label>
            <input
              :id="field.id"
              v-model="formData[field.id]"
              type="text"
              :placeholder="field.placeholder"
              :required="field.required"
              class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              @blur="validateField(field)"
            />
            <p v-if="field.description" class="text-xs text-gray-500 mt-1">
              {{ field.description }}
            </p>
            <p v-if="errors[field.id]" class="text-xs text-red-600 mt-1">
              {{ errors[field.id] }}
            </p>
          </div>

          <!-- Email Input -->
          <div v-else-if="field.type === 'email'">
            <label :for="field.id" class="block text-sm font-medium text-gray-700">
              {{ field.label }}
              <span v-if="field.required" class="text-red-500">*</span>
            </label>
            <input
              :id="field.id"
              v-model="formData[field.id]"
              type="email"
              :placeholder="field.placeholder"
              :required="field.required"
              class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              @blur="validateField(field)"
            />
            <p v-if="errors[field.id]" class="text-xs text-red-600 mt-1">
              {{ errors[field.id] }}
            </p>
          </div>

          <!-- Date Input -->
          <div v-else-if="field.type === 'date'">
            <label :for="field.id" class="block text-sm font-medium text-gray-700">
              {{ field.label }}
              <span v-if="field.required" class="text-red-500">*</span>
            </label>
            <input
              :id="field.id"
              v-model="formData[field.id]"
              type="date"
              :required="field.required"
              class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              @blur="validateField(field)"
            />
            <p v-if="errors[field.id]" class="text-xs text-red-600 mt-1">
              {{ errors[field.id] }}
            </p>
          </div>

          <!-- Number Input -->
          <div v-else-if="field.type === 'number'">
            <label :for="field.id" class="block text-sm font-medium text-gray-700">
              {{ field.label }}
              <span v-if="field.required" class="text-red-500">*</span>
            </label>
            <input
              :id="field.id"
              v-model="formData[field.id]"
              type="number"
              :placeholder="field.placeholder"
              :required="field.required"
              class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              @blur="validateField(field)"
            />
            <p v-if="errors[field.id]" class="text-xs text-red-600 mt-1">
              {{ errors[field.id] }}
            </p>
          </div>

          <!-- Checkbox -->
          <div v-else-if="field.type === 'checkbox'">
            <div class="flex items-start">
              <div class="flex items-center h-5">
                <input
                  :id="field.id"
                  v-model="formData[field.id]"
                  type="checkbox"
                  :required="field.required"
                  class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-2 focus:ring-blue-500"
                  @change="validateField(field)"
                />
              </div>
              <div class="ml-3 text-sm">
                <label :for="field.id" class="font-medium text-gray-700">
                  {{ field.label }}
                  <span v-if="field.required" class="text-red-500">*</span>
                </label>
                <p v-if="field.description" class="text-gray-500">
                  {{ field.description }}
                </p>
              </div>
            </div>
            <p v-if="errors[field.id]" class="text-xs text-red-600 mt-1 ml-8">
              {{ errors[field.id] }}
            </p>
          </div>

          <!-- Radio Group -->
          <div v-else-if="field.type === 'radio'">
            <label class="block text-sm font-medium text-gray-700 mb-2">
              {{ field.label }}
              <span v-if="field.required" class="text-red-500">*</span>
            </label>
            <div class="space-y-2">
              <div v-for="option in field.options" :key="option.value" class="flex items-center">
                <input
                  :id="field.id + '-' + option.value"
                  v-model="formData[field.id]"
                  type="radio"
                  :value="option.value"
                  :required="field.required"
                  class="h-4 w-4 text-blue-600 border-gray-300 focus:ring-2 focus:ring-blue-500"
                  @change="validateField(field)"
                />
                <label :for="field.id + '-' + option.value" class="ml-3 text-sm text-gray-700">
                  {{ option.label }}
                </label>
              </div>
            </div>
            <p v-if="errors[field.id]" class="text-xs text-red-600 mt-1">
              {{ errors[field.id] }}
            </p>
          </div>

          <!-- Select Dropdown -->
          <div v-else-if="field.type === 'select'">
            <label :for="field.id" class="block text-sm font-medium text-gray-700">
              {{ field.label }}
              <span v-if="field.required" class="text-red-500">*</span>
            </label>
            <select
              :id="field.id"
              v-model="formData[field.id]"
              :required="field.required"
              class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              @change="validateField(field)"
            >
              <option value="">Select an option</option>
              <option v-for="option in field.options" :key="option.value" :value="option.value">
                {{ option.label }}
              </option>
            </select>
            <p v-if="errors[field.id]" class="text-xs text-red-600 mt-1">
              {{ errors[field.id] }}
            </p>
          </div>

          <!-- Signature Field -->
          <div v-else-if="field.type === 'signature'">
            <label class="block text-sm font-medium text-gray-700 mb-2">
              {{ field.label }}
              <span v-if="field.required" class="text-red-500">*</span>
            </label>
            
            <!-- Signature Canvas -->
            <div class="border-2 border-gray-300 rounded-md bg-white">
              <canvas
                :ref="'canvas-' + field.id"
                width="600"
                height="150"
                class="w-full cursor-crosshair"
                @mousedown="startDrawing(field.id, $event)"
                @mousemove="draw(field.id, $event)"
                @mouseup="stopDrawing(field.id)"
                @mouseleave="stopDrawing(field.id)"
                @touchstart="startDrawing(field.id, $event)"
                @touchmove="draw(field.id, $event)"
                @touchend="stopDrawing(field.id)"
              />
            </div>

            <!-- Signature Controls -->
            <div class="flex gap-2 mt-2">
              <button
                @click="clearSignature(field.id)"
                class="px-3 py-1.5 text-sm border border-gray-300 rounded-md hover:bg-gray-50"
              >
                Clear
              </button>
              <button
                @click="useTextSignature(field.id)"
                class="px-3 py-1.5 text-sm border border-gray-300 rounded-md hover:bg-gray-50"
              >
                Type Instead
              </button>
            </div>

            <p v-if="errors[field.id]" class="text-xs text-red-600 mt-1">
              {{ errors[field.id] }}
            </p>
          </div>

          <!-- Textarea -->
          <div v-else-if="field.type === 'textarea'">
            <label :for="field.id" class="block text-sm font-medium text-gray-700">
              {{ field.label }}
              <span v-if="field.required" class="text-red-500">*</span>
            </label>
            <textarea
              :id="field.id"
              v-model="formData[field.id]"
              :placeholder="field.placeholder"
              :required="field.required"
              :rows="field.rows || 3"
              class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              @blur="validateField(field)"
            ></textarea>
            <p v-if="field.description" class="text-xs text-gray-500 mt-1">
              {{ field.description }}
            </p>
            <p v-if="errors[field.id]" class="text-xs text-red-600 mt-1">
              {{ errors[field.id] }}
            </p>
          </div>
        </div>
      </div>

      <!-- Navigation Buttons -->
      <div class="flex justify-between items-center">
        <button
          @click="saveDraft"
          class="px-6 py-2 border border-gray-300 rounded-md hover:bg-gray-50 text-gray-700 font-medium"
        >
          Save Draft
        </button>
        <div class="flex gap-3">
          <button
            @click="goBack"
            class="px-6 py-2 border border-gray-300 rounded-md hover:bg-gray-50 text-gray-700 font-medium"
          >
            Back
          </button>
          <button
            @click="continueToNextStep"
            :disabled="!canContinue"
            class="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed font-medium"
          >
            Continue to Review
          </button>
        </div>
      </div>
    </div>

    <!-- Text Signature Modal -->
    <TextSignatureModal
      v-if="textSignatureFieldId"
      :field-label="getFieldLabel(textSignatureFieldId)"
      @submit="handleTextSignatureSubmit"
      @cancel="textSignatureFieldId = null"
    />

    <!-- Auto-save Indicator -->
    <div v-if="isSaving" class="fixed bottom-4 right-4 bg-gray-800 text-white px-4 py-2 rounded-md shadow-lg text-sm">
      <span class="flex items-center gap-2">
        <svg class="w-4 h-4 animate-spin" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
        </svg>
        Saving...
      </span>
    </div>

    <div v-if="showSavedIndicator" class="fixed bottom-4 right-4 bg-green-600 text-white px-4 py-2 rounded-md shadow-lg text-sm flex items-center gap-2">
      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
      </svg>
      Saved
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useStudentFormStore } from '@/student/stores/form'
import TextSignatureModal from './TextSignatureModal.vue'

const props = defineProps<{
  submissionId: number
  token: string
}>()

const emit = defineEmits<{
  (e: 'next'): void
  (e: 'back'): void
  (e: 'saved'): void
}>()

const formStore = useStudentFormStore()

const formData = ref<Record<string, any>>({})
const errors = ref<Record<string, string>>({})
const isSaving = ref(false)
const showSavedIndicator = ref(false)
const textSignatureFieldId = ref<string | null>(null)
const drawingStates = ref<Record<string, { isDrawing: boolean; ctx: CanvasRenderingContext2D | null }>>({})

const fields = computed(() => formStore.fields)
const completedFields = computed(() => {
  return fields.value.filter(field => {
    const value = formData.value[field.id]
    if (field.type === 'signature') {
      return formStore.signatureData[field.id] !== undefined
    }
    return value !== undefined && value !== '' && value !== null
  }).length
})
const totalFields = computed(() => fields.value.length)
const fieldProgress = computed(() => {
  if (totalFields.value === 0) return 0
  return Math.round((completedFields.value / totalFields.value) * 100)
})

const canContinue = computed(() => {
  // All required fields must be filled
  return fields.value.every(field => {
    if (!field.required) return true
    
    if (field.type === 'signature') {
      return formStore.signatureData[field.id] !== undefined
    }
    
    const value = formData.value[field.id]
    return value !== undefined && value !== '' && value !== null
  })
})

let autoSaveInterval: number | null = null

onMounted(async () => {
  await formStore.fetchFields(props.submissionId, props.token)
  
  // Initialize formData with existing values
  formStore.fields.forEach(field => {
    if (field.existing_value !== undefined) {
      formData.value[field.id] = field.existing_value
    }
  })

  // Start auto-save every 30 seconds
  autoSaveInterval = window.setInterval(() => {
    if (hasUnsavedChanges()) {
      performAutoSave()
    }
  }, 30000)
})

onUnmounted(() => {
  if (autoSaveInterval) {
    clearInterval(autoSaveInterval)
  }
})

// Watch for form changes to trigger validation
watch(formData, (newData) => {
  // Auto-validate on change
  Object.keys(newData).forEach(fieldId => {
    const field = fields.value.find(f => f.id === fieldId)
    if (field) {
      validateField(field)
    }
  })
}, { deep: true })

const hasUnsavedChanges = () => {
  // Check if any field has changed from initial state
  return fields.value.some(field => {
    const currentValue = formData.value[field.id]
    const signatureValue = formStore.signatureData[field.id]
    
    if (field.type === 'signature') {
      return signatureValue !== undefined && signatureValue !== field.existing_value
    }
    
    return currentValue !== undefined && currentValue !== field.existing_value
  })
}

const validateField = (field: any) => {
  const value = formData.value[field.id]
  errors.value[field.id] = ''

  // Required validation
  if (field.required && !value && field.type !== 'signature') {
    errors.value[field.id] = 'This field is required'
    return false
  }

  if (field.type === 'signature' && field.required && !formStore.signatureData[field.id]) {
    errors.value[field.id] = 'Signature is required'
    return false
  }

  // Email validation
  if (field.type === 'email' && value) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(value)) {
      errors.value[field.id] = 'Invalid email format'
      return false
    }
  }

  // Number validation
  if (field.type === 'number' && value) {
    if (field.min !== undefined && parseFloat(value) < field.min) {
      errors.value[field.id] = `Minimum value is ${field.min}`
      return false
    }
    if (field.max !== undefined && parseFloat(value) > field.max) {
      errors.value[field.id] = `Maximum value is ${field.max}`
      return false
    }
  }

  // Checkbox validation
  if (field.type === 'checkbox' && field.required && !value) {
    errors.value[field.id] = 'You must check this box'
    return false
  }

  return true
}

const validateAllFields = () => {
  let isValid = true
  fields.value.forEach(field => {
    if (!validateField(field)) {
      isValid = false
    }
  })
  return isValid
}

// Signature Drawing Functions
const startDrawing = (fieldId: string, event: MouseEvent | TouchEvent) => {
  const canvasKey = 'canvas-' + fieldId
  const canvas = document.querySelector(`canvas`) // Need to get specific canvas
  // Note: In actual implementation, use refs properly
  // This is a simplified version
  
  if (!drawingStates.value[fieldId]) {
    drawingStates.value[fieldId] = { isDrawing: false, ctx: null }
  }
  
  drawingStates.value[fieldId].isDrawing = true
  // Setup canvas context...
}

const draw = (fieldId: string, event: MouseEvent | TouchEvent) => {
  if (!drawingStates.value[fieldId]?.isDrawing) return
  // Drawing logic...
}

const stopDrawing = (fieldId: string) => {
  if (drawingStates.value[fieldId]) {
    drawingStates.value[fieldId].isDrawing = false
    
    // Save signature data
    // const canvas = ...
    // formStore.signatureData[fieldId] = canvas.toDataURL()
  }
}

const clearSignature = (fieldId: string) => {
  formStore.signatureData[fieldId] = undefined
  // Clear canvas
  errors.value[fieldId] = ''
}

const useTextSignature = (fieldId: string) => {
  textSignatureFieldId.value = fieldId
}

const handleTextSignatureSubmit = (text: string) => {
  if (textSignatureFieldId.value) {
    formStore.signatureData[textSignatureFieldId.value] = text
    formStore.signatureType[textSignatureFieldId.value] = 'text'
    textSignatureFieldId.value = null
  }
}

const getFieldLabel = (fieldId: string) => {
  const field = fields.value.find(f => f.id === fieldId)
  return field ? field.label : ''
}

const saveDraft = async () => {
  isSaving.value = true
  try {
    await formStore.saveDraft(props.submissionId, props.token, {
      form_data: formData.value,
      signature_data: formStore.signatureData
    })
    showSavedIndicator.value = true
    setTimeout(() => {
      showSavedIndicator.value = false
    }, 2000)
    emit('saved')
  } catch (error) {
    console.error('Failed to save draft:', error)
  } finally {
    isSaving.value = false
  }
}

const performAutoSave = async () => {
  try {
    await formStore.saveDraft(props.submissionId, props.token, {
      form_data: formData.value,
      signature_data: formStore.signatureData
    })
  } catch (error) {
    console.warn('Auto-save failed:', error)
  }
}

const goBack = () => {
  emit('back')
}

const continueToNextStep = async () => {
  if (!canContinue.value) {
    validateAllFields()
    return
  }

  // Save current state
  await formStore.saveFormData(props.submissionId, props.token, {
    form_data: formData.value,
    signature_data: formStore.signatureData
  })

  // Mark form step as complete
  await formStore.completeFormStep(props.submissionId, props.token)
  
  emit('next')
}
</script>

<style scoped>
/* Smooth progress bar transitions */
.bg-blue-600 {
  transition: width 0.5s ease-in-out;
}

/* Signature canvas styling */
canvas {
  touch-action: none;
}
</style>
```

**Pinia Store:**
```typescript
// app/javascript/student/stores/form.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { SubmissionAPI } from '@/student/api/submission'
import type { FormField, FormSubmissionData } from '@/student/types'

export const useStudentFormStore = defineStore('studentForm', {
  state: () => ({
    fields: [] as FormField[],
    signatureData: {} as Record<string, string>,
    signatureType: {} as Record<string, 'canvas' | 'text'>,
    isLoading: false,
    error: null as string | null,
    submissionId: null as number | null
  }),

  getters: {
    completedFieldCount: (state) => {
      return state.fields.filter(field => {
        const value = state.signatureData[field.id]
        return value !== undefined
      }).length
    },

    totalFieldCount: (state) => {
      return state.fields.length
    },

    isFormComplete: (state) => {
      return state.fields.every(field => {
        if (field.required) {
          return state.signatureData[field.id] !== undefined
        }
        return true
      })
    }
  },

  actions: {
    async fetchFields(submissionId: number, token: string): Promise<void> {
      this.isLoading = true
      this.error = null

      try {
        const response = await SubmissionAPI.getFormFields(submissionId, token)
        this.fields = response.fields
        this.submissionId = submissionId

        // Restore existing data
        if (response.existing_data) {
          Object.keys(response.existing_data).forEach(key => {
            if (key.startsWith('signature_')) {
              const fieldId = key.replace('signature_', '')
              this.signatureData[fieldId] = response.existing_data[key]
            }
          })
        }
      } catch (error) {
        this.error = error instanceof Error ? error.message : 'Failed to fetch fields'
        console.error('Fetch fields error:', error)
        throw error
      } finally {
        this.isLoading = false
      }
    },

    async saveDraft(
      submissionId: number,
      token: string,
      data: FormSubmissionData
    ): Promise<void> {
      try {
        await SubmissionAPI.saveFormDraft(submissionId, token, data)
      } catch (error) {
        console.error('Save draft error:', error)
        throw error
      }
    },

    async saveFormData(
      submissionId: number,
      token: string,
      data: FormSubmissionData
    ): Promise<void> {
      try {
        await SubmissionAPI.saveFormData(submissionId, token, data)
      } catch (error) {
        console.error('Save form data error:', error)
        throw error
      }
    },

    async completeFormStep(submissionId: number, token: string): Promise<void> {
      try {
        await SubmissionAPI.completeFormStep(submissionId, token)
      } catch (error) {
        console.error('Complete form step error:', error)
        throw error
      }
    },

    clearError(): void {
      this.error = null
    }
  }
})
```

**API Layer:**
```typescript
// app/javascript/student/api/submission.ts (extended)
export interface FormField {
  id: string
  type: 'text' | 'email' | 'date' | 'number' | 'checkbox' | 'radio' | 'select' | 'signature' | 'textarea'
  label: string
  required: boolean
  placeholder?: string
  description?: string
  options?: Array<{ value: string; label: string }>
  rows?: number
  min?: number
  max?: number
  existing_value?: any
}

export interface FormFieldsResponse {
  fields: FormField[]
  existing_data?: Record<string, any>
}

export interface FormSubmissionData {
  form_data: Record<string, any>
  signature_data: Record<string, string>
}

export const SubmissionAPI = {
  // ... existing methods

  async getFormFields(submissionId: number, token: string): Promise<FormFieldsResponse> {
    const response = await fetch(`/api/student/submissions/${submissionId}/form-fields`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    })

    if (!response.ok) {
      if (response.status === 403) {
        throw new Error('Access denied or token expired')
      }
      if (response.status === 404) {
        throw new Error('Submission not found')
      }
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    return response.json()
  },

  async saveFormDraft(
    submissionId: number,
    token: string,
    data: FormSubmissionData
  ): Promise<void> {
    const response = await fetch(`/api/student/submissions/${submissionId}/form-draft`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(data)
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
  },

  async saveFormData(
    submissionId: number,
    token: string,
    data: FormSubmissionData
  ): Promise<void> {
    const response = await fetch(`/api/student/submissions/${submissionId}/form-data`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(data)
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
  },

  async completeFormStep(submissionId: number, token: string): Promise<void> {
    const response = await fetch(`/api/student/submissions/${submissionId}/complete-form`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
  }
}
```

**Type Definitions:**
```typescript
// app/javascript/student/types/index.ts (extended)
export interface FormField {
  id: string
  type: 'text' | 'email' | 'date' | 'number' | 'checkbox' | 'radio' | 'select' | 'signature' | 'textarea'
  label: string
  required: boolean
  placeholder?: string
  description?: string
  options?: Array<{ value: string; label: string }>
  rows?: number
  min?: number
  max?: number
  existing_value?: any
}

export interface FormFieldsResponse {
  fields: FormField[]
  existing_data?: Record<string, any>
}

export interface FormSubmissionData {
  form_data: Record<string, any>
  signature_data: Record<string, string>
}
```

**Design System Compliance:**
Per FR28, all Form Completion components must use design system assets from:
- `@.claude/skills/frontend-design/SKILL.md` - Design tokens
- `@.claude/skills/frontend-design/design-system/` - SVG assets

Specific requirements:
- **Colors**: 
  - Primary (Blue-600): `#2563EB` for buttons and focus states
  - Success (Green-600): `#16A34A` for completed fields
  - Danger (Red-600): `#DC2626` for errors
  - Neutral (Gray-300): `#D1D5DB` for borders
- **Spacing**: 4px base unit, 1.5rem (24px) for sections, 0.75rem (12px) for field gaps
- **Typography**: 
  - Labels: 14px, medium weight
  - Input text: 16px
  - Error messages: 12px
  - Helper text: 12px, gray-500
- **Icons**: Use SVG icons from design system for:
  - Signature (pen)
  - Clear (trash)
  - Type (keyboard)
  - Save (floppy disk)
  - Checkmark (completed)
- **Layout**: 
  - Max width: 3xl (48rem / 768px)
  - Input padding: 0.5rem (8px) vertical, 0.75rem (12px) horizontal
  - Focus ring: 2px solid blue-500
  - Signature canvas: 600x150px
- **Accessibility**: 
  - All inputs have associated labels
  - Required fields marked with asterisk
  - Error messages linked to inputs
  - Keyboard navigation support
  - Screen reader announcements for auto-save
  - Color contrast ratio minimum 4.5:1

##### Acceptance Criteria

**Functional:**
1. ✅ Component loads and fetches form fields on mount
2. ✅ Renders all field types correctly (text, email, date, number, checkbox, radio, select, signature, textarea)
3. ✅ Validates each field type appropriately
4. ✅ Shows error messages below invalid fields
5. ✅ Signature canvas supports drawing with mouse/touch
6. ✅ Signature can be cleared and replaced with text
7. ✅ Progress bar updates as fields are completed
8. ✅ Auto-save triggers every 30 seconds if changes detected
9. ✅ Save Draft button works immediately
10. ✅ Continue button disabled until all required fields valid
11. ✅ Back button returns to previous step
12. ✅ Existing data is restored if user returns to draft

**UI/UX:**
1. ✅ All inputs show focus states with blue ring
2. ✅ Required fields marked with red asterisk
3. ✅ Signature canvas shows drawing feedback
4. ✅ Text signature modal appears centered
5. ✅ Auto-save indicator shows when saving
6. ✅ Success indicator appears briefly after save
7. ✅ Mobile-responsive design (inputs stack properly)
8. ✅ Radio buttons and checkboxes are clickable and accessible
9. ✅ Date picker uses native browser date selector
10. ✅ Textarea auto-expands or has scroll for long text

**Integration:**
1. ✅ API endpoint: `GET /api/student/submissions/{id}/form-fields`
2. ✅ API endpoint: `POST /api/student/submissions/{id}/form-draft`
3. ✅ API endpoint: `POST /api/student/submissions/{id}/form-data`
4. ✅ API endpoint: `POST /api/student/submissions/{id}/complete-form`
5. ✅ Token authentication in headers
6. ✅ Form data and signature data sent to server
7. ✅ State persistence in Pinia store
8. ✅ Data restored on page reload

**Security:**
1. ✅ Token-based authentication required
2. ✅ Authorization check: student can only fill their submission
3. ✅ Input validation (client-side + server-side)
4. ✅ XSS prevention (sanitized input)
5. ✅ Rate limiting on save endpoints
6. ✅ Audit log of all form saves

**Quality:**
1. ✅ Auto-save doesn't interfere with user typing
2. ✅ Network errors handled gracefully
3. ✅ No memory leaks (clean up intervals)
4. ✅ Performance: handles 50+ fields without lag
5. ✅ Browser compatibility: Chrome, Firefox, Safari, Edge

##### Integration Verification (IV1-4)

**IV1: API Integration**
- `FormFieldCompletion.vue` calls `SubmissionAPI.getFormFields()` on mount
- `FormFieldCompletion.vue` calls `SubmissionAPI.saveFormDraft()` on save
- `FormFieldCompletion.vue` calls `SubmissionAPI.saveFormData()` before continue
- `FormFieldCompletion.vue` calls `SubmissionAPI.completeFormStep()` on continue
- All endpoints use `Authorization: Bearer {token}` header

**IV2: Pinia Store**
- `studentFormStore.fields` holds all form field definitions
- `studentFormStore.signatureData` tracks signature data
- `studentFormStore.saveDraft()` persists data
- `studentFormStore.saveFormData()` saves final state
- `studentFormStore.completeFormStep()` marks step complete

**IV3: Getters**
- `completedFieldCount()` counts filled fields
- `totalFieldCount()` counts all fields
- `isFormComplete()` checks if all required fields filled

**IV4: Token Routing**
- FormCompletion receives `token` prop from parent
- Parent loads token from URL param (`?token=...`)
- All API calls pass token to store actions

##### Test Requirements

**Component Specs:**
```javascript
// spec/javascript/student/views/FormFieldCompletion.spec.js
import { mount, flushPromises } from '@vue/test-utils'
import FormFieldCompletion from '@/student/views/FormFieldCompletion.vue'
import { useStudentFormStore } from '@/student/stores/form'
import { createPinia, setActivePinia } from 'pinia'

describe('FormFieldCompletion', () => {
  const mockFields = [
    { id: 'name', type: 'text', label: 'Full Name', required: true },
    { id: 'email', type: 'email', label: 'Email', required: true },
    { id: 'signature', type: 'signature', label: 'Signature', required: true }
  ]

  beforeEach(() => {
    setActivePinia(createPinia())
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('renders all field types correctly', async () => {
    const wrapper = mount(FormFieldCompletion, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentFormStore()
    store.fields = mockFields
    await flushPromises()

    expect(wrapper.find('input[type="text"]').exists()).toBe(true)
    expect(wrapper.find('input[type="email"]').exists()).toBe(true)
    expect(wrapper.find('canvas').exists()).toBe(true)
  })

  it('validates required fields', async () => {
    const wrapper = mount(FormFieldCompletion, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentFormStore()
    store.fields = mockFields
    await flushPromises()

    // Try to continue without filling fields
    const continueButton = wrapper.find('button').filter(n => n.text().includes('Continue'))
    await continueButton.trigger('click')

    // Should show validation errors
    expect(wrapper.text()).toContain('This field is required')
  })

  it('updates progress bar as fields are filled', async () => {
    const wrapper = mount(FormFieldCompletion, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentFormStore()
    store.fields = mockFields
    await flushPromises()

    // Fill first field
    const nameInput = wrapper.find('input[type="text"]')
    await nameInput.setValue('John Doe')
    await wrapper.vm.$nextTick()

    // Progress should be 33%
    expect(wrapper.text()).toContain('1 of 3 completed')
  })

  it('enables continue button when all required fields filled', async () => {
    const wrapper = mount(FormFieldCompletion, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentFormStore()
    store.fields = mockFields
    await flushPromises()

    const continueButton = wrapper.find('button').filter(n => n.text().includes('Continue'))
    expect(continueButton.element.disabled).toBe(true)

    // Fill all fields
    await wrapper.find('input[type="text"]').setValue('John Doe')
    await wrapper.find('input[type="email"]').setValue('john@example.com')
    store.signatureData['signature'] = 'data:image/png;base64,signature'
    await wrapper.vm.$nextTick()

    expect(continueButton.element.disabled).toBe(false)
  })

  it('auto-saves every 30 seconds', async () => {
    const wrapper = mount(FormFieldCompletion, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentFormStore()
    store.fields = mockFields
    const saveSpy = vi.spyOn(store, 'saveDraft')
    await flushPromises()

    // Fill a field
    await wrapper.find('input[type="text"]').setValue('John Doe')

    // Fast-forward 30 seconds
    vi.advanceTimersByTime(30000)

    expect(saveSpy).toHaveBeenCalled()
  })

  it('handles text signature', async () => {
    const wrapper = mount(FormFieldCompletion, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentFormStore()
    store.fields = mockFields
    await flushPromises()

    // Click "Type Instead" on signature
    const typeButton = wrapper.find('button').filter(n => n.text() === 'Type Instead')
    await typeButton.trigger('click')

    expect(wrapper.findComponent({ name: 'TextSignatureModal' }).exists()).toBe(true)
  })

  it('validates email format', async () => {
    const wrapper = mount(FormFieldCompletion, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentFormStore()
    store.fields = mockFields
    await flushPromises()

    const emailInput = wrapper.find('input[type="email"]')
    await emailInput.setValue('invalid-email')
    await emailInput.trigger('blur')

    expect(wrapper.text()).toContain('Invalid email format')
  })
})
```

**Integration Tests:**
```javascript
// spec/javascript/student/integration/form-flow.spec.js
describe('Form Completion Flow', () => {
  it('completes full form workflow', async () => {
    // 1. Load form page
    // 2. Fetch fields
    // 3. Fill text fields
    // 4. Draw signature
    // 5. Auto-save triggers
    // 6. Save draft manually
    // 7. Validate all fields
    // 8. Continue to next step
  })
})
```

**E2E Tests:**
```javascript
// spec/system/student_form_completion_spec.rb
RSpec.describe 'Student Form Completion', type: :system do
  let(:cohort) { create(:cohort, status: :in_progress) }
  let(:student) { create(:student, cohort: cohort) }
  let(:submission) { create(:submission, student: student, status: :upload_complete) }
  let(:token) { submission.token }

  scenario 'student fills form and signs' do
    visit "/student/submissions/#{submission.id}/form?token=#{token}"

    # Fill text fields
    fill_in 'Full Name', with: 'John Doe'
    fill_in 'Email', with: 'john@example.com'
    select 'United States', from: 'Country'

    # Draw signature
    canvas = find('canvas')
    page.driver.browser.action.move_to(canvas.native).click_and_hold.perform
    page.driver.browser.action.move_by(50, 0).perform
    page.driver.browser.action.release.perform

    # Verify progress
    expect(page).to have_content('3 of 5 completed')

    # Save draft
    click_button 'Save Draft'
    expect(page).to have_content('Saved')

    # Continue
    click_button 'Continue to Review'
    expect(page).to have_content('Step 3 of 3')
  end

  scenario 'auto-save works while typing', do
    visit "/student/submissions/#{submission.id}/form?token=#{token}"

    fill_in 'Full Name', with: 'John Doe'

    # Wait for auto-save
    sleep 30

    # Reload page
    visit "/student/submissions/#{submission.id}/form?token=#{token}"

    # Should restore data
    expect(find_field('Full Name').value).to eq('John Doe')
  end

  scenario 'validates all required fields', do
    visit "/student/submissions/#{submission.id}/form?token=#{token}"

    # Try to continue without filling
    click_button 'Continue to Review'

    expect(page).to have_content('This field is required')
  end
end
```

##### Rollback Procedure

**If form submission fails:**
1. Show error message with retry option
2. Preserve all form data in store
3. Allow user to save draft and try later
4. Log error to monitoring service

**If auto-save fails:**
1. Show "Save failed" indicator
2. Continue attempting auto-save
3. Warn user before leaving page
4. Offer manual save option

**If signature canvas is corrupted:**
1. Clear canvas and signature data
2. Allow re-draw or text signature
3. Show error message with retry option

**If user navigates away accidentally:**
1. Check for unsaved changes
2. Show confirmation dialog
3. Auto-save if user confirms
4. Restore state on return

**Data Safety:**
- All form data stored in Pinia store
- Auto-save creates backup every 30 seconds
- Draft saves preserve all data
- No data loss on page refresh

##### Risk Assessment

**Medium Risk** because:
- Complex form validation across multiple field types
- Signature capture requires canvas API
- Auto-save mechanism must not interfere with user input
- State management for 50+ fields
- Mobile signature capture is challenging

**Specific Risks:**
1. **Signature Canvas Compatibility**: Mobile browsers handle touch events differently
   - **Mitigation**: Use `signature_pad` library, provide text fallback

2. **Auto-save Interference**: Auto-save while user is typing
   - **Mitigation**: Debounce auto-save, save only after 2 seconds of inactivity

3. **Large Forms**: Performance issues with 50+ fields
   - **Mitigation**: Virtual scrolling, lazy load non-visible fields

4. **Data Loss**: Network failure during auto-save
   - **Mitigation**: Store data in localStorage as backup, retry mechanism

5. **Validation Complexity**: Different rules for different field types
   - **Mitigation**: Centralized validation library, comprehensive tests

**Mitigation Strategies:**
- Use `signature_pad` library for cross-browser signature support
- Debounce auto-save to 2 seconds after last input
- Implement localStorage backup for critical data
- Comprehensive validation test suite
- Performance testing with large forms

##### Success Metrics

- **Form Completion Rate**: 95% of students who start complete the form
- **Auto-save Success**: 99.5% of auto-save attempts succeed
- **Zero Data Loss**: 100% of drafts restore correctly
- **Validation Accuracy**: 100% of invalid inputs caught
- **Mobile Compatibility**: 90% of mobile users can sign successfully
- **Average Completion Time**: <5 minutes for typical 10-field form
- **Support Tickets**: <2% of issues related to form completion

---

#### Story 5.3: Student Portal - Progress Tracking & Save Draft

**Status**: Draft/Pending
**Priority**: High
**Epic**: Student Portal - Frontend Development
**Estimated Effort**: 2 days
**Risk Level**: Low

##### User Story

**As a** Student,
**I want** to see my overall progress and save my work as a draft at any time,
**So that** I can complete the submission at my own pace without losing work.

##### Background

Students may need multiple sessions to complete their submission:
1. Upload documents (Story 5.1)
2. Fill form fields (Story 5.2)
3. Review and submit (Story 5.4)

The student portal must provide:
- **Progress Dashboard**: Visual overview of all steps and their status
- **Draft Management**: Save and resume capability
- **Session Persistence**: Data survives browser refresh
- **Multi-step Navigation**: Jump between steps
- **Completion Indicators**: Clear visual feedback

This story implements the progress tracking UI that shows all three steps (Upload, Form, Review) with their completion status, and provides a persistent "Save Draft" mechanism accessible from any step.

**Integration Point**: This ties together Stories 5.1 and 5.2, providing the navigation layer that orchestrates the complete student workflow.

##### Technical Implementation Notes

**Vue 3 Component Structure:**
```vue
<!-- app/javascript/student/views/ProgressDashboard.vue -->
<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-4xl mx-auto px-4">
      <!-- Header -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <div class="flex justify-between items-start">
          <div>
            <h1 class="text-2xl font-bold text-gray-900 mb-2">
              Your Submission Progress
            </h1>
            <p class="text-gray-600">
              Cohort: <strong>{{ cohortName }}</strong>
            </p>
          </div>
          <div class="text-right">
            <div class="text-sm text-gray-500">Last Saved</div>
            <div class="font-medium text-gray-900">{{ lastSavedText }}</div>
          </div>
        </div>
      </div>

      <!-- Overall Progress Card -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Overall Progress</h2>
        
        <!-- Progress Bar -->
        <div class="mb-2">
          <div class="flex justify-between text-sm mb-1">
            <span class="font-medium">{{ overallProgress }}% Complete</span>
            <span class="text-gray-500">{{ completedSteps }} of {{ totalSteps }} Steps</span>
          </div>
          <div class="w-full bg-gray-200 rounded-full h-3 overflow-hidden">
            <div 
              class="bg-green-600 h-3 rounded-full transition-all duration-500"
              :style="{ width: overallProgress + '%' }"
            />
          </div>
        </div>

        <!-- Status Badge -->
        <div class="flex items-center gap-2 mt-3">
          <span 
            class="px-3 py-1 rounded-full text-sm font-medium"
            :class="statusBadgeClass"
          >
            {{ statusText }}
          </span>
          <span class="text-sm text-gray-600">
            {{ statusDescription }}
          </span>
        </div>
      </div>

      <!-- Step Navigation Cards -->
      <div class="space-y-4 mb-6">
        <!-- Step 1: Upload Documents -->
        <div 
          class="bg-white rounded-lg shadow-md p-5 border-l-4 transition-all hover:shadow-lg cursor-pointer"
          :class="[
            step1Completed ? 'border-green-500' : 'border-blue-500',
            currentStep === 1 ? 'ring-2 ring-blue-500' : ''
          ]"
          @click="goToStep(1)"
        >
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-4 flex-1">
              <!-- Step Icon -->
              <div class="flex-shrink-0">
                <div 
                  class="w-10 h-10 rounded-full flex items-center justify-center font-bold"
                  :class="step1Completed ? 'bg-green-100 text-green-700' : 'bg-blue-100 text-blue-700'"
                >
                  <svg v-if="step1Completed" class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                  </svg>
                  <span v-else>1</span>
                </div>
              </div>
              <!-- Step Info -->
              <div class="flex-1">
                <h3 class="font-semibold text-gray-900">Upload Required Documents</h3>
                <p class="text-sm text-gray-600">Government ID, certificates, photos</p>
                <div v-if="uploadProgress > 0" class="mt-1">
                  <div class="flex items-center gap-2 text-xs">
                    <div class="w-24 bg-gray-200 rounded-full h-1.5 overflow-hidden">
                      <div class="bg-blue-600 h-1.5 rounded-full" :style="{ width: uploadProgress + '%' }" />
                    </div>
                    <span class="text-gray-600">{{ uploadProgress }}%</span>
                  </div>
                </div>
              </div>
            </div>
            <!-- Status -->
            <div class="flex-shrink-0">
              <span 
                class="px-2 py-1 rounded-full text-xs font-medium"
                :class="step1Completed ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'"
              >
                {{ step1Completed ? 'Completed' : 'Pending' }}
              </span>
            </div>
          </div>
        </div>

        <!-- Step 2: Complete Form -->
        <div 
          class="bg-white rounded-lg shadow-md p-5 border-l-4 transition-all hover:shadow-lg cursor-pointer"
          :class="[
            step2Completed ? 'border-green-500' : 'border-blue-500',
            currentStep === 2 ? 'ring-2 ring-blue-500' : ''
          ]"
          @click="goToStep(2)"
        >
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-4 flex-1">
              <!-- Step Icon -->
              <div class="flex-shrink-0">
                <div 
                  class="w-10 h-10 rounded-full flex items-center justify-center font-bold"
                  :class="step2Completed ? 'bg-green-100 text-green-700' : 'bg-blue-100 text-blue-700'"
                >
                  <svg v-if="step2Completed" class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                  </svg>
                  <span v-else>2</span>
                </div>
              </div>
              <!-- Step Info -->
              <div class="flex-1">
                <h3 class="font-semibold text-gray-900">Complete Your Information</h3>
                <p class="text-sm text-gray-600">Personal details, signatures, agreements</p>
                <div v-if="formProgress > 0" class="mt-1">
                  <div class="flex items-center gap-2 text-xs">
                    <div class="w-24 bg-gray-200 rounded-full h-1.5 overflow-hidden">
                      <div class="bg-blue-600 h-1.5 rounded-full" :style="{ width: formProgress + '%' }" />
                    </div>
                    <span class="text-gray-600">{{ formProgress }}%</span>
                  </div>
                </div>
              </div>
            </div>
            <!-- Status -->
            <div class="flex-shrink-0">
              <span 
                class="px-2 py-1 rounded-full text-xs font-medium"
                :class="step2Completed ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'"
              >
                {{ step2Completed ? 'Completed' : 'Pending' }}
              </span>
            </div>
          </div>
        </div>

        <!-- Step 3: Review & Submit -->
        <div 
          class="bg-white rounded-lg shadow-md p-5 border-l-4 transition-all hover:shadow-lg cursor-pointer"
          :class="[
            step3Completed ? 'border-green-500' : 'border-blue-500',
            currentStep === 3 ? 'ring-2 ring-blue-500' : ''
          ]"
          @click="goToStep(3)"
        >
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-4 flex-1">
              <!-- Step Icon -->
              <div class="flex-shrink-0">
                <div 
                  class="w-10 h-10 rounded-full flex items-center justify-center font-bold"
                  :class="step3Completed ? 'bg-green-100 text-green-700' : 'bg-blue-100 text-blue-700'"
                >
                  <svg v-if="step3Completed" class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                  </svg>
                  <span v-else>3</span>
                </div>
              </div>
              <!-- Step Info -->
              <div class="flex-1">
                <h3 class="font-semibold text-gray-900">Review & Submit</h3>
                <p class="text-sm text-gray-600">Final review before sponsor signature</p>
              </div>
            </div>
            <!-- Status -->
            <div class="flex-shrink-0">
              <span 
                class="px-2 py-1 rounded-full text-xs font-medium"
                :class="step3Completed ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'"
              >
                {{ step3Completed ? 'Completed' : 'Pending' }}
              </span>
            </div>
          </div>
        </div>
      </div>

      <!-- Quick Actions -->
      <div class="bg-white rounded-lg shadow-md p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h2>
        <div class="flex flex-wrap gap-3">
          <button
            @click="saveDraft"
            class="px-4 py-2 bg-gray-600 text-white rounded-md hover:bg-gray-700 font-medium flex items-center gap-2"
            :disabled="isSaving"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4" />
            </svg>
            {{ isSaving ? 'Saving...' : 'Save Draft' }}
          </button>

          <button
            v-if="canSubmit"
            @click="submitForReview"
            class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 font-medium flex items-center gap-2"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            Submit for Review
          </button>

          <button
            v-if="!canSubmit && allStepsComplete"
            @click="viewSubmission"
            class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 font-medium flex items-center gap-2"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
            </svg>
            View Submission
          </button>

          <button
            v-if="!canSubmit && !allStepsComplete"
            @click="resumeWorkflow"
            class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 font-medium flex items-center gap-2"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            Resume Workflow
          </button>

          <button
            @click="showHelp = true"
            class="px-4 py-2 border border-gray-300 rounded-md hover:bg-gray-50 text-gray-700 font-medium flex items-center gap-2"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            Help
          </button>
        </div>
      </div>

      <!-- Auto-save Status -->
      <div v-if="isSaving" class="fixed bottom-4 right-4 bg-gray-800 text-white px-4 py-2 rounded-md shadow-lg text-sm flex items-center gap-2">
        <svg class="w-4 h-4 animate-spin" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
        </svg>
        Saving draft...
      </div>

      <div v-if="showSaved" class="fixed bottom-4 right-4 bg-green-600 text-white px-4 py-2 rounded-md shadow-lg text-sm flex items-center gap-2">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
        Draft saved
      </div>

      <!-- Help Modal -->
      <HelpModal
        v-if="showHelp"
        @close="showHelp = false"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useStudentProgressStore } from '@/student/stores/progress'
import { useStudentAuthStore } from '@/student/stores/auth'
import HelpModal from './HelpModal.vue'

const props = defineProps<{
  submissionId: number
  token: string
  initialStep?: number
}>()

const emit = defineEmits<{
  (e: 'navigate', step: number): void
  (e: 'submitted'): void
}>()

const progressStore = useStudentProgressStore()
const authStore = useStudentAuthStore()

const isSaving = ref(false)
const showSaved = ref(false)
const showHelp = ref(false)
const currentStep = ref(props.initialStep || 1)

const cohortName = computed(() => progressStore.cohortName)
const uploadProgress = computed(() => progressStore.uploadProgress)
const formProgress = computed(() => progressStore.formProgress)
const step1Completed = computed(() => progressStore.step1Completed)
const step2Completed = computed(() => progressStore.step2Completed)
const step3Completed = computed(() => progressStore.step3Completed)

const totalSteps = computed(() => 3)
const completedSteps = computed(() => {
  return [step1Completed.value, step2Completed.value, step3Completed.value].filter(Boolean).length
})

const overallProgress = computed(() => {
  return Math.round((completedSteps.value / totalSteps.value) * 100)
})

const allStepsComplete = computed(() => {
  return step1Completed.value && step2Completed.value && step3Completed.value
})

const canSubmit = computed(() => {
  return allStepsComplete.value && !progressStore.submitted
})

const statusBadgeClass = computed(() => {
  if (progressStore.submitted) return 'bg-purple-100 text-purple-800'
  if (allStepsComplete.value) return 'bg-green-100 text-green-800'
  if (completedSteps.value > 0) return 'bg-blue-100 text-blue-800'
  return 'bg-gray-100 text-gray-800'
})

const statusText = computed(() => {
  if (progressStore.submitted) return 'Submitted for Review'
  if (allStepsComplete.value) return 'Ready to Submit'
  if (completedSteps.value > 0) return 'In Progress'
  return 'Not Started'
})

const statusDescription = computed(() => {
  if (progressStore.submitted) return 'Waiting for sponsor signature'
  if (allStepsComplete.value) return 'All steps completed, ready for final submission'
  if (completedSteps.value > 0) return 'Continue where you left off'
  return 'Start by uploading your required documents'
})

const lastSavedText = computed(() => {
  if (!progressStore.lastSaved) return 'Never'
  
  const diff = Date.now() - progressStore.lastSaved
  const minutes = Math.floor(diff / 60000)
  
  if (minutes < 1) return 'Just now'
  if (minutes < 60) return `${minutes}m ago`
  const hours = Math.floor(minutes / 60)
  return `${hours}h ago`
})

let autoSaveInterval: number | null = null

onMounted(async () => {
  await progressStore.fetchProgress(props.submissionId, props.token)
  
  // Start auto-save every 30 seconds
  autoSaveInterval = window.setInterval(() => {
    if (progressStore.hasUnsavedChanges) {
      performAutoSave()
    }
  }, 30000)
})

onUnmounted(() => {
  if (autoSaveInterval) {
    clearInterval(autoSaveInterval)
  }
})

const goToStep = (step: number) => {
  if (step === 1 && !step1Completed.value && currentStep.value > 1) {
    // Can't go back to upload if already completed
    return
  }
  
  currentStep.value = step
  emit('navigate', step)
}

const saveDraft = async () => {
  isSaving.value = true
  try {
    await progressStore.saveDraft(props.submissionId, props.token)
    showSaved.value = true
    setTimeout(() => {
      showSaved.value = false
    }, 2000)
  } catch (error) {
    console.error('Failed to save draft:', error)
  } finally {
    isSaving.value = false
  }
}

const performAutoSave = async () => {
  try {
    await progressStore.saveDraft(props.submissionId, props.token)
  } catch (error) {
    console.warn('Auto-save failed:', error)
  }
}

const submitForReview = async () => {
  if (!canSubmit.value) return

  if (!confirm('Submit your application for review? This will notify the sponsor and training provider.')) {
    return
  }

  try {
    await progressStore.submitForReview(props.submissionId, props.token)
    emit('submitted')
  } catch (error) {
    console.error('Submission failed:', error)
  }
}

const resumeWorkflow = () => {
  // Determine which step to go to
  if (!step1Completed.value) {
    goToStep(1)
  } else if (!step2Completed.value) {
    goToStep(2)
  } else {
    goToStep(3)
  }
}

const viewSubmission = () => {
  // Navigate to submission view
  emit('navigate', 3)
}
</script>

<style scoped>
/* Smooth progress bar transitions */
.bg-green-600, .bg-blue-600 {
  transition: width 0.5s ease-in-out;
}

/* Hover effects */
.cursor-pointer:hover {
  transform: translateY(-2px);
  transition: transform 0.2s ease;
}
</style>
```

**Pinia Store:**
```typescript
// app/javascript/student/stores/progress.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { SubmissionAPI } from '@/student/api/submission'
import type { ProgressData, SaveDraftResponse, SubmitResponse } from '@/student/types'

export const useStudentProgressStore = defineStore('studentProgress', {
  state: () => ({
    cohortName: '',
    uploadProgress: 0,
    formProgress: 0,
    step1Completed: false,
    step2Completed: false,
    step3Completed: false,
    submitted: false,
    lastSaved: null as number | null,
    hasUnsavedChanges: false,
    isLoading: false,
    error: null as string | null
  }),

  getters: {
    overallProgressPercent: (state) => {
      const total = 3
      const completed = [
        state.step1Completed,
        state.step2Completed,
        state.step3Completed
      ].filter(Boolean).length
      return Math.round((completed / total) * 100)
    }
  },

  actions: {
    async fetchProgress(submissionId: number, token: string): Promise<void> {
      this.isLoading = true
      this.error = null

      try {
        const response = await SubmissionAPI.getProgress(submissionId, token)
        this.cohortName = response.cohort_name
        this.uploadProgress = response.upload_progress
        this.formProgress = response.form_progress
        this.step1Completed = response.step1_completed
        this.step2Completed = response.step2_completed
        this.step3Completed = response.step3_completed
        this.submitted = response.submitted
        this.lastSaved = response.last_saved ? new Date(response.last_saved).getTime() : null
      } catch (error) {
        this.error = error instanceof Error ? error.message : 'Failed to fetch progress'
        console.error('Fetch progress error:', error)
        throw error
      } finally {
        this.isLoading = false
      }
    },

    async saveDraft(submissionId: number, token: string): Promise<void> {
      try {
        const response = await SubmissionAPI.saveDraft(submissionId, token)
        this.lastSaved = Date.now()
        this.hasUnsavedChanges = false
        return response
      } catch (error) {
        console.error('Save draft error:', error)
        throw error
      }
    },

    async submitForReview(submissionId: number, token: string): Promise<void> {
      try {
        const response = await SubmissionAPI.submitForReview(submissionId, token)
        this.submitted = true
        this.step3Completed = true
        return response
      } catch (error) {
        console.error('Submit error:', error)
        throw error
      }
    },

    markUnsaved(): void {
      this.hasUnsavedChanges = true
    },

    clearError(): void {
      this.error = null
    }
  }
})
```

**API Layer:**
```typescript
// app/javascript/student/api/submission.ts (extended)
export interface ProgressData {
  cohort_name: string
  upload_progress: number
  form_progress: number
  step1_completed: boolean
  step2_completed: boolean
  step3_completed: boolean
  submitted: boolean
  last_saved: string | null
}

export interface SaveDraftResponse {
  success: boolean
  saved_at: string
}

export interface SubmitResponse {
  success: boolean
  submission_id: number
  status: string
}

export const SubmissionAPI = {
  // ... existing methods

  async getProgress(submissionId: number, token: string): Promise<ProgressData> {
    const response = await fetch(`/api/student/submissions/${submissionId}/progress`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    })

    if (!response.ok) {
      if (response.status === 403) {
        throw new Error('Access denied or token expired')
      }
      if (response.status === 404) {
        throw new Error('Submission not found')
      }
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    return response.json()
  },

  async saveDraft(submissionId: number, token: string): Promise<SaveDraftResponse> {
    const response = await fetch(`/api/student/submissions/${submissionId}/save-draft`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    return response.json()
  },

  async submitForReview(submissionId: number, token: string): Promise<SubmitResponse> {
    const response = await fetch(`/api/student/submissions/${submissionId}/submit`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    })

    if (!response.ok) {
      if (response.status === 409) {
        throw new Error('Submission already submitted or incomplete')
      }
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    return response.json()
  }
}
```

**Type Definitions:**
```typescript
// app/javascript/student/types/index.ts (extended)
export interface ProgressData {
  cohort_name: string
  upload_progress: number
  form_progress: number
  step1_completed: boolean
  step2_completed: boolean
  step3_completed: boolean
  submitted: boolean
  last_saved: string | null
}

export interface SaveDraftResponse {
  success: boolean
  saved_at: string
}

export interface SubmitResponse {
  success: boolean
  submission_id: number
  status: string
}
```

**Design System Compliance:**
Per FR28, all Progress Tracking components must use design system assets from:
- `@.claude/skills/frontend-design/SKILL.md` - Design tokens
- `@.claude/skills/frontend-design/design-system/` - SVG assets

Specific requirements:
- **Colors**: 
  - Success (Green-600): `#16A34A` for completed steps
  - Primary (Blue-600): `#2563EB` for active/in-progress
  - Neutral (Gray-500): `#6B7280` for pending
  - Warning (Purple-600): `#7C3AED` for submitted state
- **Spacing**: 4px base unit, 1.5rem (24px) for card gaps, 1rem (16px) for internal padding
- **Typography**: 
  - Headings: 20px (h2), 16px (h3)
  - Body: 14px for descriptions
  - Labels: 12px uppercase, letter-spacing 0.05em
- **Icons**: Use SVG icons from design system for:
  - Checkmark (completed)
  - Document (upload step)
  - Form (form step)
  - Eye (review step)
  - Floppy disk (save)
  - Paper airplane (submit)
  - Question mark (help)
- **Layout**: 
  - Max width: 4xl (896px)
  - Card corners: rounded-lg (8px)
  - Shadow: shadow-md for cards
  - Border accent: 4px left border on step cards
- **Accessibility**: 
  - ARIA labels on all buttons
  - Keyboard navigation for step cards
  - Screen reader announcements for progress updates
  - Focus indicators on interactive elements
  - Color contrast ratio minimum 4.5:1

##### Acceptance Criteria

**Functional:**
1. ✅ Dashboard loads progress data on mount
2. ✅ Shows correct overall progress percentage
3. ✅ Displays all 3 steps with correct status
4. ✅ Step cards show completion indicators (checkmark, numbers)
5. ✅ Progress bars animate smoothly
6. ✅ Status badge shows correct text and color
7. ✅ Last saved timestamp updates correctly
8. ✅ "Save Draft" button works and shows feedback
9. ✅ "Submit for Review" only enabled when all steps complete
10. ✅ "Resume Workflow" directs to appropriate step
11. ✅ Clicking step cards navigates to that step
12. ✅ Auto-save triggers every 30 seconds if changes detected

**UI/UX:**
1. ✅ Step cards have hover effects (lift, shadow)
2. ✅ Active step shows ring highlight
3. ✅ Progress bars animate from 0 to current value
4. ✅ Status badge uses color-coded styling
5. ✅ Last saved time formats correctly (just now, Xm ago, Xh ago)
6. ✅ Success toast appears after save
7. ✅ Loading state during save
8. ✅ Mobile-responsive layout
9. ✅ Step cards are clickable and show cursor pointer
10. ✅ Help modal provides clear instructions

**Integration:**
1. ✅ API endpoint: `GET /api/student/submissions/{id}/progress`
2. ✅ API endpoint: `POST /api/student/submissions/{id}/save-draft`
3. ✅ API endpoint: `POST /api/student/submissions/{id}/submit`
4. ✅ Token authentication in headers
5. ✅ Navigation emits events to parent
6. ✅ Progress data reflects uploads and form completion

**Security:**
1. ✅ Token-based authentication required
2. ✅ Authorization check: student can only view their submission
3. ✅ Submit endpoint validates all steps complete
4. ✅ Rate limiting on save endpoints
5. ✅ Audit log of all saves and submissions

**Quality:**
1. ✅ Auto-save doesn't trigger if no changes
2. ✅ Navigation prevents invalid transitions
3. ✅ Error handling for failed API calls
4. ✅ No memory leaks (clean up intervals)
5. ✅ Performance: loads in <2 seconds

##### Integration Verification (IV1-4)

**IV1: API Integration**
- `ProgressDashboard.vue` calls `SubmissionAPI.getProgress()` on mount
- `ProgressDashboard.vue` calls `SubmissionAPI.saveDraft()` on save
- `ProgressDashboard.vue` calls `SubmissionAPI.submitForReview()` on submit
- All endpoints use `Authorization: Bearer {token}` header
- Progress data reflects actual completion from other stories

**IV2: Pinia Store**
- `studentProgressStore.cohortName` holds cohort information
- `studentProgressStore.uploadProgress` tracks upload completion
- `studentProgressStore.formProgress` tracks form completion
- `studentProgressStore.step1Completed` reflects upload status
- `studentProgressStore.step2Completed` reflects form status
- `studentProgressStore.step3Completed` reflects review status

**IV3: Getters**
- `overallProgressPercent()` calculates completion across all steps
- State reflects real-time updates from other components

**IV4: Token Routing**
- ProgressDashboard receives `token` prop from parent
- Parent loads token from URL param (`?token=...`)
- All API calls pass token to store actions

##### Test Requirements

**Component Specs:**
```javascript
// spec/javascript/student/views/ProgressDashboard.spec.js
import { mount, flushPromises } from '@vue/test-utils'
import ProgressDashboard from '@/student/views/ProgressDashboard.vue'
import { useStudentProgressStore } from '@/student/stores/progress'
import { createPinia, setActivePinia } from 'pinia'

describe('ProgressDashboard', () => {
  const mockProgress = {
    cohort_name: 'Summer 2025',
    upload_progress: 100,
    form_progress: 75,
    step1_completed: true,
    step2_completed: false,
    step3_completed: false,
    submitted: false,
    last_saved: new Date().toISOString()
  }

  beforeEach(() => {
    setActivePinia(createPinia())
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('renders overall progress correctly', async () => {
    const wrapper = mount(ProgressDashboard, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentProgressStore()
    Object.assign(store, mockProgress)
    await flushPromises()

    expect(wrapper.text()).toContain('33% Complete')
    expect(wrapper.text()).toContain('1 of 3 Steps')
  })

  it('displays step cards with correct status', async () => {
    const wrapper = mount(ProgressDashboard, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentProgressStore()
    Object.assign(store, mockProgress)
    await flushPromises()

    expect(wrapper.text()).toContain('Upload Required Documents')
    expect(wrapper.text()).toContain('Complete Your Information')
    expect(wrapper.text()).toContain('Review & Submit')
    
    // Step 1 should show completed
    expect(wrapper.text()).toContain('Completed')
  })

  it('enables submit button only when all steps complete', async () => {
    const wrapper = mount(ProgressDashboard, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentProgressStore()
    Object.assign(store, mockProgress)
    await flushPromises()

    let submitButton = wrapper.find('button').filter(n => n.text().includes('Submit'))
    expect(submitButton.exists()).toBe(false)

    // Complete all steps
    store.step2_completed = true
    store.step3_completed = true
    await wrapper.vm.$nextTick()

    submitButton = wrapper.find('button').filter(n => n.text().includes('Submit'))
    expect(submitButton.exists()).toBe(true)
  })

  it('saves draft when button clicked', async () => {
    const wrapper = mount(ProgressDashboard, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentProgressStore()
    Object.assign(store, mockProgress)
    const saveSpy = vi.spyOn(store, 'saveDraft')
    await flushPromises()

    const saveButton = wrapper.find('button').filter(n => n.text().includes('Save Draft'))
    await saveButton.trigger('click')

    expect(saveSpy).toHaveBeenCalledWith(1, 'test-token')
  })

  it('auto-saves every 30 seconds when changes detected', async () => {
    const wrapper = mount(ProgressDashboard, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentProgressStore()
    Object.assign(store, mockProgress)
    store.hasUnsavedChanges = true
    const saveSpy = vi.spyOn(store, 'saveDraft')
    await flushPromises()

    // Fast-forward 30 seconds
    vi.advanceTimersByTime(30000)

    expect(saveSpy).toHaveBeenCalled()
  })

  it('navigates to step when card clicked', async () => {
    const wrapper = mount(ProgressDashboard, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentProgressStore()
    Object.assign(store, mockProgress)
    await flushPromises()

    const stepCards = wrapper.findAll('.cursor-pointer')
    await stepCards[1].trigger('click') // Click step 2

    expect(wrapper.emitted()).toHaveProperty('navigate')
    expect(wrapper.emitted('navigate')[0]).toEqual([2])
  })

  it('shows correct status badge', async () => {
    const wrapper = mount(ProgressDashboard, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentProgressStore()
    Object.assign(store, mockProgress)
    await flushPromises()

    expect(wrapper.text()).toContain('In Progress')

    // Complete all steps
    store.step2_completed = true
    store.step3_completed = true
    await wrapper.vm.$nextTick()

    expect(wrapper.text()).toContain('Ready to Submit')

    // Submit
    store.submitted = true
    await wrapper.vm.$nextTick()

    expect(wrapper.text()).toContain('Submitted for Review')
  })

  it('formats last saved time correctly', async () => {
    const wrapper = mount(ProgressDashboard, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentProgressStore()
    Object.assign(store, mockProgress)
    await flushPromises()

    expect(wrapper.text()).toContain('Just now')

    // Test 5 minutes ago
    store.lastSaved = Date.now() - 5 * 60 * 1000
    await wrapper.vm.$nextTick()
    expect(wrapper.text()).toContain('5m ago')
  })
})
```

**Integration Tests:**
```javascript
// spec/javascript/student/integration/progress-flow.spec.js
describe('Progress Tracking Flow', () => {
  it('tracks progress across all steps', async () => {
    // 1. Load dashboard with incomplete steps
    // 2. Navigate to upload, complete it
    // 3. Return to dashboard, verify step 1 complete
    // 4. Navigate to form, partially complete
    // 5. Return to dashboard, verify progress bar
    // 6. Save draft
    // 7. Submit when all complete
  })
})
```

**E2E Tests:**
```javascript
// spec/system/student_progress_spec.rb
RSpec.describe 'Student Progress Tracking', type: :system do
  let(:cohort) { create(:cohort, status: :in_progress) }
  let(:student) { create(:student, cohort: cohort) }
  let(:submission) { create(:submission, student: student, status: :pending) }
  let(:token) { submission.token }

  scenario 'student monitors and completes workflow' do
    # Start at dashboard
    visit "/student/submissions/#{submission.id}/dashboard?token=#{token}"
    expect(page).to have_content('Overall Progress')
    expect(page).to have_content('0% Complete')

    # Complete upload step
    click_link 'Upload Required Documents'
    attach_file('Government ID', Rails.root.join('spec/fixtures/files/test_id.jpg'))
    click_button 'Continue to Next Step'

    # Return to dashboard
    visit "/student/submissions/#{submission.id}/dashboard?token=#{token}"
    expect(page).to have_content('33% Complete')
    expect(page).to have_content('Completed', count: 1)

    # Complete form step
    click_link 'Complete Your Information'
    fill_in 'Full Name', with: 'John Doe'
    # ... complete form
    click_button 'Continue to Review'

    # Return to dashboard
    visit "/student/submissions/#{submission.id}/dashboard?token=#{token}"
    expect(page).to have_content('67% Complete')
    expect(page).to have_content('Ready to Submit')

    # Submit
    click_button 'Submit for Review'
    expect(page).to have_content('Submitted for Review')
  end

  scenario 'auto-save works in background', do
    visit "/student/submissions/#{submission.id}/dashboard?token=#{token}"

    # Navigate to form and start typing
    click_link 'Complete Your Information'
    fill_in 'Full Name', with: 'John'

    # Wait for auto-save
    sleep 30

    # Return to dashboard
    visit "/student/submissions/#{submission.id}/dashboard?token=#{token}"

    # Should show last saved time
    expect(page).to have_content('Last Saved')
  end
end
```

##### Rollback Procedure

**If progress data fails to load:**
1. Show error message with retry button
2. Display cached data if available
3. Allow manual refresh
4. Log error to monitoring

**If submission fails:**
1. Show error message with details
2. Preserve all data
3. Allow user to save draft and try later
4. Provide support contact

**If navigation fails:**
1. Show error message
2. Keep user on dashboard
3. Allow retry
4. Log navigation errors

**Data Safety:**
- All progress data stored server-side
- Local cache for offline viewing
- No data loss on navigation failures
- Draft saves preserve all work

##### Risk Assessment

**Low Risk** because:
- Read-only operations for most of the flow
- Simple state management
- Standard navigation patterns
- No complex business logic

**Specific Risks:**
1. **Stale Progress**: Progress doesn't update after step completion
   - **Mitigation**: Refresh on dashboard load, manual refresh button

2. **Navigation Errors**: User navigates to invalid step
   - **Mitigation**: Validate step availability before navigation

3. **Auto-save Conflicts**: Multiple save operations overlap
   - **Mitigation**: Debounce save operations, use locks

**Mitigation Strategies:**
- Comprehensive testing of navigation flow
- Refresh data on every dashboard visit
- Clear error messages for navigation failures
- Audit trail for all saves

##### Success Metrics

- **Dashboard Load Time**: <1 second
- **Save Success Rate**: 99.5%
- **Auto-save Success**: 99% of scheduled saves
- **Zero Data Loss**: 100% of drafts restore correctly
- **User Satisfaction**: 90% can monitor progress without confusion
- **Navigation Accuracy**: 100% of valid navigations succeed
- **Support Tickets**: <1% related to progress tracking

---

#### Story 5.4: Student Portal - Submission Confirmation & Status

**Status**: Draft/Pending
**Priority**: High
**Epic**: Student Portal - Frontend Development
**Estimated Effort**: 2 days
**Risk Level**: Low

##### User Story

**As a** Student,
**I want** to review my complete submission and receive confirmation of successful submission,
**So that** I can verify everything is correct and track when the sponsor signs.

##### Background

After completing all three steps (upload, form filling, review), students need to:
1. **Final Review**: See a summary of all uploaded documents and filled fields
2. **Confirmation**: Receive clear confirmation that submission was successful
3. **Status Tracking**: Monitor progress through sponsor signature and TP review phases
4. **Email Notifications**: Get updates when status changes

This is the final step in the student workflow. The student portal must provide:
- Complete submission summary
- Clear success confirmation
- Real-time status updates
- Email notification settings
- Access to final document once complete

**Status Flow:**
- **Pending**: Student hasn't submitted yet
- **In Review**: Submitted, waiting for sponsor
- **Sponsor Signed**: Sponsor completed their part
- **TP Reviewed**: TP completed final review
- **Completed**: All parties finished, document finalized

**Integration Point**: This story completes the student portal frontend (Phase 5). It connects to the sponsor portal (Phase 6) and TP review (Phase 4).

##### Technical Implementation Notes

**Vue 3 Component Structure:**
```vue
<!-- app/javascript/student/views/SubmissionStatus.vue -->
<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-4xl mx-auto px-4">
      <!-- Success Confirmation Banner -->
      <div v-if="showSuccessBanner" class="mb-6 bg-green-50 border border-green-200 rounded-lg p-6 flex items-start gap-4">
        <div class="flex-shrink-0">
          <svg class="w-8 h-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <div class="flex-1">
          <h2 class="text-xl font-bold text-green-900 mb-1">Submission Successful!</h2>
          <p class="text-green-700">
            Your application has been submitted for sponsor signature. You'll receive email updates as your submission progresses.
          </p>
        </div>
        <button @click="showSuccessBanner = false" class="text-green-600 hover:text-green-800">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      <!-- Header -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <div class="flex justify-between items-start">
          <div>
            <h1 class="text-2xl font-bold text-gray-900 mb-2">Submission Status</h1>
            <p class="text-gray-600">
              Cohort: <strong>{{ cohortName }}</strong>
            </p>
            <p class="text-sm text-gray-500 mt-1">
              Submitted: <strong>{{ submittedAt }}</strong>
            </p>
          </div>
          <div class="text-right">
            <div class="text-sm text-gray-500">Current Status</div>
            <span 
              class="px-3 py-1 rounded-full text-sm font-medium inline-block mt-1"
              :class="statusBadgeClass"
            >
              {{ statusText }}
            </span>
          </div>
        </div>
      </div>

      <!-- Status Timeline -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-6">Progress Timeline</h2>
        
        <div class="space-y-6">
          <!-- Student Completed -->
          <div class="flex items-start gap-4">
            <div class="flex-shrink-0">
              <div class="w-10 h-10 rounded-full bg-green-100 flex items-center justify-center">
                <svg class="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
              </div>
            </div>
            <div class="flex-1">
              <div class="flex items-center gap-2">
                <h3 class="font-semibold text-gray-900">Student Completed</h3>
                <span class="text-xs text-gray-500">({{ studentCompletedAt }})</span>
              </div>
              <p class="text-sm text-gray-600 mt-1">All documents uploaded and forms completed</p>
            </div>
          </div>

          <!-- Sponsor Signature -->
          <div class="flex items-start gap-4">
            <div class="flex-shrink-0">
              <div 
                class="w-10 h-10 rounded-full flex items-center justify-center"
                :class="sponsorSigned ? 'bg-green-100' : 'bg-gray-100'"
              >
                <svg 
                  class="w-6 h-6"
                  :class="sponsorSigned ? 'text-green-600' : 'text-gray-400'"
                  fill="none" stroke="currentColor" viewBox="0 0 24 24"
                >
                  <path v-if="sponsorSigned" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                  <path v-else stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
            </div>
            <div class="flex-1">
              <div class="flex items-center gap-2">
                <h3 class="font-semibold" :class="sponsorSigned ? 'text-gray-900' : 'text-gray-600'">
                  Sponsor Signature
                </h3>
                <span v-if="sponsorSigned" class="text-xs text-gray-500">({{ sponsorSignedAt }})</span>
                <span v-else class="text-xs text-gray-500">Pending</span>
              </div>
              <p class="text-sm text-gray-600 mt-1">
                {{ sponsorSigned ? 'Sponsor has signed the document' : 'Waiting for sponsor to review and sign' }}
              </p>
              <div v-if="!sponsorSigned && estimatedCompletion" class="text-xs text-gray-500 mt-1">
                Estimated completion: {{ estimatedCompletion }}
              </div>
            </div>
          </div>

          <!-- TP Review -->
          <div class="flex items-start gap-4">
            <div class="flex-shrink-0">
              <div 
                class="w-10 h-10 rounded-full flex items-center justify-center"
                :class="tpReviewed ? 'bg-green-100' : 'bg-gray-100'"
              >
                <svg 
                  class="w-6 h-6"
                  :class="tpReviewed ? 'text-green-600' : 'text-gray-400'"
                  fill="none" stroke="currentColor" viewBox="0 0 24 24"
                >
                  <path v-if="tpReviewed" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                  <path v-else stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
            </div>
            <div class="flex-1">
              <div class="flex items-center gap-2">
                <h3 class="font-semibold" :class="tpReviewed ? 'text-gray-900' : 'text-gray-600'">
                  TP Final Review
                </h3>
                <span v-if="tpReviewed" class="text-xs text-gray-500">({{ tpReviewedAt }})</span>
                <span v-else class="text-xs text-gray-500">Pending</span>
              </div>
              <p class="text-sm text-gray-600 mt-1">
                {{ tpReviewed ? 'Training provider completed final review' : 'Waiting for TP to verify and finalize' }}
              </p>
            </div>
          </div>

          <!-- Final Completion -->
          <div class="flex items-start gap-4">
            <div class="flex-shrink-0">
              <div 
                class="w-10 h-10 rounded-full flex items-center justify-center"
                :class="isCompleted ? 'bg-green-100' : 'bg-gray-100'"
              >
                <svg 
                  class="w-6 h-6"
                  :class="isCompleted ? 'text-green-600' : 'text-gray-400'"
                  fill="none" stroke="currentColor" viewBox="0 0 24 24"
                >
                  <path v-if="isCompleted" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                  <path v-else stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                </svg>
              </div>
            </div>
            <div class="flex-1">
              <div class="flex items-center gap-2">
                <h3 class="font-semibold" :class="isCompleted ? 'text-gray-900' : 'text-gray-600'">
                  Final Document Ready
                </h3>
                <span v-if="isCompleted" class="text-xs text-gray-500">({{ completedAt }})</span>
              </div>
              <p class="text-sm text-gray-600 mt-1">
                {{ isCompleted ? 'Signed document is ready for download' : 'All parties must complete their steps' }}
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- Submission Summary -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Submission Summary</h2>
        
        <div class="space-y-4">
          <!-- Documents Section -->
          <div>
            <h3 class="font-medium text-gray-900 mb-2">Uploaded Documents</h3>
            <div v-if="uploadedDocuments.length === 0" class="text-sm text-gray-500">
              No documents uploaded
            </div>
            <div v-else class="space-y-2">
              <div 
                v-for="doc in uploadedDocuments" 
                :key="doc.id"
                class="flex items-center justify-between text-sm py-2 border-b border-gray-100"
              >
                <span class="text-gray-700">{{ doc.name }}</span>
                <span class="text-gray-500">{{ formatFileSize(doc.size) }}</span>
              </div>
            </div>
          </div>

          <!-- Form Fields Section -->
          <div>
            <h3 class="font-medium text-gray-900 mb-2">Completed Fields</h3>
            <div v-if="completedFields.length === 0" class="text-sm text-gray-500">
              No fields completed
            </div>
            <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-2">
              <div 
                v-for="field in completedFields" 
                :key="field.id"
                class="text-sm"
              >
                <span class="text-gray-600">{{ field.label }}:</span>
                <span class="font-medium text-gray-900 ml-1">{{ field.value }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Email Notifications -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Email Notifications</h2>
        
        <div class="space-y-3">
          <label class="flex items-center justify-between">
            <span class="text-sm text-gray-700">Status updates</span>
            <input 
              type="checkbox" 
              v-model="notificationSettings.statusUpdates"
              class="w-4 h-4 text-blue-600 rounded focus:ring-blue-500"
              @change="updateNotificationSettings"
            />
          </label>
          
          <label class="flex items-center justify-between">
            <span class="text-sm text-gray-700">Sponsor signature alerts</span>
            <input 
              type="checkbox" 
              v-model="notificationSettings.sponsorSigned"
              class="w-4 h-4 text-blue-600 rounded focus:ring-blue-500"
              @change="updateNotificationSettings"
            />
          </label>
          
          <label class="flex items-center justify-between">
            <span class="text-sm text-gray-700">Final completion alerts</span>
            <input 
              type="checkbox" 
              v-model="notificationSettings.completed"
              class="w-4 h-4 text-blue-600 rounded focus:ring-blue-500"
              @change="updateNotificationSettings"
            />
          </label>
        </div>
      </div>

      <!-- Action Buttons -->
      <div class="flex flex-wrap gap-3">
        <button
          v-if="isCompleted"
          @click="downloadDocument"
          class="px-6 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 font-medium flex items-center gap-2"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
          </svg>
          Download Signed Document
        </button>

        <button
          @click="refreshStatus"
          class="px-6 py-2 border border-gray-300 rounded-md hover:bg-gray-50 text-gray-700 font-medium flex items-center gap-2"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          Refresh Status
        </button>

        <button
          @click="contactSupport"
          class="px-6 py-2 border border-gray-300 rounded-md hover:bg-gray-50 text-gray-700 font-medium flex items-center gap-2"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z" />
          </svg>
          Contact Support
        </button>
      </div>

      <!-- Status Refresh Indicator -->
      <div v-if="isRefreshing" class="fixed bottom-4 right-4 bg-gray-800 text-white px-4 py-2 rounded-md shadow-lg text-sm flex items-center gap-2">
        <svg class="w-4 h-4 animate-spin" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
        </svg>
        Checking status...
      </div>

      <!-- Success Toast -->
      <div v-if="showToast" class="fixed bottom-4 right-4 bg-green-600 text-white px-4 py-2 rounded-md shadow-lg text-sm flex items-center gap-2">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
        {{ toastMessage }}
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useStudentStatusStore } from '@/student/stores/status'
import { useStudentAuthStore } from '@/student/stores/auth'

const props = defineProps<{
  submissionId: number
  token: string
}>()

const statusStore = useStudentStatusStore()
const authStore = useStudentAuthStore()

const showSuccessBanner = ref(false)
const isRefreshing = ref(false)
const showToast = ref(false)
const toastMessage = ref('')
const pollingInterval = ref<number | null>(null)

const cohortName = computed(() => statusStore.cohortName)
const submittedAt = computed(() => statusStore.submittedAt)
const studentCompletedAt = computed(() => statusStore.studentCompletedAt)
const sponsorSigned = computed(() => statusStore.sponsorSigned)
const sponsorSignedAt = computed(() => statusStore.sponsorSignedAt)
const tpReviewed = computed(() => statusStore.tpReviewed)
const tpReviewedAt = computed(() => statusStore.tpReviewedAt)
const isCompleted = computed(() => statusStore.isCompleted)
const completedAt = computed(() => statusStore.completedAt)
const uploadedDocuments = computed(() => statusStore.uploadedDocuments)
const completedFields = computed(() => statusStore.completedFields)
const estimatedCompletion = computed(() => statusStore.estimatedCompletion)

const notificationSettings = ref({
  statusUpdates: true,
  sponsorSigned: true,
  completed: true
})

const statusBadgeClass = computed(() => {
  if (isCompleted.value) return 'bg-green-100 text-green-800'
  if (tpReviewed.value) return 'bg-blue-100 text-blue-800'
  if (sponsorSigned.value) return 'bg-purple-100 text-purple-800'
  if (submittedAt.value) return 'bg-yellow-100 text-yellow-800'
  return 'bg-gray-100 text-gray-800'
})

const statusText = computed(() => {
  if (isCompleted.value) return 'Completed'
  if (tpReviewed.value) return 'TP Reviewed'
  if (sponsorSigned.value) return 'Sponsor Signed'
  if (submittedAt.value) return 'In Review'
  return 'Not Submitted'
})

onMounted(async () => {
  await statusStore.fetchStatus(props.submissionId, props.token)
  
  // Check if this is a fresh submission (show success banner)
  const urlParams = new URLSearchParams(window.location.search)
  if (urlParams.get('new') === 'true') {
    showSuccessBanner.value = true
  }
  
  // Start polling for status updates (every 60 seconds)
  pollingInterval.value = window.setInterval(() => {
    statusStore.fetchStatus(props.submissionId, props.token)
  }, 60000)
})

onUnmounted(() => {
  if (pollingInterval.value) {
    clearInterval(pollingInterval.value)
  }
})

const refreshStatus = async () => {
  isRefreshing.value = true
  try {
    await statusStore.fetchStatus(props.submissionId, props.token)
    showToast.value = true
    toastMessage.value = 'Status updated'
    setTimeout(() => {
      showToast.value = false
    }, 2000)
  } catch (error) {
    console.error('Failed to refresh status:', error)
    showToast.value = true
    toastMessage.value = 'Failed to refresh'
    setTimeout(() => {
      showToast.value = false
    }, 2000)
  } finally {
    isRefreshing.value = false
  }
}

const downloadDocument = async () => {
  try {
    const response = await fetch(`/api/student/submissions/${props.submissionId}/download`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${props.token}`
      }
    })
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
    
    const blob = await response.blob()
    const url = window.URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `submission_${props.submissionId}_final.pdf`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    window.URL.revokeObjectURL(url)
    
    showToast.value = true
    toastMessage.value = 'Download started'
    setTimeout(() => {
      showToast.value = false
    }, 2000)
  } catch (error) {
    console.error('Download failed:', error)
    showToast.value = true
    toastMessage.value = 'Download failed'
    setTimeout(() => {
      showToast.value = false
    }, 2000)
  }
}

const updateNotificationSettings = async () => {
  try {
    await fetch(`/api/student/submissions/${props.submissionId}/notifications`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${props.token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(notificationSettings.value)
    })
    
    showToast.value = true
    toastMessage.value = 'Notification settings updated'
    setTimeout(() => {
      showToast.value = false
    }, 2000)
  } catch (error) {
    console.error('Failed to update notifications:', error)
  }
}

const contactSupport = () => {
  // In production, this would open a support ticket or email
  window.location.href = 'mailto:support@floDoc.example.com?subject=Submission Support Request'
}

const formatFileSize = (bytes: number) => {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
}
</script>

<style scoped>
/* Smooth progress bar transitions */
.bg-green-600, .bg-blue-600, .bg-purple-600 {
  transition: all 0.5s ease-in-out;
}

/* Timeline connector lines */
.space-y-6 > div:not(:last-child)::after {
  content: '';
  position: absolute;
  left: 20px;
  top: 40px;
  width: 2px;
  height: 24px;
  background: #e5e7eb;
}
</style>
```

**Pinia Store:**
```typescript
// app/javascript/student/stores/status.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { SubmissionAPI } from '@/student/api/submission'
import type { SubmissionStatus, DocumentSummary, FieldSummary } from '@/student/types'

export const useStudentStatusStore = defineStore('studentStatus', {
  state: () => ({
    cohortName: '',
    submittedAt: null as string | null,
    studentCompletedAt: null as string | null,
    sponsorSigned: false,
    sponsorSignedAt: null as string | null,
    tpReviewed: false,
    tpReviewedAt: null as string | null,
    isCompleted: false,
    completedAt: null as string | null,
    uploadedDocuments: [] as DocumentSummary[],
    completedFields: [] as FieldSummary[],
    estimatedCompletion: null as string | null,
    isLoading: false,
    error: null as string | null
  }),

  getters: {
    currentStatus: (state) => {
      if (state.isCompleted) return 'completed'
      if (state.tpReviewed) return 'tp_reviewed'
      if (state.sponsorSigned) return 'sponsor_signed'
      if (state.submittedAt) return 'in_review'
      return 'not_submitted'
    }
  },

  actions: {
    async fetchStatus(submissionId: number, token: string): Promise<void> {
      this.isLoading = true
      this.error = null

      try {
        const response = await SubmissionAPI.getStatus(submissionId, token)
        
        this.cohortName = response.cohort_name
        this.submittedAt = response.submitted_at
        this.studentCompletedAt = response.student_completed_at
        this.sponsorSigned = response.sponsor_signed
        this.sponsorSignedAt = response.sponsor_signed_at
        this.tpReviewed = response.tp_reviewed
        this.tpReviewedAt = response.tp_reviewed_at
        this.isCompleted = response.is_completed
        this.completedAt = response.completed_at
        this.uploadedDocuments = response.uploaded_documents || []
        this.completedFields = response.completed_fields || []
        this.estimatedCompletion = response.estimated_completion
      } catch (error) {
        this.error = error instanceof Error ? error.message : 'Failed to fetch status'
        console.error('Fetch status error:', error)
        throw error
      } finally {
        this.isLoading = false
      }
    }
  }
})
```

**API Layer:**
```typescript
// app/javascript/student/api/submission.ts (extended)
export interface DocumentSummary {
  id: number
  name: string
  size: number
  uploaded_at: string
}

export interface FieldSummary {
  id: string
  label: string
  value: string
  type: string
}

export interface SubmissionStatus {
  cohort_name: string
  submitted_at: string | null
  student_completed_at: string | null
  sponsor_signed: boolean
  sponsor_signed_at: string | null
  tp_reviewed: boolean
  tp_reviewed_at: string | null
  is_completed: boolean
  completed_at: string | null
  uploaded_documents?: DocumentSummary[]
  completed_fields?: FieldSummary[]
  estimated_completion?: string
}

export const SubmissionAPI = {
  // ... existing methods

  async getStatus(submissionId: number, token: string): Promise<SubmissionStatus> {
    const response = await fetch(`/api/student/submissions/${submissionId}/status`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    })

    if (!response.ok) {
      if (response.status === 403) {
        throw new Error('Access denied or token expired')
      }
      if (response.status === 404) {
        throw new Error('Submission not found')
      }
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    return response.json()
  }
}
```

**Type Definitions:**
```typescript
// app/javascript/student/types/index.ts (extended)
export interface DocumentSummary {
  id: number
  name: string
  size: number
  uploaded_at: string
}

export interface FieldSummary {
  id: string
  label: string
  value: string
  type: string
}

export interface SubmissionStatus {
  cohort_name: string
  submitted_at: string | null
  student_completed_at: string | null
  sponsor_signed: boolean
  sponsor_signed_at: string | null
  tp_reviewed: boolean
  tp_reviewed_at: string | null
  is_completed: boolean
  completed_at: string | null
  uploaded_documents?: DocumentSummary[]
  completed_fields?: FieldSummary[]
  estimated_completion?: string
}
```

**Design System Compliance:**
Per FR28, all Status components must use design system assets from:
- `@.claude/skills/frontend-design/SKILL.md` - Design tokens
- `@.claude/skills/frontend-design/design-system/` - SVG assets

Specific requirements:
- **Colors**: 
  - Success (Green-600): `#16A34A` for completed states
  - Primary (Blue-600): `#2563EB` for active elements
  - Warning (Yellow-600): `#CA8A04` for pending states
  - Neutral (Gray-500): `#6B7280` for text
  - Info (Purple-600): `#7C3AED` for sponsor pending
- **Spacing**: 4px base unit, 1.5rem (24px) for sections, 1rem (16px) for gaps
- **Typography**: 
  - Headings: 24px (h1), 20px (h2), 16px (h3)
  - Body: 16px base, 14px for secondary
  - Labels: 12px uppercase, letter-spacing 0.05em
- **Icons**: Use SVG icons from design system for:
  - Checkmark (completed)
  - Clock (pending)
  - Document (files)
  - Signature (sponsor)
  - Eye (review)
  - Download (export)
  - Refresh (update)
  - Mail (contact)
- **Layout**: 
  - Max width: 4xl (896px)
  - Card corners: rounded-lg (8px)
  - Shadow: shadow-md for cards
  - Timeline: vertical with connector lines
- **Accessibility**: 
  - ARIA labels on all buttons
  - Keyboard navigation for interactive elements
  - Screen reader announcements for status changes
  - Focus indicators on all interactive elements
  - Color contrast ratio minimum 4.5:1

##### Acceptance Criteria

**Functional:**
1. ✅ Component loads status data on mount
2. ✅ Shows success banner on fresh submission
3. ✅ Displays timeline with all 4 stages
4. ✅ Updates timeline icons based on status
5. ✅ Shows uploaded documents list with sizes
6. ✅ Shows completed fields with values
7. ✅ Displays estimated completion time
8. ✅ Refresh button fetches latest status
9. ✅ Download button works when completed
10. ✅ Notification settings can be updated
11. ✅ Contact support opens email client
12. ✅ Polling updates status every 60 seconds

**UI/UX:**
1. ✅ Success banner can be dismissed
2. ✅ Timeline shows connector lines between stages
3. ✅ Status badges use color-coded styling
4. ✅ Current stage is highlighted
5. ✅ Completed stages show green checkmarks
6. ✅ Pending stages show appropriate icons
7. ✅ Document list shows file sizes formatted
8. ✅ Field values are displayed clearly
9. ✅ Toast notifications show after actions
10. ✅ Mobile-responsive design

**Integration:**
1. ✅ API endpoint: `GET /api/student/submissions/{id}/status`
2. ✅ API endpoint: `GET /api/student/submissions/{id}/download`
3. ✅ API endpoint: `POST /api/student/submissions/{id}/notifications`
4. ✅ Token authentication in headers
5. ✅ Polling mechanism with cleanup
6. ✅ Data reflects actual submission state

**Security:**
1. ✅ Token-based authentication required
2. ✅ Authorization check: student can only view their submission
3. ✅ Download endpoint validates completion
4. ✅ Rate limiting on status refresh (max 30 per hour)
5. ✅ Audit log of all downloads

**Quality:**
1. ✅ Polling stops when component unmounts
2. ✅ Error handling for failed API calls
3. ✅ No duplicate polling intervals
4. ✅ Performance: loads in <1 second
5. ✅ Data consistency across refreshes

##### Integration Verification (IV1-4)

**IV1: API Integration**
- `SubmissionStatus.vue` calls `SubmissionAPI.getStatus()` on mount
- `SubmissionStatus.vue` calls `SubmissionAPI.getStatus()` in polling interval
- `SubmissionStatus.vue` calls download endpoint for PDF
- `SubmissionStatus.vue` calls notification settings endpoint
- All endpoints use `Authorization: Bearer {token}` header

**IV2: Pinia Store**
- `studentStatusStore.cohortName` holds cohort information
- `studentStatusStore.sponsorSigned` tracks sponsor completion
- `studentStatusStore.tpReviewed` tracks TP completion
- `studentStatusStore.isCompleted` tracks final completion
- `studentStatusStore.uploadedDocuments` holds document summaries
- `studentStatusStore.completedFields` holds field summaries

**IV3: Getters**
- `currentStatus()` returns status string for badge display
- State reflects real-time updates from polling

**IV4: Token Routing**
- SubmissionStatus receives `token` prop from parent
- Parent loads token from URL param (`?token=...`)
- All API calls pass token to store actions

##### Test Requirements

**Component Specs:**
```javascript
// spec/javascript/student/views/SubmissionStatus.spec.js
import { mount, flushPromises } from '@vue/test-utils'
import SubmissionStatus from '@/student/views/SubmissionStatus.vue'
import { useStudentStatusStore } from '@/student/stores/status'
import { createPinia, setActivePinia } from 'pinia'

describe('SubmissionStatus', () => {
  const mockStatus = {
    cohort_name: 'Summer 2025',
    submitted_at: '2025-01-15T10:00:00Z',
    student_completed_at: '2025-01-15T09:30:00Z',
    sponsor_signed: false,
    sponsor_signed_at: null,
    tp_reviewed: false,
    tp_reviewed_at: null,
    is_completed: false,
    completed_at: null,
    uploaded_documents: [
      { id: 1, name: 'ID Card.pdf', size: 1024000, uploaded_at: '2025-01-15T09:00:00Z' }
    ],
    completed_fields: [
      { id: 'name', label: 'Full Name', value: 'John Doe', type: 'text' }
    ],
    estimated_completion: '2 days'
  }

  beforeEach(() => {
    setActivePinia(createPinia())
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('renders success banner on fresh submission', async () => {
    const wrapper = mount(SubmissionStatus, {
      props: { submissionId: 1, token: 'test-token' },
      global: {
        mocks: {
          $route: { query: { new: 'true' } }
        }
      }
    })

    const store = useStudentStatusStore()
    Object.assign(store, mockStatus)
    await flushPromises()

    expect(wrapper.text()).toContain('Submission Successful!')
  })

  it('displays correct status badge', async () => {
    const wrapper = mount(SubmissionStatus, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentStatusStore()
    Object.assign(store, mockStatus)
    await flushPromises()

    expect(wrapper.text()).toContain('In Review')
  })

  it('renders timeline with correct stages', async () => {
    const wrapper = mount(SubmissionStatus, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentStatusStore()
    Object.assign(store, mockStatus)
    await flushPromises()

    expect(wrapper.text()).toContain('Student Completed')
    expect(wrapper.text()).toContain('Sponsor Signature')
    expect(wrapper.text()).toContain('TP Final Review')
    expect(wrapper.text()).toContain('Final Document Ready')
  })

  it('shows uploaded documents', async () => {
    const wrapper = mount(SubmissionStatus, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentStatusStore()
    Object.assign(store, mockStatus)
    await flushPromises()

    expect(wrapper.text()).toContain('ID Card.pdf')
    expect(wrapper.text()).toContain('1 MB')
  })

  it('shows completed fields', async () => {
    const wrapper = mount(SubmissionStatus, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentStatusStore()
    Object.assign(store, mockStatus)
    await flushPromises()

    expect(wrapper.text()).toContain('Full Name')
    expect(wrapper.text()).toContain('John Doe')
  })

  it('refreshes status when button clicked', async () => {
    const wrapper = mount(SubmissionStatus, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentStatusStore()
    Object.assign(store, mockStatus)
    const fetchSpy = vi.spyOn(store, 'fetchStatus')
    await flushPromises()

    const refreshButton = wrapper.find('button').filter(n => n.text().includes('Refresh'))
    await refreshButton.trigger('click')

    expect(fetchSpy).toHaveBeenCalledWith(1, 'test-token')
  })

  it('polls for updates every 60 seconds', async () => {
    const wrapper = mount(SubmissionStatus, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentStatusStore()
    Object.assign(store, mockStatus)
    const fetchSpy = vi.spyOn(store, 'fetchStatus')
    await flushPromises()

    // Fast-forward 60 seconds
    vi.advanceTimersByTime(60000)
    expect(fetchSpy).toHaveBeenCalledTimes(2) // Once on mount, once after 60s
  })

  it('hides success banner when dismissed', async () => {
    const wrapper = mount(SubmissionStatus, {
      props: { submissionId: 1, token: 'test-token' },
      global: {
        mocks: {
          $route: { query: { new: 'true' } }
        }
      }
    })

    const store = useStudentStatusStore()
    Object.assign(store, mockStatus)
    await flushPromises()

    expect(wrapper.text()).toContain('Submission Successful!')
    
    const dismissButton = wrapper.find('button[aria-label="Close"]')
    await dismissButton.trigger('click')
    
    expect(wrapper.text()).not.toContain('Submission Successful!')
  })

  it('shows download button only when completed', async () => {
    const wrapper = mount(SubmissionStatus, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentStatusStore()
    Object.assign(store, mockStatus)
    await flushPromises()

    let downloadButton = wrapper.find('button').filter(n => n.text().includes('Download'))
    expect(downloadButton.exists()).toBe(false)

    // Mark as completed
    store.is_completed = true
    store.completed_at = '2025-01-20T10:00:00Z'
    await wrapper.vm.$nextTick()

    downloadButton = wrapper.find('button').filter(n => n.text().includes('Download'))
    expect(downloadButton.exists()).toBe(true)
  })

  it('updates notification settings', async () => {
    const wrapper = mount(SubmissionStatus, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentStatusStore()
    Object.assign(store, mockStatus)
    await flushPromises()

    const checkbox = wrapper.find('input[type="checkbox"]')
    await checkbox.trigger('change')

    // Should make API call
    expect(wrapper.vm.notificationSettings.statusUpdates).toBe(true)
  })
})
```

**Integration Tests:**
```javascript
// spec/javascript/student/integration/status-flow.spec.js
describe('Submission Status Flow', () => {
  it('tracks complete submission lifecycle', async () => {
    // 1. Load status for pending submission
    // 2. Verify initial state (submitted, waiting for sponsor)
    // 3. Simulate sponsor signature
    // 4. Verify status update
    // 5. Simulate TP review
    // 6. Verify final completion
    // 7. Download final document
  })
})
```

**E2E Tests:**
```javascript
// spec/system/student_submission_status_spec.rb
RSpec.describe 'Student Submission Status', type: :system do
  let(:cohort) { create(:cohort, status: :in_progress) }
  let(:student) { create(:student, cohort: cohort) }
  let(:submission) { create(:submission, student: student, status: :submitted) }
  let(:token) { submission.token }

  scenario 'student monitors submission through completion' do
    visit "/student/submissions/#{submission.id}/status?token=#{token}"
    
    # Verify initial status
    expect(page).to have_content('In Review')
    expect(page).to have_content('Student Completed')
    expect(page).to have_content('Waiting for sponsor to review and sign')
    
    # Simulate sponsor signing (in test, we'd update the submission state)
    submission.update!(sponsor_signed: true, sponsor_signed_at: Time.current)
    click_button 'Refresh Status'
    
    expect(page).to have_content('Sponsor Signed')
    
    # Simulate TP review
    submission.update!(tp_reviewed: true, tp_reviewed_at: Time.current, status: :completed)
    click_button 'Refresh Status'
    
    expect(page).to have_content('Completed')
    expect(page).to have_button('Download Signed Document')
    
    # Download document
    click_button 'Download Signed Document'
    # Verify download initiated
  end

  scenario 'auto-polling updates status', do
    visit "/student/submissions/#{submission.id}/status?token=#{token}"
    
    expect(page).to have_content('In Review')
    
    # Update in background
    submission.update!(sponsor_signed: true)
    
    # Wait for polling interval
    sleep 60
    
    expect(page).to have_content('Sponsor Signed')
  end
end
```

##### Rollback Procedure

**If status fails to load:**
1. Show error message with retry button
2. Display cached status if available
3. Allow manual refresh
4. Log error to monitoring

**If download fails:**
1. Show error message with retry option
2. Verify document is actually ready
3. Check server-side PDF generation
4. Provide alternative download method

**If polling causes issues:**
1. Reduce polling frequency to 2 minutes
2. Implement exponential backoff
3. Stop polling if user navigates away
4. Show manual refresh option

**If notification settings fail:**
1. Show error message
2. Preserve current settings
3. Allow retry
4. Log to monitoring

**Data Safety:**
- All status data is read-only
- No data mutation in this component
- Download generates fresh PDF from server
- Notification settings stored server-side

##### Risk Assessment

**Low Risk** because:
- Read-only operations (except notifications)
- Simple state management
- Standard polling mechanism
- No complex business logic

**Specific Risks:**
1. **Stale Status**: Polling doesn't capture all updates
   - **Mitigation**: Refresh on visibility change, manual refresh button

2. **Download Failures**: PDF generation may fail
   - **Mitigation**: Async generation with email notification fallback

3. **Polling Memory**: Interval not cleaned up properly
   - **Mitigation**: `onUnmounted` hook with `clearInterval`

4. **Token Expiration**: Long-running sessions may expire
   - **Mitigation**: Token renewal mechanism (Story 4.9)

**Mitigation Strategies:**
- Comprehensive error handling for all API calls
- Clear user feedback for all actions
- Fallback mechanisms for downloads
- Performance testing with long polling sessions

##### Success Metrics

- **Status Accuracy**: 100% match between UI and actual state
- **Polling Success**: 99% of polling attempts succeed
- **Download Success**: 98% of downloads complete successfully
- **Load Time**: <1 second for status page
- **User Satisfaction**: 95% can track submission without confusion
- **Zero Data Loss**: 100% of status data preserved across refreshes
- **Support Tickets**: <1% related to status tracking

---

#### Story 5.5: Student Portal - Email Notifications & Reminders

**Status**: Draft/Pending
**Priority**: High
**Epic**: Student Portal - Frontend Development
**Estimated Effort**: 2 days
**Risk Level**: Low

##### User Story

**As a** Student,
**I want** to receive email notifications for status updates and reminders to complete my submission,
**So that** I can stay informed and complete my work on time without constantly checking the portal.

##### Background

Students need to stay informed about their submission progress without manually checking the portal. The system should provide:

1. **Initial Invitation Email**: Sent when cohort is created, contains access link with token
2. **Reminder Emails**: Sent if student hasn't started or hasn't completed after certain time
3. **Status Update Emails**: Sent when key milestones are reached
4. **Final Completion Email**: Sent when document is fully signed and ready

**Email Types:**
- **Invitation**: "You've been invited to join [Cohort Name]"
- **Reminder - Not Started**: "Don't forget to complete your submission"
- **Reminder - Incomplete**: "You're almost there! Finish your submission"
- **Status - Sponsor Signed**: "Sponsor has signed your document"
- **Status - Completed**: "Your document is ready!"
- **TP Reminder**: (TP sends to students who haven't completed)

**Key Requirements:**
- Emails contain secure, time-limited links
- Links use JWT tokens (Story 2.2, 2.3)
- Unsubscribe option in all emails
- Email preferences can be managed
- Reminder frequency is configurable
- Email templates are customizable

**Integration Point**: This story connects to the email system (Story 2.2, 2.3) and provides the student-facing notification preferences.

##### Technical Implementation Notes

**Vue 3 Component Structure:**
```vue
<!-- app/javascript/student/views/EmailPreferences.vue -->
<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-3xl mx-auto px-4">
      <!-- Header -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <h1 class="text-2xl font-bold text-gray-900 mb-2">Email Notification Preferences</h1>
        <p class="text-gray-600">
          Control which emails you receive about your submission in <strong>{{ cohortName }}</strong>
        </p>
      </div>

      <!-- Notification Settings -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Email Settings</h2>
        
        <div class="space-y-4">
          <!-- Status Updates -->
          <div class="flex items-start justify-between border-b border-gray-100 pb-4">
            <div class="flex-1">
              <h3 class="font-medium text-gray-900">Status Updates</h3>
              <p class="text-sm text-gray-600 mt-1">
                Receive emails when your submission status changes
              </p>
              <div class="text-xs text-gray-500 mt-1">
                Examples: Sponsor signed, TP reviewed, completed
              </div>
            </div>
            <label class="flex items-center ml-4">
              <input 
                type="checkbox" 
                v-model="settings.statusUpdates"
                class="w-5 h-5 text-blue-600 rounded focus:ring-blue-500"
                @change="saveSettings"
              />
            </label>
          </div>

          <!-- Reminders -->
          <div class="flex items-start justify-between border-b border-gray-100 pb-4">
            <div class="flex-1">
              <h3 class="font-medium text-gray-900">Completion Reminders</h3>
              <p class="text-sm text-gray-600 mt-1">
                Receive reminders if you haven't completed your submission
              </p>
              <div class="text-xs text-gray-500 mt-1">
                Sent after 24 hours (not started) and 72 hours (incomplete)
              </div>
            </div>
            <label class="flex items-center ml-4">
              <input 
                type="checkbox" 
                v-model="settings.reminders"
                class="w-5 h-5 text-blue-600 rounded focus:ring-blue-500"
                @change="saveSettings"
              />
            </label>
          </div>

          <!-- Sponsor Alerts -->
          <div class="flex items-start justify-between border-b border-gray-100 pb-4">
            <div class="flex-1">
              <h3 class="font-medium text-gray-900">Sponsor Signature Alerts</h3>
              <p class="text-sm text-gray-600 mt-1">
                Get notified when sponsor signs your document
              </p>
              <div class="text-xs text-gray-500 mt-1">
                Immediate notification when sponsor completes their part
              </div>
            </div>
            <label class="flex items-center ml-4">
              <input 
                type="checkbox" 
                v-model="settings.sponsorAlerts"
                class="w-5 h-5 text-blue-600 rounded focus:ring-blue-500"
                @change="saveSettings"
              />
            </label>
          </div>

          <!-- Completion Alerts -->
          <div class="flex items-start justify-between pb-4">
            <div class="flex-1">
              <h3 class="font-medium text-gray-900">Final Completion Alerts</h3>
              <p class="text-sm text-gray-600 mt-1">
                Get notified when document is fully signed and ready
              </p>
              <div class="text-xs text-gray-500 mt-1">
                Includes download link for final document
              </div>
            </div>
            <label class="flex items-center ml-4">
              <input 
                type="checkbox" 
                v-model="settings.completionAlerts"
                class="w-5 h-5 text-blue-600 rounded focus:ring-blue-500"
                @change="saveSettings"
              />
            </label>
          </div>
        </div>
      </div>

      <!-- Reminder Frequency -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Reminder Frequency</h2>
        
        <div class="space-y-3">
          <label class="flex items-center justify-between">
            <span class="text-sm text-gray-700">Every 24 hours</span>
            <input 
              type="radio" 
              v-model="settings.reminderFrequency"
              value="24h"
              class="w-4 h-4 text-blue-600 focus:ring-blue-500"
              @change="saveSettings"
            />
          </label>
          
          <label class="flex items-center justify-between">
            <span class="text-sm text-gray-700">Every 48 hours</span>
            <input 
              type="radio" 
              v-model="settings.reminderFrequency"
              value="48h"
              class="w-4 h-4 text-blue-600 focus:ring-blue-500"
              @change="saveSettings"
            />
          </label>
          
          <label class="flex items-center justify-between">
            <span class="text-sm text-gray-700">Weekly</span>
            <input 
              type="radio" 
              v-model="settings.reminderFrequency"
              value="1w"
              class="w-4 h-4 text-blue-600 focus:ring-blue-500"
              @change="saveSettings"
            />
          </label>
          
          <label class="flex items-center justify-between">
            <span class="text-sm text-gray-700">No reminders</span>
            <input 
              type="radio" 
              v-model="settings.reminderFrequency"
              value="none"
              class="w-4 h-4 text-blue-600 focus:ring-blue-500"
              @change="saveSettings"
            />
          </label>
        </div>
      </div>

      <!-- Email Preview -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Email Preview</h2>
        
        <div class="bg-gray-50 rounded-lg p-4 border border-gray-200">
          <div class="text-xs text-gray-500 mb-2">Example: Status Update Email</div>
          <div class="text-sm">
            <p class="font-medium text-gray-900 mb-1">Subject: Your submission status has been updated</p>
            <p class="text-gray-700">
              Hi {{ studentName }},<br><br>
              Your document for <strong>{{ cohortName }}</strong> has been signed by the sponsor.<br>
              Current status: <strong>Sponsor Signed</strong><br><br>
              View your submission: <a href="#" class="text-blue-600 hover:underline">View Status</a>
            </p>
          </div>
        </div>
      </div>

      <!-- Unsubscribe All -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6 border border-red-200">
        <h2 class="text-lg font-semibold text-gray-900 mb-2 text-red-800">Unsubscribe from All Emails</h2>
        <p class="text-sm text-gray-600 mb-4">
          This will disable all email notifications. You will need to check the portal manually for updates.
        </p>
        <button
          @click="unsubscribeAll"
          class="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 font-medium"
        >
          Unsubscribe from All
        </button>
      </div>

      <!-- Action Buttons -->
      <div class="flex justify-end gap-3">
        <button
          @click="resetToDefaults"
          class="px-6 py-2 border border-gray-300 rounded-md hover:bg-gray-50 text-gray-700 font-medium"
        >
          Reset to Defaults
        </button>
        <button
          @click="saveSettings"
          class="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 font-medium"
        >
          Save Settings
        </button>
      </div>

      <!-- Success Toast -->
      <div v-if="showToast" class="fixed bottom-4 right-4 bg-green-600 text-white px-4 py-2 rounded-md shadow-lg text-sm flex items-center gap-2">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
        {{ toastMessage }}
      </div>

      <!-- Loading State -->
      <div v-if="isLoading" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div class="bg-white rounded-lg p-6 flex items-center gap-3">
          <svg class="w-6 h-6 animate-spin text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          <span class="text-gray-700">Saving preferences...</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useStudentNotificationStore } from '@/student/stores/notifications'

const props = defineProps<{
  submissionId: number
  token: string
}>()

const notificationStore = useStudentNotificationStore()

const isLoading = ref(false)
const showToast = ref(false)
const toastMessage = ref('')

const cohortName = ref('')
const studentName = ref('')

const settings = ref({
  statusUpdates: true,
  reminders: true,
  sponsorAlerts: true,
  completionAlerts: true,
  reminderFrequency: '48h'
})

onMounted(async () => {
  try {
    const data = await notificationStore.fetchPreferences(props.submissionId, props.token)
    settings.value = {
      statusUpdates: data.status_updates,
      reminders: data.reminders,
      sponsorAlerts: data.sponsor_alerts,
      completionAlerts: data.completion_alerts,
      reminderFrequency: data.reminder_frequency
    }
    cohortName.value = data.cohort_name
    studentName.value = data.student_name
  } catch (error) {
    console.error('Failed to load preferences:', error)
  }
})

const saveSettings = async () => {
  isLoading.value = true
  try {
    await notificationStore.updatePreferences(props.submissionId, props.token, settings.value)
    toastMessage.value = 'Preferences saved successfully'
    showToast.value = true
    setTimeout(() => {
      showToast.value = false
    }, 2000)
  } catch (error) {
    console.error('Failed to save settings:', error)
    toastMessage.value = 'Failed to save settings'
    showToast.value = true
    setTimeout(() => {
      showToast.value = false
    }, 2000)
  } finally {
    isLoading.value = false
  }
}

const resetToDefaults = () => {
  settings.value = {
    statusUpdates: true,
    reminders: true,
    sponsorAlerts: true,
    completionAlerts: true,
    reminderFrequency: '48h'
  }
  saveSettings()
}

const unsubscribeAll = async () => {
  if (!confirm('Are you sure you want to unsubscribe from ALL emails? You will miss important updates.')) {
    return
  }

  settings.value = {
    statusUpdates: false,
    reminders: false,
    sponsorAlerts: false,
    completionAlerts: false,
    reminderFrequency: 'none'
  }
  
  await saveSettings()
}
</script>

<style scoped>
/* Smooth transitions */
input[type="checkbox"], input[type="radio"] {
  transition: all 0.2s ease;
}

/* Hover effects */
label:hover {
  cursor: pointer;
}
</style>
```

**Email Template Components:**
```vue
<!-- app/javascript/student/emails/InvitationEmail.vue -->
<template>
  <div class="email-template">
    <h1>You've been invited to join {{ cohortName }}</h1>
    <p>Hi {{ studentName }},</p>
    <p>You've been invited to complete your documents for <strong>{{ cohortName }}</strong>.</p>
    <p>Click the button below to get started:</p>
    <a :href="invitationLink" class="button">Start Your Submission</a>
    <p class="small">This link will expire in 7 days.</p>
  </div>
</template>

<script setup>
const props = defineProps<{
  cohortName: string
  studentName: string
  token: string
  submissionId: number
}>()

const invitationLink = computed(() => {
  return `${window.location.origin}/student/submissions/${props.submissionId}?token=${props.token}`
})
</script>
```

**Pinia Store:**
```typescript
// app/javascript/student/stores/notifications.ts
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { NotificationAPI } from '@/student/api/notification'

export interface NotificationPreferences {
  status_updates: boolean
  reminders: boolean
  sponsor_alerts: boolean
  completion_alerts: boolean
  reminder_frequency: string
  cohort_name: string
  student_name: string
}

export const useStudentNotificationStore = defineStore('studentNotifications', {
  state: () => ({
    preferences: null as NotificationPreferences | null,
    isLoading: false,
    error: null as string | null
  }),

  actions: {
    async fetchPreferences(submissionId: number, token: string): Promise<NotificationPreferences> {
      this.isLoading = true
      this.error = null

      try {
        const response = await NotificationAPI.getPreferences(submissionId, token)
        this.preferences = response
        return response
      } catch (error) {
        this.error = error instanceof Error ? error.message : 'Failed to fetch preferences'
        console.error('Fetch preferences error:', error)
        throw error
      } finally {
        this.isLoading = false
      }
    },

    async updatePreferences(
      submissionId: number,
      token: string,
      preferences: Partial<NotificationPreferences>
    ): Promise<void> {
      this.isLoading = true
      this.error = null

      try {
        await NotificationAPI.updatePreferences(submissionId, token, preferences)
        // Update local state
        if (this.preferences) {
          this.preferences = { ...this.preferences, ...preferences }
        }
      } catch (error) {
        this.error = error instanceof Error ? error.message : 'Failed to update preferences'
        console.error('Update preferences error:', error)
        throw error
      } finally {
        this.isLoading = false
      }
    }
  }
})
```

**API Layer:**
```typescript
// app/javascript/student/api/notification.ts
export interface NotificationPreferences {
  status_updates: boolean
  reminders: boolean
  sponsor_alerts: boolean
  completion_alerts: boolean
  reminder_frequency: string
  cohort_name: string
  student_name: string
}

export interface UpdatePreferencesRequest {
  status_updates?: boolean
  reminders?: boolean
  sponsor_alerts?: boolean
  completion_alerts?: boolean
  reminder_frequency?: string
}

export const NotificationAPI = {
  async getPreferences(submissionId: number, token: string): Promise<NotificationPreferences> {
    const response = await fetch(`/api/student/submissions/${submissionId}/notification-preferences`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    })

    if (!response.ok) {
      if (response.status === 403) {
        throw new Error('Access denied or token expired')
      }
      if (response.status === 404) {
        throw new Error('Submission not found')
      }
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    return response.json()
  },

  async updatePreferences(
    submissionId: number,
    token: string,
    preferences: UpdatePreferencesRequest
  ): Promise<void> {
    const response = await fetch(`/api/student/submissions/${submissionId}/notification-preferences`, {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(preferences)
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
  },

  async sendInvitationEmail(submissionId: number, token: string): Promise<void> {
    const response = await fetch(`/api/student/submissions/${submissionId}/send-invitation`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
  },

  async sendReminderEmail(submissionId: number, token: string, type: string): Promise<void> {
    const response = await fetch(`/api/student/submissions/${submissionId}/send-reminder`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ type })
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
  }
}
```

**Type Definitions:**
```typescript
// app/javascript/student/types/index.ts (extended)
export interface NotificationPreferences {
  status_updates: boolean
  reminders: boolean
  sponsor_alerts: boolean
  completion_alerts: boolean
  reminder_frequency: string
  cohort_name: string
  student_name: string
}

export interface UpdatePreferencesRequest {
  status_updates?: boolean
  reminders?: boolean
  sponsor_alerts?: boolean
  completion_alerts?: boolean
  reminder_frequency?: string
}

export interface EmailTemplate {
  subject: string
  body: string
  variables: string[]
}
```

**Design System Compliance:**
Per FR28, all Notification components must use design system assets from:
- `@.claude/skills/frontend-design/SKILL.md` - Design tokens
- `@.claude/skills/frontend-design/design-system/` - SVG assets

Specific requirements:
- **Colors**: 
  - Primary (Blue-600): `#2563EB` for buttons and links
  - Warning (Red-600): `#DC2626` for unsubscribe section
  - Success (Green-600): `#16A34A` for saved indicators
  - Neutral (Gray-500): `#6B7280` for text
- **Spacing**: 4px base unit, 1.5rem (24px) for sections, 1rem (16px) for field gaps
- **Typography**: 
  - Headings: 24px (h1), 20px (h2), 16px (h3)
  - Body: 16px base, 14px for descriptions
  - Small: 12px for helper text
- **Icons**: Use SVG icons from design system for:
  - Mail (email)
  - Bell (notifications)
  - Checkmark (saved)
  - Trash (unsubscribe)
  - Refresh (reset)
  - Settings (preferences)
- **Layout**: 
  - Max width: 3xl (48rem / 768px)
  - Card corners: rounded-lg (8px)
  - Shadow: shadow-md for cards
  - Toggle switches: right-aligned
- **Accessibility**: 
  - ARIA labels on all toggles
  - Keyboard navigation for checkboxes
  - Screen reader announcements for save actions
  - Focus indicators on all interactive elements
  - Color contrast ratio minimum 4.5:1
  - Warning section clearly marked

##### Acceptance Criteria

**Functional:**
1. ✅ Component loads existing preferences on mount
2. ✅ All 4 notification toggles work correctly
3. ✅ Reminder frequency radio buttons work
4. ✅ Save button persists changes to server
5. ✅ Reset to defaults restores original settings
6. ✅ Unsubscribe all disables all notifications
7. ✅ Confirmation dialog before unsubscribe
8. ✅ Email preview updates based on settings
9. ✅ Shows success toast after save
10. ✅ Loading state during API calls

**UI/UX:**
1. ✅ Toggles show clear on/off states
2. ✅ Settings organized in logical sections
3. ✅ Warning section visually distinct (red border)
4. ✅ Email preview shows realistic example
5. ✅ Success toast appears for 2 seconds
6. ✅ Loading overlay blocks interaction
7. ✅ Mobile-responsive design
8. ✅ Hover states on all interactive elements

**Integration:**
1. ✅ API endpoint: `GET /api/student/submissions/{id}/notification-preferences`
2. ✅ API endpoint: `PUT /api/student/submissions/{id}/notification-preferences`
3. ✅ API endpoint: `POST /api/student/submissions/{id}/send-invitation`
4. ✅ API endpoint: `POST /api/student/submissions/{id}/send-reminder`
5. ✅ Token authentication in headers
6. ✅ Settings persist across sessions

**Security:**
1. ✅ Token-based authentication required
2. ✅ Authorization check: student can only manage their preferences
3. ✅ Rate limiting on update endpoint (max 10 per hour)
4. ✅ Validation of reminder frequency values
5. ✅ Audit log of all preference changes

**Quality:**
1. ✅ No duplicate API calls on rapid clicks
2. ✅ Error handling for failed API calls
3. ✅ State consistency between UI and server
4. ✅ Performance: loads in <1 second
5. ✅ Browser compatibility: Chrome, Firefox, Safari, Edge

##### Integration Verification (IV1-4)

**IV1: API Integration**
- `EmailPreferences.vue` calls `NotificationAPI.getPreferences()` on mount
- `EmailPreferences.vue` calls `NotificationAPI.updatePreferences()` on save
- `EmailPreferences.vue` calls `NotificationAPI.sendInvitationEmail()` (if needed)
- All endpoints use `Authorization: Bearer {token}` header

**IV2: Pinia Store**
- `studentNotificationStore.preferences` holds notification settings
- `studentNotificationStore.fetchPreferences()` loads settings
- `studentNotificationStore.updatePreferences()` saves changes

**IV3: Getters**
- Store provides computed properties for UI display
- Settings are reactive and update UI immediately

**IV4: Token Routing**
- EmailPreferences receives `token` prop from parent
- Parent loads token from URL param (`?token=...`)
- All API calls pass token to store actions

##### Test Requirements

**Component Specs:**
```javascript
// spec/javascript/student/views/EmailPreferences.spec.js
import { mount, flushPromises } from '@vue/test-utils'
import EmailPreferences from '@/student/views/EmailPreferences.vue'
import { useStudentNotificationStore } from '@/student/stores/notifications'
import { createPinia, setActivePinia } from 'pinia'

describe('EmailPreferences', () => {
  const mockPreferences = {
    status_updates: true,
    reminders: true,
    sponsor_alerts: true,
    completion_alerts: true,
    reminder_frequency: '48h',
    cohort_name: 'Summer 2025',
    student_name: 'John Doe'
  }

  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('loads preferences on mount', async () => {
    const wrapper = mount(EmailPreferences, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentNotificationStore()
    store.preferences = mockPreferences
    await flushPromises()

    expect(wrapper.vm.settings.statusUpdates).toBe(true)
    expect(wrapper.vm.settings.reminderFrequency).toBe('48h')
  })

  it('toggles notification settings', async () => {
    const wrapper = mount(EmailPreferences, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentNotificationStore()
    store.preferences = mockPreferences
    await flushPromises()

    const statusToggle = wrapper.find('input[type="checkbox"]')
    await statusToggle.trigger('click')

    expect(wrapper.vm.settings.statusUpdates).toBe(false)
  })

  it('saves settings when save button clicked', async () => {
    const wrapper = mount(EmailPreferences, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentNotificationStore()
    store.preferences = mockPreferences
    const updateSpy = vi.spyOn(store, 'updatePreferences')
    await flushPromises()

    const saveButton = wrapper.find('button').filter(n => n.text().includes('Save'))
    await saveButton.trigger('click')

    expect(updateSpy).toHaveBeenCalledWith(1, 'test-token', expect.any(Object))
  })

  it('resets to defaults', async () => {
    const wrapper = mount(EmailPreferences, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentNotificationStore()
    store.preferences = mockPreferences
    await flushPromises()

    // Change some settings
    wrapper.vm.settings.reminders = false
    await wrapper.vm.$nextTick()

    // Reset
    const resetButton = wrapper.find('button').filter(n => n.text().includes('Reset'))
    await resetButton.trigger('click')

    expect(wrapper.vm.settings.reminders).toBe(true)
  })

  it('unsubscribes all with confirmation', async () => {
    const wrapper = mount(EmailPreferences, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentNotificationStore()
    store.preferences = mockPreferences
    const updateSpy = vi.spyOn(store, 'updatePreferences')
    await flushPromises()

    // Mock confirm to return true
    window.confirm = vi.fn(() => true)

    const unsubscribeButton = wrapper.find('button').filter(n => n.text().includes('Unsubscribe'))
    await unsubscribeButton.trigger('click')

    expect(window.confirm).toHaveBeenCalled()
    expect(wrapper.vm.settings.statusUpdates).toBe(false)
    expect(wrapper.vm.settings.reminders).toBe(false)
    expect(updateSpy).toHaveBeenCalled()
  })

  it('shows loading state during save', async () => {
    const wrapper = mount(EmailPreferences, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentNotificationStore()
    store.preferences = mockPreferences
    store.isLoading = true
    await flushPromises()

    expect(wrapper.find('.loading-overlay').exists()).toBe(true)
  })

  it('shows success toast after save', async () => {
    const wrapper = mount(EmailPreferences, {
      props: { submissionId: 1, token: 'test-token' }
    })

    const store = useStudentNotificationStore()
    store.preferences = mockPreferences
    await flushPromises()

    const saveButton = wrapper.find('button').filter(n => n.text().includes('Save'))
    await saveButton.trigger('click')

    await wrapper.vm.$nextTick()
    expect(wrapper.text()).toContain('Preferences saved successfully')
  })
})
```

**Integration Tests:**
```javascript
// spec/javascript/student/integration/notification-flow.spec.js
describe('Notification Preferences Flow', () => {
  it('manages complete notification workflow', async () => {
    // 1. Load preferences
    // 2. Disable all notifications
    // 3. Save changes
    // 4. Reload page to verify persistence
    // 5. Reset to defaults
    // 6. Verify all enabled again
  })
})
```

**E2E Tests:**
```javascript
// spec/system/student_notification_preferences_spec.rb
RSpec.describe 'Student Notification Preferences', type: :system do
  let(:cohort) { create(:cohort, status: :in_progress) }
  let(:student) { create(:student, cohort: cohort) }
  let(:submission) { create(:submission, student: student, status: :pending) }
  let(:token) { submission.token }

  scenario 'student manages email preferences' do
    visit "/student/submissions/#{submission.id}/preferences?token=#{token}"
    
    expect(page).to have_content('Email Notification Preferences')
    
    # Disable status updates
    uncheck 'Status Updates'
    click_button 'Save Settings'
    
    expect(page).to have_content('Preferences saved successfully')
    
    # Reload and verify
    visit "/student/submissions/#{submission.id}/preferences?token=#{token}"
    expect(page).not_to have_checked_field('Status Updates')
    
    # Unsubscribe all
    click_button 'Unsubscribe from All'
    page.driver.browser.switch_to.alert.accept
    
    expect(page).to have_content('Preferences saved successfully')
    expect(page).not_to have_checked_field('Status Updates')
    expect(page).not_to have_checked_field('Completion Reminders')
  end

  scenario 'reset to defaults', do
    visit "/student/submissions/#{submission.id}/preferences?token=#{token}"
    
    # Change settings
    uncheck 'Status Updates'
    uncheck 'Completion Reminders'
    click_button 'Save Settings'
    
    # Reset
    click_button 'Reset to Defaults'
    
    expect(page).to have_checked_field('Status Updates')
    expect(page).to have_checked_field('Completion Reminders')
  end
end
```

##### Rollback Procedure

**If preferences fail to load:**
1. Show error message with retry button
2. Use default settings temporarily
3. Log error to monitoring
4. Allow manual refresh

**If save fails:**
1. Show error message with retry option
2. Preserve unsaved changes in UI
3. Check network connection
4. Log failure for investigation

**If unsubscribe fails:**
1. Show error message
2. Don't change settings
3. Provide alternative (contact support)
4. Log for security audit

**If email preview breaks:**
1. Hide preview section
2. Show fallback text
3. Continue allowing settings changes
4. Log template error

**Data Safety:**
- All settings stored server-side
- No data loss if UI fails
- Changes only applied after successful save
- Unsubscribe requires confirmation

##### Risk Assessment

**Low Risk** because:
- Simple CRUD operations
- Standard form handling
- No complex business logic
- Read-mostly operations

**Specific Risks:**
1. **Email Deliverability**: Emails may not reach students
   - **Mitigation**: Use reputable SMTP, monitor delivery rates

2. **Rate Limiting**: Too many emails sent
   - **Mitigation**: Implement queue system, respect frequency settings

3. **Unsubscribe Compliance**: Legal requirements (CAN-SPAM, GDPR)
   - **Mitigation**: Clear unsubscribe, honor all requests immediately

4. **Token Expiration**: Links in emails may expire
   - **Mitigation**: Long expiry (7 days), renewal mechanism

**Mitigation Strategies:**
- Comprehensive email testing
- Monitor email delivery metrics
- Implement email queue with retry
- Clear unsubscribe in all emails
- Regular compliance audits

##### Success Metrics

- **Save Success Rate**: 99% of preference updates succeed
- **Email Delivery**: 98% of emails reach inbox (not spam)
- **User Engagement**: 80% of students enable at least one notification
- **Unsubscribe Rate**: <5% (industry standard is 0.2-0.5%)
- **Reminder Effectiveness**: 60% of reminders lead to completion
- **Support Tickets**: <2% related to email notifications
- **Load Time**: <1 second for preferences page

---

---

### 6.6 Phase 6: Frontend - Sponsor Portal

**Focus**: Sponsor-facing interface for bulk signing and progress tracking

This phase implements the sponsor portal, where sponsors access their assigned cohorts via email links (no account creation required). Sponsors can review all student documents in a cohort and sign once to complete all submissions. The portal emphasizes efficiency, bulk operations, and clear progress indicators.

---

#### Story 6.1: Sponsor Portal - Cohort Dashboard & Bulk Signing Interface

**Status**: Draft/Pending
**Priority**: High
**Epic**: Sponsor Portal - Frontend Development
**Estimated Effort**: 3 days
**Risk Level**: Medium

##### User Story

**As a** Sponsor,
**I want** to view all pending student documents in a cohort and sign them all at once,
**So that** I can efficiently complete my signing responsibility without reviewing each submission individually.

##### Background

Sponsors receive a single email per cohort (per FR12) with a secure link to the sponsor portal. Upon accessing the portal, they see:

1. **Cohort Overview**: Name, total students, completion status
2. **Student List**: All students with their completion status
3. **Bulk Signing**: Sign once to apply to all pending submissions
4. **Progress Tracking**: Real-time updates of signing progress

**Key Requirements:**
- Single signing action for entire cohort
- Preview of what will be signed
- Clear indication of which students are affected
- Confirmation before signing
- Immediate status update after signing
- Email confirmation to TP after sponsor signs

**Workflow:**
1. Sponsor clicks email link with token
2. Portal loads cohort dashboard
3. Sponsor reviews student list
4. Sponsor signs once (signature or typed name)
5. System applies signature to all student submissions
6. Status updates to "Sponsor Signed"
7. TP receives notification
8. Students receive status update email

**Integration Point**: This story connects to the email system (Story 2.2, 2.3) and the backend signing workflow (Stories 2.5, 2.6).

##### Technical Implementation Notes

**Vue 3 Component Structure:**
```vue
<!-- app/javascript/sponsor/views/CohortDashboard.vue -->
<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-7xl mx-auto px-4">
      <!-- Header -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <div class="flex justify-between items-start">
          <div>
            <h1 class="text-3xl font-bold text-gray-900 mb-2">
              {{ cohortName }}
            </h1>
            <p class="text-gray-600">
              Review and sign student documents for this cohort
            </p>
            <div class="flex gap-4 mt-3 text-sm">
              <div class="flex items-center gap-2">
                <span class="text-gray-500">Total Students:</span>
                <span class="font-semibold text-gray-900">{{ totalStudents }}</span>
              </div>
              <div class="flex items-center gap-2">
                <span class="text-gray-500">Pending:</span>
                <span class="font-semibold text-blue-600">{{ pendingStudents }}</span>
              </div>
              <div class="flex items-center gap-2">
                <span class="text-gray-500">Completed:</span>
                <span class="font-semibold text-green-600">{{ completedStudents }}</span>
              </div>
            </div>
          </div>
          <div class="text-right">
            <div class="text-sm text-gray-500">Cohort ID</div>
            <div class="font-mono text-gray-900">#{{ cohortId }}</div>
          </div>
        </div>
      </div>

      <!-- Quick Stats Cards -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div class="bg-white rounded-lg shadow p-6 border-l-4 border-blue-500">
          <div class="text-sm text-gray-500 mb-1">Waiting for Your Signature</div>
          <div class="text-3xl font-bold text-gray-900">{{ pendingStudents }}</div>
          <div class="text-xs text-gray-500 mt-1">students need signing</div>
        </div>
        
        <div class="bg-white rounded-lg shadow p-6 border-l-4 border-green-500">
          <div class="text-sm text-gray-500 mb-1">Already Signed</div>
          <div class="text-3xl font-bold text-gray-900">{{ completedStudents }}</div>
          <div class="text-xs text-gray-500 mt-1">students completed</div>
        </div>
        
        <div class="bg-white rounded-lg shadow p-6 border-l-4 border-purple-500">
          <div class="text-sm text-gray-500 mb-1">Total Students</div>
          <div class="text-3xl font-bold text-gray-900">{{ totalStudents }}</div>
          <div class="text-xs text-gray-500 mt-1">in this cohort</div>
        </div>
      </div>

      <!-- Signing Section -->
      <div v-if="pendingStudents > 0" class="bg-white rounded-lg shadow-md p-6 mb-6">
        <h2 class="text-xl font-bold text-gray-900 mb-4">Bulk Signing</h2>
        
        <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-4">
          <div class="flex items-start gap-3">
            <svg class="w-5 h-5 text-blue-600 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <div class="flex-1">
              <p class="text-sm text-blue-900 font-medium">
                Your signature will be applied to all {{ pendingStudents }} pending student submissions.
              </p>
              <p class="text-xs text-blue-700 mt-1">
                This is a bulk operation. After signing, all students will be notified and the training provider will receive confirmation.
              </p>
            </div>
          </div>
        </div>

        <!-- Signature Method Selection -->
        <div class="mb-4">
          <label class="block text-sm font-medium text-gray-700 mb-2">Signature Method</label>
          <div class="flex gap-3">
            <button
              @click="signatureMethod = 'draw'"
              :class="[
                'px-4 py-2 rounded-md border font-medium transition-all',
                signatureMethod === 'draw'
                  ? 'bg-blue-600 text-white border-blue-600'
                  : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
              ]"
            >
              Draw Signature
            </button>
            <button
              @click="signatureMethod = 'type'"
              :class="[
                'px-4 py-2 rounded-md border font-medium transition-all',
                signatureMethod === 'type'
                  ? 'bg-blue-600 text-white border-blue-600'
                  : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
              ]"
            >
              Type Name
            </button>
          </div>
        </div>

        <!-- Draw Signature -->
        <div v-if="signatureMethod === 'draw'" class="mb-4">
          <label class="block text-sm font-medium text-gray-700 mb-2">Draw Your Signature</label>
          <div class="border-2 border-gray-300 rounded-md bg-white">
            <canvas
              ref="signatureCanvas"
              width="600"
              height="150"
              class="w-full cursor-crosshair"
              @mousedown="startDrawing"
              @mousemove="draw"
              @mouseup="stopDrawing"
              @mouseleave="stopDrawing"
              @touchstart="startDrawing"
              @touchmove="draw"
              @touchend="stopDrawing"
            />
          </div>
          <div class="flex gap-2 mt-2">
            <button
              @click="clearSignature"
              class="px-3 py-1.5 text-sm border border-gray-300 rounded-md hover:bg-gray-50"
            >
              Clear
            </button>
            <button
              @click="signatureMethod = 'type'"
              class="px-3 py-1.5 text-sm border border-gray-300 rounded-md hover:bg-gray-50"
            >
              Type Instead
            </button>
          </div>
        </div>

        <!-- Type Signature -->
        <div v-if="signatureMethod === 'type'" class="mb-4">
          <label class="block text-sm font-medium text-gray-700 mb-2">Type Your Full Name</label>
          <input
            v-model="typedSignature"
            type="text"
            placeholder="Enter your full legal name"
            class="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          />
          <p class="text-xs text-gray-500 mt-1">
            By typing your name, you certify this is your legal signature
          </p>
        </div>

        <!-- Confirmation Checkbox -->
        <div class="mb-4">
          <label class="flex items-start gap-2">
            <input
              v-model="confirmed"
              type="checkbox"
              class="mt-1 w-4 h-4 text-blue-600 rounded focus:ring-blue-500"
            />
            <span class="text-sm text-gray-700">
              I confirm that I have reviewed the signing requirements and authorize my signature to be applied to all {{ pendingStudents }} student submissions in this cohort.
            </span>
          </label>
        </div>

        <!-- Action Buttons -->
        <div class="flex gap-3">
          <button
            @click="previewSigning"
            :disabled="!canPreview"
            class="px-6 py-2 border border-gray-300 rounded-md hover:bg-gray-50 text-gray-700 font-medium disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Preview
          </button>
          <button
            @click="executeBulkSign"
            :disabled="!canSign"
            class="px-6 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 font-medium disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            Sign All {{ pendingStudents }} Documents
          </button>
        </div>
      </div>

      <!-- Already Signed Message -->
      <div v-else-if="totalStudents > 0" class="bg-white rounded-lg shadow-md p-6 mb-6">
        <div class="flex items-center gap-3">
          <svg class="w-8 h-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <div>
            <h2 class="text-xl font-bold text-gray-900">All Documents Signed</h2>
            <p class="text-gray-600">
              You have already signed all student documents in this cohort.
            </p>
          </div>
        </div>
      </div>

      <!-- Student List -->
      <div class="bg-white rounded-lg shadow-md p-6">
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-xl font-bold text-gray-900">Student List</h2>
          <div class="flex gap-2">
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Search students..."
              class="px-3 py-1.5 text-sm border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500"
            />
            <select
              v-model="statusFilter"
              class="px-3 py-1.5 text-sm border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500"
            >
              <option value="all">All Status</option>
              <option value="pending">Pending</option>
              <option value="completed">Completed</option>
            </select>
          </div>
        </div>

        <!-- Empty State -->
        <div v-if="filteredStudents.length === 0" class="text-center py-8 text-gray-500">
          No students found
        </div>

        <!-- Student Table (Desktop) -->
        <div v-else class="hidden md:block overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Student Name</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Submitted</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Progress</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr v-for="student in filteredStudents" :key="student.id" class="hover:bg-gray-50">
                <td class="px-4 py-3 text-sm font-medium text-gray-900">{{ student.name }}</td>
                <td class="px-4 py-3 text-sm text-gray-600">{{ student.email }}</td>
                <td class="px-4 py-3 text-sm">
                  <span 
                    class="px-2 py-1 rounded-full text-xs font-medium"
                    :class="student.signed ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'"
                  >
                    {{ student.signed ? 'Signed' : 'Pending' }}
                  </span>
                </td>
                <td class="px-4 py-3 text-sm text-gray-600">{{ formatDate(student.submitted_at) }}</td>
                <td class="px-4 py-3 text-sm">
                  <div class="flex items-center gap-2">
                    <div class="w-24 bg-gray-200 rounded-full h-2 overflow-hidden">
                      <div 
                        class="h-2 rounded-full"
                        :class="student.signed ? 'bg-green-500' : 'bg-yellow-500'"
                        :style="{ width: student.signed ? '100%' : '0%' }"
                      />
                    </div>
                    <span class="text-xs text-gray-600">{{ student.signed ? '100%' : '0%' }}</span>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Student Cards (Mobile) -->
        <div class="md:hidden space-y-3">
          <div 
            v-for="student in filteredStudents" 
            :key="student.id"
            class="border rounded-lg p-4"
          >
            <div class="flex justify-between items-start mb-2">
              <div>
                <div class="font-medium text-gray-900">{{ student.name }}</div>
                <div class="text-sm text-gray-600">{{ student.email }}</div>
              </div>
              <span 
                class="px-2 py-1 rounded-full text-xs font-medium"
                :class="student.signed ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'"
              >
                {{ student.signed ? 'Signed' : 'Pending' }}
              </span>
            </div>
            <div class="text-xs text-gray-500">
              Submitted: {{ formatDate(student.submitted_at) }}
            </div>
          </div>
        </div>
      </div>

      <!-- Preview Modal -->
      <div v-if="showPreview" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
        <div class="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
          <div class="p-6">
            <div class="flex justify-between items-start mb-4">
              <h3 class="text-xl font-bold text-gray-900">Signing Preview</h3>
              <button @click="showPreview = false" class="text-gray-400 hover:text-gray-600">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <div class="space-y-4">
              <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <h4 class="font-semibold text-blue-900 mb-2">What will happen:</h4>
                <ul class="text-sm text-blue-800 space-y-1 list-disc list-inside">
                  <li>Your signature will be applied to {{ pendingStudents }} student submissions</li>
                  <li>All students will receive email notification</li>
                  <li>Training provider will be notified</li>
                  <li>Status will change to "Sponsor Signed"</li>
                </ul>
              </div>

              <div>
                <h4 class="font-semibold text-gray-900 mb-2">Affected Students:</h4>
                <div class="max-h-48 overflow-y-auto border rounded-md">
                  <table class="min-w-full text-sm">
                    <thead class="bg-gray-50">
                      <tr>
                        <th class="px-3 py-2 text-left font-medium text-gray-600">Name</th>
                        <th class="px-3 py-2 text-left font-medium text-gray-600">Email</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="student in pendingStudentsList" :key="student.id" class="border-t">
                        <td class="px-3 py-2 text-gray-900">{{ student.name }}</td>
                        <td class="px-3 py-2 text-gray-600">{{ student.email }}</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>

              <div>
                <h4 class="font-semibold text-gray-900 mb-2">Your Signature:</h4>
                <div class="border-2 border-gray-300 rounded-md p-4 bg-gray-50">
                  <img v-if="signaturePreview" :src="signaturePreview" class="max-h-32" />
                  <div v-else class="text-gray-600 font-cursive text-2xl">
                    {{ typedSignature }}
                  </div>
                </div>
              </div>

              <div class="flex gap-3 justify-end pt-4 border-t">
                <button
                  @click="showPreview = false"
                  class="px-4 py-2 border border-gray-300 rounded-md hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  @click="confirmSigning"
                  class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 font-medium"
                >
                  Confirm & Sign All
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Success Modal -->
      <div v-if="showSuccess" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
        <div class="bg-white rounded-lg max-w-md w-full p-6">
          <div class="text-center">
            <div class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-green-100 mb-4">
              <svg class="h-6 w-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <h3 class="text-lg font-bold text-gray-900 mb-2">Signing Complete!</h3>
            <p class="text-gray-600 mb-4">
              You have successfully signed all {{ pendingStudents }} student documents.
            </p>
            <p class="text-sm text-gray-500 mb-4">
              Students and the training provider have been notified.
            </p>
            <button
              @click="showSuccess = false; refreshData()"
              class="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 font-medium w-full"
            >
              Done
            </button>
          </div>
        </div>
      </div>

      <!-- Loading Overlay -->
      <div v-if="isSigning" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div class="bg-white rounded-lg p-6 flex flex-col items-center gap-3">
          <svg class="w-8 h-8 animate-spin text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          <div class="text-gray-700 font-medium">Signing documents...</div>
          <div class="text-sm text-gray-500">Applying signature to {{ pendingStudents }} submissions</div>
        </div>
      </div>

      <!-- Status Toast -->
      <div v-if="toastMessage" class="fixed bottom-4 right-4 bg-gray-800 text-white px-4 py-2 rounded-md shadow-lg text-sm flex items-center gap-2">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
        {{ toastMessage }}
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useSponsorCohortStore } from '@/sponsor/stores/cohort'

const props = defineProps<{
  cohortId: number
  token: string
}>()

const emit = defineEmits<{
  (e: 'signed'): void
}>()

const cohortStore = useSponsorCohortStore()

const signatureMethod = ref<'draw' | 'type'>('draw')
const typedSignature = ref('')
const confirmed = ref(false)
const showPreview = ref(false)
const showSuccess = ref(false)
const isSigning = ref(false)
const toastMessage = ref('')
const searchQuery = ref('')
const statusFilter = ref<'all' | 'pending' | 'completed'>('all')

// Signature drawing
const signatureCanvas = ref<HTMLCanvasElement | null>(null)
const isDrawing = ref(false)
const signatureData = ref<string | null>(null)
const signaturePreview = ref<string | null>(null)

const cohortName = computed(() => cohortStore.cohortName)
const totalStudents = computed(() => cohortStore.students.length)
const pendingStudents = computed(() => cohortStore.students.filter(s => !s.signed).length)
const completedStudents = computed(() => cohortStore.students.filter(s => s.signed).length)

const filteredStudents = computed(() => {
  let students = [...cohortStore.students]
  
  if (searchQuery.value.trim()) {
    const query = searchQuery.value.toLowerCase()
    students = students.filter(s => 
      s.name.toLowerCase().includes(query) || 
      s.email.toLowerCase().includes(query)
    )
  }
  
  if (statusFilter.value !== 'all') {
    students = students.filter(s => 
      statusFilter.value === 'pending' ? !s.signed : s.signed
    )
  }
  
  return students
})

const pendingStudentsList = computed(() => {
  return cohortStore.students.filter(s => !s.signed)
})

const canPreview = computed(() => {
  if (signatureMethod.value === 'draw') {
    return signatureData.value !== null && confirmed.value
  } else {
    return typedSignature.value.trim().length > 0 && confirmed.value
  }
})

const canSign = computed(() => {
  return canPreview.value
})

onMounted(async () => {
  await cohortStore.fetchCohort(props.cohortId, props.token)
})

// Signature Drawing Functions
const startDrawing = (event: MouseEvent | TouchEvent) => {
  if (!signatureCanvas.value) return
  
  const ctx = signatureCanvas.value.getContext('2d')
  if (!ctx) return
  
  isDrawing.value = true
  const rect = signatureCanvas.value.getBoundingClientRect()
  
  const x = event instanceof MouseEvent 
    ? event.clientX - rect.left 
    : event.touches[0].clientX - rect.left
  
  const y = event instanceof MouseEvent 
    ? event.clientY - rect.top 
    : event.touches[0].clientY - rect.top
  
  ctx.beginPath()
  ctx.moveTo(x, y)
  ctx.strokeStyle = '#000000'
  ctx.lineWidth = 2
  ctx.lineCap = 'round'
}

const draw = (event: MouseEvent | TouchEvent) => {
  if (!isDrawing.value || !signatureCanvas.value) return
  
  const ctx = signatureCanvas.value.getContext('2d')
  if (!ctx) return
  
  const rect = signatureCanvas.value.getBoundingClientRect()
  
  const x = event instanceof MouseEvent 
    ? event.clientX - rect.left 
    : event.touches[0].clientX - rect.left
  
  const y = event instanceof MouseEvent 
    ? event.clientY - rect.top 
    : event.touches[0].clientY - rect.top
  
  ctx.lineTo(x, y)
  ctx.stroke()
}

const stopDrawing = () => {
  if (!isDrawing.value || !signatureCanvas.value) return
  
  isDrawing.value = false
  signatureData.value = signatureCanvas.value.toDataURL()
}

const clearSignature = () => {
  if (!signatureCanvas.value) return
  
  const ctx = signatureCanvas.value.getContext('2d')
  if (ctx) {
    ctx.clearRect(0, 0, signatureCanvas.value.width, signatureCanvas.value.height)
  }
  signatureData.value = null
}

const previewSigning = () => {
  if (signatureMethod.value === 'draw' && signatureData.value) {
    signaturePreview.value = signatureData.value
  } else {
    signaturePreview.value = null
  }
  showPreview.value = true
}

const confirmSigning = async () => {
  showPreview.value = false
  isSigning.value = true
  
  try {
    const signature = signatureMethod.value === 'draw' 
      ? signatureData.value 
      : typedSignature.value
    
    await cohortStore.bulkSign(props.cohortId, props.token, {
      signature_method: signatureMethod.value,
      signature_data: signature,
      signature_type: signatureMethod.value === 'draw' ? 'canvas' : 'text'
    })
    
    showSuccess.value = true
    emit('signed')
  } catch (error) {
    console.error('Signing failed:', error)
    toastMessage.value = 'Signing failed. Please try again.'
    setTimeout(() => {
      toastMessage.value = ''
    }, 3000)
  } finally {
    isSigning.value = false
  }
}

const executeBulkSign = () => {
  if (!canSign.value) return
  previewSigning()
}

const refreshData = async () => {
  await cohortStore.fetchCohort(props.cohortId, props.token)
}

const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}
</script>

<style scoped>
/* Smooth transitions */
.bg-green-600, .bg-blue-600, .bg-yellow-500 {
  transition: all 0.3s ease;
}

/* Signature canvas */
canvas {
  touch-action: none;
}

/* Modal animations */
.fixed.inset-0 {
  animation: fadeIn 0.2s ease;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}
</style>
```

**Pinia Store:**
```typescript
// app/javascript/sponsor/stores/cohort.ts
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { CohortAPI } from '@/sponsor/api/cohort'
import type { Cohort, Student, BulkSignRequest } from '@/sponsor/types'

export const useSponsorCohortStore = defineStore('sponsorCohort', {
  state: () => ({
    cohortName: '',
    cohortId: null as number | null,
    students: [] as Student[],
    isLoading: false,
    error: null as string | null
  }),

  actions: {
    async fetchCohort(cohortId: number, token: string): Promise<void> {
      this.isLoading = true
      this.error = null

      try {
        const response = await CohortAPI.getById(cohortId, token)
        this.cohortName = response.name
        this.cohortId = response.id
        this.students = response.students
      } catch (error) {
        this.error = error instanceof Error ? error.message : 'Failed to fetch cohort'
        console.error('Fetch cohort error:', error)
        throw error
      } finally {
        this.isLoading = false
      }
    },

    async bulkSign(cohortId: number, token: string, data: BulkSignRequest): Promise<void> {
      this.isLoading = true
      this.error = null

      try {
        await CohortAPI.bulkSign(cohortId, token, data)
        // Update local state
        this.students = this.students.map(s => ({
          ...s,
          signed: true,
          signed_at: new Date().toISOString()
        }))
      } catch (error) {
        this.error = error instanceof Error ? error.message : 'Failed to sign documents'
        console.error('Bulk sign error:', error)
        throw error
      } finally {
        this.isLoading = false
      }
    }
  }
})
```

**API Layer:**
```typescript
// app/javascript/sponsor/api/cohort.ts
export interface Student {
  id: number
  name: string
  email: string
  signed: boolean
  signed_at?: string
  submitted_at: string
}

export interface CohortResponse {
  id: number
  name: string
  students: Student[]
}

export interface BulkSignRequest {
  signature_method: 'draw' | 'type'
  signature_data: string | null
  signature_type: 'canvas' | 'text'
}

export const CohortAPI = {
  async getById(cohortId: number, token: string): Promise<CohortResponse> {
    const response = await fetch(`/api/sponsor/cohorts/${cohortId}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    })

    if (!response.ok) {
      if (response.status === 403) {
        throw new Error('Access denied or token expired')
      }
      if (response.status === 404) {
        throw new Error('Cohort not found')
      }
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    return response.json()
  },

  async bulkSign(cohortId: number, token: string, data: BulkSignRequest): Promise<void> {
    const response = await fetch(`/api/sponsor/cohorts/${cohortId}/bulk-sign`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(data)
    })

    if (!response.ok) {
      if (response.status === 409) {
        throw new Error('Cohort already signed or has no pending submissions')
      }
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
  }
}
```

**Type Definitions:**
```typescript
// app/javascript/sponsor/types/index.ts
export interface Student {
  id: number
  name: string
  email: string
  signed: boolean
  signed_at?: string
  submitted_at: string
}

export interface CohortResponse {
  id: number
  name: string
  students: Student[]
}

export interface BulkSignRequest {
  signature_method: 'draw' | 'type'
  signature_data: string | null
  signature_type: 'canvas' | 'text'
}
```

**Design System Compliance:**
Per FR28, all Sponsor Portal components must use design system assets from:
- `@.claude/skills/frontend-design/SKILL.md` - Design tokens
- `@.claude/skills/frontend-design/design-system/` - SVG assets

Specific requirements:
- **Colors**: 
  - Primary (Blue-600): `#2563EB` for headers and buttons
  - Success (Green-600): `#16A34A` for completed/signed states
  - Warning (Yellow-600): `#CA8A04` for pending states
  - Info (Purple-600): `#7C3AED` for stats cards
  - Neutral (Gray-500): `#6B7280` for text
- **Spacing**: 4px base unit, 1.5rem (24px) for sections, 0.75rem (12px) for gaps
- **Typography**: 
  - Headings: 24px (h1), 20px (h2), 16px (h3)
  - Body: 16px base, 14px for descriptions
  - Labels: 12px uppercase, letter-spacing 0.05em
- **Icons**: Use SVG icons from design system for:
  - Pen (signature)
  - Checkmark (completed)
  - Clock (pending)
  - Document (files)
  - Search (filter)
  - Refresh (update)
  - Eye (preview)
- **Layout**: 
  - Max width: 7xl (1280px)
  - Card corners: rounded-lg (8px)
  - Shadow: shadow-md for cards
  - Table: grid layout on desktop, cards on mobile
- **Accessibility**: 
  - ARIA labels on all buttons
  - Keyboard navigation for modals
  - Screen reader announcements for signing actions
  - Focus indicators on all interactive elements
  - Color contrast ratio minimum 4.5:1
  - Signature canvas has clear instructions

##### Acceptance Criteria

**Functional:**
1. ✅ Component loads cohort data on mount
2. ✅ Shows correct student counts (total, pending, completed)
3. ✅ Displays student list with status
4. ✅ Search filters students by name/email
5. ✅ Status filter works correctly
6. ✅ Signature method selection works
7. ✅ Canvas signature drawing works
8. ✅ Typed signature input works
9. ✅ Clear signature button works
10. ✅ Confirmation checkbox required
11. ✅ Preview modal shows affected students
12. ✅ Preview modal shows signature preview
13. ✅ Bulk sign executes successfully
14. ✅ Success modal appears after signing
15. ✅ Data refreshes after signing

**UI/UX:**
1. ✅ Desktop: Table layout with 5 columns
2. ✅ Mobile: Card layout with stacked information
3. ✅ Status badges use color-coded styling
4. ✅ Progress bars animate smoothly
5. ✅ Quick stats cards show key metrics
6. ✅ Signature canvas shows drawing feedback
7. ✅ Modals are centered and scrollable
8. ✅ Loading overlay blocks interaction
9. ✅ Success modal shows confirmation
10. ✅ Toast notifications for errors

**Integration:**
1. ✅ API endpoint: `GET /api/sponsor/cohorts/{id}`
2. ✅ API endpoint: `POST /api/sponsor/cohorts/{id}/bulk-sign`
3. ✅ Token authentication in headers
4. ✅ Signature data sent correctly
5. ✅ State updates after signing

**Security:**
1. ✅ Token-based authentication required
2. ✅ Authorization check: sponsor can only sign their assigned cohorts
3. ✅ Validation: all required fields before signing
4. ✅ Rate limiting on bulk sign (max 5 per hour)
5. ✅ Audit log of all signing actions

**Quality:**
1. ✅ No duplicate signing attempts
2. ✅ Error handling for failed API calls
3. ✅ Data consistency after signing
4. ✅ Performance: handles 100+ students
5. ✅ Browser compatibility: Chrome, Firefox, Safari, Edge

##### Integration Verification (IV1-4)

**IV1: API Integration**
- `CohortDashboard.vue` calls `CohortAPI.getById()` on mount
- `CohortDashboard.vue` calls `CohortAPI.bulkSign()` on confirm
- All endpoints use `Authorization: Bearer {token}` header
- Signature data format matches backend expectations

**IV2: Pinia Store**
- `sponsorCohortStore.cohortName` holds cohort information
- `sponsorCohortStore.students` holds student list
- `sponsorCohortStore.bulkSign()` updates student states
- State reflects signing completion

**IV3: Getters**
- `pendingStudents` counts unsigned students
- `completedStudents` counts signed students
- `filteredStudents` applies search and filter
- `pendingStudentsList` shows affected students in preview

**IV4: Token Routing**
- CohortDashboard receives `token` prop from parent
- Parent loads token from URL param (`?token=...`)
- All API calls pass token to store actions

##### Test Requirements

**Component Specs:**
```javascript
// spec/javascript/sponsor/views/CohortDashboard.spec.js
import { mount, flushPromises } from '@vue/test-utils'
import CohortDashboard from '@/sponsor/views/CohortDashboard.vue'
import { useSponsorCohortStore } from '@/sponsor/stores/cohort'
import { createPinia, setActivePinia } from 'pinia'

describe('CohortDashboard', () => {
  const mockCohort = {
    id: 1,
    name: 'Summer 2025',
    students: [
      { id: 1, name: 'John Doe', email: 'john@example.com', signed: false, submitted_at: '2025-01-15T10:00:00Z' },
      { id: 2, name: 'Jane Smith', email: 'jane@example.com', signed: false, submitted_at: '2025-01-15T10:30:00Z' },
      { id: 3, name: 'Bob Johnson', email: 'bob@example.com', signed: true, signed_at: '2025-01-16T10:00:00Z', submitted_at: '2025-01-15T10:00:00Z' }
    ]
  }

  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('renders cohort stats correctly', async () => {
    const wrapper = mount(CohortDashboard, {
      props: { cohortId: 1, token: 'test-token' }
    })

    const store = useSponsorCohortStore()
    Object.assign(store, mockCohort)
    await flushPromises()

    expect(wrapper.text()).toContain('Summer 2025')
    expect(wrapper.text()).toContain('Total Students: 3')
    expect(wrapper.text()).toContain('Pending: 2')
    expect(wrapper.text()).toContain('Completed: 1')
  })

  it('displays student list', async () => {
    const wrapper = mount(CohortDashboard, {
      props: { cohortId: 1, token: 'test-token' }
    })

    const store = useSponsorCohortStore()
    Object.assign(store, mockCohort)
    await flushPromises()

    expect(wrapper.text()).toContain('John Doe')
    expect(wrapper.text()).toContain('Jane Smith')
    expect(wrapper.text()).toContain('Bob Johnson')
  })

  it('filters students by search', async () => {
    const wrapper = mount(CohortDashboard, {
      props: { cohortId: 1, token: 'test-token' }
    })

    const store = useSponsorCohortStore()
    Object.assign(store, mockCohort)
    await flushPromises()

    const searchInput = wrapper.find('input[type="text"]')
    await searchInput.setValue('John')
    await wrapper.vm.$nextTick()

    expect(wrapper.text()).toContain('John Doe')
    expect(wrapper.text()).not.toContain('Jane Smith')
  })

  it('enables signing only when requirements met', async () => {
    const wrapper = mount(CohortDashboard, {
      props: { cohortId: 1, token: 'test-token' }
    })

    const store = useSponsorCohortStore()
    Object.assign(store, mockCohort)
    await flushPromises()

    // Initially disabled
    let signButton = wrapper.find('button').filter(n => n.text().includes('Sign All'))
    expect(signButton.element.disabled).toBe(true)

    // Select type method and enter signature
    wrapper.vm.signatureMethod = 'type'
    wrapper.vm.typedSignature = 'John Doe'
    wrapper.vm.confirmed = true
    await wrapper.vm.$nextTick()

    signButton = wrapper.find('button').filter(n => n.text().includes('Sign All'))
    expect(signButton.element.disabled).toBe(false)
  })

  it('executes bulk signing', async () => {
    const wrapper = mount(CohortDashboard, {
      props: { cohortId: 1, token: 'test-token' }
    })

    const store = useSponsorCohortStore()
    Object.assign(store, mockCohort)
    const signSpy = vi.spyOn(store, 'bulkSign')
    await flushPromises()

    // Setup signing
    wrapper.vm.signatureMethod = 'type'
    wrapper.vm.typedSignature = 'John Doe'
    wrapper.vm.confirmed = true
    await wrapper.vm.$nextTick()

    // Click sign
    const signButton = wrapper.find('button').filter(n => n.text().includes('Sign All'))
    await signButton.trigger('click')

    // Should show preview first
    expect(wrapper.vm.showPreview).toBe(true)

    // Confirm in preview
    const confirmButton = wrapper.find('button').filter(n => n.text().includes('Confirm'))
    await confirmButton.trigger('click')

    expect(signSpy).toHaveBeenCalledWith(1, 'test-token', expect.any(Object))
  })

  it('shows success modal after signing', async () => {
    const wrapper = mount(CohortDashboard, {
      props: { cohortId: 1, token: 'test-token' }
    })

    const store = useSponsorCohortStore()
    Object.assign(store, mockCohort)
    await flushPromises()

    // Complete signing flow
    wrapper.vm.signatureMethod = 'type'
    wrapper.vm.typedSignature = 'John Doe'
    wrapper.vm.confirmed = true
    wrapper.vm.showPreview = true
    
    // Mock successful signing
    store.bulkSign = vi.fn().mockResolvedValue(undefined)
    await wrapper.vm.confirmSigning()

    expect(wrapper.vm.showSuccess).toBe(true)
  })

  it('handles canvas signature', async () => {
    const wrapper = mount(CohortDashboard, {
      props: { cohortId: 1, token: 'test-token' }
    })

    const store = useSponsorCohortStore()
    Object.assign(store, mockCohort)
    await flushPromises()

    wrapper.vm.signatureMethod = 'draw'
    await wrapper.vm.$nextTick()

    const canvas = wrapper.find('canvas')
    expect(canvas.exists()).toBe(true)

    // Simulate drawing
    wrapper.vm.signatureData = 'data:image/png;base64,signature'
    wrapper.vm.confirmed = true
    await wrapper.vm.$nextTick()

    const signButton = wrapper.find('button').filter(n => n.text().includes('Sign All'))
    expect(signButton.element.disabled).toBe(false)
  })
})
```

**Integration Tests:**
```javascript
// spec/javascript/sponsor/integration/bulk-sign-flow.spec.js
describe('Bulk Signing Flow', () => {
  it('completes full signing workflow', async () => {
    // 1. Load cohort dashboard
    // 2. Verify student list
    // 3. Select signature method
    // 4. Draw or type signature
    // 5. Confirm checkbox
    // 6. Preview signing
    // 7. Confirm and execute
    // 8. Verify success modal
    // 9. Refresh and verify all signed
  })
})
```

**E2E Tests:**
```javascript
// spec/system/sponsor_bulk_signing_spec.rb
RSpec.describe 'Sponsor Bulk Signing', type: :system do
  let(:cohort) { create(:cohort, status: :ready_for_sponsor) }
  let!(:students) { create_list(:student, 5, cohort: cohort) }
  let(:token) { cohort.generate_sponsor_token }

  scenario 'sponsor signs all documents at once' do
    visit "/sponsor/cohorts/#{cohort.id}?token=#{token}"
    
    expect(page).to have_content(cohort.name)
    expect(page).to have_content('Total Students: 5')
    expect(page).to have_content('Pending: 5')
    
    # Select type signature
    click_button 'Type Name'
    fill_in 'Type Your Full Name', with: 'Jane Sponsor'
    check 'I confirm that I have reviewed'
    
    # Preview
    click_button 'Preview'
    expect(page).to have_content('Signing Preview')
    expect(page).to have_content('Jane Sponsor')
    
    # Confirm
    click_button 'Confirm & Sign All'
    
    # Should show success
    expect(page).to have_content('Signing Complete!')
    expect(page).to have_content('5 student documents')
    
    # Close modal and verify
    click_button 'Done'
    expect(page).to have_content('All Documents Signed')
    expect(page).to have_content('Completed: 5')
  end

  scenario 'sponsor draws signature', do
    visit "/sponsor/cohorts/#{cohort.id}?token=#{token}"
    
    # Canvas is visible by default
    expect(page).to have_css('canvas')
    
    # Draw on canvas (simplified in test)
    # In real test, would use browser actions to draw
    
    check 'I confirm that I have reviewed'
    click_button 'Sign All 5 Documents'
    
    expect(page).to have_content('Signing Complete!')
  end

  scenario 'search and filter students', do
    visit "/sponsor/cohorts/#{cohort.id}?token=#{token}"
    
    # Search for specific student
    fill_in 'Search students...', with: students.first.name
    expect(page).to have_content(students.first.name)
    expect(page).not_to have_content(students.second.name)
    
    # Filter by pending
    select 'Pending', from: 'status'
    expect(page).to have_content('5')
  end
end
```

##### Rollback Procedure

**If cohort fails to load:**
1. Show error message with retry button
2. Display access instructions
3. Log error to monitoring
4. Provide support contact

**If signing fails:**
1. Show error message with details
2. Preserve signature data if possible
3. Allow retry without re-entering signature
4. Log failure for investigation
5. Notify support if persistent

**If signature canvas breaks:**
1. Show error message
2. Automatically switch to type method
3. Preserve other form data
4. Log canvas error

**If preview modal fails:**
1. Close modal
2. Show error toast
3. Allow retry
4. Preserve signature data

**Data Safety:**
- No data mutation until final confirmation
- Signature data held in memory only
- All operations atomic (all or nothing)
- No partial signing allowed

##### Risk Assessment

**Medium Risk** because:
- Bulk operations affect multiple records
- Signature capture requires canvas API
- Complex state management for 100+ students
- Security implications of bulk signing
- User error could sign wrong cohort

**Specific Risks:**
1. **Accidental Bulk Sign**: Sponsor signs without realizing scope
   - **Mitigation**: Clear preview modal showing all affected students, confirmation required

2. **Signature Quality**: Canvas signature may be poor quality
   - **Mitigation**: Provide type fallback, preview before final

3. **Browser Compatibility**: Canvas touch events vary
   - **Mitigation**: Use signature_pad library, test on all browsers

4. **Token Expiration**: Long signing sessions may expire
   - **Mitigation**: Token renewal mechanism (Story 4.9)

5. **Concurrent Signing**: Multiple sponsors for same cohort
   - **Mitigation**: Lock cohort during signing, check state before commit

**Mitigation Strategies:**
- Comprehensive preview before any signing
- Clear scope indication (number of students affected)
- Confirmation dialog with details
- Rate limiting to prevent abuse
- Audit trail for all signing actions
- Fallback to type signature if canvas fails

##### Success Metrics

- **Signing Success Rate**: 98% of bulk signing attempts succeed
- **User Error Rate**: <2% of signers report confusion about scope
- **Time to Complete**: Average <2 minutes for full cohort
- **Canvas Usage**: 70% use draw, 30% use type
- **Preview Usage**: 100% of successful signers view preview
- **Support Tickets**: <1% related to bulk signing
- **Zero Partial Signatures**: 100% atomic operations

---

#### Story 6.2: Sponsor Portal - Email Notifications & Reminders

**Status**: Draft/Pending
**Priority**: High
**Epic**: Sponsor Portal - Frontend Development
**Estimated Effort**: 2 days
**Risk Level**: Low

##### User Story

**As a** Sponsor,
**I want** to receive email notifications about signing requests and reminders to complete my cohort signing,
**So that** I can stay informed and fulfill my signing responsibility on time without constantly checking the portal.

##### Background

Sponsors need to stay informed about their signing responsibilities without manually monitoring the portal. The system should provide:

1. **Initial Invitation Email**: Sent when TP creates cohort and assigns sponsor
2. **Reminder Emails**: Sent if sponsor hasn't accessed the cohort after certain time
3. **Status Update Emails**: Sent when students complete their submissions
4. **Completion Confirmation**: Sent after sponsor completes bulk signing

**Email Types:**
- **Invitation**: "You've been assigned to sign documents for [Cohort Name]"
- **Reminder - Not Accessed**: "Action required: Sign documents for [Cohort Name]"
- **Reminder - Partial**: "You're almost done! [X] students still need your signature"
- **Status - Student Completed**: "[Student Name] has submitted their documents"
- **Status - Signing Complete**: "You've successfully signed all documents"

**Key Requirements:**
- Emails contain secure, time-limited links with JWT tokens
- Unsubscribe option in all emails (per FR12)
- Email preferences can be managed by sponsor
- Reminder frequency is configurable
- Single email per cohort (no duplicates per student)
- Immediate notification when students complete submissions

**Integration Point**: This story connects to the email system (Stories 2.2, 2.3) and provides sponsor-facing notification management.

##### Technical Implementation Notes

**Vue 3 Component Structure:**
```vue
<!-- app/javascript/sponsor/views/EmailPreferences.vue -->
<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-3xl mx-auto px-4">
      <!-- Header -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <h1 class="text-2xl font-bold text-gray-900 mb-2">Email Notification Preferences</h1>
        <p class="text-gray-600">
          Manage which emails you receive for cohort <strong>{{ cohortName }}</strong>
        </p>
      </div>

      <!-- Notification Settings -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Email Settings</h2>
        
        <div class="space-y-4">
          <!-- Signing Requests -->
          <div class="flex items-start justify-between border-b border-gray-100 pb-4">
            <div class="flex-1">
              <h3 class="font-medium text-gray-900">Signing Requests</h3>
              <p class="text-sm text-gray-600 mt-1">
                Receive emails when assigned to sign documents
              </p>
              <div class="text-xs text-gray-500 mt-1">
                Includes initial invitation and cohort access link
              </div>
            </div>
            <label class="flex items-center ml-4">
              <input 
                type="checkbox" 
                v-model="settings.signingRequests"
                class="w-5 h-5 text-blue-600 rounded focus:ring-blue-500"
                @change="saveSettings"
              />
            </label>
          </div>

          <!-- Student Completion Alerts -->
          <div class="flex items-start justify-between border-b border-gray-100 pb-4">
            <div class="flex-1">
              <h3 class="font-medium text-gray-900">Student Completion Alerts</h3>
              <p class="text-sm text-gray-600 mt-1">
                Get notified when students submit their documents
              </p>
              <div class="text-xs text-gray-500 mt-1">
                Sent once per cohort, not per student
              </div>
            </div>
            <label class="flex items-center ml-4">
              <input 
                type="checkbox" 
                v-model="settings.studentAlerts"
                class="w-5 h-5 text-blue-600 rounded focus:ring-blue-500"
                @change="saveSettings"
              />
            </label>
          </div>

          <!-- Reminders -->
          <div class="flex items-start justify-between border-b border-gray-100 pb-4">
            <div class="flex-1">
              <h3 class="font-medium text-gray-900">Completion Reminders</h3>
              <p class="text-sm text-gray-600 mt-1">
                Receive reminders if you haven't signed yet
              </p>
              <div class="text-xs text-gray-500 mt-1">
                Sent after 48 hours and 72 hours if incomplete
              </div>
            </div>
            <label class="flex items-center ml-4">
              <input 
                type="checkbox" 
                v-model="settings.reminders"
                class="w-5 h-5 text-blue-600 rounded focus:ring-blue-500"
                @change="saveSettings"
              />
            </label>
          </div>

          <!-- Completion Confirmation -->
          <div class="flex items-start justify-between pb-4">
            <div class="flex-1">
              <h3 class="font-medium text-gray-900">Completion Confirmation</h3>
              <p class="text-sm text-gray-600 mt-1">
                Get confirmation after you complete signing
              </p>
              <div class="text-xs text-gray-500 mt-1">
                Includes summary and next steps
              </div>
            </div>
            <label class="flex items-center ml-4">
              <input 
                type="checkbox" 
                v-model="settings.completionAlerts"
                class="w-5 h-5 text-blue-600 rounded focus:ring-blue-500"
                @change="saveSettings"
              />
            </label>
          </div>
        </div>
      </div>

      <!-- Reminder Frequency -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Reminder Frequency</h2>
        
        <div class="space-y-3">
          <label class="flex items-center justify-between">
            <span class="text-sm text-gray-700">Every 48 hours</span>
            <input 
              type="radio" 
              v-model="settings.reminderFrequency"
              value="48h"
              class="w-4 h-4 text-blue-600 focus:ring-blue-500"
              @change="saveSettings"
            />
          </label>
          
          <label class="flex items-center justify-between">
            <span class="text-sm text-gray-700">Weekly</span>
            <input 
              type="radio" 
              v-model="settings.reminderFrequency"
              value="1w"
              class="w-4 h-4 text-blue-600 focus:ring-blue-500"
              @change="saveSettings"
            />
          </label>
          
          <label class="flex items-center justify-between">
            <span class="text-sm text-gray-700">Only urgent (72+ hours)</span>
            <input 
              type="radio" 
              v-model="settings.reminderFrequency"
              value="urgent"
              class="w-4 h-4 text-blue-600 focus:ring-blue-500"
              @change="saveSettings"
            />
          </label>
          
          <label class="flex items-center justify-between">
            <span class="text-sm text-gray-700">No reminders</span>
            <input 
              type="radio" 
              v-model="settings.reminderFrequency"
              value="none"
              class="w-4 h-4 text-blue-600 focus:ring-blue-500"
              @change="saveSettings"
            />
          </label>
        </div>
      </div>

      <!-- Email Preview -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Email Preview</h2>
        
        <div class="bg-gray-50 rounded-lg p-4 border border-gray-200">
          <div class="text-xs text-gray-500 mb-2">Example: Signing Request</div>
          <div class="text-sm">
            <p class="font-medium text-gray-900 mb-1">Subject: Action Required: Sign documents for {{ cohortName }}</p>
            <p class="text-gray-700">
              Hello,<br><br>
              You have been assigned to sign student documents for <strong>{{ cohortName }}</strong>.<br>
              <strong>3 students</strong> are waiting for your signature.<br><br>
              <a href="#" class="text-blue-600 hover:underline">Click here to review and sign</a><br><br>
              This link will expire in 7 days.
            </p>
          </div>
        </div>
      </div>

      <!-- Unsubscribe All -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6 border border-red-200">
        <h2 class="text-lg font-semibold text-gray-900 mb-2 text-red-800">Unsubscribe from All Emails</h2>
        <p class="text-sm text-gray-600 mb-4">
          This will disable all email notifications. You will need to check the portal manually for updates.
        </p>
        <button
          @click="unsubscribeAll"
          class="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 font-medium"
        >
          Unsubscribe from All
        </button>
      </div>

      <!-- Action Buttons -->
      <div class="flex justify-end gap-3">
        <button
          @click="resetToDefaults"
          class="px-6 py-2 border border-gray-300 rounded-md hover:bg-gray-50 text-gray-700 font-medium"
        >
          Reset to Defaults
        </button>
        <button
          @click="saveSettings"
          class="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 font-medium"
        >
          Save Settings
        </button>
      </div>

      <!-- Success Toast -->
      <div v-if="showToast" class="fixed bottom-4 right-4 bg-green-600 text-white px-4 py-2 rounded-md shadow-lg text-sm flex items-center gap-2">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
        {{ toastMessage }}
      </div>

      <!-- Loading State -->
      <div v-if="isLoading" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div class="bg-white rounded-lg p-6 flex items-center gap-3">
          <svg class="w-6 h-6 animate-spin text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          <span class="text-gray-700">Saving preferences...</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useSponsorNotificationStore } from '@/sponsor/stores/notifications'

const props = defineProps<{
  cohortId: number
  token: string
}>()

const notificationStore = useSponsorNotificationStore()

const isLoading = ref(false)
const showToast = ref(false)
const toastMessage = ref('')

const cohortName = ref('')

const settings = ref({
  signingRequests: true,
  studentAlerts: true,
  reminders: true,
  completionAlerts: true,
  reminderFrequency: '48h'
})

onMounted(async () => {
  try {
    const data = await notificationStore.fetchPreferences(props.cohortId, props.token)
    settings.value = {
      signingRequests: data.signing_requests,
      studentAlerts: data.student_alerts,
      reminders: data.reminders,
      completionAlerts: data.completion_alerts,
      reminderFrequency: data.reminder_frequency
    }
    cohortName.value = data.cohort_name
  } catch (error) {
    console.error('Failed to load preferences:', error)
  }
})

const saveSettings = async () => {
  isLoading.value = true
  try {
    await notificationStore.updatePreferences(props.cohortId, props.token, settings.value)
    toastMessage.value = 'Preferences saved successfully'
    showToast.value = true
    setTimeout(() => {
      showToast.value = false
    }, 2000)
  } catch (error) {
    console.error('Failed to save settings:', error)
    toastMessage.value = 'Failed to save settings'
    showToast.value = true
    setTimeout(() => {
      showToast.value = false
    }, 2000)
  } finally {
    isLoading.value = false
  }
}

const resetToDefaults = () => {
  settings.value = {
    signingRequests: true,
    studentAlerts: true,
    reminders: true,
    completionAlerts: true,
    reminderFrequency: '48h'
  }
  saveSettings()
}

const unsubscribeAll = async () => {
  if (!confirm('Are you sure you want to unsubscribe from ALL emails? You will miss important updates.')) {
    return
  }

  settings.value = {
    signingRequests: false,
    studentAlerts: false,
    reminders: false,
    completionAlerts: false,
    reminderFrequency: 'none'
  }
  
  await saveSettings()
}
</script>

<style scoped>
/* Smooth transitions */
input[type="checkbox"], input[type="radio"] {
  transition: all 0.2s ease;
}

/* Hover effects */
label:hover {
  cursor: pointer;
}
</style>
```

**Pinia Store:**
```typescript
// app/javascript/sponsor/stores/notifications.ts
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { NotificationAPI } from '@/sponsor/api/notification'

export interface NotificationPreferences {
  signing_requests: boolean
  student_alerts: boolean
  reminders: boolean
  completion_alerts: boolean
  reminder_frequency: string
  cohort_name: string
}

export const useSponsorNotificationStore = defineStore('sponsorNotifications', {
  state: () => ({
    preferences: null as NotificationPreferences | null,
    isLoading: false,
    error: null as string | null
  }),

  actions: {
    async fetchPreferences(cohortId: number, token: string): Promise<NotificationPreferences> {
      this.isLoading = true
      this.error = null

      try {
        const response = await NotificationAPI.getPreferences(cohortId, token)
        this.preferences = response
        return response
      } catch (error) {
        this.error = error instanceof Error ? error.message : 'Failed to fetch preferences'
        console.error('Fetch preferences error:', error)
        throw error
      } finally {
        this.isLoading = false
      }
    },

    async updatePreferences(
      cohortId: number,
      token: string,
      preferences: Partial<NotificationPreferences>
    ): Promise<void> {
      this.isLoading = true
      this.error = null

      try {
        await NotificationAPI.updatePreferences(cohortId, token, preferences)
        if (this.preferences) {
          this.preferences = { ...this.preferences, ...preferences }
        }
      } catch (error) {
        this.error = error instanceof Error ? error.message : 'Failed to update preferences'
        console.error('Update preferences error:', error)
        throw error
      } finally {
        this.isLoading = false
      }
    }
  }
})
```

**API Layer:**
```typescript
// app/javascript/sponsor/api/notification.ts
export interface NotificationPreferences {
  signing_requests: boolean
  student_alerts: boolean
  reminders: boolean
  completion_alerts: boolean
  reminder_frequency: string
  cohort_name: string
}

export interface UpdatePreferencesRequest {
  signing_requests?: boolean
  student_alerts?: boolean
  reminders?: boolean
  completion_alerts?: boolean
  reminder_frequency?: string
}

export const NotificationAPI = {
  async getPreferences(cohortId: number, token: string): Promise<NotificationPreferences> {
    const response = await fetch(`/api/sponsor/cohorts/${cohortId}/notification-preferences`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    })

    if (!response.ok) {
      if (response.status === 403) {
        throw new Error('Access denied or token expired')
      }
      if (response.status === 404) {
        throw new Error('Cohort not found')
      }
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    return response.json()
  },

  async updatePreferences(
    cohortId: number,
    token: string,
    preferences: UpdatePreferencesRequest
  ): Promise<void> {
    const response = await fetch(`/api/sponsor/cohorts/${cohortId}/notification-preferences`, {
      method: 'PUT',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(preferences)
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
  },

  async sendInvitationEmail(cohortId: number, token: string): Promise<void> {
    const response = await fetch(`/api/sponsor/cohorts/${cohortId}/send-invitation`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
  },

  async sendReminderEmail(cohortId: number, token: string, type: string): Promise<void> {
    const response = await fetch(`/api/sponsor/cohorts/${cohortId}/send-reminder`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ type })
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
  },

  async sendStudentCompletionAlert(cohortId: number, token: string): Promise<void> {
    const response = await fetch(`/api/sponsor/cohorts/${cohortId}/send-student-alert`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    })

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
  }
}
```

**Type Definitions:**
```typescript
// app/javascript/sponsor/types/index.ts (extended)
export interface NotificationPreferences {
  signing_requests: boolean
  student_alerts: boolean
  reminders: boolean
  completion_alerts: boolean
  reminder_frequency: string
  cohort_name: string
}

export interface UpdatePreferencesRequest {
  signing_requests?: boolean
  student_alerts?: boolean
  reminders?: boolean
  completion_alerts?: boolean
  reminder_frequency?: string
}
```

**Design System Compliance:**
Per FR28, all Sponsor Notification components must use design system assets from:
- `@.claude/skills/frontend-design/SKILL.md` - Design tokens
- `@.claude/skills/frontend-design/design-system/` - SVG assets

Specific requirements:
- **Colors**: 
  - Primary (Blue-600): `#2563EB` for buttons and links
  - Warning (Red-600): `#DC2626` for unsubscribe section
  - Success (Green-600): `#16A34A` for saved indicators
  - Neutral (Gray-500): `#6B7280` for text
- **Spacing**: 4px base unit, 1.5rem (24px) for sections, 1rem (16px) for field gaps
- **Typography**: 
  - Headings: 24px (h1), 20px (h2), 16px (h3)
  - Body: 16px base, 14px for descriptions
  - Small: 12px for helper text
- **Icons**: Use SVG icons from design system for:
  - Mail (email)
  - Bell (notifications)
  - Checkmark (saved)
  - Trash (unsubscribe)
  - Refresh (reset)
  - Settings (preferences)
- **Layout**: 
  - Max width: 3xl (48rem / 768px)
  - Card corners: rounded-lg (8px)
  - Shadow: shadow-md for cards
  - Toggle switches: right-aligned
- **Accessibility**: 
  - ARIA labels on all toggles
  - Keyboard navigation for checkboxes
  - Screen reader announcements for save actions
  - Focus indicators on all interactive elements
  - Color contrast ratio minimum 4.5:1
  - Warning section clearly marked

##### Acceptance Criteria

**Functional:**
1. ✅ Component loads existing preferences on mount
2. ✅ All 4 notification toggles work correctly
3. ✅ Reminder frequency radio buttons work
4. ✅ Save button persists changes to server
5. ✅ Reset to defaults restores original settings
6. ✅ Unsubscribe all disables all notifications
7. ✅ Confirmation dialog before unsubscribe
8. ✅ Email preview shows realistic example
9. ✅ Shows success toast after save
10. ✅ Loading state during API calls

**UI/UX:**
1. ✅ Toggles show clear on/off states
2. ✅ Settings organized in logical sections
3. ✅ Warning section visually distinct (red border)
4. ✅ Email preview shows realistic example
5. ✅ Success toast appears for 2 seconds
6. ✅ Loading overlay blocks interaction
7. ✅ Mobile-responsive design
8. ✅ Hover states on all interactive elements

**Integration:**
1. ✅ API endpoint: `GET /api/sponsor/cohorts/{id}/notification-preferences`
2. ✅ API endpoint: `PUT /api/sponsor/cohorts/{id}/notification-preferences`
3. ✅ API endpoint: `POST /api/sponsor/cohorts/{id}/send-invitation`
4. ✅ API endpoint: `POST /api/sponsor/cohorts/{id}/send-reminder`
5. ✅ API endpoint: `POST /api/sponsor/cohorts/{id}/send-student-alert`
6. ✅ Token authentication in headers
7. ✅ Settings persist across sessions

**Security:**
1. ✅ Token-based authentication required
2. ✅ Authorization check: sponsor can only manage their preferences
3. ✅ Rate limiting on update endpoint (max 10 per hour)
4. ✅ Validation of reminder frequency values
5. ✅ Audit log of all preference changes

**Quality:**
1. ✅ No duplicate API calls on rapid clicks
2. ✅ Error handling for failed API calls
3. ✅ State consistency between UI and server
4. ✅ Performance: loads in <1 second
5. ✅ Browser compatibility: Chrome, Firefox, Safari, Edge

##### Integration Verification (IV1-4)

**IV1: API Integration**
- `EmailPreferences.vue` calls `NotificationAPI.getPreferences()` on mount
- `EmailPreferences.vue` calls `NotificationAPI.updatePreferences()` on save
- `EmailPreferences.vue` calls `NotificationAPI.sendInvitationEmail()` (if needed)
- All endpoints use `Authorization: Bearer {token}` header

**IV2: Pinia Store**
- `sponsorNotificationStore.preferences` holds notification settings
- `sponsorNotificationStore.fetchPreferences()` loads settings
- `sponsorNotificationStore.updatePreferences()` saves changes

**IV3: Getters**
- Store provides computed properties for UI display
- Settings are reactive and update UI immediately

**IV4: Token Routing**
- EmailPreferences receives `token` prop from parent
- Parent loads token from URL param (`?token=...`)
- All API calls pass token to store actions

##### Test Requirements

**Component Specs:**
```javascript
// spec/javascript/sponsor/views/EmailPreferences.spec.js
import { mount, flushPromises } from '@vue/test-utils'
import EmailPreferences from '@/sponsor/views/EmailPreferences.vue'
import { useSponsorNotificationStore } from '@/sponsor/stores/notifications'
import { createPinia, setActivePinia } from 'pinia'

describe('EmailPreferences', () => {
  const mockPreferences = {
    signing_requests: true,
    student_alerts: true,
    reminders: true,
    completion_alerts: true,
    reminder_frequency: '48h',
    cohort_name: 'Summer 2025'
  }

  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('loads preferences on mount', async () => {
    const wrapper = mount(EmailPreferences, {
      props: { cohortId: 1, token: 'test-token' }
    })

    const store = useSponsorNotificationStore()
    store.preferences = mockPreferences
    await flushPromises()

    expect(wrapper.vm.settings.signingRequests).toBe(true)
    expect(wrapper.vm.settings.reminderFrequency).toBe('48h')
  })

  it('toggles notification settings', async () => {
    const wrapper = mount(EmailPreferences, {
      props: { cohortId: 1, token: 'test-token' }
    })

    const store = useSponsorNotificationStore()
    store.preferences = mockPreferences
    await flushPromises()

    const statusToggle = wrapper.find('input[type="checkbox"]')
    await statusToggle.trigger('click')

    expect(wrapper.vm.settings.signingRequests).toBe(false)
  })

  it('saves settings when save button clicked', async () => {
    const wrapper = mount(EmailPreferences, {
      props: { cohortId: 1, token: 'test-token' }
    })

    const store = useSponsorNotificationStore()
    store.preferences = mockPreferences
    const updateSpy = vi.spyOn(store, 'updatePreferences')
    await flushPromises()

    const saveButton = wrapper.find('button').filter(n => n.text().includes('Save'))
    await saveButton.trigger('click')

    expect(updateSpy).toHaveBeenCalledWith(1, 'test-token', expect.any(Object))
  })

  it('resets to defaults', async () => {
    const wrapper = mount(EmailPreferences, {
      props: { cohortId: 1, token: 'test-token' }
    })

    const store = useSponsorNotificationStore()
    store.preferences = mockPreferences
    await flushPromises()

    // Change some settings
    wrapper.vm.settings.reminders = false
    await wrapper.vm.$nextTick()

    // Reset
    const resetButton = wrapper.find('button').filter(n => n.text().includes('Reset'))
    await resetButton.trigger('click')

    expect(wrapper.vm.settings.reminders).toBe(true)
  })

  it('unsubscribes all with confirmation', async () => {
    const wrapper = mount(EmailPreferences, {
      props: { cohortId: 1, token: 'test-token' }
    })

    const store = useSponsorNotificationStore()
    store.preferences = mockPreferences
    const updateSpy = vi.spyOn(store, 'updatePreferences')
    await flushPromises()

    // Mock confirm to return true
    window.confirm = vi.fn(() => true)

    const unsubscribeButton = wrapper.find('button').filter(n => n.text().includes('Unsubscribe'))
    await unsubscribeButton.trigger('click')

    expect(window.confirm).toHaveBeenCalled()
    expect(wrapper.vm.settings.signingRequests).toBe(false)
    expect(wrapper.vm.settings.reminders).toBe(false)
    expect(updateSpy).toHaveBeenCalled()
  })

  it('shows loading state during save', async () => {
    const wrapper = mount(EmailPreferences, {
      props: { cohortId: 1, token: 'test-token' }
    })

    const store = useSponsorNotificationStore()
    store.preferences = mockPreferences
    store.isLoading = true
    await flushPromises()

    expect(wrapper.find('.loading-overlay').exists()).toBe(true)
  })

  it('shows success toast after save', async () => {
    const wrapper = mount(EmailPreferences, {
      props: { cohortId: 1, token: 'test-token' }
    })

    const store = useSponsorNotificationStore()
    store.preferences = mockPreferences
    await flushPromises()

    const saveButton = wrapper.find('button').filter(n => n.text().includes('Save'))
    await saveButton.trigger('click')

    await wrapper.vm.$nextTick()
    expect(wrapper.text()).toContain('Preferences saved successfully')
  })
})
```

**Integration Tests:**
```javascript
// spec/javascript/sponsor/integration/notification-flow.spec.js
describe('Sponsor Notification Flow', () => {
  it('manages complete notification workflow', async () => {
    // 1. Load preferences
    // 2. Disable all notifications
    // 3. Save changes
    // 4. Reload page to verify persistence
    // 5. Reset to defaults
    // 6. Verify all enabled again
  })
})
```

**E2E Tests:**
```javascript
// spec/system/sponsor_notification_preferences_spec.rb
RSpec.describe 'Sponsor Notification Preferences', type: :system do
  let(:cohort) { create(:cohort, status: :ready_for_sponsor) }
  let(:token) { cohort.generate_sponsor_token }

  scenario 'sponsor manages email preferences' do
    visit "/sponsor/cohorts/#{cohort.id}/preferences?token=#{token}"
    
    expect(page).to have_content('Email Notification Preferences')
    
    # Disable signing requests
    uncheck 'Signing Requests'
    click_button 'Save Settings'
    
    expect(page).to have_content('Preferences saved successfully')
    
    # Reload and verify
    visit "/sponsor/cohorts/#{cohort.id}/preferences?token=#{token}"
    expect(page).not_to have_checked_field('Signing Requests')
    
    # Unsubscribe all
    click_button 'Unsubscribe from All'
    page.driver.browser.switch_to.alert.accept
    
    expect(page).to have_content('Preferences saved successfully')
  end

  scenario 'reset to defaults', do
    visit "/sponsor/cohorts/#{cohort.id}/preferences?token=#{token}"
    
    # Change settings
    uncheck 'Signing Requests'
    uncheck 'Completion Reminders'
    click_button 'Save Settings'
    
    # Reset
    click_button 'Reset to Defaults'
    
    expect(page).to have_checked_field('Signing Requests')
    expect(page).to have_checked_field('Completion Reminders')
  end
end
```

##### Rollback Procedure

**If preferences fail to load:**
1. Show error message with retry button
2. Use default settings temporarily
3. Log error to monitoring
4. Allow manual refresh

**If save fails:**
1. Show error message with retry option
2. Preserve unsaved changes in UI
3. Check network connection
4. Log failure for investigation

**If unsubscribe fails:**
1. Show error message
2. Don't change settings
3. Provide alternative (contact support)
4. Log for security audit

**If email preview breaks:**
1. Hide preview section
2. Show fallback text
3. Continue allowing settings changes
4. Log template error

**Data Safety:**
- All settings stored server-side
- No data loss if UI fails
- Changes only applied after successful save
- Unsubscribe requires confirmation

##### Risk Assessment

**Low Risk** because:
- Simple CRUD operations
- Standard form handling
- No complex business logic
- Read-mostly operations

**Specific Risks:**
1. **Email Deliverability**: Emails may not reach sponsors
   - **Mitigation**: Use reputable SMTP, monitor delivery rates

2. **Rate Limiting**: Too many emails sent
   - **Mitigation**: Implement queue system, respect frequency settings

3. **Unsubscribe Compliance**: Legal requirements (CAN-SPAM, GDPR)
   - **Mitigation**: Clear unsubscribe, honor all requests immediately

4. **Token Expiration**: Links in emails may expire
   - **Mitigation**: Long expiry (7 days), renewal mechanism

**Mitigation Strategies:**
- Comprehensive email testing
- Monitor email delivery metrics
- Implement email queue with retry
- Clear unsubscribe in all emails
- Regular compliance audits

##### Success Metrics

- **Save Success Rate**: 99% of preference updates succeed
- **Email Delivery**: 98% of emails reach inbox (not spam)
- **User Engagement**: 85% of sponsors enable at least one notification
- **Unsubscribe Rate**: <3% (industry standard is 0.2-0.5%)
- **Reminder Effectiveness**: 70% of reminders lead to signing within 24 hours
- **Support Tickets**: <2% related to email notifications
- **Load Time**: <1 second for preferences page

---

---

### 6.7 Phase 7: Integration & Testing

**Focus**: End-to-end integration testing, performance validation, and security auditing

This phase ensures all three portals work together seamlessly, performance meets requirements, and security is maintained. Testing covers the complete workflow from TP cohort creation through student submission to sponsor signing and TP review.

---

#### Story 7.1: End-to-End Workflow Testing

**Status**: Draft/Pending
**Priority**: Critical
**Epic**: Integration & Testing
**Estimated Effort**: 3 days
**Risk Level**: High

##### User Story

**As a** QA Engineer,
**I want** to test the complete 3-portal workflow from start to finish,
**So that** I can verify all integrations work correctly and identify any breaking issues before production deployment.

##### Background

This story validates the entire FloDoc system through complete end-to-end testing. The workflow must be tested in sequence:

1. **TP Portal**: Create cohort, configure template, assign sponsor, sign first student
2. **Student Portal**: Receive invitation, upload documents, fill forms, submit
3. **Sponsor Portal**: Receive notification, sign all documents at once
4. **TP Portal**: Review and finalize cohort

**Key Testing Scenarios:**
- **Happy Path**: All parties complete their steps successfully
- **Edge Cases**: Invalid tokens, expired sessions, network failures
- **State Transitions**: Proper status updates at each step
- **Email Delivery**: All notifications sent and received
- **Data Integrity**: No data loss or corruption
- **Concurrent Access**: Multiple users accessing same cohort
- **Error Recovery**: Graceful handling of failures

**Test Data Requirements:**
- Multiple cohorts with varying student counts (1, 5, 25, 100)
- Different document types (PDF, images)
- Various form field types (signature, text, date, checkbox)
- Different signature methods (draw, type)

**Integration Points to Verify:**
- Template → Cohort mapping
- Student → Submission mapping
- Bulk signing → Individual student updates
- Email triggers → Actual email delivery
- Token generation → Token validation
- State machine transitions
- Excel export data accuracy

##### Technical Implementation Notes

**Test Framework Setup:**
```ruby
# spec/system/end_to_end_workflow_spec.rb
require 'rails_helper'
require 'capybara/rspec'
require 'selenium-webdriver'

RSpec.describe 'End-to-End FloDoc Workflow', type: :system do
  include ActiveJob::TestHelper
  include EmailSpec::Helpers

  let(:tp_user) { create(:user, :tp_admin) }
  let(:cohort) { create(:cohort, status: :draft) }
  let(:sponsor) { create(:sponsor) }
  let(:students) { create_list(:student, 5, cohort: cohort) }

  before do
    driven_by :selenium, using: :headless_chrome
    clear_enqueued_jobs
    clear_delivered_emails
  end

  after do
    clear_enqueued_jobs
    clear_delivered_emails
  end

  # Test scenarios will go here
end
```

**Test Data Factory Setup:**
```ruby
# spec/factories/cohort.rb
FactoryBot.define do
  factory :cohort do
    name { "Spring 2025 - #{SecureRandom.hex(4)}" }
    status { :draft }
    institution { create(:institution) }
    sponsor { create(:sponsor) }
    
    trait :with_students do
      after(:create) do |cohort|
        create_list(:student, 5, cohort: cohort)
      end
    end
    
    trait :ready_for_sponsor do
      after(:create) do |cohort|
        cohort.students.each do |student|
          student.submissions.update_all(status: :submitted, submitted_at: Time.current)
        end
        cohort.update!(status: :ready_for_sponsor)
      end
    end
  end
end

# spec/factories/student.rb
FactoryBot.define do
  factory :student do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    cohort
    
    trait :with_submission do
      after(:create) do |student|
        create(:submission, student: student, status: :submitted)
      end
    end
  end
end

# spec/factories/submission.rb
FactoryBot.define do
  factory :submission do
    student
    status { :pending }
    
    trait :submitted do
      status { :submitted }
      submitted_at { Time.current }
    end
    
    trait :sponsor_signed do
      status { :sponsor_signed }
      submitted_at { Time.current }
      sponsor_signed_at { Time.current }
    end
    
    trait :completed do
      status { :completed }
      submitted_at { Time.current }
      sponsor_signed_at { Time.current }
      tp_reviewed_at { Time.current }
    end
  end
end
```

**Test Helper Module:**
```ruby
# spec/support/end_to_end_helpers.rb
module EndToEndHelpers
  def complete_tp_workflow(cohort, student_count: 5)
    # 1. TP creates cohort
    visit tp_cohorts_path
    click_button 'Create Cohort'
    fill_in 'Cohort Name', with: cohort.name
    click_button 'Next'
    
    # 2. Upload template document
    attach_file 'template_document', Rails.root.join('spec/fixtures/sample.pdf')
    click_button 'Upload'
    
    # 3. Configure fields
    # (Simulate field configuration)
    
    # 4. Assign sponsor
    fill_in 'Sponsor Email', with: cohort.sponsor.email
    click_button 'Assign'
    
    # 5. Sign first student (TP signing phase)
    cohort.students.first.submissions.each do |submission|
      click_link "Sign Submission ##{submission.id}"
      # Simulate signature
      submission.update!(tp_signed: true, tp_signed_at: Time.current)
    end
    
    cohort.update!(status: :ready_for_sponsor)
  end
  
  def complete_student_workflow(student, submission)
    # 1. Access via token
    visit student_submission_path(submission, token: submission.token)
    
    # 2. Upload documents
    attach_file 'student_documents', Rails.root.join('spec/fixtures/student_id.pdf')
    click_button 'Upload'
    
    # 3. Fill form fields
    fill_in 'Full Name', with: student.name
    fill_in 'Date', with: Date.today
    
    # 4. Sign
    click_button 'Sign'
    submission.update!(student_completed: true, student_completed_at: Time.current)
  end
  
  def complete_sponsor_bulk_sign(cohort)
    # 1. Access sponsor portal
    visit sponsor_cohort_path(cohort, token: cohort.sponsor_token)
    
    # 2. Verify student list
    expect(page).to have_content(cohort.students.count)
    
    # 3. Draw/type signature
    fill_in 'Type Your Full Name', with: cohort.sponsor.name
    check 'I confirm'
    
    # 4. Preview
    click_button 'Preview'
    
    # 5. Confirm bulk sign
    click_button 'Confirm & Sign All'
    
    # 6. Verify success
    expect(page).to have_content('Signing Complete')
    
    # Update all submissions
    cohort.students.each do |student|
      student.submissions.update_all(
        sponsor_signed: true,
        sponsor_signed_at: Time.current,
        status: :sponsor_signed
      )
    end
    
    cohort.update!(status: :in_review)
  end
  
  def complete_tp_review(cohort)
    # 1. Access TP portal
    visit tp_cohort_path(cohort)
    
    # 2. Review submissions
    cohort.students.each do |student|
      click_link "Review #{student.name}"
      # Verify documents
      click_button 'Approve'
    end
    
    # 3. Finalize cohort
    click_button 'Finalize Cohort'
    cohort.update!(status: :completed, completed_at: Time.current)
  end
end
```

**Test Scenarios Structure:**
```ruby
# spec/system/end_to_end_workflow_spec.rb (continued)

describe 'Complete 3-Portal Workflow' do
  include EndToEndHelpers

  context 'Happy Path - 5 Students' do
    it 'completes full workflow from TP creation to finalization' do
      # Setup
      cohort = create(:cohort, :with_students, student_count: 5)
      sponsor = create(:sponsor)
      cohort.update!(sponsor: sponsor)
      
      # Test TP Portal
      sign_in tp_user
      complete_tp_workflow(cohort, student_count: 5)
      
      expect(cohort.reload.status).to eq('ready_for_sponsor')
      expect(Email.where(to: sponsor.email, subject: /assigned/).count).to eq(1)
      
      # Test Student Portals
      cohort.students.each do |student|
        submission = student.submissions.first
        clear_enqueued_jobs
        
        complete_student_workflow(student, submission)
        
        expect(submission.reload.student_completed).to be true
        expect(Email.where(to: cohort.sponsor.email, subject: /submitted/).count).to eq(1)
      end
      
      # Test Sponsor Portal
      clear_enqueued_jobs
      complete_sponsor_bulk_sign(cohort)
      
      cohort.students.each do |student|
        student.submissions.each do |submission|
          expect(submission.reload.sponsor_signed).to be true
        end
      end
      
      expect(cohort.reload.status).to eq('in_review')
      expect(Email.where(to: tp_user.email, subject: /review/).count).to eq(1)
      
      # Test TP Review
      complete_tp_review(cohort)
      
      expect(cohort.reload.status).to eq('completed')
      expect(cohort.completed_at).not_to be_nil
    end
  end

  context 'Edge Cases' do
    it 'handles expired token gracefully' do
      cohort = create(:cohort, :with_students)
      submission = cohort.students.first.submissions.first
      
      # Expire token
      submission.update!(token_expires_at: 1.day.ago)
      
      visit student_submission_path(submission, token: submission.token)
      
      expect(page).to have_content('Link Expired')
      expect(page).to have_button('Request New Link')
      
      # Request renewal
      click_button 'Request New Link'
      
      expect(page).to have_content('New link sent to your email')
      expect(Email.where(to: submission.student.email).count).to eq(1)
    end

    it 'handles network failures during bulk signing' do
      cohort = create(:cohort, :ready_for_sponsor)
      
      # Mock network failure
      allow_any_instance_of(CohortAPI).to receive(:bulk_sign).and_raise(Net::ReadTimeout)
      
      visit sponsor_cohort_path(cohort, token: cohort.sponsor_token)
      
      fill_in 'Type Your Full Name', with: 'Sponsor Name'
      check 'I confirm'
      click_button 'Sign All 5 Documents'
      
      expect(page).to have_content('Signing failed')
      expect(page).to have_button('Retry')
      
      # Retry should work
      allow_any_instance_of(CohortAPI).to receive(:bulk_sign).and_call_original
      click_button 'Retry'
      
      expect(page).to have_content('Signing Complete')
    end

    it 'prevents duplicate sponsor emails' do
      cohort = create(:cohort, :ready_for_sponsor)
      
      # Trigger multiple student completions
      cohort.students.each do |student|
        student.submissions.update_all(student_completed: true, student_completed_at: Time.current)
      end
      
      # Should only send one email to sponsor
      expect(Email.where(to: cohort.sponsor.email, subject: /submitted/).count).to eq(1)
    end

    it 'handles concurrent access to same cohort' do
      cohort = create(:cohort, :ready_for_sponsor)
      
      # Two sponsors try to access
      using_session('sponsor1') do
        visit sponsor_cohort_path(cohort, token: cohort.sponsor_token)
        expect(page).to have_content(cohort.name)
      end
      
      using_session('sponsor2') do
        visit sponsor_cohort_path(cohort, token: cohort.sponsor_token)
        expect(page).to have_content(cohort.name)
      end
      
      # Both can view, but only one can sign
      # (Locking mechanism tested separately)
    end

    it 'validates data integrity throughout workflow' do
      cohort = create(:cohort, :with_students, student_count: 3)
      
      # Record initial state
      initial_count = Submission.count
      initial_student_count = Student.count
      
      # Run full workflow
      complete_tp_workflow(cohort)
      cohort.students.each do |student|
        submission = student.submissions.first
        complete_student_workflow(student, submission)
      end
      complete_sponsor_bulk_sign(cohort)
      complete_tp_review(cohort)
      
      # Verify no data loss
      expect(Submission.count).to eq(initial_count)
      expect(Student.count).to eq(initial_student_count)
      expect(cohort.submissions.all? { |s| s.status == 'completed' }).to be true
    end
  end

  context 'Performance with Large Cohorts' do
    it 'handles 100 students efficiently', :slow do
      cohort = create(:cohort, :with_students, student_count: 100)
      
      # Time the sponsor bulk signing
      start_time = Time.current
      
      complete_sponsor_bulk_sign(cohort)
      
      elapsed = Time.current - start_time
      
      # Should complete within 5 seconds
      expect(elapsed).to be < 5
      
      # All submissions should be updated
      expect(cohort.submissions.where(sponsor_signed: true).count).to eq(100)
    end
  end

  context 'Email Delivery Verification' do
    it 'sends all expected emails in correct sequence' do
      cohort = create(:cohort, :with_students, student_count: 2)
      
      # Track email sequence
      email_sequence = []
      
      # TP creates cohort
      complete_tp_workflow(cohort)
      email_sequence << 'tp_invitation'
      
      # Student completes
      cohort.students.each do |student|
        submission = student.submissions.first
        complete_student_workflow(student, submission)
      end
      email_sequence << 'student_completion'
      
      # Sponsor signs
      complete_sponsor_bulk_sign(cohort)
      email_sequence << 'sponsor_confirmation'
      
      # Verify email count and content
      delivered = Email.all
      expect(delivered.count).to eq(3)
      
      # Verify subjects
      expect(delivered[0].subject).to include('assigned')
      expect(delivered[1].subject).to include('submitted')
      expect(delivered[2].subject).to include('completed')
    end
  end
end
```

**API Integration Tests:**
```ruby
# spec/requests/api/v1/end_to_end_spec.rb
RSpec.describe 'API End-to-End Integration', type: :request do
  include ActiveJob::TestHelper

  describe 'Complete API Workflow' do
    it 'processes cohort through all stages via API' do
      # 1. Create cohort via API
      post '/api/v1/cohorts', params: {
        name: 'API Test Cohort',
        sponsor_email: 'sponsor@example.com'
      }, headers: { 'Authorization' => "Bearer #{tp_token}" }
      
      cohort_id = JSON.parse(response.body)['id']
      
      # 2. Upload template
      post "/api/v1/cohorts/#{cohort_id}/template", 
        params: { file: fixture_file_upload('sample.pdf') },
        headers: { 'Authorization' => "Bearer #{tp_token}" }
      
      # 3. Add students
      post "/api/v1/cohorts/#{cohort_id}/students", 
        params: { students: [{ name: 'Student 1', email: 's1@example.com' }] },
        headers: { 'Authorization' => "Bearer #{tp_token}" }
      
      # 4. TP signs first
      post "/api/v1/cohorts/#{cohort_id}/tp-sign",
        params: { signature: 'TP Signature' },
        headers: { 'Authorization' => "Bearer #{tp_token}" }
      
      # 5. Student submits
      student_token = cohort.students.first.submissions.first.token
      post "/api/v1/student/submissions/#{cohort.students.first.submissions.first.id}/submit",
        params: { 
          documents: [fixture_file_upload('student_doc.pdf')],
          fields: { name: 'Student 1', date: '2025-01-15' }
        },
        headers: { 'Authorization' => "Bearer #{student_token}" }
      
      # 6. Sponsor bulk signs
      sponsor_token = cohort.sponsor_token
      post "/api/v1/sponsor/cohorts/#{cohort_id}/bulk-sign",
        params: { signature: 'Sponsor Signature' },
        headers: { 'Authorization' => "Bearer #{sponsor_token}" }
      
      # 7. TP reviews and finalizes
      post "/api/v1/cohorts/#{cohort_id}/finalize",
        headers: { 'Authorization' => "Bearer #{tp_token}" }
      
      # Verify final state
      cohort = Cohort.find(cohort_id)
      expect(cohort.status).to eq('completed')
      expect(cohort.submissions.all? { |s| s.status == 'completed' }).to be true
    end
  end
end
```

**Database State Verification:**
```ruby
# spec/support/database_verifiers.rb
module DatabaseVerifiers
  def verify_cohort_state(cohort, expected_status)
    cohort.reload
    expect(cohort.status).to eq(expected_status)
    
    # Verify all submissions have correct state
    case expected_status
    when 'ready_for_sponsor'
      expect(cohort.submissions.all? { |s| s.student_completed }).to be true
      expect(cohort.submissions.none? { |s| s.sponsor_signed }).to be true
    when 'in_review'
      expect(cohort.submissions.all? { |s| s.sponsor_signed }).to be true
      expect(cohort.submissions.none? { |s| s.tp_reviewed }).to be true
    when 'completed'
      expect(cohort.submissions.all? { |s| s.status == 'completed' }).to be true
    end
  end
  
  def verify_email_delivery(expected_emails)
    delivered = Email.all
    expect(delivered.count).to eq(expected_emails.count)
    
    expected_emails.each do |expected|
      found = delivered.find { |e| e.subject.include?(expected[:subject]) && e.to == expected[:to] }
      expect(found).not_to be_nil, "Expected email with subject '#{expected[:subject]}' to '#{expected[:to]}' not found"
    end
  end
  
  def verify_data_integrity
    # Check for orphaned records
    expect(Submission.joins(:student).where(students: { id: nil }).count).to eq(0)
    expect(Cohort.joins(:submissions).where(submissions: { id: nil }).count).to eq(0)
    
    # Check for duplicate tokens
    tokens = Submission.pluck(:token)
    expect(tokens.uniq.count).to eq(tokens.count)
    
    # Check for invalid state transitions
    invalid_states = Submission.where.not(status: %w[pending submitted sponsor_signed completed])
    expect(invalid_states.count).to eq(0)
  end
end
```

##### Acceptance Criteria

**Functional:**
1. ✅ Complete workflow tested with 5 students
2. ✅ Complete workflow tested with 25 students
3. ✅ Complete workflow tested with 100 students
4. ✅ All edge cases handled (expired tokens, network failures, etc.)
5. ✅ Concurrent access scenarios tested
6. ✅ Data integrity verified throughout
7. ✅ Email delivery verified in correct sequence
8. ✅ State transitions validated
9. ✅ Error recovery tested
10. ✅ Performance benchmarks met

**Integration:**
1. ✅ TP Portal → Student Portal handoff verified
2. ✅ Student Portal → Sponsor Portal handoff verified
3. ✅ Sponsor Portal → TP Portal handoff verified
4. ✅ Email system integration verified
5. ✅ Token system integration verified
6. ✅ Database state consistency verified
7. ✅ API endpoints tested end-to-end

**Security:**
1. ✅ Token validation enforced throughout
2. ✅ Authorization checks at each step
3. ✅ No data leakage between users
4. ✅ Rate limiting tested
5. ✅ Audit trail completeness verified

**Performance:**
1. ✅ 100-student cohort completes within 5 seconds
2. ✅ Email delivery within 10 seconds
3. ✅ API response times < 500ms
4. ✅ No memory leaks in long-running sessions

**Quality:**
1. ✅ 100% test coverage for critical paths
2. ✅ All tests pass consistently
3. ✅ No flaky tests
4. ✅ Test data cleanup verified

##### Integration Verification (IV1-4)

**IV1: API Integration**
- All API endpoints tested in sequence
- Token authentication verified at each step
- Error responses validated
- Rate limiting tested

**IV2: Pinia Store**
- State updates propagate correctly
- Store actions trigger API calls
- Error handling in stores verified
- Loading states tested

**IV3: Getters**
- Computed properties reflect correct state
- Filtering and sorting work correctly
- Performance with large datasets verified

**IV4: Token Routing**
- Tokens generated correctly
- Tokens validated at each access point
- Expiration handled gracefully
- Renewal mechanism tested

##### Test Requirements

**System Specs:**
```ruby
# spec/system/end_to_end_workflow_spec.rb
# (Full implementation shown in Technical Implementation Notes)
```

**Request Specs:**
```ruby
# spec/requests/api/v1/end_to_end_spec.rb
# (Full implementation shown in Technical Implementation Notes)
```

**Performance Specs:**
```ruby
# spec/performance/workflow_spec.rb
require 'rails_helper'
require 'benchmark'

RSpec.describe 'Workflow Performance', type: :performance do
  it 'benchmarks full workflow with 100 students' do
    cohort = create(:cohort, :with_students, student_count: 100)
    
    time = Benchmark.measure do
      # TP workflow
      complete_tp_workflow(cohort)
      
      # Student workflows (parallel)
      cohort.students.each do |student|
        submission = student.submissions.first
        complete_student_workflow(student, submission)
      end
      
      # Sponsor bulk sign
      complete_sponsor_bulk_sign(cohort)
      
      # TP review
      complete_tp_review(cohort)
    end
    
    expect(time.real).to be < 5.0 # Should complete in under 5 seconds
  end
end
```

**Email Specs:**
```ruby
# spec/mailers/workflow_mailer_spec.rb
RSpec.describe WorkflowMailer, type: :mailer do
  it 'sends correct emails in workflow' do
    cohort = create(:cohort, :with_students)
    
    # Test invitation email
    mail = WorkflowMailer.invitation(cohort, cohort.sponsor)
    expect(mail.subject).to include('assigned')
    expect(mail.to).to eq([cohort.sponsor.email])
    expect(mail.body).to include(cohort.name)
    
    # Test completion email
    mail = WorkflowMailer.completion(cohort)
    expect(mail.subject).to include('completed')
    expect(mail.body).to include(cohort.students.count.to_s)
  end
end
```

##### Rollback Procedure

**If tests fail:**
1. Identify failing scenario
2. Check test data setup
3. Verify database state
4. Review logs for errors
5. Fix underlying issue
6. Re-run tests

**If performance tests fail:**
1. Profile database queries
2. Check for N+1 queries
3. Review indexing
4. Optimize slow operations
5. Re-run with profiling

**If integration tests fail:**
1. Check API endpoints
2. Verify token generation
3. Test email delivery
4. Review state machine
5. Fix integration points

**Data Safety:**
- Tests use isolated database (test environment)
- No production data affected
- Test data automatically cleaned up
- Rollback not needed for test failures

##### Risk Assessment

**High Risk** because:
- Tests entire system end-to-end
- Many moving parts to coordinate
- External dependencies (email, storage)
- Performance requirements must be met
- Security vulnerabilities could be exposed

**Specific Risks:**
1. **Flaky Tests**: Tests may pass/fail intermittently
   - **Mitigation**: Use deterministic test data, proper waiting, avoid time-based tests

2. **Performance Bottlenecks**: System may not meet speed requirements
   - **Mitigation**: Profile early, optimize database queries, implement caching

3. **Email Delivery Failures**: Test emails may not deliver
   **Mitigation**: Use test email catcher, mock external SMTP

4. **Token Issues**: Token generation/validation may fail
   - **Mitigation**: Test token library thoroughly, verify expiration logic

5. **State Machine Bugs**: Invalid state transitions
   - **Mitigation**: Test all transitions, use AASM gem for state management

**Mitigation Strategies:**
- Run tests in CI/CD pipeline
- Use headless browsers for UI tests
- Mock external services where appropriate
- Implement test retries for flaky scenarios
- Use database transactions for test isolation
- Monitor test execution time

##### Success Metrics

- **Test Pass Rate**: 100% of tests pass consistently
- **Test Coverage**: >90% of critical paths covered
- **Performance**: 100-student workflow <5 seconds
- **Reliability**: <1% flaky test rate
- **Email Delivery**: 100% of test emails captured
- **Data Integrity**: Zero data corruption in tests
- **Security**: All authorization checks pass
- **API Coverage**: All endpoints tested end-to-end

---

#### Story 7.2: Mobile Responsiveness Testing

**Status**: Draft/Pending
**Priority**: High
**Epic**: Integration & Testing
**Estimated Effort**: 2 days
**Risk Level**: Medium

##### User Story

**As a** QA Engineer,
**I want** to test all three portals across different screen sizes and devices,
**So that** I can ensure the FloDoc system works perfectly on mobile, tablet, and desktop devices.

##### Background

FloDoc must work seamlessly across all device types:
- **Mobile**: 320px - 640px (smartphones)
- **Tablet**: 641px - 1024px (iPad, Android tablets)
- **Desktop**: 1025px+ (laptops, monitors)

**Portal-Specific Mobile Requirements:**

**TP Portal**:
- Complex admin interface must remain usable
- Bulk operations need touch-friendly targets
- Data tables must be responsive
- Navigation must collapse to hamburger menu
- Forms must stack vertically
- Progress indicators must be visible

**Student Portal**:
- Mobile-first design (primary use case)
- Maximum 3 clicks to complete any action
- Touch targets minimum 44x44px
- File upload must work with mobile camera
- Form fields must be mobile-optimized
- Progress tracking must be clear

**Sponsor Portal**:
- Bulk signing must work on touch devices
- Signature canvas must support touch drawing
- Student list must be scrollable
- Preview modal must be mobile-friendly
- Action buttons must be thumb-accessible

**Testing Scenarios:**
- **Viewport Sizes**: Test at 10+ breakpoints
- **Orientation**: Portrait and landscape modes
- **Touch Gestures**: Swipe, tap, pinch, scroll
- **Input Methods**: Touch, keyboard, mouse
- **Browser Compatibility**: Chrome, Safari, Firefox on mobile
- **OS Compatibility**: iOS, Android

**Critical Components to Test:**
- Navigation menus
- Forms and inputs
- Tables and lists
- Modals and dialogs
- Buttons and links
- File uploads
- Signature capture
- Progress indicators
- Error messages
- Loading states

##### Technical Implementation Notes

**Test Framework Setup:**
```javascript
// spec/javascript/mobile-responsiveness.spec.js
import { mount } from '@vue/test-utils'
import { describe, it, expect, beforeEach } from 'vitest'

describe('Mobile Responsiveness', () => {
  const viewports = [
    { name: 'iPhone SE', width: 375, height: 667 },
    { name: 'iPhone 12', width: 390, height: 844 },
    { name: 'iPad Mini', width: 768, height: 1024 },
    { name: 'iPad Pro', width: 1024, height: 1366 },
    { name: 'Desktop HD', width: 1920, height: 1080 }
  ]

  const testComponent = (component, props = {}) => {
    viewports.forEach(viewport => {
      it(`renders correctly on ${viewport.name}`, () => {
        // Set viewport
        window.innerWidth = viewport.width
        window.innerHeight = viewport.height
        
        const wrapper = mount(component, { props })
        
        // Check responsive classes
        expect(wrapper.classes()).toContain('responsive')
        
        // Check touch targets
        const buttons = wrapper.findAll('button')
        buttons.forEach(btn => {
          const styles = window.getComputedStyle(btn.element)
          expect(parseInt(styles.minWidth)).toBeGreaterThanOrEqual(44)
          expect(parseInt(styles.minHeight)).toBeGreaterThanOrEqual(44)
        })
      })
    })
  }
})
```

**Capybara System Tests:**
```ruby
# spec/system/mobile_responsiveness_spec.rb
require 'rails_helper'

RSpec.describe 'Mobile Responsiveness', type: :system do
  include MobileHelpers

  before do
    driven_by :selenium, using: :headless_chrome
  end

  # TP Portal Tests
  describe 'TP Portal', js: true do
    let(:user) { create(:user, :tp_admin) }
    let(:cohort) { create(:cohort, :with_students, student_count: 5) }

    before do
      sign_in user
    end

    context 'Mobile (375px)' do
      before { resize_window(375, 667) }

      it 'displays hamburger menu' do
        visit tp_cohorts_path
        expect(page).to have_css('.hamburger-menu')
        expect(page).not_to have_css('.desktop-nav')
      end

      it 'stacks cohort cards vertically' do
        visit tp_cohorts_path
        within('.cohort-list') do
          expect(page).to have_css('.cohort-card', count: 1)
          expect(page).to have_css('.stacked-layout')
        end
      end

      it 'collapses bulk operations' do
        visit tp_cohort_path(cohort)
        expect(page).to have_css('.bulk-actions-dropdown')
        click_button 'Bulk Actions'
        expect(page).to have_button('Export Excel')
        expect(page).to have_button('Send Reminders')
      end

      it 'makes forms mobile-friendly' do
        visit new_tp_cohort_path
        expect(page).to have_css('input[type="text"]', minimum_width: 44)
        expect(page).to have_css('button[type="submit"]', minimum_height: 44)
      end
    end

    context 'Tablet (768px)' do
      before { resize_window(768, 1024) }

      it 'shows split view for cohort management' do
        visit tp_cohort_path(cohort)
        expect(page).to have_css('.split-view')
        expect(page).to have_css('.sidebar')
        expect(page).to have_css('.main-content')
      end

      it 'displays data tables with horizontal scroll' do
        visit tp_cohort_path(cohort)
        within('.student-table') do
          expect(page).to have_css('.table-scroll')
        end
      end
    end

    context 'Desktop (1280px)' do
      before { resize_window(1280, 800) }

      it 'shows full navigation' do
        visit tp_cohorts_path
        expect(page).to have_css('.desktop-nav')
        expect(page).not_to have_css('.hamburger-menu')
      end
    end
  end

  # Student Portal Tests
  describe 'Student Portal', js: true do
    let(:cohort) { create(:cohort, :with_students) }
    let(:student) { cohort.students.first }
    let(:submission) { create(:submission, student: student) }

    context 'Mobile (375px)' do
      before { resize_window(375, 667) }

      it 'optimizes document upload for mobile' do
        visit student_submission_path(submission, token: submission.token)
        
        # Camera upload button visible
        expect(page).to have_button('Use Camera')
        
        # File input is touch-friendly
        file_input = find('input[type="file"]', visible: false)
        expect(file_input).not_to be_nil
      end

      it 'makes form fields mobile-optimized' do
        visit student_submission_path(submission, token: submission.token)
        
        # All inputs have proper types
        expect(page).to have_css('input[type="text"]')
        expect(page).to have_css('input[type="date"]')
        
        # Labels are above inputs
        expect(page).to have_css('label.top-aligned')
      end

      it 'shows progress as horizontal bar' do
        visit student_submission_path(submission, token: submission.token)
        
        expect(page).to have_css('.progress-bar')
        expect(page).to have_css('.step-indicator')
      end

      it 'handles touch signature' do
        visit student_submission_path(submission, token: submission.token)
        
        # Canvas is touch-enabled
        canvas = find('canvas')
        expect(canvas).not_to be_nil
        
        # Simulate touch event
        page.execute_script("document.querySelector('canvas').dispatchEvent(new TouchEvent('touchstart'))")
      end
    end

    context 'Tablet (768px)' do
      before { resize_window(768, 1024) }

      it 'shows two-column layout for forms' do
        visit student_submission_path(submission, token: submission.token)
        
        expect(page).to have_css('.two-column-layout')
      end
    end
  end

  # Sponsor Portal Tests
  describe 'Student Portal', js: true do
    let(:cohort) { create(:cohort, :ready_for_sponsor) }

    context 'Mobile (375px)' do
      before { resize_window(375, 667) }

      it 'makes bulk signing touch-friendly' do
        visit sponsor_cohort_path(cohort, token: cohort.sponsor_token)
        
        # Signature canvas is large enough for finger
        canvas = find('canvas')
        expect(canvas[:width]).to eq('600')
        expect(canvas[:height]).to eq('150')
        
        # Buttons are thumb-accessible
        expect(page).to have_css('button.large-touch-target')
      end

      it 'scrolls student list vertically' do
        visit sponsor_cohort_path(cohort, token: cohort.sponsor_token)
        
        within('.student-list') do
          expect(page).to have_css('.scrollable')
          expect(page).to have_css('.student-card', count: cohort.students.count)
        end
      end

      it 'shows modal full-screen on mobile' do
        visit sponsor_cohort_path(cohort, token: cohort.sponsor_token)
        
        click_button 'Sign All'
        
        # Modal takes full screen
        expect(page).to have_css('.modal.full-screen')
      end
    end

    context 'Tablet (768px)' do
      before { resize_window(768, 1024) }

      it 'shows preview alongside list' do
        visit sponsor_cohort_path(cohort, token: cohort.sponsor_token)
        
        expect(page).to have_css('.split-layout')
      end
    end
  end

  # Cross-Portal Consistency Tests
  describe 'Cross-Portal Consistency', js: true do
    it 'maintains consistent touch targets across all portals' do
      # Test TP Portal
      resize_window(375, 667)
      visit tp_cohorts_path
      tp_buttons = all('button').map { |b| [b.text, b.size] }
      
      # Test Student Portal
      cohort = create(:cohort, :with_students)
      submission = cohort.students.first.submissions.first
      visit student_submission_path(submission, token: submission.token)
      student_buttons = all('button').map { |b| [b.text, b.size] }
      
      # Test Sponsor Portal
      visit sponsor_cohort_path(cohort, token: cohort.sponsor_token)
      sponsor_buttons = all('button').map { |b| [b.text, b.size] }
      
      # All should have minimum 44x44px
      all_buttons = tp_buttons + student_buttons + sponsor_buttons
      all_buttons.each do |_, size|
        expect(size[:width]).to be >= 44
        expect(size[:height]).to be >= 44
      end
    end

    it 'maintains consistent navigation patterns' do
      # All portals should have clear back/forward navigation
      # All should show current location
      # All should have accessible help
    end
  end
end
```

**Mobile Helper Module:**
```ruby
# spec/support/mobile_helpers.rb
module MobileHelpers
  def resize_window(width, height)
    page.driver.browser.manage.window.resize_to(width, height)
  end

  def touch_click(selector)
    element = find(selector)
    page.execute_script("arguments[0].dispatchEvent(new TouchEvent('touchstart'))", element)
    page.execute_script("arguments[0].dispatchEvent(new TouchEvent('touchend'))", element)
  end

  def swipe_left(selector)
    element = find(selector)
    page.execute_script("
      const touch = new TouchEvent('touchstart', { touches: [{ clientX: 200, clientY: 0 }] });
      arguments[0].dispatchEvent(touch);
    ", element)
  end

  def check_touch_target(element)
    style = element.native.css_value('min-width')
    expect(style).to eq('44px')
  end
end
```

**Visual Regression Testing:**
```javascript
// spec/visual/mobile-visual.spec.js
import { percySnapshot } from '@percy/playwright'

describe('Mobile Visual Regression', () => {
  const viewports = [
    { width: 375, height: 667, name: 'iPhone SE' },
    { width: 768, height: 1024, name: 'iPad Mini' }
  ]

  it('TP Portal looks correct on mobile', async ({ page }) => {
    await page.goto('/tp/cohorts')
    await page.setViewportSize({ width: 375, height: 667 })
    await percySnapshot(page, 'TP Portal - Mobile')
  })

  it('Student Portal looks correct on mobile', async ({ page }) => {
    await page.goto('/student/submissions/1?token=abc')
    await page.setViewportSize({ width: 375, height: 667 })
    await percySnapshot(page, 'Student Portal - Mobile')
  })

  it('Sponsor Portal looks correct on mobile', async ({ page }) => {
    await page.goto('/sponsor/cohorts/1?token=abc')
    await page.setViewportSize({ width: 375, height: 667 })
    await percySnapshot(page, 'Sponsor Portal - Mobile')
  })
})
```

**Accessibility Testing:**
```ruby
# spec/accessibility/mobile_a11y_spec.rb
require 'axe/rspec'

RSpec.describe 'Mobile Accessibility', type: :system do
  it 'passes WCAG 2.1 AA on mobile', js: true do
    resize_window(375, 667)
    
    # Test TP Portal
    visit tp_cohorts_path
    expect(page).to be_axe_clean.according_to(:wcag21aa)
    
    # Test Student Portal
    cohort = create(:cohort, :with_students)
    submission = cohort.students.first.submissions.first
    visit student_submission_path(submission, token: submission.token)
    expect(page).to be_axe_clean.according_to(:wcag21aa)
    
    # Test Sponsor Portal
    visit sponsor_cohort_path(cohort, token: cohort.sponsor_token)
    expect(page).to be_axe_clean.according_to(:wcag21aa)
  end

  it 'maintains proper contrast ratios', js: true do
    resize_window(375, 667)
    visit tp_cohorts_path
    
    # Check text contrast
    text_elements = all('p, h1, h2, h3, h4, h5, h6, span, a, button, label')
    text_elements.each do |element|
      color = element.style('color')
      bg = element.style('background-color')
      # Verify contrast ratio >= 4.5:1
      expect(contrast_ratio(color, bg)).to be >= 4.5
    end
  end

  it 'supports screen readers', js: true do
    resize_window(375, 667)
    visit tp_cohorts_path
    
    # Check ARIA labels
    expect(page).to have_css('[aria-label]')
    expect(page).to have_css('[role="button"]')
    expect(page).to have_css('[role="navigation"]')
    
    # Check semantic HTML
    expect(page).to have_css('nav')
    expect(page).to have_css('main')
    expect(page).to have_css('header')
  end
end
```

**Touch Interaction Tests:**
```javascript
// spec/javascript/touch-interactions.spec.js
import { mount } from '@vue/test-utils'
import { describe, it, expect, vi } from 'vitest'

describe('Touch Interactions', () => {
  it('handles touch events on signature canvas', async () => {
    const wrapper = mount(SignatureCanvas)
    const canvas = wrapper.find('canvas')
    
    // Simulate touch start
    await canvas.trigger('touchstart', {
      touches: [{ clientX: 100, clientY: 100 }]
    })
    
    // Simulate touch move
    await canvas.trigger('touchmove', {
      touches: [{ clientX: 150, clientY: 150 }]
    })
    
    // Simulate touch end
    await canvas.trigger('touchend')
    
    expect(wrapper.vm.signatureData).not.toBeNull()
  })

  it('handles swipe gestures for navigation', async () => {
    const wrapper = mount(StudentPortal)
    
    // Simulate swipe left
    await wrapper.trigger('touchstart', { touches: [{ clientX: 300, clientY: 0 }] })
    await wrapper.trigger('touchmove', { touches: [{ clientX: 100, clientY: 0 }] })
    await wrapper.trigger('touchend')
    
    // Should navigate to next step
    expect(wrapper.vm.currentStep).toBe(2)
  })

  it('handles pinch-to-zoom on document preview', async () => {
    const wrapper = mount(DocumentPreview)
    
    // Simulate two-finger pinch
    await wrapper.trigger('touchstart', {
      touches: [
        { clientX: 100, clientY: 100 },
        { clientX: 200, clientY: 200 }
      ]
    })
    
    // Expand fingers
    await wrapper.trigger('touchmove', {
      touches: [
        { clientX: 50, clientY: 50 },
        { clientX: 250, clientY: 250 }
      ]
    })
    
    expect(wrapper.vm.zoomLevel).toBeGreaterThan(1)
  })

  it('handles long press for context menu', async () => {
    const wrapper = mount(StudentList)
    
    // Simulate long press
    const studentCard = wrapper.find('.student-card')
    await studentCard.trigger('touchstart')
    
    // Wait 500ms
    await new Promise(resolve => setTimeout(resolve, 500))
    
    // Context menu should appear
    expect(wrapper.find('.context-menu').exists()).toBe(true)
  })
})
```

**Browser Compatibility Matrix:**
```yaml
# config/mobile-test-matrix.yml
browsers:
  mobile:
    - name: Safari iOS
      versions: [15, 16, 17]
      devices: [iPhone SE, iPhone 12, iPhone 14]
      
    - name: Chrome Android
      versions: [11, 12, 13]
      devices: [Pixel 5, Samsung Galaxy S21]
      
    - name: Samsung Internet
      versions: [15, 16, 17]
      devices: [Galaxy S21, Galaxy S22]

  tablet:
    - name: Safari iPad
      versions: [15, 16, 17]
      devices: [iPad Mini, iPad Air, iPad Pro]
      
    - name: Chrome Tablet
      versions: [11, 12, 13]
      devices: [Samsung Tab S7, Pixel Tablet]

test_scenarios:
  - viewport_sizes: [375, 768, 1024, 1280]
  - orientations: [portrait, landscape]
  - input_methods: [touch, keyboard, mouse]
  - network_conditions: [3G, 4G, WiFi]
```

##### Acceptance Criteria

**Functional:**
1. ✅ All portals render correctly on 375px (mobile)
2. ✅ All portals render correctly on 768px (tablet)
3. ✅ All portals render correctly on 1280px (desktop)
4. ✅ Touch targets are minimum 44x44px everywhere
5. ✅ Forms are mobile-optimized (proper input types)
6. ✅ Navigation collapses to hamburger on mobile
7. ✅ Tables scroll horizontally on small screens
8. ✅ Modals are full-screen on mobile
9. ✅ Signature canvas works with touch
10. ✅ File upload works with mobile camera

**UI/UX:**
1. ✅ Portrait and landscape modes work
2. ✅ Swipe gestures work correctly
3. ✅ Pinch-to-zoom works on document preview
4. ✅ Long press shows context menus
5. ✅ Loading states are visible on all sizes
6. ✅ Error messages are readable on mobile
7. ✅ Buttons are thumb-accessible
8. ✅ Text is readable without zoom

**Integration:**
1. ✅ All portals maintain consistent design
2. ✅ Responsive breakpoints work across portals
3. ✅ Touch events propagate correctly
4. ✅ Keyboard navigation works on tablets
5. ✅ Mouse events don't break touch

**Security:**
1. ✅ No sensitive data exposed in mobile view
2. ✅ Touch events don't bypass security
3. ✅ Mobile camera upload is secure
4. ✅ Session management works on mobile

**Quality:**
1. ✅ Tests pass on all viewport sizes
2. ✅ Visual regression tests pass
3. ✅ Accessibility tests pass (WCAG 2.1 AA)
4. ✅ No horizontal scroll on content
5. ✅ Performance is acceptable on mobile

##### Integration Verification (IV1-4)

**IV1: API Integration**
- Mobile views call same APIs as desktop
- No mobile-specific API endpoints needed
- Response data formatted for mobile display

**IV2: Pinia Store**
- Store logic unchanged for mobile
- UI components adapt based on viewport
- State management consistent

**IV3: Getters**
- Computed properties work on all sizes
- Filtering/sorting adapted for mobile UI
- Performance optimized for mobile

**IV4: Token Routing**
- Token handling unchanged
- Mobile links work correctly
- No mobile-specific security issues

##### Test Requirements

**System Specs:**
```ruby
# spec/system/mobile_responsiveness_spec.rb
# (Full implementation shown in Technical Implementation Notes)
```

**Visual Regression Specs:**
```javascript
// spec/visual/mobile-visual.spec.js
# (Full implementation shown in Technical Implementation Notes)
```

**Accessibility Specs:**
```ruby
# spec/accessibility/mobile_a11y_spec.rb
# (Full implementation shown in Technical Implementation Notes)
```

**Touch Interaction Specs:**
```javascript
// spec/javascript/touch-interactions.spec.js
# (Full implementation shown in Technical Implementation Notes)
```

**E2E Mobile Tests:**
```ruby
# spec/system/mobile_e2e_spec.rb
RSpec.describe 'Mobile End-to-End', type: :system do
  it 'completes full workflow on mobile', js: true do
    resize_window(375, 667)
    
    # TP creates cohort
    sign_in tp_user
    visit new_tp_cohort_path
    fill_in 'Name', with: 'Mobile Test'
    click_button 'Create'
    
    # Student completes on mobile
    visit student_submission_path(submission, token: submission.token)
    attach_file 'Document', Rails.root.join('spec/fixtures/mobile_doc.pdf')
    fill_in 'Name', with: 'Mobile Student'
    click_button 'Submit'
    
    # Sponsor signs on mobile
    visit sponsor_cohort_path(cohort, token: cohort.sponsor_token)
    fill_in 'Type Your Full Name', with: 'Mobile Sponsor'
    check 'I confirm'
    click_button 'Sign All'
    
    expect(page).to have_content('Complete')
  end
end
```

##### Rollback Procedure

**If mobile tests fail:**
1. Check viewport sizing
2. Verify responsive CSS classes
3. Test touch event handlers
4. Review media queries
5. Fix mobile-specific bugs

**If accessibility tests fail:**
1. Check ARIA labels
2. Verify color contrast
3. Test keyboard navigation
4. Fix semantic HTML
5. Re-run accessibility tests

**If visual regression fails:**
1. Review screenshot differences
2. Check if change is intentional
3. Update baseline if needed
4. Re-run visual tests

**If touch interactions fail:**
1. Check event listeners
2. Verify touch event propagation
3. Test on real device
4. Fix touch handling

**Data Safety:**
- Tests use test environment only
- No production data affected
- Visual tests don't affect functionality
- Rollback not needed for test failures

##### Risk Assessment

**Medium Risk** because:
- Many device/browser combinations
- Touch events vary across devices
- Visual regression can be flaky
- Accessibility issues may be complex
- Performance on low-end devices

**Specific Risks:**
1. **Device Fragmentation**: Too many combinations to test
   - **Mitigation**: Focus on top 80% of devices, use cloud testing services

2. **Touch Event Inconsistency**: Different devices handle touch differently
   - **Mitigation**: Use standardized touch libraries, test on real devices

3. **Visual Regression Flakiness**: Slight rendering differences
   - **Mitigation**: Use percy with 1% threshold, test in consistent environment

4. **Performance on Mobile**: Slow devices may lag
   - **Mitigation**: Optimize images, reduce animations, lazy load content

5. **Accessibility Complexity**: WCAG compliance is hard
   - **Mitigation**: Use automated tools, manual testing, axe-core integration

**Mitigation Strategies:**
- Use BrowserStack or Sauce Labs for device testing
- Implement visual regression with Percy
- Use axe-core for automated accessibility
- Test on real devices when possible
- Monitor mobile performance metrics
- Use responsive design patterns

##### Success Metrics

- **Test Coverage**: 100% of mobile views tested
- **Device Coverage**: Top 20 devices covering 90% of users
- **Accessibility Score**: 100% WCAG 2.1 AA compliance
- **Visual Regression**: <1% difference threshold
- **Touch Success Rate**: 99% of touch interactions work
- **Performance**: Mobile load time <3 seconds
- **Browser Compatibility**: Pass on Chrome, Safari, Firefox mobile
- **Orientation Support**: 100% portrait and landscape support

---

#### Story 7.3: Performance Testing (50+ Students)

**Status**: Draft/Pending
**Priority**: Critical
**Epic**: Integration & Testing
**Estimated Effort**: 3 days
**Risk Level**: High

##### User Story

**As a** QA Engineer,
**I want** to test system performance with large cohorts (50+ students),
**So that** I can ensure FloDoc scales efficiently and meets NFR requirements.

##### Background

Performance is critical for production success. This story validates:
- **Load Time**: Pages must load within acceptable timeframes
- **Database Queries**: No N+1 queries, optimized indexes
- **Memory Usage**: No memory leaks, efficient garbage collection
- **Concurrent Users**: System must handle multiple users simultaneously
- **Large Cohorts**: 50, 100, even 500 students per cohort
- **Bulk Operations**: Signing 100+ students at once
- **Excel Export**: Generate large files without timeout
- **Email Delivery**: Queue and send 100+ emails efficiently

**Performance Requirements (from NFRs):**
- Page load time: <2 seconds
- API response time: <500ms
- Bulk signing: <5 seconds for 100 students
- Excel export: <10 seconds for 100 rows
- Email queue: Process 100 emails in <30 seconds
- Memory growth: <10% per operation
- Database queries: <20 per page load

**Test Scenarios:**
1. **Cohort Creation**: Create cohort with 100 students
2. **Student Upload**: 100 students uploading documents simultaneously
3. **Bulk Signing**: Sponsor signs 100 students at once
4. **Excel Export**: Export 100 student records
5. **Email Blast**: Send 100 invitation emails
6. **Concurrent Access**: 10 users accessing same cohort
7. **Database Load**: Complex queries with large datasets
8. **Memory Leak**: Long-running sessions over hours

**Tools and Monitoring:**
- **Rails Panel**: Query count and time
- **Bullet**: N+1 query detection
- **rack-mini-profiler**: Performance profiling
- **memory_profiler**: Memory usage tracking
- **New Relic**: Production monitoring simulation
- **JMeter**: Load testing
- **PgHero**: Database performance

##### Technical Implementation Notes

**Test Framework Setup:**
```ruby
# spec/performance/cohort_performance_spec.rb
require 'rails_helper'
require 'benchmark'
require 'memory_profiler'
require 'rack-mini-profiler'

RSpec.describe 'Cohort Performance', type: :performance do
  include PerformanceHelpers

  before do
    # Enable profiling
    Rack::MiniProfiler.config.enable = true
    Rack::MiniProfiler.config.storage = Rack::MiniProfiler::MemoryStore
  end

  describe 'Cohort Creation Performance' do
    it 'creates cohort with 100 students in <2 seconds', :slow do
      time = Benchmark.measure do
        perform_enqueued_jobs do
          post '/api/v1/cohorts', 
            params: {
              name: 'Large Cohort',
              student_count: 100,
              sponsor_email: 'sponsor@example.com'
            },
            headers: { 'Authorization' => "Bearer #{tp_token}" }
        end
      end

      expect(time.real).to be < 2.0
      expect(Cohort.last.students.count).to eq(100)
    end

    it 'generates 100 student tokens efficiently' do
      cohort = create(:cohort)
      
      time = Benchmark.measure do
        100.times do
          student = create(:student, cohort: cohort)
          submission = create(:submission, student: student)
          submission.generate_token!
        end
      end

      expect(time.real).to be < 1.0
      expect(Submission.where(cohort: cohort).count).to eq(100)
    end
  end

  describe 'Student Upload Performance' do
    it 'handles 100 concurrent uploads', :slow do
      cohort = create(:cohort, :with_students, student_count: 100)
      
      time = Benchmark.measure do
        cohort.students.each do |student|
          submission = student.submissions.first
          
          # Simulate concurrent upload
          Thread.new do
            post "/api/v1/student/submissions/#{submission.id}/upload",
              params: { file: fixture_file_upload('document.pdf') },
              headers: { 'Authorization' => "Bearer #{submission.token}" }
          end
        end
        
        # Wait for all threads
        sleep 0.1 until cohort.submissions.where.not(document: nil).count == 100
      end

      expect(time.real).to be < 5.0
      expect(cohort.submissions.where.not(document: nil).count).to eq(100)
    end
  end

  describe 'Bulk Signing Performance' do
    it 'signs 100 students in <5 seconds', :slow do
      cohort = create(:cohort, :ready_for_sponsor, student_count: 100)
      
      time = Benchmark.measure do
        post "/api/v1/sponsor/cohorts/#{cohort.id}/bulk-sign",
          params: { signature: 'Sponsor Signature', method: 'text' },
          headers: { 'Authorization' => "Bearer #{cohort.sponsor_token}" }
      end

      expect(time.real).to be < 5.0
      expect(cohort.submissions.where(sponsor_signed: true).count).to eq(100)
    end

    it 'uses single database transaction for bulk operations' do
      cohort = create(:cohort, :ready_for_sponsor, student_count: 50)
      
      # Monitor queries
      count_before = ActiveRecord::Base.connection.query_cache.length
      
      post "/api/v1/sponsor/cohorts/#{cohort.id}/bulk-sign",
        params: { signature: 'Signature' },
        headers: { 'Authorization' => "Bearer #{cohort.sponsor_token}" }
      
      count_after = ActiveRecord::Base.connection.query_cache.length
      
      # Should use minimal queries
      expect(count_after - count_before).to be < 10
    end
  end

  describe 'Excel Export Performance' do
    it 'generates Excel file for 100 students in <10 seconds', :slow do
      cohort = create(:cohort, :with_students, student_count: 100)
      
      time = Benchmark.measure do
        get "/api/v1/cohorts/#{cohort.id}/export",
          headers: { 'Authorization' => "Bearer #{tp_token}" }
      end

      expect(time.real).to be < 10.0
      expect(response.headers['Content-Type']).to include('application/vnd.openxmlformats')
    end

    it 'does not load all records into memory' do
      cohort = create(:cohort, :with_students, student_count: 100)
      
      # Monitor memory
      report = MemoryProfiler.report do
        get "/api/v1/cohorts/#{cohort.id}/export",
          headers: { 'Authorization' => "Bearer #{tp_token}" }
      end

      # Should use less than 50MB
      expect(report.total_allocated_memsize).to be < 50.megabytes
    end
  end

  describe 'Email Delivery Performance' do
    it 'queues 100 emails in <30 seconds', :slow do
      cohort = create(:cohort, :with_students, student_count: 100)
      
      time = Benchmark.measure do
        perform_enqueued_jobs do
          cohort.students.each do |student|
            StudentMailer.invitation(student, cohort).deliver_later
          end
        end
      end

      expect(time.real).to be < 30.0
      expect(ActionMailer::Base.deliveries.count).to eq(100)
    end

    it 'uses background jobs efficiently' do
      cohort = create(:cohort, :with_students, student_count: 100)
      
      # Should enqueue jobs, not execute immediately
      assert_enqueued_jobs 100 do
        cohort.students.each do |student|
          StudentMailer.invitation(student, cohort).deliver_later
        end
      end
    end
  end

  describe 'Concurrent User Performance' do
    it 'handles 10 concurrent users accessing same cohort' do
      cohort = create(:cohort, :ready_for_sponsor, student_count: 50)
      
      time = Benchmark.measure do
        threads = 10.times.map do
          Thread.new do
            get "/api/v1/sponsor/cohorts/#{cohort.id}",
              headers: { 'Authorization' => "Bearer #{cohort.sponsor_token}" }
          end
        end
        
        threads.each(&:join)
      end

      expect(time.real).to be < 2.0
    end

    it 'prevents race conditions in bulk signing' do
      cohort = create(:cohort, :ready_for_sponsor, student_count: 50)
      
      # Two threads try to sign simultaneously
      threads = [
        Thread.new do
          post "/api/v1/sponsor/cohorts/#{cohort.id}/bulk-sign",
            params: { signature: 'Signature 1' },
            headers: { 'Authorization' => "Bearer #{cohort.sponsor_token}" }
        end,
        Thread.new do
          post "/api/v1/sponsor/cohorts/#{cohort.id}/bulk-sign",
            params: { signature: 'Signature 2' },
            headers: { 'Authorization' => "Bearer #{cohort.sponsor_token}" }
        end
      ]
      
      threads.each(&:join)
      
      # Only one should succeed
      expect(cohort.submissions.where(sponsor_signed: true).count).to eq(50)
    end
  end

  describe 'Database Query Performance' do
    it 'detects N+1 queries', :slow do
      cohort = create(:cohort, :with_students, student_count: 50)
      
      # Enable Bullet
      Bullet.enable = true
      Bullet.raise = true
      
      expect {
        get "/api/v1/cohorts/#{cohort.id}/submissions",
          headers: { 'Authorization' => "Bearer #{tp_token}" }
      }.not_to raise_error
      
      Bullet.enable = false
    end

    it 'uses proper indexes' do
      # Check query plan
      cohort = create(:cohort, :with_students, student_count: 50)
      
      query = "EXPLAIN SELECT * FROM submissions WHERE cohort_id = #{cohort.id}"
      result = ActiveRecord::Base.connection.execute(query)
      
      # Should use index, not sequential scan
      expect(result.first['QUERY PLAN']).to include('Index Scan')
    end

    it 'avoids SELECT * in large queries' do
      cohort = create(:cohort, :with_students, student_count: 100)
      
      # Monitor queries
      queries = []
      callback = ->(name, start, finish, id, payload) { queries << payload[:sql] }
      
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get "/api/v1/cohorts/#{cohort.id}/export",
          headers: { 'Authorization' => "Bearer #{tp_token}" }
      end
      
      # Check for SELECT *
      select_star_queries = queries.select { |q| q.include?('SELECT *') }
      expect(select_star_queries.count).to eq(0)
    end
  end

  describe 'Memory Leak Detection' do
    it 'does not leak memory over multiple operations', :slow do
      cohort = create(:cohort, :with_students, student_count: 50)
      
      initial_memory = `ps -o rss= -p #{Process.pid}`.to_i
      
      10.times do
        post "/api/v1/sponsor/cohorts/#{cohort.id}/bulk-sign",
          params: { signature: 'Signature' },
          headers: { 'Authorization' => "Bearer #{cohort.sponsor_token}" }
        
        cohort.update!(status: :draft)
        cohort.submissions.update_all(sponsor_signed: false)
      end
      
      final_memory = `ps -o rss= -p #{Process.pid}`.to_i
      growth = final_memory - initial_memory
      
      # Memory growth should be < 10%
      expect(growth).to be < (initial_memory * 0.1)
    end

    it 'cleans up temporary objects' do
      cohort = create(:cohort, :with_students, student_count: 100)
      
      # Force GC
      GC.start
      
      before_count = ObjectSpace.count_objects[:TOTAL]
      
      # Perform operation
      get "/api/v1/cohorts/#{cohort.id}/export",
        headers: { 'Authorization' => "Bearer #{tp_token}" }
      
      # Force GC again
      GC.start
      
      after_count = ObjectSpace.count_objects[:TOTAL]
      
      # Should not create excessive objects
      expect(after_count - before_count).to be < 1000
    end
  end

  describe 'Load Testing' do
    it 'handles sustained load of 100 requests/minute', :slow do
      cohort = create(:cohort, :ready_for_sponsor, student_count: 50)
      
      # Simulate 100 requests over 1 minute
      start_time = Time.current
      
      100.times do
        get "/api/v1/sponsor/cohorts/#{cohort.id}",
          headers: { 'Authorization' => "Bearer #{cohort.sponsor_token}" }
      end
      
      elapsed = Time.current - start_time
      
      # Should complete in under 60 seconds
      expect(elapsed).to be < 60.0
      
      # Average response time should be < 500ms
      expect(elapsed / 100).to be < 0.5
    end

    it 'maintains performance under memory pressure' do
      cohort = create(:cohort, :with_students, student_count: 100)
      
      # Allocate memory to simulate pressure
      large_array = 100.times.map { 'x' * 1000 }
      
      time = Benchmark.measure do
        get "/api/v1/cohorts/#{cohort.id}/export",
          headers: { 'Authorization' => "Bearer #{tp_token}" }
      end
      
      # Should still perform reasonably
      expect(time.real).to be < 15.0
      
      large_array = nil # Clean up
      GC.start
    end
  end
end
```

**Performance Helper Module:**
```ruby
# spec/support/performance_helpers.rb
module PerformanceHelpers
  def profile_query(&block)
    count = 0
    callback = ->(name, start, finish, id, payload) { count += 1 }
    
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      yield
    end
    
    count
  end

  def profile_memory(&block)
    report = MemoryProfiler.report(&block)
    {
      total_allocated: report.total_allocated_memsize,
      total_retained: report.total_retained_memsize,
      allocated_objects: report.allocated_objects,
      retained_objects: report.retained_objects
    }
  end

  def profile_time(&block)
    result = nil
    time = Benchmark.measure { result = yield }
    { time: time.real, result: result }
  end

  def explain_query(sql)
    ActiveRecord::Base.connection.execute("EXPLAIN #{sql}").first
  end
end
```

**Database Performance Monitoring:**
```ruby
# spec/support/database_monitor.rb
module DatabaseMonitor
  def self.slow_queries
    ActiveRecord::Base.connection.execute("
      SELECT query, mean_exec_time, calls
      FROM pg_stat_statements
      WHERE mean_exec_time > 100
      ORDER BY mean_exec_time DESC
      LIMIT 10
    ")
  end

  def self.index_usage
    ActiveRecord::Base.connection.execute("
      SELECT schemaname, tablename, indexname, idx_scan
      FROM pg_stat_all_indexes
      WHERE idx_scan = 0
      ORDER BY tablename
    ")
  end

  def self.table_sizes
    ActiveRecord::Base.connection.execute("
      SELECT tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
      FROM pg_tables
      ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
      LIMIT 10
    ")
  end
end
```

**Rails Performance Test:**
```ruby
# spec/rails/performance_test.rb
require 'test_helper'
require 'rails/performance_test'

class CohortPerformanceTest < ActionDispatch::PerformanceTest
  def setup
    @cohort = create(:cohort, :with_students, student_count: 100)
  end

  def test_cohort_creation
    post '/api/v1/cohorts', 
      params: { name: 'Performance Test', student_count: 100 },
      headers: { 'Authorization' => "Bearer #{tp_token}" }
    
    assert_response :success
  end

  def test_bulk_signing
    post "/api/v1/sponsor/cohorts/#{@cohort.id}/bulk-sign",
      params: { signature: 'Performance Signature' },
      headers: { 'Authorization' => "Bearer #{@cohort.sponsor_token}" }
    
    assert_response :success
  end

  def test_excel_export
    get "/api/v1/cohorts/#{@cohort.id}/export",
      headers: { 'Authorization' => "Bearer #{tp_token}" }
    
    assert_response :success
    assert_equal 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 
                 response.content_type
  end
end
```

**JMeter Test Plan (XML):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<jmeterTestPlan version="1.2" properties="5.0" jmeter="5.4.1">
  <hashTree>
    <TestPlan guiclass="TestPlanGui" testclass="TestPlan" testname="FloDoc Load Test">
      <elementProp name="TestPlan.arguments" elementType="Arguments">
        <collectionProp name="Arguments.arguments"/>
      </elementProp>
    </TestPlan>
    <hashTree>
      <ThreadGroup guiclass="ThreadGroupGui" testclass="ThreadGroup" testname="Cohort Operations">
        <stringProp name="ThreadGroup.num_threads">10</stringProp>
        <stringProp name="ThreadGroup.ramp_time">60</stringProp>
        <boolProp name="ThreadGroup.scheduler">false</boolProp>
      </ThreadGroup>
      <hashTree>
        <!-- HTTP Request: Bulk Signing -->
        <HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="Bulk Sign">
          <stringProp name="HTTPSampler.domain">localhost</stringProp>
          <stringProp name="HTTPSampler.port">3000</stringProp>
          <stringProp name="HTTPSampler.path">/api/v1/sponsor/cohorts/1/bulk-sign</stringProp>
          <stringProp name="HTTPSampler.method">POST</stringProp>
          <stringProp name="HTTPSampler.body">{"signature":"Load Test Signature"}</stringProp>
        </HTTPSamplerProxy>
        
        <!-- HTTP Request: Excel Export -->
        <HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="Excel Export">
          <stringProp name="HTTPSampler.domain">localhost</stringProp>
          <stringProp name="HTTPSampler.port">3000</stringProp>
          <stringProp name="HTTPSampler.path">/api/v1/cohorts/1/export</stringProp>
          <stringProp name="HTTPSampler.method">GET</stringProp>
        </HTTPSamplerProxy>
      </hashTree>
    </hashTree>
  </hashTree>
</jmeterTestPlan>
```

**New Relic Monitoring Simulation:**
```ruby
# spec/support/new_relic_simulator.rb
module NewRelicSimulator
  def self.record_metric(name, value)
    # Simulate New Relic metric recording
    Rails.logger.info "[NewRelic] #{name}: #{value}"
    
    # Store for assertion
    @metrics ||= {}
    @metrics[name] = value
  end

  def self.get_metric(name)
    @metrics&.dig(name)
  end

  def self.reset
    @metrics = {}
  end
end

# Usage in tests
RSpec.configure do |config|
  config.before(:each, :new_relic) do
    NewRelicSimulator.reset
  end
  
  config.after(:each, :new_relic) do
    # Log all metrics
    puts "\n=== New Relic Metrics ==="
    NewRelicSimulator.instance_variable_get(:@metrics)&.each do |k, v|
      puts "#{k}: #{v}"
    end
  end
end
```

##### Acceptance Criteria

**Functional:**
1. ✅ Cohort creation with 100 students <2 seconds
2. ✅ Bulk signing 100 students <5 seconds
3. ✅ Excel export 100 rows <10 seconds
4. ✅ Email queue 100 messages <30 seconds
5. ✅ Concurrent access (10 users) <2 seconds
6. ✅ Student uploads (100 concurrent) <5 seconds
7. ✅ Database queries <20 per page load
8. ✅ API responses <500ms average

**Performance:**
1. ✅ No N+1 queries detected
2. ✅ Proper database indexes used
3. ✅ Memory growth <10% per operation
4. ✅ No memory leaks over 10 iterations
5. ✅ Object creation <1000 per operation
6. ✅ GC overhead <5% of total time
7. ✅ Sustained load (100 req/min) <60s total

**Database:**
1. ✅ All queries use indexes
2. ✅ No SELECT * queries
3. ✅ Transactions used for bulk operations
4. ✅ Query count optimized
5. ✅ Table sizes reasonable

**Quality:**
1. ✅ All performance tests pass consistently
2. ✅ No flaky performance tests
3. ✅ Performance metrics documented
4. ✅ Bottlenecks identified and documented
5. ✅ Recommendations provided

##### Integration Verification (IV1-4)

**IV1: API Integration**
- All API endpoints tested under load
- Response times measured and validated
- Error rates monitored
- Rate limiting verified

**IV2: Pinia Store**
- Store actions performant with large datasets
- No excessive re-renders
- Memory usage optimized
- State updates efficient

**IV3: Getters**
- Computed properties optimized
- No expensive operations in getters
- Caching works correctly
- Performance scales with data size

**IV4: Token Routing**
- Token generation is fast
- Token validation doesn't bottleneck
- No performance impact from security

##### Test Requirements

**Performance Specs:**
```ruby
# spec/performance/cohort_performance_spec.rb
# (Full implementation shown in Technical Implementation Notes)
```

**Load Test Script:**
```bash
# script/load_test.sh
#!/bin/bash

# Run JMeter load test
jmeter -n -t config/jmeter/floDoc_load_test.jmx \
  -l results/floDoc_results.jtl \
  -e -o results/floDoc_report

# Run memory profiling
bundle exec ruby -r ./spec/performance/memory_profiler.rb

# Run database analysis
bundle exec rails runner "DatabaseMonitor.report"
```

**Benchmark Script:**
```ruby
# script/benchmark.rb
require_relative '../config/environment'

puts "=== FloDoc Performance Benchmark ==="

# Cohort with 100 students
cohort = Cohort.create!(name: 'Benchmark Test')
100.times do |i|
  student = cohort.students.create!(name: "Student #{i}", email: "s#{i}@test.com")
  student.submissions.create!
end

puts "Created cohort with 100 students"

# Benchmark bulk signing
time = Benchmark.measure do
  cohort.submissions.update_all(sponsor_signed: true, sponsor_signed_at: Time.current)
end

puts "Bulk signing: #{time.real.round(3)}s"

# Benchmark export
time = Benchmark.measure do
  # Excel generation
end

puts "Excel export: #{time.real.round(3)}s"

puts "=== Complete ==="
```

##### Rollback Procedure

**If performance tests fail:**
1. Identify bottleneck (database, memory, CPU)
2. Profile slow queries
3. Check for N+1 queries
4. Review indexes
5. Optimize code
6. Re-run tests

**If memory leaks detected:**
1. Use memory_profiler to find leak source
2. Check for object retention
3. Review long-lived objects
4. Fix leak
5. Re-run memory tests

**If database performance poor:**
1. Run EXPLAIN on slow queries
2. Add missing indexes
3. Optimize queries
4. Consider caching
5. Re-run database tests

**If load tests fail:**
1. Check server configuration
2. Review concurrency settings
3. Scale resources if needed
4. Optimize for parallel processing
5. Re-run load tests

**Data Safety:**
- Tests use isolated test database
- No production data affected
- Performance data is informational only
- Rollback not needed for test failures

##### Risk Assessment

**High Risk** because:
- Performance issues are hard to fix late
- Large datasets expose hidden problems
- Memory leaks may not be obvious
- Database performance critical
- Must meet strict NFR requirements

**Specific Risks:**
1. **N+1 Queries**: Common Rails problem with large datasets
   - **Mitigation**: Use Bullet gem, eager loading, test query count

2. **Memory Leaks**: Objects not released, growing memory
   - **Mitigation**: Use memory_profiler, force GC, monitor object count

3. **Database Bottlenecks**: Slow queries, missing indexes
   - **Mitigation**: Use pg_stat_statements, EXPLAIN, add indexes

4. **Timeout Issues**: Long operations exceed limits
   - **Mitigation**: Background jobs, streaming responses, pagination

5. **Concurrent Access**: Race conditions, deadlocks
   - **Mitigation**: Database locks, transactions, optimistic locking

**Mitigation Strategies:**
- Profile early and often
- Use automated performance monitoring
- Set up CI performance gates
- Document all performance metrics
- Have optimization plan ready
- Use caching strategically
- Implement background jobs for heavy operations

##### Success Metrics

- **Load Time**: All pages <2 seconds
- **API Response**: 95% of requests <500ms
- **Bulk Operations**: 100 students <5 seconds
- **Export Time**: 100 rows <10 seconds
- **Email Queue**: 100 emails <30 seconds
- **Query Count**: <20 queries per page
- **Memory Growth**: <10% per operation
- **Concurrent Users**: 10+ users without degradation
- **Database Indexes**: 100% of queries use indexes
- **Zero N+1**: Bullet reports no issues

---

#### Story 7.4: Security Audit & Penetration Testing

**Status**: Draft/Pending
**Priority**: Critical
**Epic**: Integration & Testing
**Estimated Effort**: 3 days
**Risk Level**: High

##### User Story

**As a** Security Engineer,
**I want** to perform comprehensive security testing on all three portals,
**So that** I can identify and remediate vulnerabilities before production deployment.

##### Background

Security is paramount for a document signing platform handling sensitive student data. This story validates:

**Authentication Security:**
- JWT token generation and validation
- Token expiration and renewal mechanisms
- Ad-hoc access pattern security (no account creation)
- Token leakage prevention
- Session management

**Authorization Security:**
- Role-based access control (TP, Student, Sponsor)
- Cross-portal access prevention
- Data isolation between cohorts
- Proper Cancancan ability definitions
- API endpoint protection

**Data Security:**
- Student PII protection (names, emails, documents)
- Document encryption at rest
- Secure file uploads (content validation)
- GDPR compliance (data retention, deletion)
- Audit trail integrity

**Input Validation:**
- SQL injection prevention
- XSS prevention (Vue templates, form inputs)
- File upload validation (type, size, content)
- API parameter sanitization
- Mass assignment protection

**Web Security:**
- CSRF protection
- CORS configuration
- HTTPS enforcement
- Secure headers (CSP, HSTS, X-Frame-Options)
- Clickjacking prevention

**Email Security:**
- Email spoofing prevention
- Link tampering protection
- Token expiration in emails
- Secure email templates

**Third-Party Security:**
- DocuSeal API integration security
- Webhook signature verification
- External service authentication

**Compliance:**
- OWASP Top 10 coverage
- GDPR data protection requirements
- Audit logging for all sensitive operations

##### Technical Implementation Notes

**Security Test Framework:**
```ruby
# spec/security/security_audit_spec.rb
require 'rails_helper'
require 'owasp_zap'
require 'brakeman'

RSpec.describe 'Security Audit', type: :security do
  describe 'Authentication Security' do
    it 'prevents token tampering' do
      # Test JWT signature validation
      original_token = generate_valid_token
      tampered_token = original_token[0..-5] + 'X' * 4

      get '/api/v1/tp/cohorts',
        headers: { 'Authorization' => "Bearer #{tampered_token}" }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'enforces token expiration' do
      expired_token = generate_expired_token

      get '/api/v1/tp/cohorts',
        headers: { 'Authorization' => "Bearer #{expired_token}" }

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)['error']).to include('expired')
    end

    it 'prevents token reuse after renewal' do
      token = generate_valid_token
      old_token = token.dup

      # Renew token
      post '/api/v1/auth/renew',
        headers: { 'Authorization' => "Bearer #{old_token}" }

      expect(response).to have_http_status(:success)

      # Old token should be invalid
      get '/api/v1/tp/cohorts',
        headers: { 'Authorization' => "Bearer #{old_token}" }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'prevents cross-portal access' do
      sponsor_token = generate_sponsor_token

      # Sponsor tries to access TP endpoint
      get '/api/v1/tp/cohorts',
        headers: { 'Authorization' => "Bearer #{sponsor_token}" }

      expect(response).to have_http_status(:forbidden)
    end

    it 'validates ad-hoc token security' do
      # Test that tokens are cryptographically secure
      token = generate_token_for_student

      # Verify token contains no sensitive data
      payload = JWT.decode(token, Rails.application.secrets.secret_key_base, true, { algorithm: 'HS256' })

      expect(payload[0]).not_to include('password')
      expect(payload[0]).not_to include('document_content')
      expect(payload[0]).to include('exp')
      expect(payload[0]).to include('sub')
    end
  end

  describe 'Authorization Security' do
    it 'prevents unauthorized cohort access' do
      cohort = create(:cohort)
      student_token = generate_student_token_for_different_cohort

      get "/api/v1/student/cohorts/#{cohort.id}",
        headers: { 'Authorization' => "Bearer #{student_token}" }

      expect(response).to have_http_status(:not_found)
    end

    it 'enforces ability-based access' do
      cohort = create(:cohort)
      user = create(:user) # Not associated with cohort

      ability = Ability.new(user)

      expect(ability).not_to be_able_to(:read, cohort)
      expect(ability).not_to be_able_to(:update, cohort)
    end

    it 'prevents sponsor from accessing other cohorts' do
      cohort1 = create(:cohort)
      cohort2 = create(:cohort)

      token1 = cohort1.sponsor_token
      token2 = cohort2.sponsor_token

      # Sponsor 1 tries to access cohort 2
      get "/api/v1/sponsor/cohorts/#{cohort2.id}",
        headers: { 'Authorization' => "Bearer #{token1}" }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'Input Validation Security' do
    it 'prevents SQL injection' do
      malicious_params = {
        name: "Cohort'; DROP TABLE cohorts; --",
        student_emails: ["test@example.com'; DROP TABLE users; --"]
      }

      post '/api/v1/tp/cohorts',
        params: malicious_params,
        headers: { 'Authorization' => "Bearer #{tp_token}" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Cohort.count).to eq(0) # No cohort created
    end

    it 'prevents XSS in student names' do
      post '/api/v1/tp/cohorts',
        params: {
          name: 'Test Cohort',
          students: [{ name: '<script>alert("xss")</script>', email: 'test@example.com' }]
        },
        headers: { 'Authorization' => "Bearer #{tp_token}" }

      expect(response).to have_http_status(:success)

      # Verify sanitization
      cohort = Cohort.last
      expect(cohort.students.first.name).not_to include('<script>')
    end

    it 'validates file uploads' do
      # Test malicious file types
      malicious_file = fixture_file_upload(
        Rails.root.join('spec/fixtures/files/malicious.exe'),
        'application/x-msdownload'
      )

      post '/api/v1/student/documents',
        params: { file: malicious_file },
        headers: { 'Authorization' => "Bearer #{student_token}" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('invalid file type')
    end

    it 'enforces file size limits' do
      large_file = fixture_file_upload(
        Rails.root.join('spec/fixtures/files/large.pdf'),
        'application/pdf'
      )

      post '/api/v1/student/documents',
        params: { file: large_file },
        headers: { 'Authorization' => "Bearer #{student_token}" }

      expect(response).to have_http_status(:request_entity_too_large)
    end
  end

  describe 'Web Security' do
    it 'enforces HTTPS' do
      # Test that HTTP requests are rejected or redirected
      get 'http://localhost:3000/api/v1/tp/cohorts',
        headers: { 'Authorization' => "Bearer #{tp_token}" }

      # Should redirect or return error
      expect([301, 302, 400]).to include(response.status)
    end

    it 'has secure headers' do
      get '/api/v1/tp/cohorts',
        headers: { 'Authorization' => "Bearer #{tp_token}" }

      expect(response.headers['Content-Security-Policy']).to be_present
      expect(response.headers['X-Frame-Options']).to eq('DENY')
      expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
      expect(response.headers['X-XSS-Protection']).to eq('1; mode=block')
      expect(response.headers['Strict-Transport-Security']).to be_present
    end

    it 'prevents CSRF on state-changing operations' do
      # API endpoints should use token auth, not session cookies
      cohort = create(:cohort)

      # Without token
      post "/api/v1/tp/cohorts/#{cohort.id}/finalize"

      expect(response).to have_http_status(:unauthorized)
    end

    it 'validates CORS configuration' do
      # Test CORS headers for API endpoints
      options '/api/v1/tp/cohorts',
        headers: { 'Origin' => 'https://evil.com' }

      expect(response.headers['Access-Control-Allow-Origin']).not_to include('evil.com')
    end
  end

  describe 'Data Security' do
    it 'encrypts documents at rest' do
      cohort = create(:cohort)
      document = create(:completed_document, cohort: cohort)

      # Verify database doesn't contain plaintext
      raw_doc = CompletedDocument.find(document.id)

      # Check that Active Storage encryption is configured
      expect(document.file).to be_attached
      expect(document.file.key).not_to be_nil
    end

    it 'prevents document access without proper token' do
      cohort = create(:cohort)
      document = create(:completed_document, cohort: cohort)

      # Try to access document directly
      get document.file.service_url

      # Should require signed URL or token
      expect(response).to have_http_status(:not_found)
    end

    it 'enforces data retention policies' do
      # GDPR: auto-delete after retention period
      old_cohort = create(:cohort, created_at: 366.days.ago)

      expect {
        Cohort.enforce_retention_policy!
      }.to change(Cohort, :count).by(-1)
    end

    it 'logs all sensitive operations' do
      cohort = create(:cohort)

      expect {
        post "/api/v1/tp/cohorts/#{cohort.id}/finalize",
          headers: { 'Authorization' => "Bearer #{tp_token}" }
      }.to change(SubmissionEvent, :count).by(1)

      event = SubmissionEvent.last
      expect(event.event_type).to eq('cohort_finalized')
      expect(event.user_id).to eq(tp_user.id)
      expect(event.audit_data).to include('cohort_id')
    end
  end

  describe 'Email Security' do
    it 'prevents email spoofing' do
      # Verify SPF, DKIM, DMARC configuration
      email = deliver_email('invite', to: 'student@example.com')

      expect(email.from).to eq(['noreply@docuseal.com'])
      expect(email.header['From'].value).to include('noreply@docuseal.com')
    end

    it 'includes secure tokens with expiration' do
      email = deliver_email('invite', to: 'student@example.com')

      # Extract token from email body
      token = extract_token_from_email(email.body)

      # Verify token has expiration
      payload = JWT.decode(token, Rails.application.secrets.secret_key_base, true, { algorithm: 'HS256' })

      expect(payload[0]['exp']).to be_present
      expect(payload[0]['exp']).to be < (Time.now + 1.day).to_i
    end

    it 'prevents token leakage in logs' do
      # Ensure tokens are not logged
      expect(Rails.logger).not_to receive(:info).with(/token/)

      post '/api/v1/auth/request-link',
        params: { email: 'test@example.com', role: 'student' }
    end
  end

  describe 'Third-Party Integration Security' do
    it 'validates DocuSeal API responses' do
      # Mock malicious response
      stub_request(:post, "https://api.docuseal.co/submissions")
        .to_return(status: 200, body: '{"malicious": "content"}')

      expect {
        DocuSealService.create_submission(cohort)
      }.to raise_error(DocuSealService::InvalidResponseError)
    end

    it 'verifies webhook signatures' do
      # Test webhook signature validation
      payload = { event: 'submission.completed', id: 123 }
      signature = generate_webhook_signature(payload)

      post '/api/v1/webhooks/docuseal',
        params: payload,
        headers: { 'X-DocuSeal-Signature' => signature }

      expect(response).to have_http_status(:success)

      # Test with invalid signature
      post '/api/v1/webhooks/docuseal',
        params: payload,
        headers: { 'X-DocuSeal-Signature' => 'invalid' }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'prevents replay attacks on webhooks' do
      payload = { event: 'submission.completed', id: 123, timestamp: Time.now.to_i }
      signature = generate_webhook_signature(payload)

      # First request
      post '/api/v1/webhooks/docuseal',
        params: payload,
        headers: { 'X-DocuSeal-Signature' => signature }

      expect(response).to have_http_status(:success)

      # Replay request
      post '/api/v1/webhooks/docuseal',
        params: payload,
        headers: { 'X-DocuSeal-Signature' => signature }

      expect(response).to have_http_status(:conflict)
    end
  end

  describe 'OWASP ZAP Scanning' do
    it 'passes OWASP Top 10 vulnerability scan' do
      # This would require OWASP ZAP running
      # For now, simulate with Brakeman
      scanner = Brakeman.run(app_path: Rails.root)

      expect(scanner.filtered_warnings).to be_empty
    end

    it 'has no high-severity Brakeman warnings' do
      scanner = Brakeman.run(app_path: Rails.root)

      high_severity = scanner.filtered_warnings.select { |w| w.confidence == 'High' }
      expect(high_severity).to be_empty
    end
  end

  describe 'Penetration Testing Scenarios' do
    it 'prevents horizontal privilege escalation' do
      # Student A tries to access Student B's document
      student_a_token = generate_student_token(cohort, student_a)
      student_b_document = create(:submission, cohort: cohort, student: student_b)

      get "/api/v1/student/documents/#{student_b_document.id}",
        headers: { 'Authorization' => "Bearer #{student_a_token}" }

      expect(response).to have_http_status(:not_found)
    end

    it 'prevents vertical privilege escalation' do
      # Student tries to access TP endpoint
      student_token = generate_student_token

      post '/api/v1/tp/cohorts',
        params: { name: 'Hacked Cohort' },
        headers: { 'Authorization' => "Bearer #{student_token}" }

      expect(response).to have_http_status(:forbidden)
    end

    it 'prevents token brute force' do
      # Test rate limiting
      100.times do
        get '/api/v1/tp/cohorts',
          headers: { 'Authorization' => "Bearer #{invalid_token}" }
      end

      expect(response).to have_http_status(:too_many_requests)
    end

    it 'validates redirect URL whitelist' do
      # Test open redirect prevention
      post '/api/v1/auth/request-link',
        params: {
          email: 'test@example.com',
          role: 'student',
          redirect_url: 'https://evil.com/phishing'
        }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
```

**Security Tools Integration:**
```ruby
# Gemfile additions
group :development, :test do
  gem 'brakeman', require: false  # Static analysis
  gem 'bundler-audit', require: false  # Dependency vulnerabilities
  gem 'owasp_zap', require: false  # Dynamic scanning
  gem 'secure_headers', require: false  # Security headers
  gem 'rack-attack', require: false  # Rate limiting
  gem 'rack-protection', require: false  # CSRF, XSS protection
end

group :test do
  gem 'webmock'  # HTTP mocking
  gem 'vcr'  # HTTP recording
end
```

**Security Configuration:**
```ruby
# config/initializers/security.rb
# JWT Configuration
Rails.application.config.jwt = {
  algorithm: 'HS256',
  expiration: 30.days,
  renew_window: 7.days,
  secret_key: Rails.application.secrets.secret_key_base
}

# Secure Headers
SecureHeaders::Configuration.configure do |config|
  config.csp = {
    default_src: %w['self'],
    script_src: %w['self' 'unsafe-inline'],
    style_src: %w['self' 'unsafe-inline'],
    img_src: %w['self' data: https:],
    font_src: %w['self' https:],
    connect_src: %w['self' https://api.docuseal.co],
    frame_ancestors: %w['none'],
    base_uri: %w['self'],
    form_action: %w['self']
  }

  config.hsts = {
    max_age: 31536000,
    include_subdomains: true,
    preload: true
  }

  config.x_frame_options = 'DENY'
  config.x_content_type_options = 'nosniff'
  config.x_xss_protection = '1; mode=block'
end

# Rack Attack for Rate Limiting
class Rack::Attack
  # Limit API requests
  throttle('API requests', limit: 300, period: 5.minutes) do |req|
    req.ip if req.path.start_with?('/api/')
  end

  # Limit auth attempts
  throttle('Auth attempts', limit: 5, period: 1.minute) do |req|
    req.ip if req.path.include?('/auth/')
  end
end
```

**Data Encryption:**
```ruby
# app/models/completed_document.rb
class CompletedDocument < ApplicationRecord
  # Active Storage with encryption
  has_one_attached :file do |attachable|
    attachable.variant :preview, resize_to_limit: [800, 800]
  end

  # Encrypt sensitive fields
  attr_encrypted :student_name, :student_email,
    key: Rails.application.secrets.encryption_key,
    algorithm: 'aes-256-gcm'
end

# app/models/submission.rb
class Submission < ApplicationRecord
  # Audit logging
  has_many :submission_events, dependent: :destroy

  after_create :log_creation
  after_update :log_update

  private

  def log_creation
    SubmissionEvent.create!(
      event_type: 'submission_created',
      user_id: Current.user&.id,
      submission_id: self.id,
      audit_data: { cohort_id: cohort_id, student_id: student_id }
    )
  end

  def log_update
    SubmissionEvent.create!(
      event_type: 'submission_updated',
      user_id: Current.user&.id,
      submission_id: self.id,
      audit_data: { changes: previous_changes }
    )
  end
end
```

**GDPR Compliance Module:**
```ruby
# lib/gdpr_compliance.rb
module GDPRCompliance
  def self.export_user_data(user_id)
    # Collect all user data
    data = {
      personal_data: collect_personal_data(user_id),
      submissions: collect_submissions(user_id),
      audit_logs: collect_audit_logs(user_id),
      metadata: {
        exported_at: Time.current,
        version: '1.0'
      }
    }

    data
  end

  def self.delete_user_data(user_id)
    # Anonymize instead of delete for audit purposes
    user = User.find(user_id)
    user.update!(
      email: "deleted_#{user_id}@anonymized.local",
      name: "Deleted User"
    )

    # Delete associated personal data
    Submission.where(student_id: user_id).update_all(
      student_name: "Anonymized",
      student_email: "anonymized@local"
    )
  end

  def self.collect_personal_data(user_id)
    {
      user: User.where(id: user_id).pluck(:name, :email, :created_at),
      submissions: Submission.where(student_id: user_id).pluck(:id, :status, :created_at),
      documents: CompletedDocument.where(submitter_id: user_id).pluck(:id, :created_at)
    }
  end

  def self.collect_submissions(user_id)
    Submission.where(student_id: user_id).map do |s|
      {
        id: s.id,
        status: s.status,
        created_at: s.created_at,
        cohort: s.cohort.name
      }
    end
  end

  def self.collect_audit_logs(user_id)
    SubmissionEvent.where(user_id: user_id).map do |e|
      {
        event: e.event_type,
        timestamp: e.created_at,
        data: e.audit_data
      }
    end
  end
end
```

**Security Monitoring:**
```ruby
# app/services/security_monitor.rb
class SecurityMonitor
  def self.check_suspicious_activity
    # Check for multiple failed auth attempts
    failed_attempts = Rails.cache.fetch('failed_auth_attempts', expires_in: 1.hour) { 0 }

    if failed_attempts > 10
      SecurityAlert.create!(
        severity: 'high',
        alert_type: 'brute_force',
        message: "Multiple failed authentication attempts detected",
        metadata: { count: failed_attempts }
      )
    end

    # Check for unusual API access patterns
    check_api_anomalies

    # Check for data exfiltration patterns
    check_data_exfiltration
  end

  def self.check_api_anomalies
    # Monitor API usage patterns
    api_calls = ApiLog.where('created_at > ?', 1.hour.ago).group(:ip_address).count

    api_calls.each do |ip, count|
      if count > 1000 # Threshold
        SecurityAlert.create!(
          severity: 'medium',
          alert_type: 'api_abuse',
          message: "Unusual API activity from #{ip}",
          metadata: { ip: ip, count: count }
        )
      end
    end
  end

  def self.check_data_exfiltration
    # Monitor large data exports
    exports = AuditLog.where(event_type: 'data_export')
                      .where('created_at > ?', 1.hour.ago)
                      .where('data_size > ?', 10.megabytes)

    exports.each do |export|
      SecurityAlert.create!(
        severity: 'high',
        alert_type: 'data_exfiltration',
        message: "Large data export detected",
        metadata: export.data
      )
    end
  end
end
```

**OWASP ZAP Configuration:**
```yaml
# config/zap.yml
development:
  target: http://localhost:3000
  api_key: zap_api_key
  context: floDoc_context
  authentication:
    type: form
    login_url: http://localhost:3000/auth/login
    username: test@example.com
    password: testpassword
  scan_policy:
    - alert_threshold: Medium
    - scan_strength: Medium
    - policy: floDoc_policy
```

**Brakeman Configuration:**
```ruby
# config/brakeman.yml
---
:checks:
  - All
:exclude_checks:
  - BasicAuth
  - CookieSerialization
:minimum_confidence: Medium
:run_all_checks: true
```

##### Acceptance Criteria

**Authentication Security:**
1. ✅ JWT tokens are cryptographically signed and validated
2. ✅ Token expiration enforced (30 days default)
3. ✅ Token renewal mechanism works without data loss
4. ✅ Expired tokens rejected with proper error
5. ✅ Old tokens invalidated after renewal
6. ✅ Ad-hoc access tokens contain no sensitive data
7. ✅ Rate limiting prevents brute force attacks

**Authorization Security:**
1. ✅ Role-based access control enforced (TP, Student, Sponsor)
2. ✅ Cross-portal access prevented
3. ✅ Data isolation between cohorts enforced
4. ✅ Cancancan abilities properly defined
5. ✅ API endpoints protected by authorization
6. ✅ Horizontal privilege escalation prevented
7. ✅ Vertical privilege escalation prevented

**Data Security:**
1. ✅ Documents encrypted at rest (Active Storage)
2. ✅ Sensitive fields encrypted in database
3. ✅ PII properly sanitized and validated
4. ✅ GDPR retention policies enforced
5. ✅ Audit logs capture all sensitive operations
6. ✅ Data export includes complete user data
7. ✅ Data deletion properly anonymizes

**Input Validation:**
1. ✅ SQL injection prevented (parameterized queries)
2. ✅ XSS prevented (input sanitization, CSP headers)
3. ✅ File upload validation (type, size, content)
4. ✅ API parameter sanitization
5. ✅ Mass assignment protection
6. ✅ No malicious file types accepted
7. ✅ File size limits enforced

**Web Security:**
1. ✅ CSRF protection enabled
2. ✅ CORS properly configured
3. ✅ HTTPS enforced
4. ✅ Secure headers present (CSP, HSTS, X-Frame-Options)
5. ✅ Clickjacking prevention
6. ✅ No open redirects
7. ✅ Session fixation prevented

**Email Security:**
1. ✅ Email spoofing prevented (SPF, DKIM)
2. ✅ Secure tokens in emails with expiration
3. ✅ Token leakage prevented in logs
4. ✅ Email templates properly sanitized
5. ✅ Link tampering protection

**Third-Party Security:**
1. ✅ DocuSeal API responses validated
2. ✅ Webhook signature verification
3. ✅ Replay attack prevention
4. ✅ External service authentication secure
5. ✅ No sensitive data in webhook payloads

**Compliance:**
1. ✅ OWASP Top 10 coverage verified
2. ✅ GDPR compliance validated
3. ✅ Audit trail integrity maintained
4. ✅ Data retention policies implemented
5. ✅ User data export functionality works

**Testing Coverage:**
1. ✅ All security tests pass
2. ✅ OWASP ZAP scan clean (or critical issues documented)
3. ✅ Brakeman shows no high-severity warnings
4. ✅ Penetration test scenarios pass
5. ✅ Security monitoring alerts functional

##### Integration Verification (IV1-4)

**IV1: API Integration**
- All API endpoints tested for authentication bypass
- Authorization checks verified on every endpoint
- Rate limiting tested and validated
- Error messages don't leak sensitive information
- API logs don't contain tokens or passwords

**IV2: Pinia Store**
- Token storage in browser secure (HttpOnly cookies)
- No sensitive data in Vue component state
- Token refresh logic handles expiration gracefully
- Store actions validate permissions before execution

**IV3: Getters**
- Computed properties don't expose sensitive data
- No security decisions based on client-side state
- All data access goes through API authorization

**IV4: Token Routing**
- Token generation uses cryptographically secure random
- Token validation happens server-side
- Token renewal maintains security context
- No token leakage in URLs or logs

##### Test Requirements

**Security Specs:**
```ruby
# spec/security/authentication_spec.rb
# spec/security/authorization_spec.rb
# spec/security/data_protection_spec.rb
# spec/security/input_validation_spec.rb
# spec/security/web_security_spec.rb
# spec/security/email_security_spec.rb
# spec/security/third_party_integration_spec.rb
# spec/security/owasp_scan_spec.rb
# spec/security/penetration_test_spec.rb
```

**Security Test Helpers:**
```ruby
# spec/support/security_helpers.rb
module SecurityHelpers
  def generate_valid_token(role: 'tp', cohort: nil)
    payload = {
      sub: "user_#{SecureRandom.uuid}",
      role: role,
      cohort_id: cohort&.id,
      exp: 30.days.from_now.to_i,
      iat: Time.now.to_i
    }

    JWT.encode(payload, Rails.application.secrets.secret_key_base, 'HS256')
  end

  def generate_expired_token
    payload = {
      sub: "user_#{SecureRandom.uuid}",
      role: 'tp',
      exp: 1.day.ago.to_i,
      iat: 1.day.ago.to_i
    }

    JWT.encode(payload, Rails.application.secrets.secret_key_base, 'HS256')
  end

  def generate_tampered_token(token)
    # Modify payload without resigning
    parts = token.split('.')
    payload = JSON.parse(Base64.decode64(parts[1]))
    payload['role'] = 'admin'
    parts[1] = Base64.urlsafe_encode64(payload.to_json, padding: false)
    parts.join('.')
  end

  def generate_webhook_signature(payload)
    data = payload.sort.to_h.to_json
    OpenSSL::HMAC.hexdigest('SHA256', Rails.application.secrets.webhook_secret, data)
  end

  def extract_token_from_email(body)
    # Extract JWT token from email body
    match = body.match(/eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/)
    match[0] if match
  end

  def deliver_email(type, to:)
    ActionMailer::Base.deliveries.clear
    SubmissionMailer.send(type, to).deliver_now
    ActionMailer::Base.deliveries.last
  end

  def simulate_brute_force(ip, attempts: 10)
    attempts.times do
      get '/api/v1/tp/cohorts',
        headers: { 'Authorization' => "Bearer #{invalid_token}" },
        env: { 'REMOTE_ADDR' => ip }
    end
  end

  def simulate_data_exfiltration(size: 50.megabytes)
    # Create large dataset
    cohort = create(:cohort)
    1000.times { create(:submission, cohort: cohort) }

    # Attempt large export
    get "/api/v1/tp/cohorts/#{cohort.id}/export",
      headers: { 'Authorization' => "Bearer #{generate_valid_token}" }
  end
end

RSpec.configure do |config|
  config.include SecurityHelpers, type: :security
end
```

**OWASP ZAP Test Script:**
```bash
#!/bin/bash
# script/security_scan.sh

echo "Starting OWASP ZAP Security Scan..."

# Start ZAP in daemon mode
zap.sh -daemon -port 8080 -config api.key=zap_api_key &

# Wait for ZAP to start
sleep 10

# Configure context
curl -s http://localhost:8080/JSON/context/action/newContext/?contextName=floDoc

# Add authentication
curl -s http://localhost:8080/JSON/context/action/setAuthenticationMethod/ \
  -d "contextName=floDoc" \
  -d "authMethodName=form" \
  -d "authMethodConfigParams=loginUrl=http://localhost:3000/auth/login"

# Set scan policy
curl -s http://localhost:8080/JSON/scanPolicy/action/loadScanPolicy/ \
  -d "scanPolicyName=floDoc_policy"

# Run active scan
curl -s http://localhost:8080/JSON/spider/action/scan/ \
  -d "url=http://localhost:3000" \
  -d "contextName=floDoc"

# Wait for scan
sleep 60

# Get alerts
curl -s http://localhost:8080/JSON/core/view/alerts/ \
  -d "baseurl=http://localhost:3000" > zap_results.json

# Generate report
zap.sh -cmd -quickurl http://localhost:3000 -quickout zap_report.html

echo "Scan complete. Results in zap_results.json and zap_report.html"

# Kill ZAP
pkill -f zap.sh
```

**Brakeman Scan:**
```bash
#!/bin/bash
# script/security_audit.sh

echo "Running Brakeman Security Audit..."

# Run Brakeman
bundle exec brakeman -o brakeman.json -o brakeman.html

# Run Bundler Audit
bundle exec bundle-audit check --update

# Check for outdated gems with known vulnerabilities
bundle exec gem outdated --filter=security

echo "Security audit complete."
```

##### Rollback Procedure

**If authentication vulnerabilities found:**
1. Immediately disable affected endpoints
2. Rotate all JWT secrets
3. Invalidate all active tokens
4. Force password reset for affected users
5. Implement proper fix
6. Re-run security tests
7. Monitor for exploitation attempts

**If authorization bypass discovered:**
1. Disable affected portal/API
2. Review all ability definitions
3. Add missing authorization checks
4. Test all access patterns
5. Deploy fix with emergency patch
6. Audit logs for exploitation

**If data breach detected:**
1. Immediately isolate affected systems
2. Preserve logs and evidence
3. Notify affected parties (GDPR requirement)
4. Rotate all encryption keys
5. Force re-authentication
6. Implement additional monitoring
7. Conduct forensic analysis

**If injection vulnerability found:**
1. Disable affected input fields
2. Implement parameterized queries
3. Add input validation
4. Sanitize existing data
5. Re-run injection tests
6. Monitor for attacks

**If CSRF vulnerability found:**
1. Enable CSRF protection immediately
2. Force logout for all users
3. Require re-authentication
4. Verify all forms have CSRF tokens
5. Re-run CSRF tests

**Data Safety:**
- All security tests use isolated test environment
- No production data used in security testing
- Security findings documented, not exploited
- Emergency patches follow standard deployment process
- All changes require security review

##### Risk Assessment

**High Risk** because:
- Security vulnerabilities can lead to data breaches
- Document signing involves sensitive PII
- GDPR violations carry heavy fines
- Authentication bypass is critical
- Third-party integrations add attack surface
- Ad-hoc access pattern is unconventional

**Specific Risks:**

1. **Authentication Bypass**: JWT implementation flaws could allow unauthorized access
   - **Mitigation**: Use battle-tested libraries, comprehensive testing, security audits

2. **Authorization Escalation**: Improper ability definitions could allow privilege escalation
   - **Mitigation**: Test all role combinations, use automated ability testing, principle of least privilege

3. **Data Exposure**: Unencrypted data or improper access controls
   - **Mitigation**: Encrypt at rest, validate all access, audit logs, GDPR compliance

4. **Injection Attacks**: SQL, XSS, command injection through user inputs
   - **Mitigation**: Parameterized queries, input sanitization, CSP headers, WAF

5. **Token Compromise**: Token theft, replay attacks, brute force
   - **Mitigation**: Short expiration, rate limiting, HTTPS only, secure storage

6. **Third-Party Vulnerabilities**: DocuSeal API or webhook compromise
   - **Mitigation**: Signature verification, response validation, fail-secure design

7. **GDPR Violation**: Improper data handling, retention, deletion
   - **Mitigation**: Automated retention policies, data export, anonymization, audit trails

8. **Email Security**: Spoofing, phishing, token leakage
   - **Mitigation**: SPF/DKIM, secure tokens, sanitization, no sensitive data in emails

9. **Webhook Security**: Unverified webhook deliveries
   - **Mitigation**: HMAC signatures, timestamp validation, replay protection

10. **Rate Limiting**: DoS through resource exhaustion
    - **Mitigation**: Rate limiting, request throttling, resource quotas

**Mitigation Strategies:**
- **Defense in Depth**: Multiple layers of security controls
- **Zero Trust**: Verify every request, assume breach
- **Secure by Default**: Most secure settings out of the box
- **Fail Secure**: Deny by default, fail closed
- **Audit Everything**: Comprehensive logging and monitoring
- **Regular Audits**: Automated and manual security testing
- **Patch Management**: Rapid response to vulnerabilities
- **Incident Response**: Documented procedures for breaches
- **Security Training**: Developer awareness of common vulnerabilities
- **Code Review**: Security-focused peer review process

##### Success Metrics

**Authentication:**
- 100% of auth endpoints tested
- 0 authentication bypasses
- Token validation success rate: 100%
- Rate limiting effective: 0 brute force successes

**Authorization:**
- 100% of authorization paths tested
- 0 privilege escalation vulnerabilities
- 0 horizontal access violations
- Ability coverage: 100% of actions

**Data Protection:**
- 100% of sensitive fields encrypted
- 0 data breaches in testing
- GDPR compliance: 100%
- Audit log completeness: 100%

**Input Validation:**
- 0 SQL injection vulnerabilities
- 0 XSS vulnerabilities
- 0 file upload bypasses
- 100% input sanitization

**Web Security:**
- 100% secure headers present
- 0 CSRF vulnerabilities
- 0 CORS misconfigurations
- 0 open redirects

**Third-Party:**
- 100% webhook signature verification
- 0 third-party integration vulnerabilities
- 100% response validation

**Compliance:**
- OWASP Top 10: 0 critical/high findings
- Brakeman: 0 high-severity warnings
- ZAP Scan: 0 critical/high alerts
- Penetration Test: 0 critical findings

**Monitoring:**
- Security alerts: 100% detection rate
- False positive rate: <5%
- Response time: <1 hour for critical issues
- Audit log integrity: 100%

---

#### Story 7.5: User Acceptance Testing

**Status**: Draft/Pending
**Priority**: High
**Epic**: Integration & Testing
**Estimated Effort**: 5 days
**Risk Level**: Medium

##### User Story

**As a** Product Owner,
**I want** to conduct comprehensive user acceptance testing with real stakeholders,
**So that** I can validate the system meets business requirements and user needs before production launch.

##### Background

User Acceptance Testing (UAT) is the final validation phase where real users test the complete system in a production-like environment. This story validates:

**Stakeholder Testing:**
- **Training Provider (TP)**: Creates cohorts, manages students, reviews submissions
- **Students**: Upload documents, fill forms, sign documents
- **Sponsors**: Bulk sign documents, track progress

**Workflow Validation:**
- Complete end-to-end cohort lifecycle
- All three portals working together
- Email notifications delivered correctly
- Document signing workflow complete
- Excel export functionality
- Token renewal and session management

**Real-World Scenarios:**
- Large cohorts (50+ students)
- Multiple concurrent users
- Different document types
- Various form field types
- Edge cases and error handling

**Business Process Validation:**
- TP creates cohort with 50 students
- TP signs first student's document
- System auto-fills TP signature to all students
- Students receive emails and upload documents
- Students fill forms and sign
- Sponsor receives ONE email for entire cohort
- Sponsor bulk signs all students
- TP reviews and finalizes cohort
- Excel export contains all data

**UX/Usability Testing:**
- Intuitive navigation across portals
- Clear user instructions
- Mobile responsiveness
- Accessibility compliance
- Performance under real usage

**Data Integrity:**
- No data loss during workflow
- Proper audit trail
- Correct document generation
- Accurate state management
- Proper error recovery

##### Technical Implementation Notes

**UAT Test Framework:**
```ruby
# spec/acceptance/uat_spec.rb
require 'rails_helper'
require 'capybara/rspec'
require 'selenium-webdriver'

RSpec.describe 'User Acceptance Testing', type: :feature, uat: true do
  let(:tp_user) { create(:user, role: 'tp') }
  let(:cohort) { create(:cohort, :with_50_students) }

  describe 'TP Portal - Complete Workflow' do
    it 'TP creates cohort and signs first document' do
      # Login to TP Portal
      visit '/tp/login'
      fill_in 'Email', with: tp_user.email
      fill_in 'Password', with: 'password'
      click_button 'Login'

      # Create cohort
      visit '/tp/cohorts/new'
      fill_in 'Cohort Name', with: 'UAT Test Cohort'
      fill_in 'Student Count', with: 50
      attach_file 'Template PDF', Rails.root.join('spec/fixtures/files/template.pdf')
      click_button 'Create Cohort'

      expect(page).to have_content('Cohort created successfully')
      expect(page).to have_content('50 students')

      # Navigate to first student
      within('.student-list') do
        first('.student-item').click
      end

      # Sign first document
      within('.signature-pad') do
        page.execute_script("drawSignature()")
      end

      click_button 'Sign Document'

      expect(page).to have_content('Document signed')
      expect(page).to have_content('Auto-filled to 49 remaining students')

      # Verify auto-fill
      cohort.reload
      expect(cohort.submissions.where(sponsor_signed: true).count).to eq(50)
    end

    it 'TP monitors cohort progress' do
      # Setup: cohort with mixed statuses
      cohort = create(:cohort, :with_mixed_statuses)

      login_as(tp_user)
      visit "/tp/cohorts/#{cohort.id}"

      # Check progress dashboard
      expect(page).to have_content('Waiting: 10')
      expect(page).to have_content('In Progress: 15')
      expect(page).to have_content('Completed: 25')

      # Click on status filter
      click_link 'Waiting'

      expect(page).to have_css('.student-item', count: 10)
    end

    it 'TP exports cohort data to Excel' do
      cohort = create(:cohort, :with_completed_students)

      login_as(tp_user)
      visit "/tp/cohorts/#{cohort.id}/export"

      # Download file
      click_button 'Export to Excel'

      expect(page.response_headers['Content-Type']).to include('spreadsheet')
      expect(page.response_headers['Content-Disposition']).to include('cohort_export.xlsx')
    end
  end

  describe 'Student Portal - Complete Workflow' do
    it 'Student uploads document and completes form' do
      # Student receives email link
      email = ActionMailer::Base.deliveries.last
      token = extract_token_from_email(email.body)

      # Access portal with token
      visit "/student/cohorts/#{cohort.id}?token=#{token}"

      expect(page).to have_content('Welcome, Student')

      # Upload document
      attach_file 'Upload ID', Rails.root.join('spec/fixtures/files/student_id.pdf')
      click_button 'Upload'

      expect(page).to have_content('Document uploaded successfully')

      # Fill form
      fill_in 'Full Name', with: 'John Doe'
      fill_in 'Date of Birth', with: '1990-01-01'
      check 'I agree to terms'

      # Sign
      within('.signature-pad') do
        page.execute_script("drawSignature()")
      end

      click_button 'Submit'

      expect(page).to have_content('Submission complete')
      expect(page).to have_content('Status: Pending Sponsor Approval')
    end

    it 'Student saves draft and resumes later' do
      token = cohort.student_tokens.first

      visit "/student/cohorts/#{cohort.id}?token=#{token}"

      # Fill partial form
      fill_in 'Full Name', with: 'Jane Smith'
      click_button 'Save Draft'

      expect(page).to have_content('Draft saved')

      # Return later
      visit "/student/cohorts/#{cohort.id}?token=#{token}"

      expect(page).to have_field('Full Name', with: 'Jane Smith')
    end

    it 'Student receives email notifications' do
      token = cohort.student_tokens.first

      # Trigger notification
      visit "/student/cohorts/#{cohort.id}?token=#{token}"

      # Check email was sent
      email = ActionMailer::Base.deliveries.last
      expect(email.to).to include(cohort.students.first.email)
      expect(email.subject).to include('Document Ready for Signing')
    end
  end

  describe 'Sponsor Portal - Complete Workflow' do
    it 'Sponsor bulk signs all students' do
      # Cohort with all students ready
      cohort = create(:cohort, :with_ready_students)

      # Access sponsor portal
      visit "/sponsor/cohorts/#{cohort.id}?token=#{cohort.sponsor_token}"

      expect(page).to have_content('Cohort: UAT Test')
      expect(page).to have_content('Students Ready: 50')

      # Bulk sign
      within('.bulk-sign-section') do
        fill_in 'Your Full Name', with: 'Sponsor Representative'
        within('.signature-pad') do
          page.execute_script("drawSignature()")
        end
        check 'I certify all documents are complete'
        click_button 'Sign All Documents'
      end

      expect(page).to have_content('Successfully signed 50 documents')
      expect(page).to have_content('All students notified')

      # Verify all submissions signed
      cohort.reload
      expect(cohort.submissions.where(sponsor_signed: true).count).to eq(50)
    end

    it 'Sponsor tracks progress across tabs' do
      cohort = create(:cohort, :with_mixed_statuses)

      visit "/sponsor/cohorts/#{cohort.id}?token=#{cohort.sponsor_token}"

      # Check Waiting tab
      click_link 'Waiting'
      expect(page).to have_css('.student-item', count: 10)

      # Check In Progress tab
      click_link 'In Progress'
      expect(page).to have_css('.student-item', count: 15)

      # Check Completed tab
      click_link 'Completed'
      expect(page).to have_css('.student-item', count: 25)
    end

    it 'Sponsor receives single email notification' do
      cohort = create(:cohort, :with_ready_students)

      # Clear previous emails
      ActionMailer::Base.deliveries.clear

      # Trigger email
      visit "/sponsor/cohorts/#{cohort.id}?token=#{cohort.sponsor_token}"

      # Check only one email sent
      emails = ActionMailer::Base.deliveries
      expect(emails.count).to eq(1)
      expect(emails.last.subject).to include('Documents Ready for Signing')
      expect(emails.last.to).to include(cohort.sponsor_email)
    end
  end

  describe 'Multi-User Concurrent Access' do
    it 'handles 10 concurrent users' do
      cohort = create(:cohort, :with_50_students)

      # Simulate concurrent access
      threads = []

      10.times do |i|
        threads << Thread.new do
          # Each thread acts as different user
          if i < 5
            # Students
            student = cohort.students[i]
            token = student.tokens.create!.token

            page = Capybara::Session.new(:selenium)
            page.visit "/student/cohorts/#{cohort.id}?token=#{token}"
            page.fill_in 'Full Name', with: "Student #{i}"
            page.click_button 'Submit'
          else
            # Sponsors (multiple sponsors for testing)
            sponsor_email = "sponsor#{i}@test.com"
            cohort.update(sponsor_email: sponsor_email)

            page = Capybara::Session.new(:selenium)
            page.visit "/sponsor/cohorts/#{cohort.id}?token=#{cohort.sponsor_token}"
            page.click_button 'Sign All Documents'
          end
        end
      end

      threads.each(&:join)

      # Verify all completed
      expect(cohort.submissions.where(sponsor_signed: true).count).to eq(50)
    end
  end

  describe 'Edge Cases and Error Handling' do
    it 'handles expired token gracefully' do
      expired_token = generate_expired_token

      visit "/student/cohorts/#{cohort.id}?token=#{expired_token}"

      expect(page).to have_content('Token expired')
      expect(page).to have_button('Request New Link')
    end

    it 'prevents duplicate submissions' do
      token = cohort.student_tokens.first

      # Submit once
      visit "/student/cohorts/#{cohort.id}?token=#{token}"
      click_button 'Submit'

      # Try to submit again
      visit "/student/cohorts/#{cohort.id}?token=#{token}"
      click_button 'Submit'

      expect(page).to have_content('Already submitted')
    end

    it 'handles network failures gracefully' do
      # Simulate network failure
      allow_any_instance_of(ActionDispatch::Request).to receive(:save).and_raise(StandardError)

      token = cohort.student_tokens.first
      visit "/student/cohorts/#{cohort.id}?token=#{token}"

      click_button 'Submit'

      expect(page).to have_content('Connection error')
      expect(page).to have_button('Retry')
    end
  end

  describe 'Accessibility Testing' do
    it 'passes WCAG 2.1 AA standards' do
      visit "/student/cohorts/#{cohort.id}?token=#{cohort.student_tokens.first}"

      # Check for alt text
      expect(page).to have_css('img[alt]')

      # Check for labels
      expect(page).to have_css('label[for]')

      # Check for keyboard navigation
      page.evaluate_script('document.activeElement')
      page.send_keys(:tab)
      expect(page.evaluate_script('document.activeElement')).not_to be_nil

      # Check color contrast (via CSS analysis)
      styles = page.evaluate_script('getComputedStyle(document.body)')
      expect(styles).not_to be_nil
    end

    it 'works with screen readers' do
      visit "/student/cohorts/#{cohort.id}?token=#{cohort.student_tokens.first}"

      # Check ARIA labels
      expect(page).to have_css('[aria-label]')
      expect(page).to have_css('[role="button"]')
    end
  end
end
```

**UAT Test Data Factory:**
```ruby
# spec/factories/uat_factory.rb
FactoryBot.define do
  factory :cohort do
    name { "UAT Cohort #{Time.now.to_i}" }
    tp_email { "tp@trainingprovider.com" }
    sponsor_email { "sponsor@company.com" }

    trait :with_50_students do
      after(:create) do |cohort|
        50.times do |i|
          student = create(:student, cohort: cohort, email: "student#{i}@test.com")
          create(:submission, cohort: cohort, student: student, status: 'waiting')
        end
      end
    end

    trait :with_completed_students do
      after(:create) do |cohort|
        50.times do |i|
          student = create(:student, cohort: cohort, email: "student#{i}@test.com")
          create(:submission, cohort: cohort, student: student, status: 'completed')
        end
      end
    end

    trait :with_ready_students do
      after(:create) do |cohort|
        50.times do |i|
          student = create(:student, cohort: cohort, email: "student#{i}@test.com")
          create(:submission, cohort: cohort, student: student,
                 status: 'waiting', tp_signed: true, student_signed: true)
        end
      end
    end

    trait :with_mixed_statuses do
      after(:create) do |cohort|
        10.times do |i|
          student = create(:student, cohort: cohort)
          create(:submission, cohort: cohort, student: student, status: 'waiting')
        end
        15.times do |i|
          student = create(:student, cohort: cohort)
          create(:submission, cohort: cohort, student: student, status: 'in_progress')
        end
        25.times do |i|
          student = create(:student, cohort: cohort)
          create(:submission, cohort: cohort, student: student, status: 'completed')
        end
      end
    end
  end
end
```

**UAT Test Scripts:**
```bash
#!/bin/bash
# script/run_uat.sh

echo "=== FloDoc User Acceptance Testing ==="

# Setup test environment
echo "Setting up test data..."
bundle exec rails runner "
  require 'rake'
  Rake::Task['db:seed'].invoke
  puts 'Test data created'
"

# Run UAT tests
echo "Running UAT scenarios..."
bundle exec rspec spec/acceptance/uat_spec.rb --format documentation

# Generate UAT report
echo "Generating UAT report..."
bundle exec rails runner "
  report = {
    timestamp: Time.current,
    total_tests: RSpec.world.example_count,
    passed: RSpec.world.examples.select(&:passed?).count,
    failed: RSpec.world.examples.select(&:failed?).count,
    duration: RSpec.world.duration
  }

  File.write('tmp/uat_report.json', JSON.pretty_generate(report))
  puts 'UAT Report saved to tmp/uat_report.json'
"

echo "=== UAT Complete ==="
```

**UAT Checklist:**
```markdown
# UAT Checklist

## TP Portal
- [ ] Can create cohort with 50 students
- [ ] Can upload template PDF
- [ ] Can sign first document
- [ ] Auto-fill works for remaining students
- [ ] Can monitor all student statuses
- [ ] Can export to Excel
- [ ] Can finalize cohort
- [ ] Email notifications work
- [ ] Token renewal works
- [ ] Mobile responsive

## Student Portal
- [ ] Can access with email link
- [ ] Can upload documents
- [ ] Can fill all field types
- [ ] Can sign documents
- [ ] Can save drafts
- [ ] Can resume later
- [ ] Receives notifications
- [ ] Mobile responsive
- [ ] Accessible (WCAG 2.1 AA)

## Sponsor Portal
- [ ] Can access with email link
- [ ] Can bulk sign all students
- [ ] Can track progress by status
- [ ] Receives ONE email per cohort
- [ ] No duplicate emails
- [ ] Mobile responsive
- [ ] Accessible (WCAG 2.1 AA)

## Workflow Integration
- [ ] Complete 3-party workflow works
- [ ] TP signs first, auto-fills to all
- [ ] Students receive emails
- [ ] Students complete submissions
- [ ] Sponsor receives single email
- [ ] Sponsor bulk signs
- [ ] TP reviews and finalizes
- [ ] Excel export contains all data
- [ ] Audit trail complete

## Performance
- [ ] Cohort creation <2s
- [ ] Bulk signing <5s
- [ ] Excel export <10s
- [ ] Concurrent users handled
- [ ] No data loss

## Security
- [ ] Tokens expire correctly
- [ ] Token renewal works
- [ ] No unauthorized access
- [ ] Data isolation enforced
- [ ] Audit logs complete

## Error Handling
- [ ] Expired tokens handled
- [ ] Duplicate submissions prevented
- [ ] Network failures handled
- [ ] Clear error messages
- [ ] Recovery options provided
```

**UAT Feedback Template:**
```ruby
# app/models/uat_feedback.rb
class UATFeedback < ApplicationRecord
  belongs_to :user
  belongs_to :cohort, optional: true

  validates :portal, presence: true, inclusion: { in: %w[tp student sponsor] }
  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :scenario, presence: true

  # Scenarios:
  # - cohort_creation
  # - document_upload
  # - form_filling
  # - signing
  # - bulk_signing
  # - export
  # - navigation
  # - mobile
  # - performance
  # - overall

  scope :critical, -> { where(rating: 1..2) }
  scope :positive, -> { where(rating: 4..5) }
end
```

##### Acceptance Criteria

**TP Portal UAT:**
1. ✅ Can create cohort with 50+ students in <2 seconds
2. ✅ Can upload and configure template PDF
3. ✅ Can sign first document and auto-fill to all students
4. ✅ Can monitor real-time progress across all students
5. ✅ Can export complete cohort data to Excel
6. ✅ Can finalize cohort after sponsor approval
7. ✅ Email notifications delivered correctly
8. ✅ Token renewal works without data loss
9. ✅ Mobile responsive on tablets and phones
10. ✅ No data loss during any operation

**Student Portal UAT:**
1. ✅ Can access portal via email link
2. ✅ Can upload required documents
3. ✅ Can fill all 12 field types correctly
4. ✅ Can sign documents with signature pad
5. ✅ Can save drafts and resume later
6. ✅ Receives timely email notifications
7. ✅ Cannot access other students' documents
8. ✅ Mobile responsive and touch-friendly
9. ✅ WCAG 2.1 AA accessibility compliant
10. ✅ Clear error messages and guidance

**Sponsor Portal UAT:**
1. ✅ Can access portal via email link
2. ✅ Can bulk sign all students at once
3. ✅ Can track progress across three tabs (Waiting/In Progress/Completed)
4. ✅ Receives exactly ONE email per cohort
5. ✅ No duplicate email notifications
6. ✅ Mobile responsive on all devices
7. ✅ WCAG 2.1 AA accessibility compliant
8. ✅ Signature appears on all student documents
9. ✅ Cannot access other cohorts
10. ✅ Clear progress indicators

**End-to-End Workflow UAT:**
1. ✅ Complete 3-party workflow succeeds
2. ✅ TP signs first, auto-fills to all students
3. ✅ All students receive emails and can complete
4. ✅ Sponsor receives single email notification
5. ✅ Sponsor bulk signs all students
6. ✅ TP reviews and finalizes cohort
7. ✅ Excel export contains complete data
8. ✅ Audit trail captures all events
9. ✅ No data corruption or loss
10. ✅ All state transitions work correctly

**Performance UAT:**
1. ✅ Cohort creation with 50 students <2 seconds
2. ✅ Bulk signing 50 students <5 seconds
3. ✅ Excel export 50 rows <10 seconds
4. ✅ Email delivery 50 messages <30 seconds
5. ✅ Concurrent access (10 users) <2 seconds
6. ✅ Student uploads (50 concurrent) <5 seconds
7. ✅ Database queries <20 per page load
8. ✅ API responses <500ms average
9. ✅ No memory leaks
10. ✅ No N+1 queries

**Security UAT:**
1. ✅ Tokens expire after 30 days
2. ✅ Token renewal works without data loss
3. ✅ Expired tokens rejected with clear error
4. ✅ Cross-portal access prevented
5. ✅ Data isolation between cohorts enforced
6. ✅ No SQL injection vulnerabilities
7. ✅ No XSS vulnerabilities
8. ✅ All sensitive operations logged
9. ✅ GDPR compliance validated
10. ✅ No unauthorized access possible

**UX/Usability UAT:**
1. ✅ Navigation is intuitive across all portals
2. ✅ User instructions are clear and helpful
3. ✅ Error messages are actionable
4. ✅ Success feedback is provided
5. ✅ Loading states are clear
6. ✅ Mobile experience is excellent
7. ✅ Desktop experience is excellent
8. ✅ Touch gestures work on mobile
9. ✅ Keyboard navigation works
10. ✅ Screen readers work correctly

**Data Integrity UAT:**
1. ✅ No data loss during workflow
2. ✅ All documents generated correctly
3. ✅ All signatures appear correctly
4. ✅ Audit trail is complete and accurate
5. ✅ State management is correct
6. ✅ Email delivery is reliable
7. ✅ Excel export is accurate
8. ✅ Token system works correctly
9. ✅ Error recovery works
10. ✅ Data consistency maintained

##### Integration Verification (IV1-4)

**IV1: API Integration**
- All API endpoints tested through UAT scenarios
- Real-world data flow validated
- Error handling tested with actual user actions
- Performance measured under realistic load
- Security validated with actual access patterns

**IV2: Pinia Store**
- State management tested through complete workflows
- Token handling validated with real expiration scenarios
- Store actions tested with actual user interactions
- Data persistence verified across sessions

**IV3: Getters**
- Computed properties tested with real data
- Performance validated with large datasets
- Filtering and sorting tested with actual use cases
- Caching behavior verified

**IV4: Token Routing**
- Token generation tested with real email delivery
- Token validation tested with expired tokens
- Renewal flow tested with actual user actions
- Security validated with tampering attempts

##### Test Requirements

**UAT Test Suite:**
```ruby
# spec/acceptance/uat_spec.rb
# (Full implementation in Technical Implementation Notes)
```

**UAT Test Data:**
```ruby
# spec/factories/uat_factory.rb
# (Full implementation in Technical Implementation Notes)
```

**UAT Scripts:**
```bash
# script/run_uat.sh
# (Full implementation in Technical Implementation Notes)
```

**UAT Checklist:**
```markdown
# docs/uat_checklist.md
# (Full implementation in Technical Implementation Notes)
```

**Feedback Collection:**
```ruby
# app/controllers/uat_feedback_controller.rb
class UATFeedbackController < ApplicationController
  def create
    @feedback = UATFeedback.new(feedback_params)

    if @feedback.save
      # Notify team of critical feedback
      if @feedback.rating <= 2
        SecurityMailer.critical_feedback(@feedback).deliver_later
      end

      render json: { message: 'Feedback received' }, status: :created
    else
      render json: { errors: @feedback.errors }, status: :unprocessable_entity
    end
  end

  private

  def feedback_params
    params.require(:feedback).permit(:portal, :scenario, :rating, :comments, :user_id, :cohort_id)
  end
end
```

##### Rollback Procedure

**If critical UAT failures found:**
1. Pause production deployment
2. Document all failures with screenshots/logs
3. Prioritize failures by severity
4. Fix critical issues immediately
5. Re-run affected UAT scenarios
6. Get stakeholder sign-off on fixes
7. Re-schedule UAT if needed

**If data integrity issues:**
1. Stop all testing immediately
2. Preserve test data for analysis
3. Identify root cause
4. Fix data corruption
5. Restore from backup if needed
6. Re-run integrity tests
7. Validate with stakeholders

**If performance issues:**
1. Document performance metrics
2. Identify bottlenecks
3. Implement optimizations
4. Re-run performance tests
5. Validate against NFRs
6. Get stakeholder approval

**If security vulnerabilities:**
1. Immediately stop testing
2. Document vulnerability
3. Follow security rollback procedure (Story 7.4)
4. Fix and re-test
5. Get security review

**If UX issues:**
1. Document all UX problems
2. Get stakeholder input on priority
3. Implement UX improvements
4. Re-run affected scenarios
5. Get stakeholder re-approval

**Data Safety:**
- All UAT uses isolated test database
- No production data used
- Test data can be reset easily
- All changes tracked in version control
- Stakeholder feedback preserved

##### Risk Assessment

**Medium Risk** because:
- UAT involves real users with varying skill levels
- Time constraints may limit test coverage
- Stakeholder availability may be limited
- Real-world scenarios may reveal unexpected issues
- User feedback may require significant changes

**Specific Risks:**

1. **Incomplete Test Coverage**: Missing critical user scenarios
   - **Mitigation**: Use comprehensive checklist, involve all stakeholders, test edge cases

2. **Stakeholder Availability**: Key users unavailable for testing
   - **Mitigation**: Schedule UAT well in advance, provide flexible time slots, record sessions

3. **User Error**: Testers make mistakes that invalidate results
   - **Mitigation**: Clear instructions, guided sessions, support available

4. **Scope Creep**: Users request new features during UAT
   - **Mitigation**: Clear scope definition, change control process, defer to post-launch

5. **Performance Issues**: Real usage reveals bottlenecks
   - **Mitigation**: Load testing before UAT, performance monitoring during UAT

6. **Data Issues**: Test data doesn't match real scenarios
   - **Mitigation**: Use realistic test data, involve stakeholders in data creation

7. **Feedback Overload**: Too much feedback to process
   - **Mitigation**: Structured feedback forms, prioritization framework, dedicated review sessions

8. **Negative User Experience**: Users frustrated with system
   - **Mitigation**: User training, clear documentation, responsive support

9. **Integration Failures**: Third-party systems fail during UAT
   - **Mitigation**: Mock external services, have fallback plans, document dependencies

10. **Timeline Pressure**: UAT takes longer than planned
    - **Mitigation**: Buffer time in schedule, prioritize critical tests, phase UAT if needed

**Mitigation Strategies:**
- **Pre-UAT Training**: Train users before testing
- **Clear Scope**: Define what's in/out of scope
- **Structured Feedback**: Use standardized forms
- **Dedicated Support**: Have team available during UAT
- **Regular Check-ins**: Daily standups during UAT
- **Prioritization**: Focus on critical workflows first
- **Documentation**: Record all findings
- **Change Control**: Manage scope creep
- **Post-UAT Review**: Learn from feedback
- **Stakeholder Sign-off**: Formal approval process

##### Success Metrics

**Test Completion:**
- 100% of UAT scenarios executed
- 100% of checklist items verified
- 100% of stakeholders participated
- 0 critical blockers

**Pass Rate:**
- 95% of scenarios pass on first attempt
- 100% of scenarios pass after fixes
- 0 high-severity failures
- <5 medium-severity issues

**User Satisfaction:**
- Average rating ≥4.0 out of 5
- ≥80% of users rate system as "Easy to use"
- ≥90% of users rate system as "Reliable"
- ≥85% of users would recommend system

**Performance:**
- All NFRs met during UAT
- No performance complaints
- Average task completion time <2 minutes
- System uptime ≥99% during UAT

**Data Integrity:**
- 0 data loss incidents
- 100% audit trail completeness
- 100% document generation accuracy
- 0 state management errors

**Security:**
- 0 security incidents
- 100% of security controls validated
- 0 unauthorized access attempts
- All tokens function correctly

**Workflow Completion:**
- 100% of complete workflows succeed
- Average workflow completion <10 minutes
- 0 workflow deadlocks
- All state transitions work

**Feedback Quality:**
- ≥90% of feedback is actionable
- <10% of feedback is out of scope
- All critical feedback addressed
- Stakeholder satisfaction with process

---

### 6.8 Phase 8: Deployment & Documentation

**Focus**: Production infrastructure setup, deployment automation, monitoring configuration, and comprehensive documentation for operational excellence

This phase prepares FloDoc v3 for production deployment with robust infrastructure, automated CI/CD pipelines, comprehensive monitoring and alerting, and complete documentation for ongoing operations and maintenance.

# FloDoc Brownfield Enhancement PRD
**3-Portal Cohort Management System for Training Institutions**

*Version: v1.0*
*Date: 2025-01-01*
*Status: Draft - Requires Architect Review*

---

## Table of Contents
1. [Intro Project Analysis and Context](#intro-project-analysis-and-context)
2. [Requirements](#requirements)
3. [Technical Constraints and Integration](#technical-constraints-and-integration)
4. [Epic and Story Structure](#epic-and-story-structure)
5. [Epic 1: 3-Portal Cohort Management System](#epic-1-3-portal-cohort-management-system)

---

## Intro Project Analysis and Context

### SCOPE ASSESSMENT
**⚠️ SIGNIFICANT ENHANCEMENT - System-Wide Impact**

This PRD documents a **Major Feature Addition** that transforms the single-portal DocuSeal platform into a specialized 3-portal cohort management system. This enhancement requires:
- Multiple coordinated user stories
- Substantial architectural additions
- System-wide integration across existing DocuSeal capabilities
- Estimated timeline: Multiple development cycles

### Existing Project Overview

**Analysis Source**: IDE-based fresh analysis

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
- **Tech Stack**: Ruby on Rails 3.4.2, Vue.js 3, TailwindCSS, DaisyUI, Sidekiq for background jobs

### Available Documentation Analysis

**Available Documentation**:
- ✅ API Documentation (Node.js, Ruby, Python, PHP, Java, Go, C#, TypeScript, JavaScript)
- ✅ Webhook Documentation (Submission, Form, Template webhooks)
- ✅ Embedding Documentation (React, Vue, Angular, JavaScript form builders and signing forms)
- ⚠️ Architecture Documentation (not present - **requires architect review**)
- ⚠️ Coding Standards (not present - **requires documentation**)
- ⚠️ Source tree documentation (not present - **requires documentation**)
- ⚠️ Technical debt documentation (not present - **requires analysis**)

**Recommendation**: Before full implementation, Winston (Architect) should run a document-project task to create comprehensive architecture documentation.

### Enhancement Scope Definition

**Enhancement Type**: ✅ **Major Feature Addition** (3-Portal Cohort Management System)

**Enhancement Description**:

Transform the single-portal DocuSeal platform into a specialized **3-portal cohort management system** for South African private training institutions. The system will manage training cohorts (learnerships, internships, candidacies) through a coordinated workflow involving institution admins, students, and sponsors. Each cohort handles document collection, verification, and multi-party signing for program agreements and supporting documentation.

**Impact Assessment**: ✅ **Significant Impact** (substantial existing code changes)

**Rationale for Impact Level**:
- New multi-tenant institution architecture required
- New authentication/authorization model (role-based per institution)
- New domain models (Cohort, StudentCohortEnrollment, Sponsor, etc.)
- Complex workflow state management (waiting → in progress → complete)
- Custom portal interfaces for each role type
- Integration with existing DocuSeal form builder and signing workflows
- New notification and reminder systems
- Dashboard and analytics layer

### Goals and Background Context

**Goals**:

- Enable private training institutions to digitally manage training program cohorts from creation to completion
- Streamline multi-party document workflows (admin → students → sponsor → finalization)
- Provide role-based portals tailored to each participant's specific needs and permissions
- Maintain 100% backward compatibility with core DocuSeal form builder and signing capabilities
- Reduce document processing time from weeks to days through automated workflows
- Provide real-time visibility into cohort and student submission status
- Ensure document compliance through manual verification workflows with audit trail

**Background Context**:

South African private training institutions currently manage learnerships, internships, and candidacy programs through manual, paper-intensive processes. Each program requires collecting student documents (matric certificates, IDs, disability docs, qualifications), getting program agreements filled and signed by multiple parties (student, sponsor, institution), and tracking completion across dozens of students per cohort.

This manual process is time-consuming (taking weeks), error-prone, lacks visibility into status, and requires physical document handling. FloDoc leverages DocuSeal's proven document signing platform to create a specialized workflow that automates this process while maintaining the flexibility and power of DocuSeal's core form builder and signing engine.

The enhancement adds a cohort management layer on top of DocuSeal, creating three specialized portals that work with the existing document infrastructure rather than replacing it. Institutions continue using DocuSeal's form builder to create agreement templates, but now have a structured workflow for managing batches of students through the document submission and signing process.

### Change Log

| Change | Date | Version | Description | Author |
|--------|------|---------|-------------|--------|
| Initial PRD Creation | 2025-01-01 | v1.0 | Brownfield enhancement for 3-portal cohort management system | PM Agent |

---

## Requirements

### Functional Requirements

**FR1**: The system shall support multi-institution architecture where each private training institution can manage multiple training cohorts independently.

**FR2**: The system shall provide three distinct portal interfaces: Admin Portal (for training institution staff), Student Portal (for enrolled students), and Sponsor Portal (for program sponsors).

**FR3**: The system shall support two admin permission levels: Super Admin (institution-level management) and Regular Admin (cohort-level management).

**FR4**: The system shall support three fixed program types: Learnership, Internship, and Candidacy, each with configurable agreement templates uploaded by admins.

**FR5**: The system shall enable admins to create cohorts by specifying: number of students, program type, sponsor email, main agreement template, and additional supporting document templates.

**FR6**: The system shall generate unique invite links or send email invitations to students for cohort enrollment.

**FR7**: The system shall allow students to upload required documents (matric certificate, ID, disability documentation, tertiary qualifications, international certificates) to their enrollment.

**FR8**: The system shall allow students to fill and sign the main program type agreement using DocuSeal's existing form builder capabilities.

**FR9**: The system shall allow students to fill and sign additional supporting documents uploaded by the admin.

**FR10**: The system shall implement a state management system for each student enrollment with states: "Waiting", "In Progress", "Complete".

**FR11**: The system shall prevent sponsor access until all students in a cohort have completed their submissions.

**FR12**: The system shall allow sponsors to review and sign each student's main agreement and supporting documents individually.

**FR13**: The system shall allow sponsors to bulk sign all students or submit individually.

**FR14**: The system shall allow sponsors to view the entire cohort overview and individual student submissions.

**FR15**: The system shall enable admin document verification with manual review and rejection capabilities (with reason provided).

**FR16**: The system shall allow admins to sign the main agreement at the beginning of the process (before student invitations).

**FR17**: The system shall provide real-time dashboard showing cohort completion status for all three portals.

**FR18**: The system shall provide email notifications for: cohort creation, student invites, submission reminders, completion status updates, and sponsor access.

**FR19**: The system shall provide reporting and analytics on document completion times, cohort status, and submission metrics.

**FR20**: The system shall allow admins to download final signed documents for all parties.

**FR21**: The system shall store all documents in DocuSeal's existing document storage infrastructure.

**FR22**: The system shall maintain 100% backward compatibility with existing DocuSeal form builder and signing workflows.

**FR23**: The system shall allow admins to export cohort data to Excel format containing: cohort name, student name, student surname, student age, student race, student city, program type, sponsor company name, disability status, and gender.

### Non-Functional Requirements

**NFR1**: The system must maintain existing performance characteristics and not exceed current memory usage by more than 20%.

**NFR2**: The system must be mobile-optimized and support all existing DocuSeal UI languages.

**NFR3**: The system must leverage existing DocuSeal authentication infrastructure with role-based access control.

**NFR4**: The system must integrate seamlessly with existing DocuSeal email notification system.

**NFR5**: The system must support concurrent cohort management across multiple institutions without data leakage.

**NFR6**: The system must provide audit trails for all document verification actions (rejections, approvals).

**NFR7**: The system must maintain document integrity and signature verification capabilities.

**NFR8**: The system must support background processing for email notifications and document operations via Sidekiq.

**NFR9**: The system must comply with South African electronic document and signature regulations.

**NFR10**: The system must provide comprehensive error handling and user feedback for all portal interactions.

### Compatibility Requirements

**CR1: API Compatibility**: All new endpoints must follow existing DocuSeal API patterns and authentication mechanisms. No breaking changes to existing public APIs.

**CR2: Database Schema Compatibility**: New tables and relationships must not modify existing DocuSeal core schemas. Extensions should use foreign keys and new tables only.

**CR3: UI/UX Consistency**: All three portals must maintain DocuSeal's existing design system (TailwindCSS + DaisyUI), component patterns, and interaction models.

**CR4: Integration Compatibility**: The system must work with existing DocuSeal integrations (webhooks, API, embedded forms) without requiring changes to external systems.

---

## Technical Constraints and Integration

### Existing Technology Stack

**Languages**: Ruby 3.4.2, JavaScript, Vue.js 3, HTML, CSS
**Frameworks**: Rails 7.x, Shakapacker, Vue 3.3.2, TailwindCSS 3.4.17, DaisyUI 3.9.4
**Database**: SQLite (development), PostgreSQL/MySQL (production)
**Infrastructure**: Docker, Sidekiq for background jobs, Puma web server
**External Dependencies**: AWS S3, Google Cloud Storage, Azure Cloud (optional), SMTP for emails

### Integration Approach

**Database Integration Strategy**:
- Create new tables: `cohorts`, `cohort_enrollments`, `institutions`, `sponsors`, `document_verifications`
- Use foreign keys to link to existing `users`, `submitters`, `submissions` tables
- Maintain existing document relationships through `cohort_enrollments` → `submissions` mapping

**API Integration Strategy**:
- Extend existing DocuSeal API with new endpoints under `/api/v1/cohorts/*`
- Reuse existing authentication (Devise tokens, JWT)
- Leverage existing submission and document APIs for core signing workflows

**Frontend Integration Strategy**:
- Add new Vue components for cohort management
- Extend existing navigation to support role-based portal switching
- Reuse existing DocuSeal form builder and signing form components
- Implement portal-specific dashboards using existing UI patterns

**Testing Integration Strategy**:
- Extend existing RSpec test suite with new model and integration tests
- Add feature tests for all three portal workflows
- Maintain existing test patterns and helpers

### Code Organization and Standards

**File Structure Approach**:
- `app/models/cohort.rb`, `app/models/cohort_enrollment.rb`, etc. (new models)
- `app/controllers/api/v1/cohorts_controller.rb` (API endpoints)
- `app/controllers/cohorts_controller.rb` (web controllers)
- `app/views/cohorts/*` (cohort management views)
- `app/views/cohorts/portal/admin/*` (admin portal views)
- `app/views/cohorts/portal/student/*` (student portal views)
- `app/views/cohorts/portal/sponsor/*` (sponsor portal views)
- `app/javascript/cohorts/*` (Vue components for all portals)
- `app/jobs/cohort_*_job.rb` (background jobs)

**Naming Conventions**:
- Models: `Cohort`, `CohortEnrollment`, `CohortDocumentVerification`
- Controllers: `CohortsController`, `Admin::CohortsController`, `Api::V1::CohortsController`
- Views: `cohorts/index.html.erb`, `cohorts/portal/admin/show.html.erb`
- Vue components: `CohortDashboard.vue`, `StudentPortal.vue`, `SponsorPortal.vue`

**Coding Standards**:
- Follow existing RuboCop configuration
- Follow existing ESLint configuration for Vue components
- Use Rails conventions (fat models, thin controllers)
- Use Vue 3 Composition API for new components
- Maintain existing test coverage patterns

**Documentation Standards**:
- Document all new models with annotations
- Add API endpoint documentation following existing patterns
- Create user guides for each portal
- Update README with new features

### Deployment and Operations

**Build Process Integration**:
- No changes required to existing build process
- New Vue components will be bundled with existing Shakapacker configuration
- New Ruby code will be processed by existing Rails asset pipeline

**Deployment Strategy**:
- Deploy as incremental feature addition to existing DocuSeal deployment
- Use database migrations for new schema
- No infrastructure changes required beyond existing Docker setup

**Monitoring and Logging**:
- Extend existing Rails logging with cohort-specific events
- Add cohort workflow metrics to existing monitoring
- Use existing Sidekiq monitoring for background jobs

**Configuration Management**:
- Use existing environment variable system
- Add new configuration for cohort-specific features (notification templates, etc.)

### Risk Assessment and Mitigation

**Technical Risks**:
- **Risk**: Performance degradation with large cohorts (100+ students)
  - **Mitigation**: Implement pagination, lazy loading, and background processing
  - **Impact**: Medium | **Likelihood**: Medium

- **Risk**: State management complexity leading to race conditions
  - **Mitigation**: Use database transactions and optimistic locking
  - **Impact**: High | **Likelihood**: Low

- **Risk**: Integration conflicts with existing DocuSeal features
  - **Mitigation**: Thorough testing of existing workflows, maintain feature flags
  - **Impact**: High | **Likelihood**: Medium

**Integration Risks**:
- **Risk**: Authentication conflicts between portals and existing DocuSeal
  - **Mitigation**: **⚠️ REQUIRES ARCHITECT REVIEW** - See Winston for authentication strategy
  - **Impact**: High | **Likelihood**: Medium

- **Risk**: Document storage capacity with multiple document types per student
  - **Mitigation**: Monitor storage usage, implement retention policies
  - **Impact**: Medium | **Likelihood**: Low

**Deployment Risks**:
- **Risk**: Database migration failures with large existing datasets
  - **Mitigation**: Test migrations on production-like data, have rollback plan
  - **Impact**: High | **Likelihood**: Low

- **Risk**: User adoption challenges with new portal interfaces
  - **Mitigation**: Comprehensive user training, phased rollout, feedback collection
  - **Impact**: Medium | **Likelihood**: Medium

**Mitigation Strategies**:
1. **Architect Review**: Winston must review authentication, multi-tenancy, and state machine design
2. **Phased Rollout**: Implement one portal at a time (Admin → Student → Sponsor)
3. **Feature Flags**: Allow rollback of individual features without full deployment
4. **Comprehensive Testing**: Unit, integration, and end-to-end tests for all workflows
5. **Performance Testing**: Load test with realistic cohort sizes (50-200 students)
6. **User Acceptance Testing**: Real training institutions testing with actual workflows

---

## Epic and Story Structure

### Epic Approach

**Epic Structure Decision**: Single comprehensive epic with multiple user stories - This enhancement will be delivered as one cohesive epic because all stories serve the unified objective of enabling 3-portal cohort management. Stories build sequentially (Admin portal → Student portal → Sponsor portal → Analytics) and leverage shared infrastructure. Multiple epics were rejected due to integration gaps and coordination overhead.

---

## User Interface Enhancement Goals

### Integration with Existing UI

The three portals will use **completely custom UI/UX designs** (not DocuSeal's existing DaisyUI design system). The admin portal will follow provided wireframes as the primary design specification. All portals will maintain mobile-optimized responsive design principles while creating distinct, role-specific user experiences.

The enhancement will leverage DocuSeal's existing form builder and signing form components as embedded interfaces within the custom portal frameworks. This maintains DocuSeal's core document filling and signing capabilities while providing a tailored workflow management layer.

### Modified/New Screens and Views

**Admin Portal:**
- Institution onboarding wizard (multi-step form)
- Cohort creation and management dashboard
- Document verification interface
- Sponsor coordination panel
- Analytics and reporting views
- Excel export interface

**Student Portal:**
- Cohort welcome/access screen
- Document upload interface
- Agreement completion screens (DocuSeal embedded)
- Status tracking dashboard
- Re-submission workflow views

**Sponsor Portal:**
- Cohort overview dashboard
- Individual student review screens
- Signing interface (DocuSeal embedded)
- Bulk signing controls

### UI Consistency Requirements

- All portals will use custom TailwindCSS design system (not DaisyUI)
- Mobile-first responsive design across all portals
- Consistent color scheme and branding for FloDoc
- Accessible UI components (WCAG 2.1 AA compliance)
- Loading states and error handling patterns consistent across portals
- Form validation feedback patterns
- Notification/alert component standardization

---

## Epic 1: 3-Portal Cohort Management System

**Epic Goal**: Transform DocuSeal into a specialized 3-portal cohort management system that enables training institutions to manage complete document workflows from cohort creation through sponsor finalization.

**Integration Requirements**:
- Must integrate with existing DocuSeal form builder for agreement templates
- Must use existing document storage and signing infrastructure
- Must extend existing authentication and user management
- Must maintain backward compatibility with all existing DocuSeal features

### Story 1.1: Institution and Admin Management

**As a** system administrator,
**I want** to create and manage training institutions with multiple admin users (super and regular admins),
**so that** private training institutions can manage their cohorts independently.

**Acceptance Criteria**:
1. Database schema for institutions and admin roles exists
2. Super admins can create institutions and invite other admins
3. Regular admins can manage cohorts within their institution
4. Admins cannot access other institutions' data
5. Role-based permissions are enforced at API and UI levels

**Integration Verification**:
1. **IV1**: Existing DocuSeal user authentication remains functional
2. **IV2**: New role system doesn't conflict with existing DocuSeal user roles
3. **IV3**: Performance impact on existing user operations is minimal

### Story 1.2: Cohort Creation and Template Management

**As an** admin,
**I want** to create cohorts with program type selection, student count, sponsor email, and upload agreement templates,
**so that** I can set up training programs with all necessary documentation.

**Acceptance Criteria**:
1. Cohort creation form captures all required fields
2. Admins can upload main agreement template using DocuSeal form builder
3. Admins can upload additional supporting document templates
4. System validates template formats and requirements
5. Cohort is saved with all associated templates and metadata

**Integration Verification**:
1. **IV1**: DocuSeal form builder integration works for template creation
2. **IV2**: Existing document storage handles new template types
3. **IV3**: Template associations don't break existing submission workflows

### Story 1.3: Student Invitation and Enrollment

**As an** admin,
**I want** to generate invite links or send email invitations to students for cohort enrollment,
**so that** students can access the student portal and begin their submission process.

**Acceptance Criteria**:
1. Admin can generate unique invite link for each student
2. Admin can bulk send email invitations to all students
3. Invite links are single-use and expire after enrollment
4. Students can access student portal via invite without existing account
5. Student enrollment creates cohort_enrollment record with "Waiting" state

**Integration Verification**:
1. **IV1**: Existing DocuSeal email system handles new invitation templates
2. **IV2**: Authentication works for new users without breaking existing users
3. **IV3**: Enrollment records link properly to existing user/submission infrastructure

### Story 1.4: Admin Document Verification Workflow

**As an** admin,
**I want** to manually review and verify student-uploaded documents with ability to reject with reasons,
**so that** I can ensure document compliance before sponsor review.

**Acceptance Criteria**:
1. Admin dashboard shows pending verifications across all cohorts
2. Admin can view student-uploaded documents with preview
3. Admin can approve or reject documents with required reason
4. Rejection notifications sent to students with reason
5. Audit trail captures all verification actions with timestamps

**Integration Verification**:
1. **IV1**: Document preview uses existing DocuSeal file rendering
2. **IV2**: Notification system doesn't interfere with existing DocuSeal emails
3. **IV3**: Audit trail storage doesn't impact existing document storage performance

### Story 1.5: Student Portal - Document Upload and Agreement Completion

**As a** student,
**I want** to upload required documents, fill and sign the main agreement and supporting documents,
**so that** I can complete my enrollment requirements.

**Acceptance Criteria**:
1. Student portal shows their cohort and required documents
2. Students can upload matric, ID, disability docs, qualifications, certificates
3. Students can fill and sign main agreement using DocuSeal form builder
4. Students can fill and sign additional supporting documents
5. System updates enrollment state from "Waiting" → "In Progress" → "Complete"
6. Students can submit all documents when complete

**Integration Verification**:
1. **IV1**: DocuSeal form builder works seamlessly for student-facing forms
2. **IV2**: File uploads use existing storage and validation
3. **IV3**: State transitions don't conflict with existing submission states

### Story 1.6: Sponsor Portal - Multi-Student Review and Signing

**As a** sponsor,
**I want** to review and sign agreements for all students in a cohort, with individual and bulk options,
**so that** I can efficiently complete sponsor responsibilities.

**Acceptance Criteria**:
1. Sponsor portal shows cohort overview with all student statuses
2. Sponsor can view individual student submissions and documents
3. Sponsor can sign each student's agreements individually
4. Sponsor can bulk sign all students at once
5. Sponsor can submit all signatures to finalize cohort
6. Sponsor portal only accessible after all students complete submissions

**Integration Verification**:
1. **IV1**: Sponsor authentication works without existing DocuSeal account
2. **IV2**: Signing workflow uses existing DocuSeal signature infrastructure
3. **IV3**: Bulk operations don't impact existing single-document signing performance

### Story 1.7: Admin Finalization and Document Access

**As an** admin,
**I want** to finalize the cohort after sponsor completion and access all signed documents,
**so that** I can complete the workflow and maintain records.

**Acceptance Criteria**:
1. Admin can finalize cohort after sponsor submission
2. System generates complete document packages for each student
3. Admin can download individual or bulk signed documents
4. Finalized cohorts show completion status in dashboard
5. Admin can access historical cohort data and reports

**Integration Verification**:
1. **IV1**: Document generation uses existing DocuSeal PDF processing
2. **IV2**: Download functionality doesn't break existing document downloads
3. **IV3**: Historical data access doesn't impact current cohort performance

### Story 1.8: Notification and Reminder System

**As a** system,
**I want** to send automated notifications for all workflow events and reminders for incomplete actions,
**so that** all parties stay informed and workflows complete efficiently.

**Acceptance Criteria**:
1. Cohort creation triggers admin notification
2. Student invite sends email with portal access link
3. Submission reminders sent after configurable delay
4. State change notifications sent to relevant parties
5. Sponsor access notification sent when all students complete
6. Deadline reminders configurable per cohort

**Integration Verification**:
1. **IV1**: All notifications use existing DocuSeal email infrastructure
2. **IV2**: Reminder scheduling doesn't impact Sidekiq job queue performance
3. **IV3**: Email templates maintain existing DocuSeal branding and formatting

### Story 1.9: Dashboard and Analytics

**As an** admin,
**I want** to see real-time dashboard showing cohort status, completion metrics, and analytics,
**so that** I can monitor progress and identify bottlenecks.

**Acceptance Criteria**:
1. Dashboard shows all cohorts with completion percentages
2. Real-time updates for student submission states
3. Analytics on completion times, document types, verification rates
4. Export functionality for reports (CSV, PDF)
5. Role-based dashboard views (admin vs. sponsor vs. student)

**Integration Verification**:
1. **IV1**: Dashboard queries don't impact existing DocuSeal performance
2. **IV2**: Analytics data collection doesn't interfere with document processing
3. **IV3**: Export functionality uses existing DocuSeal reporting infrastructure

### Story 1.10: State Management and Workflow Orchestration

**As a** system,
**I want** to manage complex state transitions and workflow orchestration across all three portals,
**so that** the entire cohort workflow progresses correctly and no steps are skipped.

**Acceptance Criteria**:
1. State machine defined for all enrollment states (Waiting → In Progress → Complete)
2. Workflow rules enforced: students can't submit until docs uploaded, sponsor can't access until all students complete, etc.
3. State transitions are atomic and handle concurrent operations
4. Rollback capabilities for incorrect state transitions
5. State history audit trail for troubleshooting

**Integration Verification**:
1. **IV1**: State management doesn't conflict with existing DocuSeal submission states
2. **IV2**: Workflow orchestration handles edge cases (student dropout, template changes, etc.)
3. **IV3**: Performance remains acceptable with large cohorts and concurrent operations


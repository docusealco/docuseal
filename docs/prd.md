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
| **PO Validation Fixes** | 2026-01-14 | v2.1 | Addressed 3 blocking issues, added scope declaration | PO/PM |

---

### 1.7 SCOPE BOUNDARIES & DEPLOYMENT STRATEGY

**Deployment Decision:** ✅ **Local Docker MVP Only** (Option A)

**Rationale:**
- Management wants to validate FloDoc system locally first
- Defers production infrastructure investment until MVP proven
- Fastest path to working demo
- No cloud costs during validation phase

---

#### In Scope (MVP - Local Docker)

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

---

## 2. Requirements

### 2.1 FUNCTIONAL REQUIREMENTS (FR)

#### FR1: Institution Management
**Priority**: P0 - Critical
**Description**: Single institution record per deployment
- Create institution with name, email, contact person, phone
- Settings stored in JSONB for flexibility
- No multi-tenancy (single institution model)

#### FR2: Cohort Creation
**Priority**: P0 - Critical
**Description**: 5-step cohort creation workflow
- Step 1: Cohort name
- Step 2: Program type (learnership/internship/candidacy)
- Step 3: Student emails (manual entry or bulk upload)
- Step 4: Sponsor email (single email for all cohort documents)
- Step 5: Upload documents + specify required student uploads

#### FR3: Cohort Status Management
**Priority**: P0 - Critical
**Description**: State tracking through workflow phases
- Status: draft → active → completed
- Timestamp tracking: tp_signed_at, students_completed_at, sponsor_completed_at, finalized_at

#### FR4: Student Enrollment
**Priority**: P0 - Critical
**Description**: Ad-hoc student enrollment without account creation
- Students access via email links
- Track enrollment status: waiting → in_progress → complete
- Required document uploads tracked per enrollment

#### FR5: Sponsor Portal
**Priority**: P0 - Critical
**Description**: Single email for all cohort assignments
- 3-panel view: student list | document viewer | student info
- Individual or bulk completion
- No duplicate emails rule

#### FR6: TP Signing Phase
**Priority**: P0 - Critical
**Description**: TP initiates signing before students/sponsor
- TP signs first student
- System auto-fills/signs remaining students
- Must complete before student enrollment begins

#### FR7: TP Review Phase
**Priority**: P0 - Critical
**Description**: Final review after sponsor completion
- Review all completed documents
- Finalize 3-party agreements
- Generate audit trail

#### FR8: Bulk Operations
**Priority**: P1 - High
**Description**: Reduce repetitive work
- Bulk student email upload
- Fill once, replicate for all students
- Bulk sponsor completion

#### FR9: Email Management
**Priority**: P0 - Critical
**Description**: Smart email delivery rules
- Single email per sponsor per cohort
- Bulk invite emails to students
- Reminder emails with configurable intervals

#### FR10: PDF Generation & Download
**Priority**: P0 - Critical
**Description**: Final document packaging
- Generate signed PDFs per student
- Bulk ZIP download: Cohort_Name/Student_Name/All_Docs.pdf
- Include Audit_Trail.pdf

#### FR11: Dashboard & Analytics
**Priority**: P1 - High
**Description**: Real-time status visibility
- Cohort overview (total students, completed, pending)
- Student status tracking
- Sponsor completion status

#### FR12: Document Templates
**Priority**: P0 - Critical
**Description**: Leverage existing DocuSeal templates
- Use existing form builder
- Map signatories (Learner, Sponsor, TP)
- Support multiple documents per cohort

#### FR13: Ad-hoc Access Links
**Priority**: P0 - Critical
**Description**: Secure access without authentication
- Short-lived tokens
- Email verification
- Role-based access (student vs sponsor)

#### FR14: Audit Trail
**Priority**: P1 - High
**Description**: Complete audit logging
- All actions logged with timestamps
- User identification
- Document versioning

#### FR15: Data Retention
**Priority**: P2 - Medium
**Description**: POPIA compliance
- Configurable retention periods
- Soft delete implementation
- Data export capabilities

#### FR16: Error Handling
**Priority**: P1 - High
**Description**: Graceful failure handling
- Validation errors with clear messages
- Transaction rollback on failures
- Retry mechanisms for background jobs

#### FR17: Mobile Responsiveness
**Priority**: P1 - High
**Description**: All portals mobile-friendly
- Responsive design
- Touch-optimized interactions
- Cross-browser compatibility

#### FR18: Real-time Updates
**Priority**: P2 - Medium
**Description**: Live status changes
- WebSocket or polling for updates
- Instant status reflection
- Notification badges

#### FR19: Bulk Import Validation
**Priority**: P1 - High
**Description**: Validate bulk student uploads
- Email format validation
- Duplicate detection
- Error reporting

#### FR20: Configurable Program Types
**Priority**: P2 - Medium
**Description**: Flexible program categorization
- learnership
- internship
- candidacy
- Extensible for future types

#### FR21: Required Document Types
**Priority**: P1 - High
**Description**: Track required student uploads
- ID copy
- Matric certificate
- Tertiary qualifications
- Custom document types

#### FR22: Reminder System
**Priority**: P2 - Medium
**Description**: Automated reminders
- Configurable intervals
- Email notifications
- Escalation rules

#### FR23: Excel Export
**Priority**: P1 - High
**Description**: Export cohort data
- Student list with status
- Completion rates
- Metadata export

#### FR24: Feature Flags
**Priority**: P2 - Medium
**Description**: Toggle FloDoc features
- Enable/disable FloDoc module
- Gradual rollout support
- Environment-based configuration

---

### 2.2 NON-FUNCTIONAL REQUIREMENTS (NFR)

#### NFR1: Performance
**Baseline**: DocuSeal performance metrics
**Target**: <20% degradation
**Metrics**:
- Page load: <1.2s
- PDF generation: <2.4s
- DB query (complex): <120ms
- Sidekiq job: <600ms

#### NFR2: Security
**Standard**: Production-ready security
**Requirements**:
- CSRF protection
- XSS prevention via Vue auto-escaping
- SQL injection prevention via ActiveRecord
- Input validation on all endpoints
- Secure token generation for ad-hoc links
- HTTPS enforcement in production

#### NFR3: Data Integrity
**Requirements**:
- Foreign key constraints on all relationships
- Unique constraints where applicable
- Transaction-based operations
- Atomic state transitions
- Audit trail for all critical operations

#### NFR4: Scalability
**Target**: Support 100+ cohorts, 1000+ students
**Requirements**:
- Indexed database queries
- Efficient eager loading
- Background job processing
- Caching where appropriate

#### NFR5: Reliability
**Requirements**:
- 99.9% uptime for MVP
- Graceful error handling
- Automatic retry for transient failures
- Data backup and recovery
- Transaction rollback on failures

#### NFR6: Maintainability
**Requirements**:
- Clear code structure
- Comprehensive documentation
- Follow Rails conventions
- Consistent naming patterns
- Test coverage >80%

#### NFR7: Testability
**Requirements**:
- Unit tests for all models
- Request specs for API endpoints
- System specs for critical workflows
- Vue component tests
- E2E tests for 3-portal workflow

#### NFR8: Observability
**Requirements**:
- Structured logging
- Error tracking
- Performance monitoring
- Email delivery tracking
- Webhook delivery tracking

#### NFR9: Accessibility
**Requirements**:
- WCAG 2.1 AA compliance
- Keyboard navigation
- Screen reader support
- Color contrast requirements

#### NFR10: Internationalization
**Requirements**:
- Support for multiple languages (initially English)
- I18n-ready architecture
- Easy translation addition

---

### 2.3 UI/UX REQUIREMENTS

#### UI1: TP Portal (Admin)
**Design**: Custom FloDoc branding (not DaisyUI defaults)
**Features**:
- Cohort creation wizard (5 steps)
- Dashboard with cohort overview
- Student management list
- Sponsor management
- Document mapping interface
- Bulk operations panel
- Settings page

#### UI2: Student Portal
**Design**: Simple, focused interface
**Features**:
- Document upload interface
- Form filling workflow
- Status indicator
- Mobile-optimized

#### UI3: Sponsor Portal
**Design**: 3-panel layout
**Features**:
- Left panel: Student list with status
- Center panel: Document viewer
- Right panel: Student info
- Bulk completion controls

#### UI4: Common UI Elements
**Requirements**:
- Consistent navigation
- Loading states
- Error states
- Success notifications
- Confirmation dialogs

---

### 2.4 INTEGRATION REQUIREMENTS

#### IR1: DocuSeal Integration
**Points**:
- Template model integration
- Submission model integration
- Submitter model integration
- PDF generation via HexaPDF
- Form builder reuse

#### IR2: Authentication Integration
**Points**:
- Devise for TP users
- Ad-hoc tokens for students/sponsors
- 2FA for TP users (existing)

#### IR3: Email Integration
**Points**:
- Action Mailer
- Sidekiq queue (mailers)
- Email event tracking
- Template reuse

#### IR4: Storage Integration
**Points**:
- Active Storage
- S3/Minio for documents
- File attachment management

#### IR5: Background Jobs
**Points**:
- Sidekiq integration
- Queue management
- Job prioritization
- Retry logic

---

### 2.5 SECURITY REQUIREMENTS

#### SR1: Data Protection
- Encryption at rest for sensitive fields
- Secure token generation
- Token expiration
- Access control validation

#### SR2: Input Validation
- All user inputs validated
- SQL injection prevention
- XSS prevention
- File upload validation

#### SR3: Authentication
- TP users: Devise + 2FA
- Students: Ad-hoc tokens with email verification
- Sponsors: Ad-hoc tokens with email verification

#### SR4: Authorization
- Role-based access control
- Institution isolation (single institution)
- Resource ownership checks

#### SR5: Audit Trail
- All critical actions logged
- User identification
- Timestamp recording
- Immutable logs

---

### 2.6 COMPLIANCE REQUIREMENTS

#### CR1: POPIA (South African Data Protection)
- Data minimization
- Purpose limitation
- Storage limitation
- Data subject rights
- Breach notification

#### CR2: Email Communication
- CAN-SPAM compliance
- Unsubscribe mechanism
- Clear sender identification

---

## 3. User Interface Enhancement Goals

### UI1: Custom Design System
**Goal**: Distinct FloDoc branding
**Implementation**:
- Custom color palette
- Typography system
- Component library
- Layout patterns

### UI2: Wizard Interfaces
**Goal**: Simplify complex workflows
**Implementation**:
- Step indicators
- Progress tracking
- Validation feedback
- Save draft functionality

### UI3: Dashboard Design
**Goal**: Real-time visibility
**Implementation**:
- Status cards
- Progress bars
- Action buttons
- Filterable lists

### UI4: Mobile Optimization
**Goal**: Full mobile support
**Implementation**:
- Responsive breakpoints
- Touch-friendly controls
- Optimized layouts
- Performance tuning

### UI5: Accessibility
**Goal**: WCAG 2.1 AA
**Implementation**:
- Semantic HTML
- ARIA labels
- Keyboard navigation
- Screen reader support

### UI6: Loading States
**Goal**: Smooth UX
**Implementation**:
- Skeleton screens
- Spinners
- Progress indicators
- Optimistic updates

### UI7: Error Handling
**Goal**: Clear feedback
**Implementation**:
- Inline validation
- Error banners
- Help text
- Recovery options

### UI8: Confirmation Flows
**Goal**: Prevent mistakes
**Implementation**:
- Confirmation dialogs
- Undo functionality
- Warning messages
- Critical action guards

### UI9: Bulk Operations UI
**Goal**: Efficient batch actions
**Implementation**:
- Select all/none
- Bulk action toolbar
- Progress tracking
- Error aggregation

### UI10: Real-time Updates
**Goal**: Live status changes
**Implementation**:
- Status indicators
- Notification badges
- Auto-refresh
- WebSocket (optional)

---

## 4. Technical Constraints and Integration

### TC1: Brownfield Constraints
**Constraint**: Must integrate with existing DocuSeal
**Impact**:
- Cannot modify core DocuSeal models extensively
- Must use existing template/submission/submitter patterns
- New tables must reference existing tables via foreign keys

### TC2: Single Institution Model
**Constraint**: Not multi-tenant
**Impact**:
- One institution record per deployment
- No account switching
- Simplified access control

### TC3: Ad-hoc Access Pattern
**Constraint**: No account creation for students/sponsors
**Impact**:
- Token-based authentication
- Email verification required
- Short-lived access tokens
- No persistent sessions

### TC4: Database Schema
**Constraint**: Must use PostgreSQL/MySQL/SQLite
**Impact**:
- JSONB fields for flexibility
- Proper indexing strategy
- Foreign key constraints
- Migration rollback support

### TC5: Frontend Framework
**Constraint**: Vue.js 3 + Pinia
**Impact**:
- Composition API required
- Pinia stores for state
- Component-based architecture
- Shakapacker build system

### TC6: Styling Framework
**Constraint**: TailwindCSS + DaisyUI
**Impact**:
- Utility-first CSS
- Component customization
- Design system compliance
- Custom branding required

### TC7: Background Processing
**Constraint**: Sidekiq + Redis
**Impact**:
- Async job processing
- Queue management
- Retry logic
- Dead letter queue

### TC8: PDF Processing
**Constraint**: HexaPDF
**Impact**:
- Digital signatures
- Form field rendering
- PDF manipulation
- License requirements

### TC9: Email Delivery
**Constraint**: SMTP + Action Mailer
**Impact**:
- Template management
- Async delivery
- Event tracking
- Testing (MailHog)

### TC10: Storage
**Constraint**: Active Storage
**Impact**:
- Multiple backend support
- File attachments
- Direct uploads
- CDN support (production)

---

## 5. Epic and Story Structure

### 5.1 EPIC OVERVIEW

**Epic 1: Core Models & Infrastructure** (Stories 1.1-1.2)
- Database schema extension
- ActiveRecord models
- Relationships and validations

**Epic 2: API Layer** (Stories 2.1-2.3)
- RESTful endpoints
- Authentication
- Business logic

**Epic 3: TP Portal - Admin Interface** (Stories 3.1-3.4)
- Cohort creation wizard
- Dashboard
- Student management
- Sponsor management

**Epic 4: Student Portal** (Stories 4.1-4.2)
- Enrollment interface
- Document upload
- Form filling

**Epic 5: Sponsor Portal** (Stories 5.1-5.2)
- 3-panel interface
- Bulk completion
- Document review

**Epic 6: Workflow & Automation** (Stories 6.1-6.3)
- Email notifications
- State management
- Bulk operations

**Epic 7: PDF & Export** (Stories 7.1-7.2)
- PDF generation
- Bulk download
- Excel export

**Epic 8: Infrastructure & Deployment** (Stories 8.0-8.0.1)
- Local Docker setup
- Demo readiness

---

### 5.2 STORY COUNT BY EPIC

| Epic | Stories | Status |
|------|---------|--------|
| 1. Core Models | 2 | Draft |
| 2. API Layer | 3 | Draft |
| 3. TP Portal | 4 | Draft |
| 4. Student Portal | 2 | Draft |
| 5. Sponsor Portal | 2 | Draft |
| 6. Workflow | 3 | Draft |
| 7. PDF & Export | 2 | Draft |
| 8. Infrastructure | 2 | ✅ Complete |
| **Total** | **20** | |

---

### 5.3 STORY PRIORITY DISTRIBUTION

**P0 - Critical (12 stories)**: Core functionality
**P1 - High (6 stories)**: Important features
**P2 - Medium (2 stories)**: Nice-to-have

---

### 5.4 DEPENDENCY MAPPING

```
1.1 → 1.2 → 2.1 → 2.2 → 2.3 → 3.1 → 3.2 → 3.3 → 3.4
                                      ↓
4.1 → 4.2 → 5.1 → 5.2 → 6.1 → 6.2 → 6.3 → 7.1 → 7.2
```

---

### 5.5 TESTING STRATEGY

**Unit Tests**: All models, services, helpers
**Request Specs**: All API endpoints
**System Specs**: Critical workflows
**Vue Tests**: All components
**E2E Tests**: 3-portal workflow

---

### 5.6 DOCUMENTATION REQUIREMENTS

**Per Story**:
- Technical implementation notes
- Code examples
- Test requirements
- Rollback procedures
- Risk assessment

**Overall**:
- Architecture diagrams
- API documentation
- Deployment guide
- User manuals

---

## 6. Epic Details

### 6.1 EPIC 1: Core Models & Infrastructure

**Objective**: Establish foundation with database schema and models

**Stories**:
- **Story 1.1**: Database Schema Extension
- **Story 1.2**: ActiveRecord Models & Relationships

**Key Deliverables**:
- 3 new tables (institutions, cohorts, cohort_enrollments)
- ActiveRecord models with validations
- Foreign key constraints
- Indexes for performance
- Migration strategy

**Integration Points**:
- References to existing `templates` table
- References to existing `submissions` table
- Backward compatibility maintained

---

### 6.2 EPIC 2: API Layer

**Objective**: Build RESTful API for all portal operations

**Stories**:
- **Story 2.1**: Cohort Management API
- **Story 2.2**: Enrollment & Student API
- **Story 2.3**: Sponsor & Bulk Operations API

**Key Deliverables**:
- `/api/v1/flodoc/` namespace
- Authentication middleware
- Rate limiting
- Error handling
- API documentation

---

### 6.3 EPIC 3: TP Portal - Admin Interface

**Objective**: Complete admin portal for training providers

**Stories**:
- **Story 3.1**: Cohort Creation Wizard
- **Story 3.2**: TP Dashboard & Analytics
- **Story 3.3**: Student Management Interface
- **Story 3.4**: Sponsor Management & Document Mapping

**Key Deliverables**:
- 5-step wizard component
- Dashboard with real-time stats
- Student list with filters
- Sponsor assignment UI
- Document signatory mapping

---

### 6.4 EPIC 4: Student Portal

**Objective**: Student-facing interface for document completion

**Stories**:
- **Story 4.1**: Student Enrollment & Access
- **Story 4.2**: Document Upload & Form Filling

**Key Deliverables**:
- Ad-hoc access flow
- Document upload interface
- Form filling workflow
- Mobile-optimized UI

---

### 6.5 EPIC 5: Sponsor Portal

**Objective**: Sponsor interface for review and completion

**Stories**:
- **Story 5.1**: Sponsor 3-Panel Interface
- **Story 5.2**: Bulk Completion & Review

**Key Deliverables**:
- 3-panel layout (list | viewer | info)
- Individual completion
- Bulk completion
- Document viewer

---

### 6.6 EPIC 6: Workflow & Automation

**Objective**: Background jobs and state management

**Stories**:
- **Story 6.1**: Email Notification System
- **Story 6.2**: State Management & Transitions
- **Story 6.3**: Bulk Operations Engine

**Key Deliverables**:
- Email templates
- State machine
- Bulk job processing
- Reminder system

---

### 6.7 EPIC 7: PDF & Export

**Objective**: Document generation and data export

**Stories**:
- **Story 7.1**: PDF Generation & Signing
- **Story 7.2**: Bulk Download & Excel Export

**Key Deliverables**:
- PDF generation pipeline
- Bulk ZIP creation
- Excel export
- Audit trail generation

---

### 6.8 EPIC 8: Infrastructure & Deployment

**Objective**: Local Docker MVP setup and demo readiness

**Stories**:
- **Story 8.0**: Development Infrastructure Setup (Local Docker)
- **Story 8.0.1**: Management Demo Readiness & Validation

**Status**: ✅ **COMPLETE**

**Deliverables**:
- Docker Compose configuration
- Setup scripts
- Demo data generation
- Validation checklist

---
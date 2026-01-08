# Source Tree

## Existing Project Structure

```
floDoc-v3/
├── app/
│   ├── controllers/
│   │   ├── api/                          # RESTful API controllers
│   │   │   ├── api_base_controller.rb
│   │   │   ├── submissions_controller.rb
│   │   │   ├── templates_controller.rb
│   │   │   └── [15+ existing controllers]
│   │   ├── [30+ existing controllers]    # Dashboard, settings, etc.
│   ├── models/
│   │   ├── account.rb                    # Multi-tenancy root
│   │   ├── user.rb                       # Devise auth + 2FA
│   │   ├── template.rb                   # Document templates
│   │   ├── submission.rb                 # Document workflows
│   │   ├── submitter.rb                  # Signers/participants
│   │   ├── account_access.rb             # User permissions
│   │   └── [15+ supporting models]
│   ├── jobs/
│   │   ├── process_submitter_completion_job.rb
│   │   ├── send_submission_completed_webhook_request_job.rb
│   │   └── [15+ existing jobs]
│   ├── mailers/
│   │   ├── application_mailer.rb
│   │   ├── submitter_mailer.rb
│   │   └── user_mailer.rb
│   ├── javascript/
│   │   ├── application.js                # Vue 3 entry point
│   │   ├── template_builder/             # PDF form builder (15+ Vue components)
│   │   ├── submission_form/              # Signing interface (10+ Vue components)
│   │   └── elements/                     # Web Components (40+ custom elements)
│   └── views/
│       ├── mailers/                      # Email templates
│       └── shared/                       # Common partials
├── lib/
│   ├── submissions/                      # Core business logic
│   │   ├── generate_result_attachments.rb
│   │   ├── generate_combined_attachment.rb
│   │   └── [10+ submission modules]
│   ├── submitters/                       # Submitter logic
│   ├── templates/                        # Template processing
│   ├── pdf_utils.rb                      # HexaPDF wrapper
│   ├── docuseal.rb                       # Global config
│   ├── ability.rb                        # CanCanCan rules
│   └── send_webhook_request.rb           # Webhook delivery
├── config/
│   ├── routes.rb                         # All routes (200+ lines)
│   ├── database.yml                      # DB config
│   ├── storage.yml                       # Active Storage config
│   ├── sidekiq.yml                       # Background job config
│   └── shakapacker.yml                   # Webpack config
├── db/
│   ├── migrate/                          # Existing migrations
│   └── schema.rb                         # Current schema
└── docs/
    ├── prd.md                            # Product requirements
    └── architecture.md                   # This document
```

## New File Organization

```
floDoc-v3/
├── app/
│   ├── controllers/
│   │   ├── api/
│   │   │   ├── v1/
│   │   │   │   ├── cohorts_controller.rb          # NEW: Cohort API endpoints
│   │   │   │   ├── enrollments_controller.rb      # NEW: Enrollment API endpoints
│   │   │   │   └── sponsors_controller.rb         # NEW: Sponsor API endpoints
│   │   ├── cohorts/                               # NEW: Web controllers
│   │   │   ├── admin_controller.rb                # Admin portal web endpoints
│   │   │   ├── student_controller.rb              # Student portal web endpoints
│   │   │   └── sponsor_controller.rb              # Sponsor portal web endpoints
│   ├── models/
│   │   ├── cohort.rb                              # NEW: Cohort model
│   │   ├── cohort_enrollment.rb                   # NEW: Enrollment model
│   │   ├── institution.rb                         # NEW: Institution model
│   │   ├── sponsor.rb                             # NEW: Sponsor model
│   │   └── document_verification.rb               # NEW: Verification model
│   ├── jobs/
│   │   ├── cohort_reminder_job.rb                 # NEW: Cohort reminders
│   │   ├── cohort_completion_job.rb               # NEW: Workflow completion
│   │   └── excel_export_job.rb                    # NEW: FR23 Excel export
│   ├── mailers/
│   │   ├── cohort_mailer.rb                       # NEW: Cohort notifications
│   │   └── sponsor_mailer.rb                      # NEW: Sponsor notifications
│   ├── javascript/
│   │   ├── cohorts/                               # NEW: Cohort management
│   │   │   ├── admin/                             # Admin portal Vue app
│   │   │   │   ├── AdminPortal.vue
│   │   │   │   ├── CohortDashboard.vue
│   │   │   │   ├── CohortWizard.vue
│   │   │   │   ├── VerificationInterface.vue
│   │   │   │   ├── SponsorCoordinator.vue
│   │   │   │   ├── AnalyticsView.vue
│   │   │   │   └── ExcelExport.vue
│   │   │   ├── student/                           # Student portal Vue app
│   │   │   │   ├── StudentPortal.vue
│   │   │   │   ├── CohortWelcome.vue
│   │   │   │   ├── DocumentUpload.vue
│   │   │   │   ├── AgreementForm.vue
│   │   │   │   ├── StatusDashboard.vue
│   │   │   │   └── ResubmissionFlow.vue
│   │   │   └── sponsor/                           # Sponsor portal Vue app
│   │   │       ├── SponsorPortal.vue
│   │   │       ├── SponsorDashboard.vue
│   │   │       ├── StudentReview.vue
│   │   │       ├── BulkSigning.vue
│   │   │       └── CohortFinalization.vue
│   │   └── shared/                                # NEW: Shared portal components
│   │       ├── PortalNavigation.vue
│   │       ├── RoleSwitcher.vue
│   │       └── PortalNotifications.vue
│   └── views/
│       ├── cohorts/
│       │   ├── admin/
│       │   │   ├── index.html.erb
│       │   │   └── show.html.erb
│       │   ├── student/
│       │   │   ├── index.html.erb
│       │   │   └── show.html.erb
│       │   └── sponsor/
│       │       ├── index.html.erb
│       │       └── show.html.erb
│       └── mailers/
│           ├── cohort_mailer/
│           │   ├── cohort_created.html.erb
│           │   ├── student_invite.html.erb
│           │   └── sponsor_access.html.erb
│           └── sponsor_mailer/
│               └── cohort_ready.html.erb
├── lib/
│   ├── cohorts/                               # NEW: Cohort business logic
│   │   ├── cohort_workflow_service.rb
│   │   ├── enrollment_service.rb
│   │   ├── verification_service.rb
│   │   ├── sponsor_service.rb
│   │   ├── cohort_state_engine.rb
│   │   ├── enrollment_validator.rb
│   │   ├── sponsor_access_manager.rb
│   │   └── excel_export_service.rb
│   └── templates/
│       └── cohort_template_processor.rb       # NEW: Cohort template extensions
├── db/
│   ├── migrate/
│   │   ├── 20250102000001_create_institutions.rb
│   │   ├── 20250102000002_create_cohorts.rb
│   │   ├── 20250102000003_create_cohort_enrollments.rb
│   │   ├── 20250102000004_create_sponsors.rb
│   │   └── 20250102000005_create_document_verifications.rb
│   └── schema.rb                             # UPDATED: New tables added
├── config/
│   └── routes.rb                             # UPDATED: New cohort routes
└── docs/
    ├── architecture.md                       # This document
    └── cohort-workflows.md                   # NEW: Workflow documentation
```

## Integration Guidelines

**File Naming:**
- **Models:** `cohort.rb`, `cohort_enrollment.rb` (snake_case, singular)
- **Controllers:** `cohorts_controller.rb`, `admin_controller.rb` (plural for resources)
- **Vue Components:** `CohortDashboard.vue`, `StudentPortal.vue` (PascalCase)
- **Services:** `cohort_workflow_service.rb` (snake_case, descriptive)
- **Jobs:** `cohort_reminder_job.rb` (snake_case, _job suffix)

**Folder Organization:**
- **API Controllers:** `app/controllers/api/v1/cohorts/` (versioned, resource-based)
- **Web Controllers:** `app/controllers/cohorts/` (portal-specific)
- **Vue Apps:** `app/javascript/cohorts/{admin,student,sponsor}/` (portal separation)
- **Services:** `lib/cohorts/` (business logic separation)

**Import/Export Patterns:**
- **Ruby:** Follow existing patterns (service objects, concerns, modules)
- **Vue:** Use ES6 imports, Composition API, existing API client patterns
- **API:** Consistent JSON response format matching existing endpoints

---

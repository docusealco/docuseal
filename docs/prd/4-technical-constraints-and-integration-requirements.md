# 4. Technical Constraints and Integration Requirements

## 4.1 Existing Technology Stack

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

## 4.2 Integration Approach

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

## 4.3 Code Organization and Standards

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

## 4.4 Deployment and Operations

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

## 4.5 Risk Assessment and Mitigation

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


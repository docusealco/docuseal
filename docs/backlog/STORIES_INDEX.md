# FloDoc Stories Index - All 42 Stories

## 📋 Complete Story List

### Phase 1: Foundation (Stories 1.1 - 1.3)

| # | Story | Focus | Time |
|---|-------|-------|------|
| 1.1 | **Database Schema Extension** | Create 3 new tables (institutions, cohorts, cohort_enrollments) | 2-3 days |
| 1.2 | **Core Models Implementation** | ActiveRecord models with associations & validations | 2 days |
| 1.3 | **Authorization Layer Extension** | Cancancan abilities for 3-portal access control | 1-2 days |

### Phase 2: Backend Logic (Stories 2.1 - 2.8)

| # | Story | Focus | Time |
|---|-------|-------|------|
| 2.1 | **Cohort Creation & Management** | TP admin creates/manages cohorts | 4 hours |
| 2.2 | **TP Signing Phase Logic** | Prototype: Sign once, replicate to all students | 4 hours |
| 2.3 | **Student Enrollment Management** | Bulk create student submissions | 4 hours |
| 2.4 | **Sponsor Review Workflow** | Sponsor receives and reviews documents | 4 hours |
| 2.5 | **TP Review & Finalization** | TP reviews all submissions, finalizes cohort | 4 hours |
| 2.6 | **Excel Export for Cohort Data** | Export cohort data to Excel (FR23) | 4 hours |
| 2.7 | **Audit Log & Compliance** | Track all actions for compliance | 4 hours |
| 2.8 | **Cohort State Machine** | Workflow orchestration & state tracking | 4 hours |

### Phase 3: API Layer (Stories 3.1 - 3.4)

| # | Story | Focus | Time |
|---|-------|-------|------|
| 3.1 | **RESTful Cohort Management API** | CRUD APIs for cohorts | 4 hours |
| 3.2 | **Webhook Events** | State change notifications | 4 hours |
| 3.3 | **Student API (Ad-hoc)** | Token-based student access | 4 hours |
| 3.4 | **API Documentation** | OpenAPI/Swagger docs | 4 hours |

### Phase 4: Admin Portal (Stories 4.1 - 4.10)

| # | Story | Focus | Time |
|---|-------|-------|------|
| 4.1 | **Cohort Management Dashboard** | Overview of all cohorts | 4 hours |
| 4.2 | **Cohort Creation & Bulk Import** | Create cohorts + import students | 4 hours |
| 4.3 | **Cohort Detail Overview** | Single cohort view with status | 4 hours |
| 4.4 | **TP Signing Interface** | TP signing workflow UI | 4 hours |
| 4.5 | **Student Management View** | Manage student enrollments | 4 hours |
| 4.6 | **Sponsor Portal Dashboard** | Sponsor's cohort overview | 4 hours |
| 4.7 | **Sponsor Portal - Bulk Signing** | Sign multiple documents at once | 4 hours |
| 4.8 | **Sponsor Portal - Progress Tracking** | View completion status | 4 hours |
| 4.9 | **Sponsor Portal - Token Renewal** | Session management for ad-hoc access | 4 hours |
| 4.10 | **TP Portal - Monitoring & Analytics** | Cohort analytics dashboard | 4 hours |

### Phase 5: Student Portal (Stories 5.1 - 5.5)

| # | Story | Focus | Time |
|---|-------|-------|------|
| 5.1 | **Student Portal - Document Upload** | Upload required documents | 4 hours |
| 5.2 | **Student Portal - Form Filling** | Complete form fields | 4 hours |
| 5.3 | **Student Portal - Progress & Draft** | Save progress, resume later | 4 hours |
| 5.4 | **Student Portal - Submission Confirmation** | Final submission UI | 4 hours |
| 5.5 | **Student Portal - Email Notifications** | Email reminders & updates | 4 hours |

### Phase 6: Sponsor Portal (Stories 6.1 - 6.2)

| # | Story | Focus | Time |
|---|-------|-------|------|
| 6.1 | **Sponsor Portal - Dashboard & Bulk Signing** | Cohort overview + bulk sign | 4 hours |
| 6.2 | **Sponsor Portal - Email Notifications** | Sponsor email workflow | 4 hours |

### Phase 7: Testing & QA (Stories 7.1 - 7.5)

| # | Story | Focus | Time |
|---|-------|-------|------|
| 7.1 | **End-to-End Workflow Testing** | Complete workflow validation | 4 hours |
| 7.2 | **Mobile Responsiveness Testing** | Mobile/tablet compatibility | 4 hours |
| 7.3 | **Performance Testing (50+ Students)** | Load testing with 50+ students | 4 hours |
| 7.4 | **Security Audit & Penetration Testing** | Security validation | 4 hours |
| 7.5 | **User Acceptance Testing** | PO/Management validation | 4 hours |

### Phase 8: Infrastructure & Documentation (Stories 8.0 - 8.7)

| # | Story | Focus | Time |
|---|-------|-------|------|
| 8.0 | **Development Infrastructure Setup** | Local Docker environment | 4 hours |
| 8.0.1 | **Management Demo Readiness** | Demo scripts & validation | 4 hours |
| 8.5 | **User Communication & Training** | Training materials | 4 hours |
| 8.6 | **In-App User Documentation** | Help system in app | 4 hours |
| 8.7 | **Knowledge Transfer & Ops Docs** | Operations documentation | 4 hours |

## 📊 Summary Statistics

- **Total Stories:** 42
- **Total Estimated Time:** ~168 hours (4 hours per story)
- **Total Phases:** 8
- **Stories per Phase:**
  - Phase 1: 3 stories
  - Phase 2: 8 stories
  - Phase 3: 4 stories
  - Phase 4: 10 stories
  - Phase 5: 5 stories
  - Phase 6: 2 stories
  - Phase 7: 5 stories
  - Phase 8: 5 stories

## 🎯 Quick Reference by Portal

### Admin Portal (TP)
- Stories: 4.1, 4.2, 4.3, 4.4, 4.5, 4.10
- Focus: Cohort management, student enrollment, signing workflow

### Student Portal
- Stories: 5.1, 5.2, 5.3, 5.4, 5.5
- Focus: Document upload, form filling, submission

### Sponsor Portal
- Stories: 4.6, 4.7, 4.8, 4.9, 6.1, 6.2
- Focus: Review, bulk signing, progress tracking

### Backend/Infrastructure
- Stories: 1.x, 2.x, 3.x, 7.x, 8.x
- Focus: Database, models, APIs, testing, deployment

## 📖 How to Use This Index

1. **Find stories by phase** - Use the phase numbers
2. **Find stories by portal** - Use the portal sections
3. **Check time estimates** - Plan sprint capacity
4. **Cross-reference** - Use story numbers with the presentation

## 🔗 Related Files

- **stories-presentation.html** - Full interactive presentation
- **STORIES_SUMMARY.md** - Quick user story reference
- **README.md** - Overview and usage guide
- **QUICKSTART.md** - Quick start instructions

---

**Generated:** 2026-01-15
**Source:** `docs/prd/6-epic-details.md`

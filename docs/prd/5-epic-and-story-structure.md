# 5. Epic and Story Structure

## 5.1 EPIC APPROACH

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

## 5.2 STORY SEQUENCING STRATEGY

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

## 5.3 INTEGRATION REQUIREMENTS

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

## 5.4 RISK-MITIGATED STORY PRIORITIZATION

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

## 5.5 ACCEPTANCE CRITERIA FRAMEWORK

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

## 5.6 STORY DEPENDENCIES AND CRITICAL PATH

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

## 5.7 TECHNICAL DEBT MANAGEMENT

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

## 5.8 AGENT COORDINATION REQUIREMENTS

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

## 5.9 SUCCESS METRICS

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

## 5.10 NEXT STEPS

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


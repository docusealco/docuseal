# Testing Strategy

## Integration with Existing Tests

**Existing Test Framework:** RSpec with FactoryBot, System specs with Capybara
**Test Organization:** `spec/models/`, `spec/requests/`, `spec/system/`
**Coverage Requirements:** Maintain existing coverage levels (aim for 80%+ on new code)

## New Testing Requirements

### **Unit Tests for New Components**

**Framework:** RSpec + FactoryBot
**Location:** `spec/models/`, `spec/services/cohorts/`, `spec/lib/cohorts/`
**Coverage Target:** 80% minimum on new models and services
**Integration with Existing:** Use existing test helpers, match existing patterns

**Test Files:**
- `spec/models/cohort_spec.rb`
- `spec/models/cohort_enrollment_spec.rb`
- `spec/services/cohorts/cohort_workflow_service_spec.rb`
- `spec/lib/cohorts/state_engine_spec.rb`

### **Integration Tests**

**Scope:** End-to-end cohort workflow testing
**Existing System Verification:** Ensure no regression in existing DocuSeal features
**New Feature Testing:** Complete workflow from cohort creation to sponsor finalization

**Test Scenarios:**
1. **Admin Flow:** Create cohort → Invite students → Verify documents → Finalize
2. **Student Flow:** Receive invite → Upload documents → Sign agreements → Track status
3. **Sponsor Flow:** Review cohort → Sign agreements → Bulk operations → Completion
4. **Integration:** Cohort features + existing DocuSeal features work together

**Test Files:**
- `spec/requests/api/v1/cohorts_spec.rb`
- `spec/requests/api/v1/enrollments_spec.rb`
- `spec/system/cohort_workflows_spec.rb`
- `spec/system/portal_access_spec.rb`

### **Regression Testing**

**Existing Feature Verification:** Run full existing test suite before merging
**Automated Regression Suite:** Include cohort tests in CI/CD pipeline
**Manual Testing Requirements:**
- ✅ Existing DocuSeal workflows (template creation, submission, signing)
- ✅ Authentication across all portals
- ✅ File upload and storage
- ✅ Email notifications
- ✅ Webhook delivery

**Test Data Strategy:**
- Use existing factories extended for cohort scenarios
- Create realistic test cohorts (50+ students)
- Test with existing document types and templates
- Include edge cases (large cohorts, rejected documents, sponsor delays)

---

# Data Models and Schema Changes

## New Data Models

### **Cohort Model**
**Purpose:** Represents a training program cohort (learnership, internship, candidacy) managed by an institution. Contains program metadata, templates, and workflow state.

**Integration:** Links to existing `Account` (institution), `Template` (agreement templates), and manages `CohortEnrollment` records.

**Key Attributes:**
- `name`: string - Cohort identifier (e.g., "Q1 2025 Learnership Program")
- `program_type`: enum [learnership, internship, candidacy] - Fixed program types
- `institution_id`: bigint - Foreign key to new `Institutions` table
- `sponsor_email`: string - Email for sponsor notifications
- `student_count`: integer - Expected number of students
- `main_template_id`: bigint - Foreign key to existing `Template` (main agreement)
- `supporting_templates`: jsonb - Array of supporting document template IDs
- `admin_signed_at`: datetime - When admin signed main agreement
- `state`: enum [draft, active, completed, cancelled] - Workflow state
- `start_date`, `end_date`: datetime - Program timeline

**Relationships:**
- **With Existing:** `Account` (institution), `Template` (agreement templates), `User` (admin creator)
- **With New:** `CohortEnrollment` (has_many), `DocumentVerification` (has_many)

### **CohortEnrollment Model**
**Purpose:** Represents a student's enrollment in a cohort, tracking their document submission progress and state through the workflow.

**Integration:** Links to existing `User` (student), `Submission` (document signing workflows), and manages verification state.

**Key Attributes:**
- `cohort_id`: bigint - Foreign key to Cohort
- `user_id`: bigint - Foreign key to existing User (student)
- `submission_id`: bigint - Foreign key to existing Submission (main agreement)
- `supporting_submission_ids`: jsonb - Array of submission IDs for supporting documents
- `state`: enum [waiting, in_progress, complete] - Student workflow state
- `document_verification_state`: enum [pending, verified, rejected] - Admin verification state
- `rejection_reason`: text - Reason for document rejection
- `student_data`: jsonb - Student demographics (age, race, city, gender, disability)
- `uploaded_documents`: jsonb - Metadata about uploaded files (matric, ID, etc.)

**Relationships:**
- **With Existing:** `User` (student), `Submission` (main agreement), `Template` (supporting docs)
- **With New:** `Cohort` (belongs_to), `DocumentVerification` (has_many)

### **Institution Model**
**Purpose:** Represents a private training institution, providing multi-tenancy for the cohort management system.

**Integration:** Extends existing `Account` concept but adds institution-specific metadata and relationships.

**Key Attributes:**
- `account_id`: bigint - Foreign key to existing Account (for backward compatibility)
- `name`: string - Institution name
- `registration_number`: string - Industry registration number
- `address`: text - Physical address
- `contact_email`: string - Primary contact
- `contact_phone`: string - Contact number
- `super_admin_id`: bigint - Foreign key to User (institution super admin)
- `settings`: jsonb - Institution-specific configurations

**Relationships:**
- **With Existing:** `Account` (has_one), `User` (has_many admins)
- **With New:** `Cohort` (has_many), `Sponsor` (has_many)

### **Sponsor Model**
**Purpose:** Represents program sponsors (companies/organizations) who sign agreements for cohorts.

**Integration:** Independent model for sponsor management, linked to cohorts via email and approval workflow.

**Key Attributes:**
- `company_name`: string - Sponsor organization name
- `contact_email`: string - Primary contact email
- `contact_name`: string - Contact person name
- `contact_phone`: string - Contact number
- `tax_number`: string - Tax/registration number
- `institution_id`: bigint - Foreign key to Institution
- `user_id`: bigint - Foreign key to User (if sponsor creates account)

**Relationships:**
- **With Existing:** `User` (optional account), `Submission` (signing workflows)
- **With New:** `Institution` (belongs_to), `Cohort` (referenced via email)

### **DocumentVerification Model**
**Purpose:** Audit trail for admin document verification actions (approvals/rejections).

**Integration:** Links to `CohortEnrollment` and existing `User` (admin who performed verification).

**Key Attributes:**
- `cohort_enrollment_id`: bigint - Foreign key to enrollment
- `admin_id`: bigint - Foreign key to User (admin)
- `document_type`: string - Type of document verified
- `action`: enum [approved, rejected] - Verification decision
- `reason`: text - Rejection reason (if rejected)
- `metadata`: jsonb - Additional verification context

**Relationships:**
- **With Existing:** `User` (admin), `Submission` (document reference)
- **With New:** `CohortEnrollment` (belongs_to)

## Schema Integration Strategy

**Database Changes Required:**

**New Tables:**
```sql
cohorts
cohort_enrollments
institutions
sponsors
document_verifications
```

**Modified Tables:** None (100% backward compatible)

**New Indexes:**
- `cohorts.account_id` - Institution lookup
- `cohort_enrollments.cohort_id, user_id` - Enrollment uniqueness
- `cohort_enrollments.state` - Workflow state queries
- `institutions.account_id` - Multi-tenancy isolation
- `document_verifications.cohort_enrollment_id` - Audit trail queries

**Migration Strategy:**
1. **Phase 1:** Create new tables with foreign keys (no data dependencies)
2. **Phase 2:** Add indexes for performance
3. **Phase 3:** Backfill any required default data
4. **Rollback Plan:** Reverse migration order, preserve existing data

**Backward Compatibility:**
- ✅ Existing tables unchanged
- ✅ Existing relationships preserved
- ✅ No breaking schema changes
- ✅ Additive-only modifications

---

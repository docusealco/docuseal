# Epic 1: 3-Portal Cohort Management System

**Epic Goal**: Transform DocuSeal into a specialized 3-portal cohort management system that enables training institutions to manage complete document workflows from cohort creation through sponsor finalization.

**Integration Requirements**:
- Must integrate with existing DocuSeal form builder for agreement templates
- Must use existing document storage and signing infrastructure
- Must extend existing authentication and user management
- Must maintain backward compatibility with all existing DocuSeal features

## Story 1.1: Institution and Admin Management

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

## Story 1.2: Cohort Creation and Template Management

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

## Story 1.3: Student Invitation and Enrollment

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

## Story 1.4: Admin Document Verification Workflow

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

## Story 1.5: Student Portal - Document Upload and Agreement Completion

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

## Story 1.6: Sponsor Portal - Multi-Student Review and Signing

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

## Story 1.7: Admin Finalization and Document Access

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

## Story 1.8: Notification and Reminder System

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

## Story 1.9: Dashboard and Analytics

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

## Story 1.10: State Management and Workflow Orchestration

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


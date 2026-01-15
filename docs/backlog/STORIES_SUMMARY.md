# FloDoc User Stories - Summary

**Total Stories:** 42

## Quick Reference

### 1.1: Database Schema Extension

**User Story:**
**As a** system architect,
**I want** to create the database schema for FloDoc's new models,
**So that** the application has the foundation to support cohort management.

---

### 1.2: Core Models Implementation

**User Story:**
**As a** developer,
**I want** to create ActiveRecord models for the new FloDoc tables,
**So that** the application can interact with cohorts and enrollments programmatically.

---

### 1.3: Authorization Layer Extension

**User Story:**
**As a** system administrator,
**I want** the authorization system to support FloDoc roles and permissions,
**So that** users can only access appropriate cohort management functions.

---

### 2.1: Cohort Creation & Management

**User Story:**
**As a** TP (Training Provider) administrator,
**I want** to create and manage cohorts with all their configuration details,
**So that** I can organize students into training programs and prepare them for the signature workflow.

---

### 2.2: TP Signing Phase Logic (High Risk - Prototype First)

**User Story:**
**As a** TP administrator,
**I want** to sign the first student's document and have that signing replicated to all other students in the cohort,
**So that** I don't need to sign each student's document individually, saving time and eliminating duplicate sponsor emails.

---

### 2.3: Student Enrollment Management

**User Story:**
**As a** TP administrator,
**I want** to manage student enrollment in cohorts and bulk-create student submissions,
**So that** students can access their documents to complete after TP signs.

---

### 2.4: Sponsor Review Workflow

**User Story:**
**As a** Sponsor,
**I want** to review all student documents in my cohort and sign them in bulk,
**So that** I can complete the verification workflow efficiently.

---

### 2.5: TP Review & Finalization

**User Story:**
**As a** TP administrator,
**I want** to review the sponsor-verified submissions and finalize the cohort,
**So that** the entire 3-party signature workflow is completed and documents are ready for archival.

---

### 2.6: Excel Export for Cohort Data

**User Story:**
**As a** TP administrator,
**I want** to export cohort enrollment data to Excel,
**So that** I can perform additional analysis or reporting outside the system.

---

### 2.7: Audit Log & Compliance

**User Story:**
**As a** TP administrator,
**I want** comprehensive audit logs of all cohort workflow activities,
**So that** we can demonstrate compliance and trace any issues.

---

### 2.8: Cohort State Machine & Workflow Orchestration

**User Story:**
**As a** system,
**I want** to manage cohort state transitions and workflow enforcement,
**So that** the 3-party signature workflow follows the correct sequence and prevents invalid operations.

---

### 3.1: RESTful Cohort Management API

**User Story:**
**As a** TP administrator or external system integrator,
**I want** to create, read, update, and delete cohorts via REST API,
**So that** I can automate cohort management and integrate with other systems.

---

### 3.2: Webhook Events for Workflow State Changes

**User Story:**
**As a** TP administrator,
**I want** webhook notifications for all cohort workflow events,
**So that** external systems can react to state changes in real-time.

---

### 3.3: Student API (Ad-hoc Token-Based Access)

**User Story:**
**As a** student with a cohort link,
**I want** a simple token-based API to access and complete my documents,
**So that** I can fulfill my requirements without account creation.

---

### 3.4: API Documentation & Versioning

**User Story:**
**As a** developer integrating with FloDoc,
**I want** comprehensive API documentation and stable versioning,
**So that** I can build reliable integrations without breaking changes.

---

### 4.1: Cohort Management Dashboard

**User Story:**
**As a** TP administrator,
**I want** a dashboard to view and manage all cohorts,
**So that** I can monitor the 3-party workflow at a glance.

---

### 4.2: Cohort Creation & Bulk Import

**User Story:**
**As a** TP administrator,
**I want** to create new cohorts and bulk-import students via Excel,
**So that** I can efficiently onboard large groups without manual data entry.

---

### 4.3: Cohort Detail Overview

**User Story:**
**As a** TP administrator,
**I want** to view detailed information about a specific cohort, including student list, progress status, and document workflow,
**So that** I can monitor and manage the cohort effectively.

---

### 4.4: TP Signing Interface

**User Story:**
**As a** TP administrator,
**I want** to sign the first student's document and have it automatically replicated to all other students,
**So that** I can sign once instead of signing each student's document individually.

---

### 4.5: Student Management View

**User Story:**
**As a** TP administrator,
**I want** to view and manage individual student details, including their document status and uploaded files,
**So that** I can track student progress and troubleshoot issues.

---

### 4.6: Sponsor Portal Dashboard

**User Story:**
**As a** Sponsor,
**I want** to access a dedicated portal where I can review and verify all student documents for a cohort,
**So that** I can sign once for the entire cohort instead of signing each student individually.

---

### 4.7: Sponsor Portal - Bulk Document Signing

**User Story:**
**As a** Sponsor,
**I want** to sign once and have that signature applied to all pending student documents,
**So that** I don't need to manually sign each student's documents individually.

---

### 4.8: Sponsor Portal - Progress Tracking & State Management

**User Story:**
**As a** Sponsor,
**I want** to see real-time progress tracking with clear visual indicators of which students have completed their documents and which are still pending,
**So that** I can monitor the signing workflow and know exactly when to proceed with bulk signing.

---

### 4.9: Sponsor Portal - Token Renewal & Session Management

**User Story:**
**As a** Sponsor,
**I want** to renew my access token if it expires while I'm reviewing documents,
**So that** I can complete my signing workflow without losing progress or being locked out.

---

### 4.10: TP Portal - Cohort Status Monitoring & Analytics

**User Story:**
**As a** Training Provider,
**I want** to monitor all cohorts with real-time status updates and analytics,
**So that** I can track progress, identify bottlenecks, and manage my document signing workflows efficiently.

---

### 5.1: Student Portal - Document Upload Interface

**User Story:**
**As a** Student,
**I want** to upload required documents (ID, certificates, etc.) through a simple interface,
**So that** I can provide the necessary proof documents for my cohort enrollment.

---

### 5.2: Student Portal - Form Filling & Field Completion

**User Story:**
**As a** Student,
**I want** to fill in my assigned form fields (personal info, signatures, dates, etc.),
**So that** I can complete my portion of the document before the sponsor signs.

---

### 5.3: Student Portal - Progress Tracking & Save Draft

**User Story:**
**As a** Student,
**I want** to see my overall progress and save my work as a draft at any time,
**So that** I can complete the submission at my own pace without losing work.

---

### 5.4: Student Portal - Submission Confirmation & Status

**User Story:**
**As a** Student,
**I want** to review my complete submission and receive confirmation of successful submission,
**So that** I can verify everything is correct and track when the sponsor signs.

---

### 5.5: Student Portal - Email Notifications & Reminders

**User Story:**
**As a** Student,
**I want** to receive email notifications for status updates and reminders to complete my submission,
**So that** I can stay informed and complete my work on time without constantly checking the portal.

---

### 6.1: Sponsor Portal - Cohort Dashboard & Bulk Signing Interface

**User Story:**
**As a** Sponsor,
**I want** to view all pending student documents in a cohort and sign them all at once,
**So that** I can efficiently complete my signing responsibility without reviewing each submission individually.

---

### 6.2: Sponsor Portal - Email Notifications & Reminders

**User Story:**
**As a** Sponsor,
**I want** to receive email notifications about signing requests and reminders to complete my cohort signing,
**So that** I can stay informed and fulfill my signing responsibility on time without constantly checking the portal.

---

### 7.1: End-to-End Workflow Testing

**User Story:**
**As a** QA Engineer,
**I want** to test the complete 3-portal workflow from start to finish,
**So that** I can verify all integrations work correctly and identify any breaking issues before production deployment.

---

### 7.2: Mobile Responsiveness Testing

**User Story:**
**As a** QA Engineer,
**I want** to test all three portals across different screen sizes and devices,
**So that** I can ensure the FloDoc system works perfectly on mobile, tablet, and desktop devices.

---

### 7.3: Performance Testing (50+ Students)

**User Story:**
**As a** QA Engineer,
**I want** to test system performance with large cohorts (50+ students),
**So that** I can ensure FloDoc scales efficiently and meets NFR requirements.

---

### 7.4: Security Audit & Penetration Testing

**User Story:**
**As a** Security Engineer,
**I want** to perform comprehensive security testing on all three portals,
**So that** I can identify and remediate vulnerabilities before production deployment.

---

### 7.5: User Acceptance Testing

**User Story:**
**As a** Product Owner,
**I want** to conduct comprehensive user acceptance testing with real stakeholders,
**So that** I can validate the system meets business requirements and user needs before production launch.

---

### 8.0: Development Infrastructure Setup (Local Docker)

**User Story:**
**As a** Developer,
**I want** to set up a local Docker-based development infrastructure with PostgreSQL and Redis,
**So that** I can demonstrate the complete FloDoc system to management without cloud costs or complexity.

---

### 8.0.1: Management Demo Readiness & Validation

**User Story:**
**As a** Product Manager,
**I want** to validate the complete 3-portal cohort management workflow end-to-end,
**So that** I can demonstrate FloDoc v3 to management with confidence and real data.

---

### 8.5: User Communication & Training Materials

**User Story:**
**As a** Training Provider (TP Admin),
**I want** clear guidance on using FloDoc's 3-portal system,
**So that** I can manage cohorts effectively without confusion.

---

### 8.6: In-App User Documentation & Help System

**User Story:**
**As a** User (TP Admin, Student, or Sponsor),
**I want** contextual help and documentation,
**So that** I can solve problems without contacting support.

---

### 8.7: Knowledge Transfer & Operations Documentation

**User Story:**
**As a** Support/Operations Team,
**I want** comprehensive runbooks and documentation,
**So that** I can support FloDoc without ad-hoc knowledge transfer.

---


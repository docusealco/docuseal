# Requirements

## Functional Requirements

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

## Non-Functional Requirements

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

## Compatibility Requirements

**CR1: API Compatibility**: All new endpoints must follow existing DocuSeal API patterns and authentication mechanisms. No breaking changes to existing public APIs.

**CR2: Database Schema Compatibility**: New tables and relationships must not modify existing DocuSeal core schemas. Extensions should use foreign keys and new tables only.

**CR3: UI/UX Consistency**: All three portals must maintain DocuSeal's existing design system (TailwindCSS + DaisyUI), component patterns, and interaction models.

**CR4: Integration Compatibility**: The system must work with existing DocuSeal integrations (webhooks, API, embedded forms) without requiring changes to external systems.

---

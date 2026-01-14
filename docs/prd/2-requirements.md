# 2. Requirements

## 2.1 FUNCTIONAL REQUIREMENTS

**FR1**: The system shall support a **single training institution** that can manage multiple training cohorts independently.

**FR2**: The system shall provide three distinct portal interfaces: TP Portal (Training Provider admin), Student Portal (for enrolled students), and Sponsor Portal (for program sponsors).

**FR3**: The TP Portal shall support **cohort creation** via a 5-step multi-form:
- Step 1: Cohort name
- Step 2: Program type (learnership/internship/candidacy)
- Step 3: Student emails (manual entry or bulk upload)
- Step 4: Sponsor email (required - single email for all cohort documents)
- Step 5: Upload main SETA agreement + additional supporting docs + specify required student uploads (ID, Matric, Tertiary Qualifications)

**FR4**: The system shall allow TP to **map signatories** (Learner, Sponsor, TP) to document sections using DocuSeal's existing mapping capabilities with tweaks for bulk operations.

**FR5**: The system shall enable **TP Signing Phase** where:
- TP signs the first student's document
- System **duplicates the completed submission** (not empty template) to remaining students
- TP's fields and signatures are **auto-filled across all student submissions**
- This eliminates the need for TP to sign each submission individually
- Prevents duplicate sponsor emails through workflow state management
- Note: DocuSeal's native multi-submission duplicates empty templates; FloDoc will duplicate the signed submission instead

**FR6**: The system shall generate **unique invite links** for students via bulk email invitations.

**FR7**: The system shall allow students to **upload required documents** (ID, Matric, Tertiary Qualifications) as specified during cohort creation.

**FR8**: The system shall allow students to **fill and sign assigned documents** using DocuSeal's existing form builder.

**FR9**: The system shall implement **state management** for each student enrollment with states: "Waiting", "In Progress", "Complete".

**FR10**: The system shall **prevent sponsor access** until all students in a cohort have completed their submissions.

**FR11**: The system shall provide **sponsor portal** with 3-panel layout:
- Left: List of all students in cohort
- Middle: Document viewer (currently selected document)
- Right: Vertical list of thumbnail representations of all documents for the currently selected student

**FR12**: The system shall allow sponsor to **review and sign** each student's documents individually OR bulk sign after first completion.

**FR13**: The system shall enforce **single email rule**: Sponsor receives ONE email per cohort, regardless of how many students they're assigned to.

**FR14**: The system shall allow sponsor to **submit all signatures** to finalize their portion of the workflow.

**FR15**: The system shall allow TP to **review all completed documents** from students and sponsor after sponsor submission.

**FR16**: The system shall enable TP to **finalize 3-party agreements** after review.

**FR17**: The system shall provide **bulk download** functionality with ZIP structure:
```
Cohort_Name/
├── Student_1/
│   ├── Main_Agreement_Signed.pdf
│   ├── ID_Document.pdf
│   ├── Matric_Certificate.pdf
│   ├── Tertiary_Qualifications.pdf
│   └── Audit_Trail.pdf
├── Student_2/
│   └── ...
```

**FR18**: The system shall provide **email notifications** for:
- Cohort creation (TP only)
- Student invitations (bulk email)
- Submission reminders (configurable)
- Sponsor access notification (when all students complete)
- State change updates

**FR19**: The system shall provide **real-time dashboard** showing cohort completion status for all three portals.

**FR20**: The system shall maintain **audit trail** for all document actions with timestamps.

**FR21**: The system shall store all documents using **DocuSeal's existing storage infrastructure**.

**FR22**: The system shall maintain **100% backward compatibility** with existing DocuSeal form builder and signing workflows.

**FR23**: The system shall allow TP to **export cohort data to Excel** format containing: cohort name, student name, student surname, student age, student race, student city, program type, sponsor company name, disability status, and gender.

## 2.2 NON-FUNCTIONAL REQUIREMENTS

**NFR1**: The system must maintain existing performance characteristics and not exceed current memory usage by more than 20%.

**NFR2**: The system must be **mobile-optimized** and support all existing DocuSeal UI languages.

**NFR3**: The system must leverage **existing DocuSeal authentication infrastructure** (Devise + JWT) with role-based access control.

**NFR4**: The system must integrate seamlessly with **existing DocuSeal email notification system**.

**NFR5**: The system must support **concurrent cohort management** without data leakage between cohorts.

**NFR6**: The system must provide **audit trails** for all document verification actions (rejections, approvals).

**NFR7**: The system must maintain **document integrity and signature verification** capabilities.

**NFR8**: The system must support **background processing** for email notifications and document operations via Sidekiq.

**NFR9**: The system must comply with **South African electronic document and signature regulations**.

**NFR10**: The system must provide **comprehensive error handling and user feedback** for all portal interactions.

**NFR11**: The system must implement **single email rule** for sponsors (no duplicate emails regardless of multiple student assignments).

**NFR12**: The system must support **bulk operations** to minimize repetitive work for TP and Sponsor.

## 2.3 COMPATIBILITY REQUIREMENTS

**CR1: API Compatibility**: All new endpoints must follow existing DocuSeal API patterns and authentication mechanisms. No breaking changes to existing public APIs.

**CR2: Database Schema Compatibility**: New tables and relationships must not modify existing DocuSeal core schemas. Extensions should use foreign keys and new tables only.

**CR3: UI/UX Consistency**: All three portals must use **custom TailwindCSS design system** (replacing DaisyUI) while maintaining mobile-first responsive design principles.

**CR4: Integration Compatibility**: The system must work with existing DocuSeal integrations (webhooks, API, embedded forms) without requiring changes to external systems.

---


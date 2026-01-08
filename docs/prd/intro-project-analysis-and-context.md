# Intro Project Analysis and Context

## SCOPE ASSESSMENT
**⚠️ SIGNIFICANT ENHANCEMENT - System-Wide Impact**

This PRD documents a **Major Feature Addition** that transforms the single-portal DocuSeal platform into a specialized 3-portal cohort management system. This enhancement requires:
- Multiple coordinated user stories
- Substantial architectural additions
- System-wide integration across existing DocuSeal capabilities
- Estimated timeline: Multiple development cycles

## Existing Project Overview

**Analysis Source**: IDE-based fresh analysis

**Current Project State**:

FloDoc is built on **DocuSeal** - an open-source document filling and signing platform. The base system provides:

- **Document Form Builder**: WYSIWYG PDF form field creation with 12 field types (Signature, Date, File, Checkbox, etc.)
- **Multi-Submitter Workflows**: Support for multiple signers per document
- **Authentication & User Management**: Devise-based authentication with 2FA support
- **Email Automation**: SMTP-based automated email notifications
- **File Storage**: Flexible storage options (local disk, AWS S3, Google Cloud Storage, Azure Cloud)
- **PDF Processing**: HexaPDF for PDF generation, manipulation, and signature embedding
- **API & Webhooks**: RESTful API with webhook support for integrations
- **Mobile-Optimized UI**: Responsive interface supporting 7 UI languages and signing in 14 languages
- **Role-Based Access**: User roles and permissions system (via Cancancan)
- **Tech Stack**: Ruby on Rails 3.4.2, Vue.js 3, TailwindCSS, DaisyUI, Sidekiq for background jobs

## Available Documentation Analysis

**Available Documentation**:
- ✅ API Documentation (Node.js, Ruby, Python, PHP, Java, Go, C#, TypeScript, JavaScript)
- ✅ Webhook Documentation (Submission, Form, Template webhooks)
- ✅ Embedding Documentation (React, Vue, Angular, JavaScript form builders and signing forms)
- ⚠️ Architecture Documentation (not present - **requires architect review**)
- ⚠️ Coding Standards (not present - **requires documentation**)
- ⚠️ Source tree documentation (not present - **requires documentation**)
- ⚠️ Technical debt documentation (not present - **requires analysis**)

**Recommendation**: Before full implementation, Winston (Architect) should run a document-project task to create comprehensive architecture documentation.

## Enhancement Scope Definition

**Enhancement Type**: ✅ **Major Feature Addition** (3-Portal Cohort Management System)

**Enhancement Description**:

Transform the single-portal DocuSeal platform into a specialized **3-portal cohort management system** for South African private training institutions. The system will manage training cohorts (learnerships, internships, candidacies) through a coordinated workflow involving institution admins, students, and sponsors. Each cohort handles document collection, verification, and multi-party signing for program agreements and supporting documentation.

**Impact Assessment**: ✅ **Significant Impact** (substantial existing code changes)

**Rationale for Impact Level**:
- New multi-tenant institution architecture required
- New authentication/authorization model (role-based per institution)
- New domain models (Cohort, StudentCohortEnrollment, Sponsor, etc.)
- Complex workflow state management (waiting → in progress → complete)
- Custom portal interfaces for each role type
- Integration with existing DocuSeal form builder and signing workflows
- New notification and reminder systems
- Dashboard and analytics layer

## Goals and Background Context

**Goals**:

- Enable private training institutions to digitally manage training program cohorts from creation to completion
- Streamline multi-party document workflows (admin → students → sponsor → finalization)
- Provide role-based portals tailored to each participant's specific needs and permissions
- Maintain 100% backward compatibility with core DocuSeal form builder and signing capabilities
- Reduce document processing time from weeks to days through automated workflows
- Provide real-time visibility into cohort and student submission status
- Ensure document compliance through manual verification workflows with audit trail

**Background Context**:

South African private training institutions currently manage learnerships, internships, and candidacy programs through manual, paper-intensive processes. Each program requires collecting student documents (matric certificates, IDs, disability docs, qualifications), getting program agreements filled and signed by multiple parties (student, sponsor, institution), and tracking completion across dozens of students per cohort.

This manual process is time-consuming (taking weeks), error-prone, lacks visibility into status, and requires physical document handling. FloDoc leverages DocuSeal's proven document signing platform to create a specialized workflow that automates this process while maintaining the flexibility and power of DocuSeal's core form builder and signing engine.

The enhancement adds a cohort management layer on top of DocuSeal, creating three specialized portals that work with the existing document infrastructure rather than replacing it. Institutions continue using DocuSeal's form builder to create agreement templates, but now have a structured workflow for managing batches of students through the document submission and signing process.

## Change Log

| Change | Date | Version | Description | Author |
|--------|------|---------|-------------|--------|
| Initial PRD Creation | 2025-01-01 | v1.0 | Brownfield enhancement for 3-portal cohort management system | PM Agent |

---

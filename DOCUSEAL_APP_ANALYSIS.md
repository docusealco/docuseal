# DocuSeal Application Analysis

## Overview
This document provides a comprehensive analysis of the original DocuSeal application, discovered through exploration of the codebase and server testing. All FloDoc-specific additions (cohorts, institutions, etc.) have been ignored as requested.

## Application Architecture

### Tech Stack
- **Backend**: Ruby 3.4.2, Rails 8.0.2.1
- **Frontend**: Vue.js 3 with Composition API, TailwindCSS 3.4.17, DaisyUI 3.9.4
- **Database**: PostgreSQL (primary), with SQLite fallback
- **Authentication**: Devise with 2FA support
- **Background Jobs**: Sidekiq with Redis
- **PDF Processing**: HexaPDF
- **Asset Pipeline**: Shakapacker 8.0 (Webpack)

### Core Models Hierarchy
```
Account (Tenant/Organization)
├── Users (Devise authentication)
├── Templates (Document templates with form fields)
│   ├── TemplateDocuments (PDF files)
│   └── TemplateFolders (Organization)
├── Submissions (Completed document workflows)
│   ├── Submitters (Signers/participants)
│   ├── CompletedDocuments (Final PDFs)
│   └── SubmissionEvents (Audit trail)
└── AccountConfig (Settings)
```

## Core DocuSeal Features

### 1. User Authentication & Management
**Routes**: `/users/sign_in`, `/users/sign_up`, `/users`, `/settings/profile`
- **Devise-based authentication** with modules:
  - `database_authenticatable`
  - `registerable`
  - `recoverable`
  - `rememberable`
  - `validatable`
  - `omniauthable`
  - `two_factor_authenticatable`
- **2FA Support**: MFA setup via `/mfa_setup`
- **User Management**: Create, update, destroy users
- **Profile Management**: Contact info, password updates, app URL configuration

### 2. Template Management System
**Routes**: `/templates`, `/templates/new`, `/templates/:id/edit`, `/templates/:id/preview`
- **WYSIWYG PDF Form Builder** with 12 field types:
  - Signature fields
  - Date pickers
  - File uploads
  - Checkboxes
  - Radio buttons
  - Text inputs
  - Dropdowns
  - Initials
  - And more...

- **Template Features**:
  - PDF upload or HTML-based creation
  - Multiple submitters per template
  - Field tagging system for dynamic content
  - Template sharing via links
  - Template folders organization
  - Template archiving/restoration
  - Field detection from PDFs
  - Template cloning and replacement

- **Template Preview**: `/templates/:id/preview`
- **Form Preview**: `/templates/:id/form`
- **Share Links**: Template sharing with configurable access

### 3. Submission Workflow Engine
**Routes**: `/submissions`, `/submissions/archived`, `/submissions/:id`
- **Multi-signer Document Workflows**:
  - Sequential or parallel signing
  - Email invitations to submitters
  - Reminders and re-invitations
  - State tracking (pending → completed)

- **Submission Features**:
  - Document generation from templates
  - Digital signature embedding
  - Email notifications
  - Audit trail via `SubmissionEvents`
  - Submission archiving
  - Bulk operations

- **Submitter Management**:
  - Individual participant management
  - Field-specific filling permissions
  - Email click tracking
  - Form view tracking
  - Download capabilities

### 4. API System
**Routes**: `/api/*`
- **RESTful API Endpoints**:
  - `GET /api/templates` - List templates
  - `POST /api/templates` - Create template
  - `GET /api/submissions` - List submissions
  - `POST /api/submissions` - Create submission
  - `GET /api/users` - User info
  - `POST /api/attachments` - File uploads
  - `POST /api/submitters/:id/complete` - Complete submitter workflow

- **Authentication**: Bearer token in Authorization header
- **Format**: JSON responses
- **Webhook Events**: API-driven event system

### 5. Webhook System
**Events**:
- `submission.created` - New submission started
- `submission.completed` - All signers finished
- `submitter.completed` - Individual signer finished
- `template.created` - New template

**Features**:
- Configurable webhook URLs
- Retry with exponential backoff
- Event payload tracking
- Delivery status monitoring

### 6. PDF Processing & Document Management
- **HexaPDF Integration**:
  - PDF generation from templates
  - Form field rendering
  - Digital signature embedding
  - Signature verification

- **PDFium Integration**:
  - PDF rendering and preview
  - Document manipulation
  - Multi-page handling

- **Document Storage**:
  - Active Storage with multiple backends (S3, Google Cloud, Azure, local)
  - Template documents storage
  - Completed documents storage
  - File attachment handling

### 7. Settings & Configuration
**Routes**: `/settings/*`
- **Account Settings**:
  - Storage configuration
  - SMS settings
  - Email SMTP settings
  - SSO configuration
  - Notification preferences
  - E-signature settings

- **API Settings**:
  - API key management
  - Webhook configuration
  - Access token revelation

- **User Settings**:
  - Profile management
  - Password updates
  - Personalization preferences

### 8. Background Jobs (Sidekiq)
**Queues**:
- `default` - General tasks
- `mailers` - Email delivery
- `webhooks` - Webhook delivery
- `pdf` - PDF generation
- `sms` - SMS delivery
- `images` - Image processing
- `recurrent` - Recurring tasks
- `rollbar` - Error reporting

**Key Jobs**:
- `SubmissionEmailJob` - Send submission invitations
- `ReminderJob` - Send reminder emails
- `WebhookDeliveryJob` - Deliver webhook events
- `DocumentGenerationJob` - Generate final PDFs
- `TokenCleanupJob` - Clean up expired tokens

### 9. Security & Authorization
- **Cancancan** for authorization
- **Role-based access control** via `AccountAccess` model
- **Template sharing** via `TemplateSharing`
- **Single-use tokens** with Redis enforcement
- **2FA/MFA support**
- **SSL/TLS support** for production

### 10. Frontend Architecture
- **Vue.js 3** with Composition API
- **TailwindCSS 3.4.17** + **DaisyUI 3.9.4**
- **Shakapacker 8.0** for asset compilation
- **Hotwire Turbo** for Rails UJS
- **Web Components** + Vue hybrid approach

**Key UI Components**:
- Template builder interface
- Submission form interface
- Dashboard with analytics
- Settings panels
- API documentation

## FloDoc Additions (Ignored)

As requested, the following FloDoc-specific additions were ignored during exploration:

### FloDoc Models (Ignored)
- `Institution` - Training institution management
- `Cohort` - Cohort management system
- `CohortEnrollment` - Student enrollment tracking
- `CohortAdminInvitation` - Admin invitation system
- `SecurityEvent` - Security audit logging

### FloDoc Routes (Ignored)
- `/cohorts` - Cohort management
- `/institutions` - Institution management
- `/api/v1/institutions` - Institution API
- `/api/v1/admin/*` - Admin-specific API endpoints

### FloDoc Workflow (Ignored)
- Three-portal system (Admin, Student, Sponsor)
- Cohort creation and enrollment workflow
- Excel export functionality
- Custom UI/UX (non-DaisyUI)

## Database Schema Summary

### Core Tables
- `users` - User authentication and profiles
- `accounts` - Multi-tenancy root
- `templates` - Document templates
- `template_documents` - Template PDF files
- `template_folders` - Template organization
- `submissions` - Document workflows
- `submitters` - Signers/participants
- `completed_documents` - Final signed PDFs
- `submission_events` - Audit trail

### Supporting Tables
- `account_access` - User permissions
- `template_sharing` - Sharing links
- `webhook_events` - Webhook delivery tracking
- `email_events` - Email delivery tracking
- `encrypted_configs` - Encrypted settings
- `user_configs` - User preferences

## Key Discovery: Server Setup Requirements

During exploration, we discovered that the DocuSeal app requires:

1. **JavaScript Asset Compilation**: Shakapacker needs either:
   - `bin/shakapacker-dev-server` running
   - `bin/shakapacker -w` with compile enabled
   - Precompiled assets for production

2. **Redis Connection**: Required for Sidekiq and token enforcement
3. **Database**: PostgreSQL/MySQL/SQLite via DATABASE_URL
4. **Sidekiq Embed**: Can be disabled for development exploration

## Conclusion

The original DocuSeal application is a comprehensive document signing platform with:

- **Robust authentication** (Devise + 2FA)
- **Flexible template system** (12 field types, PDF/HTML creation)
- **Multi-signer workflows** (submissions with state tracking)
- **Complete API** (RESTful with webhooks)
- **PDF processing** (HexaPDF + PDFium)
- **Modern frontend** (Vue.js + TailwindCSS)
- **Background processing** (Sidekiq queues)
- **Multi-tenancy support** (account-based isolation)

All FloDoc additions (cohorts, institutions, three-portal system) were successfully ignored during this exploration, focusing purely on the original DocuSeal functionality.
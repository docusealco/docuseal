# Introduction

## Introduction Content

This document outlines the architectural approach for enhancing **DocuSeal** with the **3-Portal Cohort Management System** for training institutions. Its primary goal is to serve as the guiding architectural blueprint for AI-driven development of new features while ensuring seamless integration with the existing system.

**Relationship to Existing Architecture:**
This document supplements existing DocuSeal architecture by defining how new cohort management components will integrate with current systems. Where conflicts arise between new and existing patterns, this document provides guidance on maintaining consistency while implementing enhancements.

## Existing Project Analysis

### Current Project State

**Primary Purpose:** DocuSeal is an open-source document filling and signing platform providing WYSIWYG PDF form building, multi-signer workflows, and secure digital document signing capabilities.

**Current Tech Stack:**
- **Languages:** Ruby 3.4.2, JavaScript, Vue.js 3, HTML, CSS
- **Frameworks:** Rails 7.x, Shakapacker 8.0, Vue 3.3.2, TailwindCSS 3.4.17, DaisyUI 3.9.4
- **Database:** SQLite (development), PostgreSQL/MySQL (production via DATABASE_URL)
- **Infrastructure:** Docker, Sidekiq for background jobs, Puma web server
- **External Dependencies:** AWS S3, Google Cloud Storage, Azure Cloud (optional), SMTP for emails

**Architecture Style:** Monolithic Rails 7 application with Vue.js 3 frontend, following MVC pattern with service objects for complex business logic.

**Deployment Method:** Docker-based deployment with existing CI/CD pipeline, Shakapacker for asset compilation, Sidekiq workers for background processing.

### Available Documentation

- ✅ **API Documentation** - Complete RESTful API with examples in Node.js, Ruby, Python, PHP, Java, Go, C#, TypeScript, JavaScript
- ✅ **Webhook Documentation** - Submission, form, and template webhooks with event types and payload schemas
- ✅ **Embedding Documentation** - React, Vue, Angular, JavaScript form builders and signing forms
- ⚠️ **Architecture Documentation** - **Created via this document** (previously missing)
- ⚠️ **Coding Standards** - **To be documented** (previously missing)
- ⚠️ **Source Tree Documentation** - **Created via this document** (previously missing)
- ⚠️ **Technical Debt Documentation** - **To be analyzed** (previously missing)

### Identified Constraints

- **Multi-tenancy:** Current system supports single-account or multi-tenant mode via `Docuseal.multitenant?` flag
- **Authentication:** Devise-based with 2FA support, JWT tokens for API access
- **Authorization:** Cancancan with role-based access via `AccountAccess` model
- **Storage:** Active Storage with multiple backend support (S3, GCS, Azure, local)
- **PDF Processing:** HexaPDF for generation/signing, PDFium for rendering
- **Background Jobs:** Sidekiq with Redis dependency
- **UI Framework:** Vue 3 with Composition API, DaisyUI components
- **Mobile Support:** Existing responsive design must be maintained

## Change Log

| Change | Date | Version | Description | Author |
|--------|------|---------|-------------|--------|
| Initial Architecture Creation | 2025-01-02 | v1.0 | Brownfield enhancement architecture for 3-portal cohort management | Winston (Architect) |

---

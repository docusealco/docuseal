# DocuSeal + FloDoc Current Application Sitemap
## Complete Architecture Analysis

**Generated:** 2025-01-09
**Branch:** feature/brownfield-prd
**Status:** Analysis Complete

---

## 1. High-Level System Architecture

```mermaid
graph TB
    subgraph "External Dependencies"
        DB[(PostgreSQL/MySQL/SQLite)]
        Redis[(Redis)]
        S3[(AWS S3)]
        GCS[(Google Cloud)]
        Azure[(Azure)]
        SMTP[(SMTP Server)]
    end

    subgraph "Load Balancer / Web Server"
        Puma[Puma Web Server]
    end

    subgraph "Rails Application - DocuSeal Core + FloDoc Extensions"
        subgraph "Authentication Layer"
            Devise[Devise Auth]
            JWT[JWT Tokens]
            TwoFA[2FA/OTP]
        end

        subgraph "Routing Layer"
            Routes[config/routes.rb]
            API_V1[API v1 Namespace]
            Web_Routes[Web Interface]
        end

        subgraph "Controllers - DocuSeal Core"
            Auth_C[Authentication]
            Templates_C[Templates]
            Submissions_C[Submissions]
            Submitters_C[Submitters]
            Users_C[Users]
            Accounts_C[Accounts]
            Dashboard_C[Dashboard]
        end

        subgraph "Controllers - FloDoc Additions"
            Institutions_C[Institutions]
            CohortsAdmin_C[Cohorts/Admin]
            AdminInvitations_C[Admin/Invitations]
            SecurityEvents_C[Security Events]
        end

        subgraph "Models - DocuSeal Core"
            User[User]
            Account[Account]
            Template[Template]
            Submission[Submission]
            Submitter[Submitter]
            TemplateDoc[TemplateDocument]
            CompletedDoc[CompletedDocument]
            AccountConfig[AccountConfig]
            Webhook[WebhookEvent]
        end

        subgraph "Models - FloDoc Additions"
            Institution[Institution]
            AccountAccess[AccountAccess<br/>Extended with institution_id]
            CohortAdminInvitation[CohortAdminInvitation]
            SecurityEvent[SecurityEvent]
            UserFloDoc[UserFloDocAdditions<br/>Concern]
        end

        subgraph "Authorization"
            Cancancan[Cancancan Ability]
            Abilities[Ability.rb<br/>Extended for FloDoc]
        end

        subgraph "Business Logic - Services"
            SubmissionsLib[lib/submissions/]
            PDFUtils[lib/pdf_utils.rb]
            PDFium[lib/pdfium.rb]
            InvitationService[InvitationService]
            SecurityLog[Security Logging]
        end

        subgraph "Background Jobs - Sidekiq"
            SubmissionEmail[SubmissionEmailJob]
            Reminder[ReminderJob]
            WebhookDelivery[WebhookDeliveryJob]
            DocumentGen[DocumentGenerationJob]
            CohortInvite[CohortAdminInvitationJob]
        end

        subgraph "Frontend - Vue.js"
            AppJS[application.js]
            TemplateBuilder[Template Builder]
            SubmissionForm[Submission Form]
            Elements[Custom Elements]
        end

        subgraph "Email System"
            Mailers[Action Mailers]
            CohortMailer[CohortMailer]
            TemplatesMailer[Templates Mailers]
        end
    end

    %% External Connections
    Puma --> DB
    Puma --> Redis
    Puma --> S3
    Puma --> GCS
    Puma --> Azure
    BackgroundJobs -.-> SMTP

    %% Request Flow
    User[Browser/Mobile] --> Puma

    %% Authentication Flow
    Puma --> Devise
    Devise --> JWT
    Devise --> TwoFA

    %% Routing
    Puma --> Routes
    Routes --> API_V1
    Routes --> Web_Routes

    %% Core Controllers
    API_V1 --> Auth_C
    API_V1 --> Templates_C
    API_V1 --> Submissions_C
    API_V1 --> Submitters_C
    API_V1 --> Users_C
    API_V1 --> Accounts_C

    Web_Routes --> Dashboard_C

    %% FloDoc Controllers
    API_V1 --> Institutions_C
    API_V1 --> AdminInvitations_C
    API_V1 --> SecurityEvents_C
    Web_Routes --> CohortsAdmin_C

    %% Controllers to Models
    Auth_C --> User
    Templates_C --> Template
    Submissions_C --> Submission
    Submitters_C --> Submitter
    Users_C --> User
    Accounts_C --> Account

    Institutions_C --> Institution
    Institutions_C --> AccountAccess
    CohortsAdmin_C --> Institution
    AdminInvitations_C --> CohortAdminInvitation
    SecurityEvents_C --> SecurityEvent

    %% FloDoc Model Relationships
    User --> UserFloDoc
    UserFloDoc --> AccountAccess
    AccountAccess --> Institution

    Institution --> CohortAdminInvitation
    Institution --> SecurityEvent

    %% Authorization
    Controllers --> Cancancan
    Cancancan --> Abilities
    Abilities --> User
    Abilities --> Institution
    Abilities --> AccountAccess

    %% Services
    Submissions_C --> SubmissionsLib
    Submissions_C --> PDFUtils
    Submissions_C --> PDFium
    AdminInvitations_C --> InvitationService
    SecurityEvents_C --> SecurityLog

    %% Background Jobs
    Submissions_C --> SubmissionEmail
    Submissions_C --> Reminder
    Submissions_C --> WebhookDelivery
    Submissions_C --> DocumentGen
    AdminInvitations_C --> CohortInvite

    %% Frontend
    AppJS --> TemplateBuilder
    AppJS --> SubmissionForm
    AppJS --> Elements

    %% Email
    Mailers --> SMTP
    CohortInvite --> CohortMailer
    SubmissionEmail --> TemplatesMailer
```

---

## 2. Database Schema - Core Tables

```mermaid
erDiagram
    %% DOCUSEAL CORE TABLES
    accounts {
        bigint id PK
        string name
        string subdomain
        datetime archived_at
        datetime created_at
        datetime updated_at
    }

    users {
        bigint id PK
        bigint account_id FK
        string email
        string encrypted_password
        string role
        string first_name
        string last_name
        string uuid
        boolean otp_required_for_login
        datetime created_at
        datetime updated_at
    }

    templates {
        bigint id PK
        bigint account_id FK
        bigint author_id FK
        string name
        json fields
        json field_settings
        datetime created_at
        datetime updated_at
    }

    submissions {
        bigint id PK
        bigint account_id FK
        bigint template_id FK
        string status
        string uuid
        json metadata
        datetime created_at
        datetime updated_at
    }

    submitters {
        bigint id PK
        bigint submission_id FK
        bigint user_id FK
        string email
        string name
        string status
        string access_token
        json fields
        datetime created_at
        datetime updated_at
    }

    completed_documents {
        bigint id PK
        bigint submission_id FK
        string status
        json metadata
        binary document_data
        datetime created_at
        datetime updated_at
    }

    %% FLODOC ADDITIONS
    institutions {
        bigint id PK
        bigint account_id FK
        bigint super_admin_id FK
        string name
        string registration_number
        text address
        string contact_email
        string contact_phone
        jsonb settings
        datetime created_at
        datetime updated_at
    }

    account_accesses {
        bigint id PK
        bigint account_id FK
        bigint user_id FK
        bigint institution_id FK
        string role
        datetime created_at
        datetime updated_at
    }

    cohort_admin_invitations {
        bigint id PK
        bigint institution_id FK
        bigint created_by_id FK
        string email
        string hashed_token
        string token_preview
        string role
        datetime sent_at
        datetime expires_at
        datetime used_at
        datetime created_at
        datetime updated_at
    }

    security_events {
        bigint id PK
        bigint user_id FK
        string event_type
        string ip_address
        jsonb details
        datetime created_at
        datetime updated_at
    }

    %% RELATIONSHIPS - DOCUSEAL CORE
    accounts ||--o{ users : "has many"
    accounts ||--o{ templates : "has many"
    accounts ||--o{ submissions : "has many"

    users ||--o{ templates : "authors"
    users ||--o{ submitters : "signs as"

    templates ||--o{ submissions : "generates"

    submissions ||--o{ submitters : "has many"
    submissions ||--o{ completed_documents : "produces"

    %% RELATIONSHIPS - FLODOC ADDITIONS
    accounts ||--o{ institutions : "has one"
    users ||--o{ managed_institutions : "super admin of"
    users ||--o{ account_accesses : "has many"

    institutions ||--o{ account_accesses : "has many"
    institutions ||--o{ cohort_admin_invitations : "has many"
    institutions ||--o{ security_events : "logs"

    users ||--o{ security_events : "triggers"

    account_accesses }|--|| institutions : "grants access to"
    account_accesses }|--|| users : "grants access to"
    account_accesses }|--|| account : "belongs to"

    cohort_admin_invitations }|--|| institutions : "belongs to"
    cohort_admin_invitations }|--|| users : "created by"
```

---

## 3. API Endpoint Structure

```mermaid
graph TB
    subgraph "API v1 Base: /api/v1"
        Auth[Authentication]

        subgraph "Core DocuSeal Endpoints"
            Templates[/templates]
            Submissions[/submissions]
            Submitters[/submitters]
            Users[/users]
            Accounts[/accounts]
            Webhooks[/webhooks]
        end

        subgraph "FloDoc Institution Endpoints"
            Institutions[/institutions]
            Admin[/admin/invitations]
            Security[/security-events]
        end

        subgraph "Template Endpoints"
            T_Documents[/templates/:id/documents]
            T_Sharing[/templates/:id/sharing]
            T_Fields[/templates/:id/fields]
            T_Preview[/templates/:id/preview]
        end

        subgraph "Submission Endpoints"
            S_Start[/submissions/start]
            S_Complete[/submissions/:id/complete]
            S_Download[/submissions/:id/download]
            S_Events[/submissions/:id/events]
        end

        subgraph "Submitter Endpoints"
            Sub_Complete[/submitters/:id/complete]
            Sub_Sign[/submitters/:id/sign]
            Sub_Download[/submitters/:id/download]
            Sub_Email[/submitters/:id/send-email]
        end
    end

    %% Authentication
    Auth --> |JWT Token| Templates
    Auth --> |JWT Token| Submissions
    Auth --> |JWT Token| Institutions

    %% Core Flow
    Templates --> T_Documents
    Templates --> T_Sharing
    Templates --> T_Fields
    Templates --> T_Preview

    Submissions --> S_Start
    Submissions --> S_Complete
    Submissions --> S_Download
    Submissions --> S_Events

    Submitters --> Sub_Complete
    Submitters --> Sub_Sign
    Submitters --> Sub_Download
    Submitters --> Sub_Email

    %% FloDoc Flow
    Institutions --> Admin
    Institutions --> Security

    %% Webhooks
    Webhooks --> |POST Events| External[External Systems]
```

---

## 4. Data Flow - Document Signing Workflow

```mermaid
sequenceDiagram
    participant User as User/Admin
    participant FE as Frontend Vue
    participant C as Controller
    participant M as Models
    participant S as Services
    participant SJ as Sidekiq Jobs
    participant DB as Database
    participant PDF as PDF Engine
    participant Storage as Active Storage
    participant Email as Email System
    participant API as External API
    participant Webhook as Webhooks

    %% DOCUSEAL CORE WORKFLOW
    Note over User,Webhook: Standard DocuSeal Document Flow

    User->>FE: Upload PDF Template
    FE->>C: POST /templates
    C->>M: Create Template
    M->>DB: Save template data
    C->>FE: Template Created

    User->>FE: Configure Form Fields
    FE->>C: PUT /templates/:id/fields
    C->>M: Update Template Fields
    M->>DB: Save field configuration
    C->>FE: Fields Updated

    User->>FE: Start Submission
    FE->>C: POST /submissions/start
    C->>M: Create Submission
    C->>M: Create Submitters
    M->>DB: Save submission & submitters
    C->>SJ: SubmissionEmailJob
    SJ->>Email: Send Invitation
    Email->>User: Email with Access Link

    User->>Email: Click Link
    User->>FE: Access Submission Form
    FE->>C: GET /submissions/:id
    C->>M: Fetch Submission
    M->>DB: Query submission data
    C->>FE: Return Submission Data

    User->>FE: Fill Form & Sign
    FE->>C: POST /submitters/:id/complete
    C->>M: Update Submitter Status
    C->>S: Generate PDF
    S->>PDF: Create Signed PDF
    PDF->>Storage: Save Document
    M->>DB: Save CompletedDocument
    C->>SJ: WebhookDeliveryJob
    SJ->>Webhook: POST Event
    C->>FE: Completion Confirmation

    %% FLODOC COHORT WORKFLOW
    Note over User,Webhook: FloDoc 3-Portal Cohort Flow

    User->>FE: Create Institution (Super Admin)
    FE->>C: POST /api/v1/institutions
    C->>M: Create Institution
    C->>M: Create AccountAccess
    M->>DB: Save institution & access
    C->>FE: Institution Created

    User->>FE: Invite Cohort Admin
    FE->>C: POST /api/v1/admin/invitations
    C->>S: InvitationService
    S->>M: Create CohortAdminInvitation
    S->>SJ: CohortAdminInvitationJob
    SJ->>Email: Send Admin Invite
    Email->>Admin: Invitation Email

    Admin->>Email: Accept Invitation
    Admin->>FE: Accept Invitation Link
    FE->>C: POST /api/v1/admin/invitation_acceptance
    C->>S: Validate Token
    S->>M: Verify CohortAdminInvitation
    C->>M: Create User (if new)
    C->>M: Create AccountAccess
    M->>DB: Save user & access
    C->>FE: Access Granted

    Admin->>FE: Manage Cohort
    FE->>C: Web Interface
    C->>M: Institution.for_user
    M->>DB: Scoped Query
    C->>FE: Cohort Dashboard

    %% Security Monitoring
    User->>C: Any Action
    C->>S: SecurityLog
    S->>M: SecurityEvent.log
    M->>DB: Save Security Event
```

---

## 5. Authentication & Authorization Flow

```mermaid
graph TB
    subgraph "Authentication Layers"
        L1[Layer 1: Devise Session]
        L2[Layer 2: JWT API Token]
        L3[Layer 3: 2FA/OTP]
        L4[Layer 4: Account Access]
    end

    subgraph "Authorization Layers"
        A1[Layer 1: Database Scopes]
        A2[Layer 2: Model Relationships]
        A3[Layer 3: CanCanCan Abilities]
        A4[Layer 4: Controller Filters]
    end

    subgraph "FloDoc Security Architecture"
        F1[Institution Isolation]
        F2[Role-Based Access]
        F3[Super Admin vs Admin]
        F4[Security Event Logging]
    end

    User --> L1
    L1 --> L2
    L2 --> L3
    L3 --> L4

    L4 --> A1
    A1 --> A2
    A2 --> A3
    A3 --> A4

    A4 --> F1
    F1 --> F2
    F2 --> F3
    F3 --> F4

    %% Key Methods
    L4 --> |can_access_institution?| UserFloDoc
    A1 --> |Institution.for_user| ScopedQuery
    A3 --> |Ability.rb| RoleCheck
    F4 --> |SecurityEvent.log| AuditTrail
```

---

## 6. FloDoc-Specific Additions Summary

### Models Added
- **Institution** - Multi-tenant organization container
- **AccountAccess** - Extended with `institution_id` and new roles
- **CohortAdminInvitation** - Secure admin invitation system
- **SecurityEvent** - Audit trail for security actions
- **UserFloDocAdditions** - Concern for User model

### Controllers Added
- **Cohorts::AdminController** - Web interface for cohort management
- **Api::V1::InstitutionsController** - REST API for institutions
- **Api::V1::Admin::InvitationsController** - Admin invitation management
- **Api::V1::Admin::InvitationAcceptanceController** - Accept invitations
- **Api::V1::Admin::SecurityEventsController** - Security monitoring

### Database Migrations
- `20250103000001_add_institution_id_to_account_access.rb`
- `20250103000002_create_institutions.rb`
- `20250103000003_create_cohort_admin_invitations.rb`
- `20250103000005_backfill_institution_data.rb`
- `20250103000006_create_security_events.rb`

### Services & Jobs
- **InvitationService** - Handles admin invitation creation and validation
- **CohortAdminInvitationJob** - Async email delivery
- **SecurityAlertJob** - Alert threshold monitoring

### Routes Added
```ruby
# API v1
namespace :admin do
  resources :invitations
  resources :invitation_acceptance
  resources :security_events
end
resources :institutions

# Web Interface
resources :cohorts, only: [] do
  resources :admin, controller: 'cohorts/admin'
end
```

---

## 7. Current State Assessment

### ✅ Implemented (FloDoc Additions)
1. **Institution Management** - CRUD operations with security
2. **Admin Invitation System** - Token-based secure invitations
3. **Role-Based Access** - cohort_super_admin and cohort_admin roles
4. **Security Event Logging** - Audit trail for all actions
5. **4-Layer Security Architecture** - Database → Model → Controller → UI
6. **Data Isolation** - Institution-scoped queries via `Institution.for_user`

### ⚠️ Partially Implemented
1. **Cohort Model** - Referenced in Ability.rb but not created
2. **Sponsor Model** - Referenced in Ability.rb but not created
3. **Student Portal** - Not started
4. **Sponsor Portal** - Not started
5. **Excel Export** - Mentioned in PRD but not implemented

### ❌ Not Started
1. **CohortEnrollment Model** - Student enrollment tracking
2. **Document Verification Workflow** - Manual verification process
3. **3-Portal UI** - Custom Vue portals for Admin/Student/Sponsor
4. **Cohort Dashboard** - Analytics and status tracking
5. **Multi-signer Cohort Workflows** - Integration with DocuSeal submissions
6. **Excel Export (FR23)** - Cohort data export functionality

---

## 8. Key Integration Points

### Where FloDoc Hooks Into DocuSeal
1. **User Model** - `include UserFloDocAdditions` adds institution relationships
2. **AccountAccess** - Extended with `institution_id` and new role types
3. **Ability.rb** - Added FloDoc permissions alongside existing DocuSeal rules
4. **Routes** - New namespaces under existing API structure
5. **Database** - New tables with foreign keys to existing tables

### What Remains Unchanged
1. **Core Models** - Template, Submission, Submitter, CompletedDocument
2. **PDF Processing** - HexaPDF and PDFium usage
3. **Authentication** - Devise + JWT (unchanged)
4. **Background Jobs** - Existing Sidekiq infrastructure
5. **Storage** - Active Storage configuration
6. **API Patterns** - RESTful conventions maintained

---

## 9. Next Steps for Complete Implementation

Based on the PRD and Architecture docs, the remaining work involves:

1. **Create Missing Models**: Cohort, CohortEnrollment, Sponsor
2. **Build 3-Portal UI**: Custom Vue portals with TailwindCSS (no DaisyUI)
3. **Integrate Document Workflows**: Connect cohort management to DocuSeal submissions
4. **Implement Excel Export**: Using rubyXL gem
5. **Add Verification Workflow**: Manual document verification with audit trail
6. **Cohort Dashboard**: Analytics and status tracking
7. **Student Portal**: Enrollment and document submission interface
8. **Sponsor Portal**: Review and signing interface
9. **Complete Testing**: RSpec tests for all new functionality
10. **Documentation**: API docs for new endpoints

---

**Analysis Complete** - This sitemap provides a comprehensive view of the current DocuSeal + FloDoc application state, clearly distinguishing between vanilla DocuSeal features and FloDoc additions.
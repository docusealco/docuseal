# API Design and Integration

## API Integration Strategy

**API Integration Strategy:** Extend existing DocuSeal API v1 with new cohort-specific endpoints under `/api/v1/cohorts/*`. All endpoints follow existing RESTful patterns, authentication mechanisms, and response formats.

**Authentication:** Reuse existing Devise + JWT authentication. No changes to auth flow required. New endpoints will require the same bearer token authentication as existing endpoints.

**Versioning:** No new API version required. New endpoints extend v1 following existing patterns. All new endpoints return consistent JSON response formats matching existing endpoints.

## New API Endpoints

### **Cohort Management Endpoints**

#### **Create Cohort**
- **Method:** `POST`
- **Endpoint:** `/api/v1/cohorts`
- **Purpose:** Create new cohort with templates and configuration
- **Integration:** Uses existing Template APIs for template management

**Request:**
```json
{
  "cohort": {
    "name": "Q1 2025 Learnership",
    "program_type": "learnership",
    "sponsor_email": "sponsor@company.com",
    "student_count": 50,
    "main_template_id": 123,
    "supporting_template_ids": [124, 125],
    "start_date": "2025-02-01",
    "end_date": "2025-07-31"
  }
}
```

**Response:**
```json
{
  "id": 1,
  "name": "Q1 2025 Learnership",
  "state": "draft",
  "created_at": "2025-01-02T10:00:00Z",
  "links": {
    "self": "/api/v1/cohorts/1",
    "enrollments": "/api/v1/cohorts/1/enrollments"
  }
}
```

#### **List Cohorts**
- **Method:** `GET`
- **Endpoint:** `/api/v1/cohorts`
- **Purpose:** Get paginated list of cohorts for current institution
- **Integration:** Filters by current user's institution

**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "name": "Q1 2025 Learnership",
      "program_type": "learnership",
      "state": "active",
      "completion_percentage": 65,
      "student_count": 50,
      "completed_students": 32
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 1
  }
}
```

#### **Get Cohort Details**
- **Method:** `GET`
- **Endpoint:** `/api/v1/cohorts/:id`
- **Purpose:** Get detailed cohort information with enrollment status
- **Integration:** Aggregates data from existing Submission APIs

**Response:**
```json
{
  "id": 1,
  "name": "Q1 2025 Learnership",
  "program_type": "learnership",
  "state": "active",
  "sponsor_email": "sponsor@company.com",
  "admin_signed_at": "2025-01-02T10:30:00Z",
  "templates": {
    "main": { "id": 123, "name": "Learnership Agreement" },
    "supporting": [{ "id": 124, "name": "Code of Conduct" }]
  },
  "enrollments": {
    "waiting": 5,
    "in_progress": 13,
    "complete": 32
  }
}
```

#### **Invite Students**
- **Method:** `POST`
- **Endpoint:** `/api/v1/cohorts/:id/invitations`
- **Purpose:** Generate invite links or send email invitations
- **Integration:** Uses existing email system and user creation

**Request:**
```json
{
  "students": [
    { "email": "student1@example.com", "first_name": "John", "last_name": "Doe" },
    { "email": "student2@example.com", "first_name": "Jane", "last_name": "Smith" }
  ],
  "send_email": true
}
```

**Response:**
```json
{
  "invitations_sent": 2,
  "invite_links": [
    { "email": "student1@example.com", "link": "https://flo.doc/invite/abc123" },
    { "email": "student2@example.com", "link": "https://flo.doc/invite/def456" }
  ]
}
```

#### **Export Cohort Data (FR23)**
- **Method:** `GET`
- **Endpoint:** `/api/v1/cohorts/:id/export`
- **Purpose:** Export cohort data to Excel format
- **Integration:** Uses existing rubyXL gem for Excel generation

**Query Parameters:**
- `format=xlsx`
- `include=student_demographics,program_details,sponsor_info`

**Response:** Excel file download with columns: cohort_name, student_name, student_surname, student_age, student_race, student_city, program_type, sponsor_company_name, disability_status, gender

## Web Portal Routes

### **Admin Portal Routes**

| Route | Method | Purpose | Authentication | Component |
|-------|--------|---------|----------------|-----------|
| `/cohorts/admin` | GET | Cohort dashboard | Devise + Role | `AdminPortal.vue` |
| `/cohorts/admin/new` | GET | Create cohort wizard | Devise + Role | `CohortWizard.vue` |
| `/cohorts/admin/:id` | GET | Cohort details | Devise + Role | `CohortDashboard.vue` |
| `/cohorts/admin/:id/verify` | GET | Document verification | Devise + Role | `VerificationInterface.vue` |
| `/cohorts/admin/:id/sponsors` | GET | Sponsor management | Devise + Role | `SponsorCoordinator.vue` |
| `/cohorts/admin/:id/analytics` | GET | Analytics view | Devise + Role | `AnalyticsView.vue` |
| `/cohorts/admin/:id/export` | GET | Excel export (FR23) | Devise + Role | `ExcelExport.vue` |
| `/cohorts/admin/:id/invite` | POST | Student invitations | Devise + Role | API call |

### **Student Portal Routes**

| Route | Method | Purpose | Authentication | Component |
|-------|--------|---------|----------------|-----------|
| `/cohorts/student/:token` | GET | Portal entry (token) | Token-based | `StudentPortal.vue` |
| `/cohorts/student/:token/welcome` | GET | Welcome screen | Token-based | `CohortWelcome.vue` |
| `/cohorts/student/:token/upload` | GET | Document upload | Token-based | `DocumentUpload.vue` |
| `/cohorts/student/:token/agreement` | GET | Main agreement | Token-based | `AgreementForm.vue` |
| `/cohorts/student/:token/supporting` | GET | Supporting docs | Token-based | `AgreementForm.vue` |
| `/cohorts/student/:token/status` | GET | Progress dashboard | Token-based | `StatusDashboard.vue` |
| `/cohorts/student/:token/resubmit` | GET | Re-submission flow | Token-based | `ResubmissionFlow.vue` |

### **Sponsor Portal Routes**

| Route | Method | Purpose | Authentication | Component |
|-------|--------|---------|----------------|-----------|
| `/cohorts/sponsor/:token` | GET | Sponsor dashboard | Token-based | `SponsorPortal.vue` |
| `/cohorts/sponsor/:token/overview` | GET | Cohort overview | Token-based | `SponsorDashboard.vue` |
| `/cohorts/sponsor/:token/student/:student_id` | GET | Student review | Token-based | `StudentReview.vue` |
| `/cohorts/sponsor/:token/bulk-sign` | POST | Bulk signing | Token-based | `BulkSigning.vue` |
| `/cohorts/sponsor/:token/finalize` | POST | Cohort finalization | Token-based | `CohortFinalization.vue` |

### **Enrollment Management Endpoints**

#### **List Enrollments**
- **Method:** `GET`
- **Endpoint:** `/api/v1/cohorts/:id/enrollments`
- **Purpose:** Get all student enrollments with status
- **Integration:** Aggregates from CohortEnrollment + existing User/Submission data

**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "student": { "name": "John Doe", "email": "john@example.com" },
      "state": "complete",
      "verification_state": "verified",
      "documents": { "uploaded": 5, "signed": 3 },
      "created_at": "2025-01-01T10:00:00Z"
    }
  ]
}
```

#### **Verify Document**
- **Method:** `POST`
- **Endpoint:** `/api/v1/enrollments/:id/verify`
- **Purpose:** Admin document verification (approve/reject)
- **Integration:** Creates DocumentVerification records

**Request:**
```json
{
  "action": "reject",
  "document_type": "matric_certificate",
  "reason": "Certificate is not certified by SAQA"
}
```

### **Sponsor Endpoints**

#### **Get Sponsor Cohort Overview**
- **Method:** `GET`
- **Endpoint:** `/api/v1/sponsors/cohorts/:token`
- **Purpose:** Sponsor access to cohort overview (token-based auth)
- **Integration:** Validates token, checks all students complete

**Response:**
```json
{
  "cohort": { "name": "Q1 2025 Learnership", "student_count": 50 },
  "students": [
    { "id": 1, "name": "John Doe", "state": "complete", "signed": true }
  ],
  "can_sign": true,
  "bulk_sign_available": true
}
```

#### **Bulk Sign**

**Request:**
```json
{
  "signature": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUg...",
  "initials": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUg...",
  "sign_all": true,
  "timestamp": "2025-01-02T15:30:00Z"
}
```

**Success Response (200):**
```json
{
  "signed_count": 50,
  "failed_count": 0,
  "signatures_applied": [
    {
      "enrollment_id": 1,
      "submission_id": 100,
      "status": "signed",
      "signed_at": "2025-01-02T15:30:00Z"
    }
  ],
  "cohort_finalized": true,
  "next_step": "Admin can now finalize cohort and download documents"
}
```

**Error Responses:**
```json
// 422 Validation Error
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Signature data is invalid or corrupted",
    "timestamp": "2025-01-02T15:30:00Z"
  }
}

// 403 Forbidden
{
  "error": {
    "code": "STATE_ERROR",
    "message": "Cannot sign - some students are not ready",
    "details": {
      "ready": 32,
      "total": 50,
      "pending": 18
    }
  }
}
```

## Complete API Response Schemas

### **Cohort Endpoints**

**POST /api/v1/cohorts - Request:**
```json
{
  "cohort": {
    "name": "Q1 2025 Learnership",
    "program_type": "learnership",
    "sponsor_email": "sponsor@company.com",
    "student_count": 50,
    "main_template_id": 123,
    "supporting_template_ids": [124, 125],
    "start_date": "2025-02-01",
    "end_date": "2025-07-31"
  }
}
```

**POST /api/v1/cohorts - Success Response (201):**
```json
{
  "id": 1,
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Q1 2025 Learnership",
  "program_type": "learnership",
  "state": "draft",
  "sponsor_email": "sponsor@company.com",
  "student_count": 50,
  "main_template_id": 123,
  "supporting_template_ids": [124, 125],
  "start_date": "2025-02-01",
  "end_date": "2025-07-31",
  "admin_signed_at": null,
  "created_at": "2025-01-02T10:00:00Z",
  "updated_at": "2025-01-02T10:00:00Z",
  "links": {
    "self": "/api/v1/cohorts/1",
    "enrollments": "/api/v1/cohorts/1/enrollments",
    "invitations": "/api/v1/cohorts/1/invitations"
  }
}
```

**POST /api/v1/cohorts - Error Responses:**
```json
// 422 Validation Error
{
  "errors": {
    "name": ["can't be blank"],
    "sponsor_email": ["is invalid"],
    "main_template_id": ["must exist"]
  }
}

// 403 Forbidden (wrong institution)
{
  "error": {
    "code": "AUTHORIZATION_ERROR",
    "message": "Access denied"
  }
}
```

**GET /api/v1/cohorts/:id - Success Response (200):**
```json
{
  "id": 1,
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Q1 2025 Learnership",
  "program_type": "learnership",
  "state": "active",
  "sponsor_email": "sponsor@company.com",
  "student_count": 50,
  "admin_signed_at": "2025-01-02T10:30:00Z",
  "created_at": "2025-01-02T10:00:00Z",
  "updated_at": "2025-01-02T10:30:00Z",
  "templates": {
    "main": {
      "id": 123,
      "name": "Learnership Agreement",
      "uuid": "abc123..."
    },
    "supporting": [
      {
        "id": 124,
        "name": "Code of Conduct",
        "uuid": "def456..."
      }
    ]
  },
  "enrollment_summary": {
    "total": 50,
    "waiting": 5,
    "in_progress": 13,
    "complete": 32,
    "rejected": 0
  },
  "completion_percentage": 64,
  "links": {
    "self": "/api/v1/cohorts/1",
    "enrollments": "/api/v1/cohorts/1/enrollments",
    "export": "/api/v1/cohorts/1/export"
  }
}
```

**GET /api/v1/cohorts/:id/enrollments - Success Response (200):**
```json
{
  "data": [
    {
      "id": 1,
      "uuid": "550e8400-e29b-41d4-a716-446655440001",
      "student": {
        "id": 100,
        "name": "John Doe",
        "email": "john@example.com",
        "phone": "+27123456789"
      },
      "state": "complete",
      "verification_state": "verified",
      "rejection_reason": null,
      "student_data": {
        "age": 23,
        "race": "Black",
        "city": "Johannesburg",
        "gender": "Male",
        "disability": "None"
      },
      "documents": {
        "uploaded": 5,
        "signed": 3,
        "rejected": 0
      },
      "created_at": "2025-01-01T10:00:00Z",
      "updated_at": "2025-01-02T14:30:00Z",
      "links": {
        "self": "/api/v1/enrollments/1",
        "verify": "/api/v1/enrollments/1/verify"
      }
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 50,
    "filters": {
      "state": ["complete"],
      "verification_state": ["verified"]
    }
  }
}
```

**POST /api/v1/cohorts/:id/invitations - Request:**
```json
{
  "students": [
    {
      "email": "student1@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "phone": "+27123456789",
      "age": 23,
      "race": "Black",
      "city": "Johannesburg",
      "gender": "Male",
      "disability": "None"
    }
  ],
  "send_email": true,
  "message": "Welcome to our Q1 2025 Learnership program!"
}
```

**POST /api/v1/cohorts/:id/invitations - Success Response (201):**
```json
{
  "invitations_sent": 1,
  "invite_links": [
    {
      "email": "student1@example.com",
      "token": "abc123def456",
      "link": "https://flo.doc/cohorts/student/abc123def456",
      "expires_at": "2025-02-01T10:00:00Z"
    }
  ],
  "errors": []
}
```

**GET /api/v1/cohorts/:id/export - Query Parameters:**
- `format=xlsx` (required)
- `include=student_demographics,program_details,sponsor_info` (optional)

**GET /api/v1/cohorts/:id/export - Response:**
- Returns Excel file (.xlsx) as binary download
- **Headers:**
  ```
  Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  Content-Disposition: attachment; filename="cohort_1_export_20250102.xlsx"
  ```

**Excel Columns:**
```
cohort_name | student_name | student_surname | student_age | student_race | student_city | program_type | sponsor_company_name | disability_status | gender
```

### **Enrollment Endpoints**

**POST /api/v1/enrollments/:id/verify - Request:**
```json
{
  "action": "reject",
  "document_type": "matric_certificate",
  "reason": "Certificate is not certified by SAQA. Please provide SAQA verification letter.",
  "metadata": {
    "reviewed_by": "admin@institution.com",
    "review_notes": "Checked against SAQA database"
  }
}
```

**POST /api/v1/enrollments/:id/verify - Success Response (200):**
```json
{
  "id": 1,
  "enrollment_id": 1,
  "action": "rejected",
  "document_type": "matric_certificate",
  "reason": "Certificate is not certified by SAQA. Please provide SAQA verification letter.",
  "admin_id": 50,
  "created_at": "2025-01-02T15:00:00Z",
  "metadata": {
    "reviewed_by": "admin@institution.com",
    "review_notes": "Checked against SAQA database"
  }
}
```

**POST /api/v1/enrollments/:id/verify - Error Responses:**
```json
// 422 Invalid State Transition
{
  "error": {
    "code": "STATE_ERROR",
    "message": "Cannot reject enrollment that is already complete"
  }
}

// 404 Not Found
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Enrollment not found"
  }
}
```

### **Sponsor Endpoints**

**GET /api/v1/sponsors/cohorts/:token - Success Response (200):**
```json
{
  "cohort": {
    "id": 1,
    "name": "Q1 2025 Learnership",
    "program_type": "learnership",
    "student_count": 50,
    "sponsor_email": "sponsor@company.com"
  },
  "students": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "state": "complete",
      "verification_state": "verified",
      "signed": true,
      "signed_at": "2025-01-02T10:00:00Z",
      "documents": {
        "main_agreement": {
          "id": 100,
          "status": "signed",
          "preview_url": "/api/v1/submissions/100/preview"
        },
        "supporting_docs": [
          {
            "id": 101,
            "name": "Code of Conduct",
            "status": "signed"
          }
        ]
      }
    }
  ],
  "summary": {
    "total": 50,
    "completed": 32,
    "pending": 18,
    "signed": 32
  },
  "can_sign": true,
  "bulk_sign_available": true,
  "token_expires_at": "2025-01-16T23:59:59Z"
}
```

**GET /api/v1/sponsors/cohorts/:token - Error Responses:**
```json
// 403 Forbidden (students not complete)
{
  "error": {
    "code": "STATE_ERROR",
    "message": "All students must complete their submissions before sponsor access",
    "details": {
      "completed": 32,
      "total": 50,
      "remaining": 18
    }
  }
}

// 401 Unauthorized (invalid/expired token)
{
  "error": {
    "code": "AUTHENTICATION_ERROR",
    "message": "Invalid or expired sponsor token"
  }
}
```

#### **Bulk Sign**
- **Method:** `POST`
- **Endpoint:** `/api/v1/sponsors/cohorts/:token/bulk-sign`
- **Purpose:** Sign all student agreements at once
- **Integration:** Uses existing submission signing APIs

**Request:**
```json
{
  "signature": "data:image/png;base64,...",
  "initials": "data:image/png;base64,..."
}
```

---

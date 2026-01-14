# API Design - FloDoc Architecture

**Document**: RESTful API Specifications
**Version**: 1.0
**Last Updated**: 2026-01-14

---

## 📡 API Overview

FloDoc provides a RESTful API for programmatic access to cohort management, student enrollment, and sponsor workflows. The API follows REST principles and uses JSON for request/response payloads.

**Base URL**: `/api/v1/`
**Authentication**: Bearer token in Authorization header
**Response Format**: JSON

---

## 🔐 Authentication

### JWT Token Authentication

All API requests must include an authentication token:

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxfQ.signature
```

### Token Generation

**Endpoint**: `POST /api/v1/auth/token`

**Request**:
```json
{
  "email": "admin@techpro.co.za",
  "password": "secure_password"
}
```

**Response (200 OK)**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxfQ.signature",
  "expires_at": "2026-01-15T19:00:00Z",
  "user": {
    "id": 1,
    "email": "admin@techpro.co.za",
    "role": "tp_admin"
  }
}
```

**Error Response (401 Unauthorized)**:
```json
{
  "error": "Invalid credentials"
}
```

### Token Refresh

**Endpoint**: `POST /api/v1/auth/refresh`

**Headers**:
```http
Authorization: Bearer <old_token>
```

**Response (200 OK)**:
```json
{
  "token": "new_token_here",
  "expires_at": "2026-01-16T19:00:00Z"
}
```

---

## 📚 API Endpoints

### 1. Cohorts Management

#### List Cohorts
**Endpoint**: `GET /api/v1/cohorts`

**Authentication**: Required (TP Admin)

**Query Parameters**:
- `status` (optional): Filter by status (`draft`, `active`, `completed`)
- `page` (optional): Pagination page (default: 1)
- `per_page` (optional): Items per page (default: 20)

**Request**:
```http
GET /api/v1/cohorts?status=active&page=1&per_page=10
Authorization: Bearer <token>
```

**Response (200 OK)**:
```json
{
  "data": [
    {
      "id": 1,
      "name": "2026 Q1 Learnership",
      "program_type": "learnership",
      "sponsor_email": "sponsor@company.co.za",
      "status": "active",
      "required_student_uploads": ["id_copy", "matric_certificate"],
      "cohort_metadata": {
        "start_date": "2026-02-01",
        "duration_months": 12,
        "stipend_amount": 3500
      },
      "tp_signed_at": "2026-01-14T10:00:00Z",
      "students_completed_at": null,
      "sponsor_completed_at": null,
      "finalized_at": null,
      "student_count": 15,
      "completed_count": 8,
      "created_at": "2026-01-10T08:00:00Z",
      "updated_at": "2026-01-14T10:00:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 3,
    "total_count": 25,
    "per_page": 10
  }
}
```

**Error Response (401 Unauthorized)**:
```json
{
  "error": "Unauthorized"
}
```

---

#### Create Cohort
**Endpoint**: `POST /api/v1/cohorts`

**Authentication**: Required (TP Admin)

**Request Body**:
```json
{
  "name": "2026 Q2 Internship",
  "program_type": "internship",
  "sponsor_email": "hr@company.co.za",
  "template_id": 42,
  "required_student_uploads": ["id_copy", "cv", "tertiary_certificate"],
  "cohort_metadata": {
    "start_date": "2026-04-01",
    "duration_months": 6,
    "department": "Engineering"
  }
}
```

**Required Fields**:
- `name` (string)
- `program_type` (enum: `learnership`, `internship`, `candidacy`)
- `sponsor_email` (string, valid email)
- `template_id` (integer, must exist)

**Optional Fields**:
- `required_student_uploads` (array of strings)
- `cohort_metadata` (object)

**Response (201 Created)**:
```json
{
  "id": 2,
  "name": "2026 Q2 Internship",
  "program_type": "internship",
  "sponsor_email": "hr@company.co.za",
  "status": "draft",
  "required_student_uploads": ["id_copy", "cv", "tertiary_certificate"],
  "cohort_metadata": {
    "start_date": "2026-04-01",
    "duration_months": 6,
    "department": "Engineering"
  },
  "tp_signed_at": null,
  "students_completed_at": null,
  "sponsor_completed_at": null,
  "finalized_at": null,
  "created_at": "2026-01-14T19:00:00Z",
  "updated_at": "2026-01-14T19:00:00Z"
}
```

**Error Response (422 Unprocessable Entity)**:
```json
{
  "errors": {
    "name": ["can't be blank"],
    "program_type": ["is not included in the list"],
    "sponsor_email": ["must be a valid email"]
  }
}
```

---

#### Get Cohort Details
**Endpoint**: `GET /api/v1/cohorts/:id`

**Authentication**: Required (TP Admin, must belong to same institution)

**Path Parameters**:
- `id`: Cohort ID

**Request**:
```http
GET /api/v1/cohorts/1
Authorization: Bearer <token>
```

**Response (200 OK)**:
```json
{
  "id": 1,
  "name": "2026 Q1 Learnership",
  "program_type": "learnership",
  "sponsor_email": "sponsor@company.co.za",
  "status": "active",
  "required_student_uploads": ["id_copy", "matric_certificate"],
  "cohort_metadata": {
    "start_date": "2026-02-01",
    "duration_months": 12,
    "stipend_amount": 3500
  },
  "tp_signed_at": "2026-01-14T10:00:00Z",
  "students_completed_at": null,
  "sponsor_completed_at": null,
  "finalized_at": null,
  "template": {
    "id": 42,
    "name": "Standard Learnership Agreement"
  },
  "enrollments": [
    {
      "id": 101,
      "student_email": "john@example.com",
      "student_name": "John",
      "student_surname": "Doe",
      "status": "waiting",
      "role": "student",
      "uploaded_documents": {
        "id_copy": true,
        "matric_certificate": false
      },
      "completed_at": null
    }
  ],
  "stats": {
    "total_students": 15,
    "completed": 8,
    "waiting": 5,
    "in_progress": 2
  },
  "created_at": "2026-01-10T08:00:00Z"
}
```

**Error Response (404 Not Found)**:
```json
{
  "error": "Cohort not found"
}
```

---

#### Update Cohort
**Endpoint**: `PATCH /api/v1/cohorts/:id`

**Authentication**: Required (TP Admin)

**Request Body**:
```json
{
  "name": "Updated Cohort Name",
  "sponsor_email": "new.sponsor@company.co.za",
  "required_student_uploads": ["id_copy", "cv"]
}
```

**Response (200 OK)**:
```json
{
  "id": 1,
  "name": "Updated Cohort Name",
  "sponsor_email": "new.sponsor@company.co.za",
  "required_student_uploads": ["id_copy", "cv"],
  "updated_at": "2026-01-14T19:30:00Z"
}
```

**Error Response (422 Unprocessable Entity)**:
```json
{
  "errors": {
    "sponsor_email": ["must be a valid email"]
  }
}
```

---

#### Start Signing Phase
**Endpoint**: `POST /api/v1/cohorts/:id/start_signing`

**Authentication**: Required (TP Admin)

**Description**: Transitions cohort from `draft` to `active` state. Allows students to enroll.

**Request**:
```http
POST /api/v1/cohorts/1/start_signing
Authorization: Bearer <token>
```

**Response (200 OK)**:
```json
{
  "id": 1,
  "status": "active",
  "tp_signed_at": "2026-01-14T19:30:00Z",
  "message": "Cohort is now active. Students can enroll."
}
```

**Error Responses**:
- `400 Bad Request`: Cohort is not in draft state
- `400 Bad Request`: No template associated
- `403 Forbidden`: Insufficient permissions

```json
{
  "error": "Cohort must be in draft state to start signing"
}
```

---

#### Finalize Cohort
**Endpoint**: `POST /api/v1/cohorts/:id/finalize`

**Authentication**: Required (TP Admin)

**Description**: Marks cohort as completed after sponsor signing. Generates final documents.

**Request**:
```http
POST /api/v1/cohorts/1/finalize
Authorization: Bearer <token>
```

**Response (200 OK)**:
```json
{
  "id": 1,
  "status": "completed",
  "finalized_at": "2026-01-14T19:45:00Z",
  "message": "Cohort finalized. All documents are ready for download."
}
```

**Error Responses**:
- `400 Bad Request`: Sponsor hasn't completed signing
- `400 Bad Request`: Students haven't completed

```json
{
  "error": "Cannot finalize: sponsor signing incomplete"
}
```

---

### 2. Enrollments Management

#### List Cohort Enrollments
**Endpoint**: `GET /api/v1/cohorts/:id/enrollments`

**Authentication**: Required (TP Admin)

**Query Parameters**:
- `status` (optional): Filter by status
- `role` (optional): Filter by role (`student`, `sponsor`)
- `page` (optional): Pagination

**Request**:
```http
GET /api/v1/cohorts/1/enrollments?status=complete&role=student
Authorization: Bearer <token>
```

**Response (200 OK)**:
```json
{
  "data": [
    {
      "id": 101,
      "cohort_id": 1,
      "submission_id": 501,
      "student_email": "john@example.com",
      "student_name": "John",
      "student_surname": "Doe",
      "student_id": "STU2026001",
      "status": "complete",
      "role": "student",
      "uploaded_documents": {
        "id_copy": true,
        "matric_certificate": true,
        "cv": true
      },
      "values": {
        "full_name": "John Doe",
        "phone": "+27 82 123 4567"
      },
      "completed_at": "2026-01-14T15:00:00Z",
      "created_at": "2026-01-12T10:00:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 1,
    "total_count": 5
  }
}
```

---

#### Create Enrollment (Bulk)
**Endpoint**: `POST /api/v1/cohorts/:id/enrollments`

**Authentication**: Required (TP Admin)

**Description**: Creates multiple student enrollments at once. Sends invitation emails.

**Request Body**:
```json
{
  "students": [
    {
      "email": "john@example.com",
      "name": "John",
      "surname": "Doe",
      "student_id": "STU2026001"
    },
    {
      "email": "jane@example.com",
      "name": "Jane",
      "surname": "Smith",
      "student_id": "STU2026002"
    }
  ]
}
```

**Response (201 Created)**:
```json
{
  "created": 2,
  "failed": 0,
  "enrollments": [
    {
      "id": 101,
      "student_email": "john@example.com",
      "status": "waiting",
      "token": "abc123xyz"
    },
    {
      "id": 102,
      "student_email": "jane@example.com",
      "status": "waiting",
      "token": "def456uvw"
    }
  ]
}
```

**Error Response (207 Multi-Status)**:
```json
{
  "created": 1,
  "failed": 1,
  "errors": [
    {
      "email": "duplicate@example.com",
      "error": "Student already enrolled in this cohort"
    }
  ]
}
```

---

#### Get Enrollment Details
**Endpoint**: `GET /api/v1/enrollments/:id`

**Authentication**: Required (TP Admin or Student with token)

**Request**:
```http
GET /api/v1/enrollments/101
Authorization: Bearer <token>
```

**Response (200 OK)**:
```json
{
  "id": 101,
  "cohort_id": 1,
  "submission_id": 501,
  "student_email": "john@example.com",
  "student_name": "John",
  "student_surname": "Doe",
  "status": "in_progress",
  "role": "student",
  "uploaded_documents": {
    "id_copy": true,
    "matric_certificate": false
  },
  "required_documents": ["id_copy", "matric_certificate", "cv"],
  "token": "abc123xyz",
  "token_expires_at": "2026-01-21T19:00:00Z",
  "created_at": "2026-01-12T10:00:00Z"
}
```

---

#### Update Enrollment (Student Portal)
**Endpoint**: `PATCH /api/v1/enrollments/:id`

**Authentication**: Token-based (ad-hoc)

**Description**: Student updates their enrollment, uploads documents, fills forms.

**Request Body**:
```json
{
  "token": "abc123xyz",
  "uploaded_documents": {
    "id_copy": true,
    "matric_certificate": true
  },
  "values": {
    "full_name": "John Doe",
    "phone": "+27 82 123 4567",
    "address": "123 Main St"
  }
}
```

**Response (200 OK)**:
```json
{
  "id": 101,
  "status": "in_progress",
  "uploaded_documents": {
    "id_copy": true,
    "matric_certificate": true
  },
  "values": {
    "full_name": "John Doe",
    "phone": "+27 82 123 4567",
    "address": "123 Main St"
  },
  "progress": "66%",
  "message": "Progress saved. Submit when complete."
}
```

---

#### Submit Enrollment
**Endpoint**: `POST /api/v1/enrollments/:id/submit`

**Authentication**: Token-based (ad-hoc)

**Description**: Final submission of student enrollment.

**Request Body**:
```json
{
  "token": "abc123xyz"
}
```

**Response (200 OK)**:
```json
{
  "id": 101,
  "status": "complete",
  "completed_at": "2026-01-14T15:00:00Z",
  "message": "Enrollment submitted successfully. You will be notified of next steps."
}
```

**Error Response (400 Bad Request)**:
```json
{
  "error": "Missing required documents: matric_certificate"
}
```

---

### 3. Sponsor Portal

#### Get Sponsor Dashboard
**Endpoint**: `GET /api/v1/sponsor/:token/dashboard`

**Authentication**: Token-based (ad-hoc)

**Path Parameters**:
- `token`: Sponsor token from email

**Request**:
```http
GET /api/v1/sponsor/xyz789abc/dashboard
```

**Response (200 OK)**:
```json
{
  "cohort": {
    "id": 1,
    "name": "2026 Q1 Learnership",
    "program_type": "learnership",
    "status": "active"
  },
  "stats": {
    "total_students": 15,
    "completed": 15,
    "pending": 0
  },
  "documents_ready": true,
  "can_sign": true,
  "token_expires_at": "2026-01-21T19:00:00Z"
}
```

---

#### Bulk Sign Documents
**Endpoint**: `POST /api/v1/sponsor/:token/sign`

**Authentication**: Token-based (ad-hoc)

**Description**: Sponsor signs once, applies to all student documents.

**Request Body**:
```json
{
  "signature": "John Smith",
  "agree_to_terms": true
}
```

**Response (200 OK)**:
```json
{
  "signed_count": 15,
  "cohort_id": 1,
  "status": "sponsor_completed",
  "message": "All documents signed successfully. TP has been notified."
}
```

**Error Response (400 Bad Request)**:
```json
{
  "error": "All students must complete before sponsor signing"
}
```

---

### 4. Webhooks

#### Webhook Endpoint
**Endpoint**: `POST /api/v1/webhooks`

**Authentication**: HMAC signature (optional but recommended)

**Description**: Receives webhook events for workflow state changes.

**Headers**:
```http
Content-Type: application/json
X-Webhook-Signature: sha256=...
```

**Request Body**:
```json
{
  "event": "submission.completed",
  "timestamp": "2026-01-14T15:00:00Z",
  "data": {
    "cohort_id": 1,
    "enrollment_id": 101,
    "student_email": "john@example.com"
  }
}
```

**Event Types**:
- `cohort.created` - New cohort created
- `cohort.activated` - Cohort moved to active
- `enrollment.created` - New student enrollment
- `enrollment.completed` - Student submitted
- `sponsor.signed` - Sponsor completed signing
- `cohort.finalized` - Cohort completed

**Response (200 OK)**:
```json
{
  "status": "received",
  "event_id": "evt_123456"
}
```

---

## 🔄 Error Handling

### Standard Error Responses

**400 Bad Request**:
```json
{
  "error": "Invalid request parameters",
  "details": {
    "program_type": ["must be one of: learnership, internship, candidacy"]
  }
}
```

**401 Unauthorized**:
```json
{
  "error": "Authentication required",
  "code": "AUTH_REQUIRED"
}
```

**403 Forbidden**:
```json
{
  "error": "Insufficient permissions",
  "code": "PERMISSION_DENIED"
}
```

**404 Not Found**:
```json
{
  "error": "Resource not found",
  "code": "RESOURCE_NOT_FOUND"
}
```

**422 Unprocessable Entity**:
```json
{
  "error": "Validation failed",
  "errors": {
    "email": ["must be a valid email"],
    "name": ["can't be blank"]
  }
}
```

**500 Internal Server Error**:
```json
{
  "error": "Internal server error",
  "code": "SERVER_ERROR"
}
```

---

## 📊 Pagination

All list endpoints support cursor-based pagination:

**Query Parameters**:
- `page`: Page number (default: 1)
- `per_page`: Items per page (default: 20, max: 100)

**Response Structure**:
```json
{
  "data": [...],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 95,
    "per_page": 20,
    "next_page": 2,
    "prev_page": null
  }
}
```

**Usage**:
```http
GET /api/v1/cohorts?page=2&per_page=10
```

---

## 🎯 Rate Limiting

**Rate Limit**: 100 requests per minute per API key

**Headers**:
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1642186800
```

**429 Too Many Requests**:
```json
{
  "error": "Rate limit exceeded",
  "retry_after": 45
}
```

---

## 🧪 Testing the API

### Using cURL

**Create Cohort**:
```bash
curl -X POST https://api.flodoc.com/api/v1/cohorts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Cohort",
    "program_type": "learnership",
    "sponsor_email": "test@example.com",
    "template_id": 1
  }'
```

**Get Cohorts**:
```bash
curl -X GET "https://api.flodoc.com/api/v1/cohorts?status=active" \
  -H "Authorization: Bearer $TOKEN"
```

**Student Enrollment**:
```bash
curl -X PATCH https://api.flodoc.com/api/v1/enrollments/101 \
  -H "Content-Type: application/json" \
  -d '{
    "token": "abc123xyz",
    "values": {"full_name": "John Doe"}
  }'
```

---

## 🔒 Security Best Practices

### 1. Token Security
- Tokens expire after 7 days
- Use HTTPS in production
- Store tokens securely (not in localStorage for web)
- Implement token refresh mechanism

### 2. Input Validation
- Always validate on backend
- Sanitize all inputs
- Use strong parameters
- Limit file uploads (size, type)

### 3. Rate Limiting
- Implement per-user rate limits
- Track API usage
- Block abusive clients

### 4. Webhook Security
- Verify HMAC signatures
- Validate event payloads
- Implement retry logic with exponential backoff
- Log all webhook deliveries

### 5. CORS
- Restrict origins in production
- Use specific allowed methods
- Implement preflight caching

---

## 📚 API Versioning

### Version Strategy
- URL-based: `/api/v1/`
- Future versions: `/api/v2/`
- Backward compatibility maintained for 6 months
- Deprecation headers for old versions

### Deprecation Headers
```http
Deprecation: true
Sunset: Mon, 31 Dec 2026 23:59:59 GMT
Link: </api/v2/cohorts>; rel="successor-version"
```

---

## 🔄 Webhook Delivery

### Delivery Guarantees
- At-least-once delivery
- Exponential backoff retry (1m, 5m, 15m, 1h, 6h)
- Max 5 retries
- Dead letter queue for failures

### Retry Logic
```ruby
class WebhookDeliveryJob < ApplicationJob
  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform(event)
    # Delivery logic
  end
end
```

---

## 📋 API Checklist

- [ ] Authentication required for all endpoints except auth
- [ ] Proper HTTP status codes
- [ ] Consistent JSON response format
- [ ] Error handling with helpful messages
- [ ] Pagination for list endpoints
- [ ] Rate limiting implemented
- [ ] Input validation on all endpoints
- [ ] CORS configured
- [ ] Webhook signature verification
- [ ] API versioning strategy
- [ ] Documentation complete

---

## 🎯 Next Steps

1. **Implement API Controllers** - Start with cohorts endpoints
2. **Add Authentication** - JWT token system
3. **Write Request Specs** - Test all endpoints
4. **Create API Documentation** - Auto-generate from specs
5. **Test Integration** - Verify with real data

---

**Document Status**: ✅ Complete
**Ready for**: API Implementation (Story 3.x)
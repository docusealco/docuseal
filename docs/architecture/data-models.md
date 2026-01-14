# Data Models - FloDoc Architecture

**Document**: Database Schema & Data Models
**Version**: 1.0
**Last Updated**: 2026-01-14

---

## 📊 Database Overview

FloDoc extends the existing DocuSeal database schema with three new tables to support the 3-portal cohort management system. All new tables follow Rails conventions and include soft delete functionality.

---

## 🎯 New Tables (FloDoc Enhancement)

### 1. institutions

**Purpose**: Single training institution record (one per deployment)

```ruby
create_table :institutions do |t|
  t.string  :name,            null: false
  t.string  :email,           null: false
  t.string  :contact_person
  t.string  :phone
  t.jsonb   :settings,        default: {}
  t.timestamps
  t.datetime :deleted_at
end

# Indexes
add_index :institutions, :name, unique: true
add_index :institutions, :email, unique: true
```

**Key Fields**:
- `name`: Institution name (e.g., "TechPro Training Academy")
- `email`: Official contact email
- `contact_person`: Primary contact name
- `phone`: Contact phone number
- `settings`: JSONB for future configuration (logo, branding, etc.)
- `deleted_at`: Soft delete timestamp

**Design Decisions**:
- **Single Record**: Only one institution per deployment (not multi-tenant)
- **No Account Link**: Independent of DocuSeal's `accounts` table
- **Settings JSONB**: Flexible for future features without migrations

**Relationships**:
```ruby
class Institution < ApplicationRecord
  has_many :cohorts, dependent: :destroy
  has_many :cohort_enrollments, through: :cohorts

  validates :name, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
end
```

---

### 2. cohorts

**Purpose**: Represents a training program cohort (maps to DocuSeal template)

```ruby
create_table :cohorts do |t|
  t.references :institution,              null: false, foreign_key: true
  t.references :template,                 null: false  # Links to existing templates
  t.string     :name,                     null: false
  t.string     :program_type,             null: false  # learnership/internship/candidacy
  t.string     :sponsor_email,            null: false
  t.jsonb      :required_student_uploads, default: []  # ['id', 'matric', 'tertiary']
  t.jsonb      :cohort_metadata,          default: {}  # Additional cohort info
  t.string     :status,                   default: 'draft'  # draft/active/completed
  t.datetime   :tp_signed_at              # TP completed signing
  t.datetime   :students_completed_at     # All students completed
  t.datetime   :sponsor_completed_at      # Sponsor completed
  t.datetime   :finalized_at              # TP finalized review
  t.timestamps
  t.datetime   :deleted_at
end

# Indexes
add_index :cohorts, [:institution_id, :status]
add_index :cohorts, :template_id
add_index :cohorts, :sponsor_email
```

**Key Fields**:
- `institution_id`: Foreign key to institutions
- `template_id`: Foreign key to existing `templates` table
- `name`: Cohort name (e.g., "2026 Q1 Learnership Program")
- `program_type`: Type of training program
  - `learnership`: SETA-funded learnership
  - `internship`: Workplace internship
  - `candidacy`: Professional certification candidacy
- `sponsor_email`: Email for sponsor notifications
- `required_student_uploads`: Array of required documents
  - Example: `["id_copy", "matric_certificate", "tertiary_transcript"]`
- `cohort_metadata`: JSONB for additional data
  - Example: `{"start_date": "2026-02-01", "duration_months": 12}`
- `status`: Workflow state
  - `draft`: Being configured by TP
  - `active`: Students can enroll
  - `completed`: All phases done
- `*_at` fields: Audit trail for workflow phases

**Workflow States**:
```
draft → active → [students_enroll] → [students_complete] → [tp_verifies] → [sponsor_signs] → [tp_finalizes] → completed
```

**Relationships**:
```ruby
class Cohort < ApplicationRecord
  belongs_to :institution
  belongs_to :template  # Existing DocuSeal model

  has_many :cohort_enrollments, dependent: :destroy
  has_many :submissions, through: :cohort_enrollments

  validates :name, :program_type, :sponsor_email, presence: true
  validates :status, inclusion: { in: %w[draft active completed] }

  scope :active, -> { where(status: 'active') }
  scope :completed, -> { where(status: 'completed') }
end
```

---

### 3. cohort_enrollments

**Purpose**: Links students to cohorts with state tracking

```ruby
create_table :cohort_enrollments do |t|
  t.references :cohort,              null: false, foreign_key: true
  t.references :submission,          null: false  # Links to existing submissions
  t.string     :student_email,       null: false
  t.string     :student_name
  t.string     :student_surname
  t.string     :student_id
  t.string     :status,              default: 'waiting'  # waiting/in_progress/complete
  t.string     :role,                default: 'student'  # student/sponsor
  t.jsonb      :uploaded_documents,  default: {}  # Track required uploads
  t.jsonb      :values,              default: {}  # Copy of submitter values
  t.datetime   :completed_at
  t.timestamps
  t.datetime   :deleted_at
end

# Indexes
add_index :cohort_enrollments, [:cohort_id, :status]
add_index :cohort_enrollments, [:cohort_id, :student_email], unique: true
add_index :cohort_enrollments, [:submission_id], unique: true
```

**Key Fields**:
- `cohort_id`: Foreign key to cohorts
- `submission_id`: Foreign key to existing `submissions` table
- `student_email`: Student's email (unique per cohort)
- `student_name`: First name
- `student_surname`: Last name
- `student_id`: Student ID number (optional)
- `status`: Enrollment state
  - `waiting`: Awaiting student action
  - `in_progress`: Student is filling forms
  - `complete`: Student submitted
- `role`: Participant role
  - `student`: Student participant
  - `sponsor`: Sponsor participant (rare, usually one per cohort)
- `uploaded_documents`: JSONB tracking required uploads
  - Example: `{"id_copy": true, "matric": false}`
- `values`: JSONB copy of submitter values for quick access
  - Avoids joining to `submitters` table for simple queries
- `completed_at`: When student finished

**Unique Constraints**:
- One enrollment per student per cohort (`[cohort_id, student_email]`)
- One enrollment per submission (`[submission_id]`)

**Relationships**:
```ruby
class CohortEnrollment < ApplicationRecord
  belongs_to :cohort
  belongs_to :submission  # Existing DocuSeal model

  validates :student_email, presence: true
  validates :status, inclusion: { in: %w[waiting in_progress complete] }
  validates :role, inclusion: { in: %w[student sponsor] }

  scope :students, -> { where(role: 'student') }
  scope :sponsors, -> { where(role: 'sponsor') }
  scope :completed, -> { where(status: 'complete') }
end
```

---

## 🏗️ Existing DocuSeal Tables (Integration Points)

### templates (Existing)
**Used by**: `cohorts.template_id`

```ruby
# Existing schema (simplified)
create_table :templates do |t|
  t.string :name
  t.string :status
  t.references :account
  # ... other fields
end
```

**Integration**: Cohorts reference templates for PDF generation

---

### submissions (Existing)
**Used by**: `cohort_enrollments.submission_id`

```ruby
# Existing schema (simplified)
create_table :submissions do |t|
  t.references :template
  t.string :status
  t.jsonb :values
  # ... other fields
end
```

**Integration**: Enrollments track submission progress

---

### submitters (Existing)
**Used by**: Workflow logic (not directly referenced)

```ruby
# Existing schema (simplified)
create_table :submitters do |t|
  t.references :submission
  t.string :email
  t.string :name
  t.string :status
  # ... other fields
end
```

**Integration**: Used for signing workflow, values copied to `cohort_enrollments.values`

---

## 🔗 Relationships Diagram

```
┌─────────────────┐
│  institutions   │◄────┐
│  (1 per dep)    │     │
└────────┬────────┘     │
         │              │
         1│              │
         │              │
         ▼              │
┌─────────────────┐     │
│    cohorts      │     │
│                 │     │
└────────┬────────┘     │
         │              │
         1│              │
         │              │
         ▼              │
┌─────────────────┐     │
│cohort_enrollments│    │
│                 │     │
└────────┬────────┘     │
         │              │
         │              │
         │              │
         ▼              │
┌─────────────────┐     │
│  submissions    │─────┘
│  (existing)     │
└────────┬────────┘
         │
         │
         ▼
┌─────────────────┐
│   submitters    │
│  (existing)     │
└─────────────────┘
```

---

## 🎯 State Management

### Cohort Status Flow

```ruby
class Cohort < ApplicationRecord
  def advance_to_active!
    update!(status: 'active')
  end

  def mark_students_completed!
    update!(students_completed_at: Time.current)
  end

  def mark_sponsor_completed!
    update!(sponsor_completed_at: Time.current)
  end

  def finalize!
    update!(status: 'completed', finalized_at: Time.current)
  end

  def can_be_signed_by_sponsor?
    students_completed_at.present? && tp_signed_at.present?
  end
end
```

### Enrollment Status Flow

```ruby
class CohortEnrollment < ApplicationRecord
  def start!
    update!(status: 'in_progress')
  end

  def complete!
    update!(
      status: 'complete',
      completed_at: Time.current,
      values: submission.values  # Copy for quick access
    )
  end

  def incomplete_uploads
    required = cohort.required_student_uploads
    uploaded = uploaded_documents.keys
    required - uploaded
  end
end
```

---

## 🔍 Query Patterns

### Get all students for a cohort
```ruby
cohort = Cohort.find(id)
students = cohort.cohort_enrollments.students
```

### Get pending enrollments
```ruby
pending = CohortEnrollment.where(status: ['waiting', 'in_progress'])
```

### Get sponsor dashboard data
```ruby
cohort = Cohort.find(id)
{
  total_students: cohort.cohort_enrollments.students.count,
  completed: cohort.cohort_enrollments.completed.count,
  pending: cohort.cohort_enrollments.where(status: 'waiting').count,
  documents_ready: cohort.tp_signed_at.present?
}
```

### Check if cohort is ready for sponsor
```ruby
cohort = Cohort.find(id)
ready = cohort.students_completed_at.present? &&
        cohort.tp_signed_at.present? &&
        cohort.cohort_enrollments.students.any?
```

---

## 📊 Data Integrity Rules

### Foreign Keys
```ruby
# All new tables have foreign keys
add_foreign_key :cohorts, :institutions
add_foreign_key :cohorts, :templates
add_foreign_key :cohort_enrollments, :cohorts
add_foreign_key :cohort_enrollments, :submissions
```

### Validations
```ruby
# Institution
validates :name, presence: true, uniqueness: true
validates :email, presence: true, uniqueness: true

# Cohort
validates :name, presence: true
validates :program_type, inclusion: { in: %w[learnership internship candidacy] }
validates :sponsor_email, presence: true
validates :status, inclusion: { in: %w[draft active completed] }

# Enrollment
validates :student_email, presence: true
validates :status, inclusion: { in: %w[waiting in_progress complete] }
validates :role, inclusion: { in: %w[student sponsor] }
```

### Unique Constraints
```ruby
# One enrollment per student per cohort
add_index :cohort_enrollments, [:cohort_id, :student_email], unique: true

# One enrollment per submission
add_index :cohort_enrollments, [:submission_id], unique: true
```

---

## 🗄️ Migration Strategy

### Phase 1: Create Tables
```ruby
class CreateFloDocTables < ActiveRecord::Migration[7.0]
  def change
    create_table :institutions do |t|
      # ... fields
    end

    create_table :cohorts do |t|
      # ... fields
    end

    create_table :cohort_enrollments do |t|
      # ... fields
    end

    # Add indexes
    add_index :cohorts, [:institution_id, :status]
    # ... more indexes

    # Add foreign keys
    add_foreign_key :cohorts, :institutions
    # ... more foreign keys
  end
end
```

### Phase 2: Add Models
```ruby
# app/models/institution.rb
class Institution < ApplicationRecord
  has_many :cohorts, dependent: :destroy
  # ...
end

# app/models/cohort.rb
class Cohort < ApplicationRecord
  belongs_to :institution
  belongs_to :template
  has_many :cohort_enrollments, dependent: :destroy
  # ...
end

# app/models/cohort_enrollment.rb
class CohortEnrollment < ApplicationRecord
  belongs_to :cohort
  belongs_to :submission
  # ...
end
```

### Rollback
```bash
# All migrations are reversible
bin/rails db:rollback STEP=1
# Tables are dropped, data is lost (intentional for MVP)
```

---

## 🎯 Performance Considerations

### Index Strategy
```ruby
# For cohort queries by status
add_index :cohorts, [:institution_id, :status]

# For enrollment queries by cohort and status
add_index :cohort_enrollments, [:cohort_id, :status]

# For student lookup (unique per cohort)
add_index :cohort_enrollments, [:cohort_id, :student_email], unique: true

# For submission lookup (unique)
add_index :cohort_enrollments, [:submission_id], unique: true
```

### Query Optimization
```ruby
# Eager load associations to avoid N+1
Cohort.includes(:institution, :cohort_enrollments).find(id)

# Use scopes for common queries
cohort.cohort_enrollments.completed.count
cohort.cohort_enrollments.students.pending
```

### JSONB Usage
```ruby
# Store flexible data without schema changes
cohort.update!(cohort_metadata: {
  start_date: '2026-02-01',
  duration_months: 12,
  funding_source: 'SETA'
})

# Query JSONB fields
Cohort.where("cohort_metadata->>'funding_source' = ?", 'SETA')
```

---

## 🔒 Security Considerations

### Data Isolation
```ruby
# All queries must filter by institution
class Cohort < ApplicationRecord
  scope :for_institution, ->(institution_id) { where(institution_id: institution_id) }
end

# In controllers
@cohort = current_institution.cohorts.find(params[:id])
```

### Email Encryption (Optional)
```ruby
# If policy requires, encrypt sensitive fields
class CohortEnrollment < ApplicationRecord
  encrypts :student_email
  encrypts :student_name
  encrypts :student_surname
end
```

### Audit Trail
```ruby
# All tables have timestamps and soft deletes
t.timestamps
t.datetime :deleted_at

# Use paranoia gem or manual soft delete
def soft_delete
  update!(deleted_at: Time.current)
end
```

---

## 📈 Sample Data

### Institution
```ruby
Institution.create!(
  name: "TechPro Training Academy",
  email: "admin@techpro.co.za",
  contact_person: "Jane Smith",
  phone: "+27 11 123 4567",
  settings: {
    logo_url: "/images/techpro-logo.png",
    primary_color: "#1e3a8a"
  }
)
```

### Cohort
```ruby
Cohort.create!(
  institution: institution,
  template: template,  # Existing DocuSeal template
  name: "2026 Q1 Software Learnership",
  program_type: "learnership",
  sponsor_email: "sponsor@company.co.za",
  required_student_uploads: ["id_copy", "matric_certificate", "cv"],
  cohort_metadata: {
    start_date: "2026-02-01",
    duration_months: 12,
    stipend_amount: 3500
  },
  status: "active"
)
```

### Enrollment
```ruby
CohortEnrollment.create!(
  cohort: cohort,
  submission: submission,  # Existing DocuSeal submission
  student_email: "john.doe@example.com",
  student_name: "John",
  student_surname: "Doe",
  student_id: "STU2026001",
  status: "waiting",
  role: "student",
  uploaded_documents: {
    "id_copy": true,
    "matric_certificate": false
  }
)
```

---

## 🎯 Next Steps

1. **Implement Story 1.1**: Create migrations for these tables
2. **Implement Story 1.2**: Create ActiveRecord models
3. **Write Tests**: Verify schema and relationships
4. **Test Integration**: Ensure existing DocuSeal tables work

---

**Document Status**: ✅ Complete
**Ready for**: Story 1.1 implementation
# Project Structure - FloDoc Architecture

**Document**: File Organization & Conventions
**Version**: 1.0
**Last Updated**: 2026-01-14

---

## 📁 Root Directory Structure

```
floDoc-v3/
├── app/                          # Rails application code
├── config/                       # Configuration files
├── db/                           # Database migrations and schema
├── docs/                         # Documentation
│   ├── architecture/             # Architecture docs (this folder)
│   ├── prd/                      # Product requirements (sharded)
│   ├── po/                       # Product Owner validation
│   ├── qa/                       # QA assessments & gates
│   └── stories/                  # Developer story files
├── lib/                          # Library code
├── spec/                         # Tests
├── app/javascript/               # Frontend code
├── .bmad-core/                   # BMAD workflow configuration
├── docker-compose.yml            # Local Docker setup
└── Gemfile, package.json         # Dependencies
```

---

## 🎯 Application Directory Structure

### `app/models/` - Business Logic

```
app/models/
├── application_record.rb         # Base model
├── user.rb                       # Devise authentication
├── account.rb                    # Multi-tenancy (existing)
├── template.rb                   # Document templates (existing)
├── submission.rb                 # Document workflows (existing)
├── submitter.rb                  # Signers (existing)
│
├── # NEW FloDoc Models
├── institution.rb                # Single training institution
├── cohort.rb                     # Training program cohort
├── cohort_enrollment.rb          # Student enrollment
│
├── # Concerns & Utilities
├── feature_flag.rb               # Feature flag system
├── account_access.rb             # Role-based access (existing)
└── ability.rb                    # Cancancan abilities (existing)
```

**Key Patterns**:
- All models inherit from `ApplicationRecord`
- Use `strip_attributes` for data cleaning
- Include soft delete via `deleted_at` timestamp
- Follow Rails naming conventions (singular, lowercase)

**Example Model**:
```ruby
# app/models/cohort.rb
class Cohort < ApplicationRecord
  include SoftDeletable
  strip_attributes

  belongs_to :institution
  belongs_to :template
  has_many :cohort_enrollments, dependent: :destroy

  validates :name, :program_type, :sponsor_email, presence: true
  validates :status, inclusion: { in: %w[draft active completed] }

  scope :active, -> { where(status: 'active') }
end
```

---

### `app/controllers/` - Request Handling

```
app/controllers/
├── application_controller.rb     # Base controller
├── dashboard_controller.rb       # TP dashboard (existing)
│
├── # NEW FloDoc Controllers
├── tp/                           # TP Portal namespace
│   ├── base_controller.rb
│   ├── cohorts_controller.rb
│   ├── enrollments_controller.rb
│   └── dashboard_controller.rb
│
├── student/                      # Student Portal namespace
│   ├── base_controller.rb
│   ├── enrollment_controller.rb
│   └── documents_controller.rb
│
├── sponsor/                      # Sponsor Portal namespace
│   ├── base_controller.rb
│   ├── dashboard_controller.rb
│   └── signing_controller.rb
│
├── # API Controllers
├── api/
│   ├── v1/
│   │   ├── base_controller.rb
│   │   ├── cohorts_controller.rb
│   │   ├── enrollments_controller.rb
│   │   └── webhooks_controller.rb
│   └── v2/                       # Future versions
│
├── # Settings & Admin
├── settings/
│   ├── profile_controller.rb
│   └── security_controller.rb
│
└── # Existing DocuSeal Controllers
    ├── templates_controller.rb
    ├── submissions_controller.rb
    └── submitters_controller.rb
```

**Controller Patterns**:

**TP Portal Controller**:
```ruby
# app/controllers/tp/cohorts_controller.rb
class tp::CohortsController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource

  def index
    @cohorts = current_institution.cohorts.order(created_at: :desc)
  end

  def create
    @cohort = current_institution.cohorts.new(cohort_params)
    if @cohort.save
      redirect_to tp_cohort_path(@cohort), notice: 'Cohort created'
    else
      render :new
    end
  end

  private

  def cohort_params
    params.require(:cohort).permit(:name, :program_type, :sponsor_email, :template_id)
  end
end
```

**Ad-hoc Portal Controller**:
```ruby
# app/controllers/student/enrollment_controller.rb
class Student::EnrollmentController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @enrollment = CohortEnrollment.find_by!(token: params[:token])
    redirect_to root_path, alert: 'Invalid token' unless @enrollment.pending?
  end

  def submit
    @enrollment = CohortEnrollment.find_by!(token: params[:token])
    # Process submission
  end
end
```

**API Controller**:
```ruby
# app/api/v1/cohorts_controller.rb
class Api::V1::CohortsController < Api::V1::BaseController
  def index
    @cohorts = current_institution.cohorts
    render json: @cohorts
  end

  def create
    @cohort = current_institution.cohorts.new(cohort_params)
    if @cohort.save
      render json: @cohort, status: :created
    else
      render json: { errors: @cohort.errors }, status: :unprocessable_entity
    end
  end

  private

  def cohort_params
    params.permit(:name, :program_type, :sponsor_email, :template_id)
  end
end
```

---

### `app/javascript/` - Frontend Code

```
app/javascript/
├── application.js                # Main entry point
├── packs/                        # Webpack packs
│   └── application.js
│
├── # NEW FloDoc Portals
├── tp/                           # TP Portal (Admin)
│   ├── index.js                  # Vue app entry
│   ├── views/
│   │   ├── Dashboard.vue
│   │   ├── CohortList.vue
│   │   ├── CohortCreate.vue
│   │   ├── CohortDetail.vue
│   │   ├── StudentManagement.vue
│   │   └── SponsorPortal.vue
│   ├── components/
│   │   ├── CohortCard.vue
│   │   ├── CohortForm.vue
│   │   ├── StudentTable.vue
│   │   └── StatusBadge.vue
│   ├── stores/
│   │   ├── cohortStore.js        # Pinia store
│   │   └── uiStore.js
│   └── api/
│       └── cohorts.js            # API client
│
├── student/                      # Student Portal
│   ├── index.js
│   ├── views/
│   │   ├── Enrollment.vue
│   │   ├── DocumentUpload.vue
│   │   ├── FormFill.vue
│   │   └── SubmissionStatus.vue
│   ├── components/
│   │   ├── UploadZone.vue
│   │   ├── FormField.vue
│   │   └── ProgressTracker.vue
│   ├── stores/
│   │   └── enrollmentStore.js
│   └── api/
│       └── enrollment.js
│
├── sponsor/                      # Sponsor Portal
│   ├── index.js
│   ├── views/
│   │   ├── Dashboard.vue
│   │   ├── BulkSigning.vue
│   │   ├── DocumentPreview.vue
│   │   └── ProgressTracker.vue
│   ├── components/
│   │   ├── CohortSummary.vue
│   │   ├── SigningTable.vue
│   │   └── BulkSignButton.vue
│   ├── stores/
│   │   └── sponsorStore.js
│   └── api/
│       └── sponsor.js
│
├── # Shared Components
├── components/
│   ├── ui/
│   │   ├── Button.vue
│   │   ├── Modal.vue
│   │   ├── Alert.vue
│   │   └── LoadingSpinner.vue
│   └── layout/
│       ├── Header.vue
│       ├── Sidebar.vue
│       └── Footer.vue
│
├── # Existing DocuSeal UI
├── template_builder/             # PDF form builder
├── elements/                     # Web components
├── submission_form/              # Multi-step signing
│
└── # Utilities
    ├── utils/
    │   ├── auth.js
    │   ├── api.js
    │   └── validators.js
    └── plugins/
        └── axios.js
```

**Vue Component Pattern**:
```vue
<!-- app/javascript/tp/views/CohortList.vue -->
<template>
  <div class="cohort-list">
    <Header title="Cohorts" />

    <div v-if="loading">Loading...</div>

    <div v-else>
      <CohortCard
        v-for="cohort in cohorts"
        :key="cohort.id"
        :cohort="cohort"
        @click="viewCohort(cohort.id)"
      />
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useCohortStore } from '@/tp/stores/cohortStore'
import CohortCard from '@/tp/components/CohortCard.vue'

const cohortStore = useCohortStore()
const loading = ref(true)

onMounted(async () => {
  await cohortStore.fetchCohorts()
  loading.value = false
})

function viewCohort(id) {
  // Navigate to detail view
}
</script>

<style scoped>
.cohort-list {
  padding: 2rem;
}
</style>
```

**Pinia Store Pattern**:
```javascript
// app/javascript/tp/stores/cohortStore.js
import { defineStore } from 'pinia'
import { CohortsAPI } from '@/tp/api/cohorts'

export const useCohortStore = defineStore('cohort', {
  state: () => ({
    cohorts: [],
    currentCohort: null,
    loading: false,
    error: null
  }),

  actions: {
    async fetchCohorts() {
      this.loading = true
      this.error = null
      try {
        this.cohorts = await CohortsAPI.getAll()
      } catch (err) {
        this.error = err.message
      } finally {
        this.loading = false
      }
    },

    async createCohort(data) {
      const cohort = await CohortsAPI.create(data)
      this.cohorts.unshift(cohort)
      return cohort
    },

    async fetchCohort(id) {
      this.currentCohort = await CohortsAPI.get(id)
    }
  },

  getters: {
    activeCohorts: (state) => state.cohorts.filter(c => c.status === 'active'),
    completedCohorts: (state) => state.cohorts.filter(c => c.status === 'completed')
  }
})
```

**API Client Pattern**:
```javascript
// app/javascript/tp/api/cohorts.js
import axios from 'axios'

export const CohortsAPI = {
  async getAll() {
    const response = await axios.get('/api/v1/cohorts')
    return response.data
  },

  async get(id) {
    const response = await axios.get(`/api/v1/cohorts/${id}`)
    return response.data
  },

  async create(data) {
    const response = await axios.post('/api/v1/cohorts', data)
    return response.data
  },

  async update(id, data) {
    const response = await axios.patch(`/api/v1/cohorts/${id}`, data)
    return response.data
  },

  async startSigning(id) {
    const response = await axios.post(`/api/v1/cohorts/${id}/start_signing`)
    return response.data
  }
}
```

---

### `app/controllers/api/` - API Layer

```
app/controllers/api/
├── v1/
│   ├── base_controller.rb           # API authentication & versioning
│   ├── cohorts_controller.rb        # Cohort CRUD
│   ├── enrollments_controller.rb    # Enrollment management
│   ├── students_controller.rb       # Student portal API
│   ├── sponsors_controller.rb       # Sponsor portal API
│   ├── webhooks_controller.rb       # Webhook endpoints
│   └── uploads_controller.rb        # File uploads
│
└── v2/                              # Future version
    └── base_controller.rb
```

**API Base Controller**:
```ruby
# app/controllers/api/v1/base_controller.rb
class Api::V1::BaseController < ActionController::API
  before_action :authenticate_api!
  rescue_from StandardError, with: :handle_error

  private

  def authenticate_api!
    token = request.headers['Authorization']&.split(' ')&.last
    @current_user = User.find_by(jwt_token: token)
    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
  end

  def current_institution
    @current_user.institution
  end

  def handle_error(exception)
    render json: { error: exception.message }, status: :internal_server_error
  end
end
```

---

### `db/migrate/` - Database Migrations

```
db/migrate/
├── 20260114000001_create_flo_doc_tables.rb          # Story 1.1
├── 20260114000002_create_feature_flags.rb           # Story 1.2
├── 20260114000003_add_flo_doc_indexes.rb            # Performance
└── # Existing DocuSeal migrations
```

**Migration Naming Convention**:
- Timestamp format: `YYYYMMDDHHMMSS`
- Descriptive name: `create_[table]_tables` or `add_[field]_to_[table]`
- Group related changes

**Example Migration**:
```ruby
# db/migrate/20260114000001_create_flo_doc_tables.rb
class CreateFloDocTables < ActiveRecord::Migration[7.0]
  def change
    create_table :institutions do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :contact_person
      t.string :phone
      t.jsonb :settings, default: {}
      t.timestamps
      t.datetime :deleted_at
    end

    add_index :institutions, :name, unique: true
    add_index :institutions, :email, unique: true

    # ... more tables
  end
end
```

---

### `spec/` - Test Suite

```
spec/
├── models/
│   ├── institution_spec.rb
│   ├── cohort_spec.rb
│   └── cohort_enrollment_spec.rb
│
├── controllers/
│   ├── tp/
│   │   ├── cohorts_controller_spec.rb
│   │   └── dashboard_controller_spec.rb
│   ├── student/
│   │   └── enrollment_controller_spec.rb
│   └── api/
│       └── v1/
│           ├── cohorts_controller_spec.rb
│           └── webhooks_controller_spec.rb
│
├── requests/
│   └── api/
│       └── v1/
│           ├── cohorts_spec.rb
│           └── webhooks_spec.rb
│
├── system/
│   ├── tp_portal_spec.rb
│   ├── student_portal_spec.rb
│   └── sponsor_portal_spec.rb
│
├── migrations/
│   └── create_flo_doc_tables_spec.rb
│
├── javascript/
│   ├── tp/
│   │   ├── views/
│   │   │   └── CohortList.spec.js
│   │   └── stores/
│   │       └── cohortStore.spec.js
│   └── student/
│       └── stores/
│           └── enrollmentStore.spec.js
│
├── factories/
│   ├── institutions.rb
│   ├── cohorts.rb
│   └── cohort_enrollments.rb
│
└── support/
    ├── database_cleaner.rb
    └── api_helpers.rb
```

**Model Spec Example**:
```ruby
# spec/models/cohort_spec.rb
require 'rails_helper'

RSpec.describe Cohort, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:program_type) }
    it { should validate_inclusion_of(:status).in_array(%w[draft active completed]) }
  end

  describe 'associations' do
    it { should belong_to(:institution) }
    it { should belong_to(:template) }
    it { should have_many(:cohort_enrollments) }
  end

  describe '#active?' do
    it 'returns true when status is active' do
      cohort = build(:cohort, status: 'active')
      expect(cohort.active?).to be true
    end
  end
end
```

**Vue Component Spec Example**:
```javascript
// spec/javascript/tp/views/CohortList.spec.js
import { mount, flushPromises } from '@vue/test-utils'
import CohortList from '@/tp/views/CohortList.vue'
import { createPinia, setActivePinia } from 'pinia'
import { useCohortStore } from '@/tp/stores/cohortStore'

describe('CohortList', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('displays loading state', () => {
    const wrapper = mount(CohortList)
    expect(wrapper.text()).toContain('Loading')
  })

  it('displays cohorts after loading', async () => {
    const wrapper = mount(CohortList)
    const store = useCohortStore()
    store.cohorts = [{ id: 1, name: 'Test Cohort' }]

    await flushPromises()
    expect(wrapper.text()).toContain('Test Cohort')
  })
})
```

---

### `lib/` - Utility Modules

```
lib/
├── # Business Logic Helpers
├── submissions.rb                 # Submission workflows (existing)
├── submitters.rb                  # Submitter logic (existing)
├── cohorts.rb                     # Cohort workflows (NEW)
├── enrollments.rb                 # Enrollment logic (NEW)
│
├── # PDF Processing
├── pdf_utils.rb                   # PDF utilities
├── pdfium.rb                      # PDF rendering
│
├── # Webhooks
├── send_webhook_request.rb        # Webhook delivery
├── webhook_events.rb              # Event definitions
│
├── # Token Management
├── token_generator.rb             # Secure token generation
├── token_verifier.rb              # Token validation
│
└── # Utilities
    ├── load_active_storage_configs.rb
    └── feature_flag_loader.rb
```

**Utility Module Example**:
```ruby
# lib/cohorts.rb
module Cohorts
  module Workflow
    def self.advance_to_active(cohort)
      return false unless cohort.draft?

      cohort.update!(status: 'active')
      CohortMailer.activated(cohort).deliver_later
      true
    end

    def self.ready_for_sponsor?(cohort)
      cohort.students_completed_at.present? &&
      cohort.tp_signed_at.present? &&
      cohort.cohort_enrollments.students.any?
    end
  end
end
```

---

### `config/` - Configuration

```
config/
├── application.rb                  # Rails config
├── database.yml                    # Database config
├── routes.rb                       # All routes
├── storage.yml                     # Active Storage
├── sidekiq.yml                     # Sidekiq config
├── shakapacker.yml                 # Webpack config
│
├── # Initializers
├── devise.rb                       # Devise config
├── cors.rb                         # CORS settings
├── active_storage.rb               # Storage config
│
└── # Environments
    ├── development.rb
    ├── test.rb
    └── production.rb
```

**Routes Configuration**:
```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Existing DocuSeal routes
  resources :templates
  resources :submissions

  # TP Portal (authenticated)
  namespace :tp do
    root 'dashboard#index'
    resources :cohorts do
      member do
        post :start_signing
        post :finalize
      end
      resources :enrollments, only: [:index, :show]
    end
    resources :students, only: [:index, :show]
    resources :sponsors, only: [:index, :show]
  end

  # Student Portal (ad-hoc tokens)
  scope module: :student do
    get '/enroll/:token', to: 'enrollment#show', as: :student_enroll
    post '/enroll/:token/submit', to: 'enrollment#submit'
    get '/status/:token', to: 'enrollment#status'
  end

  # Sponsor Portal (ad-hoc tokens)
  scope module: :sponsor do
    get '/sponsor/:token', to: 'dashboard#show', as: :sponsor_dashboard
    post '/sponsor/:token/sign', to: 'signing#bulk_sign'
  end

  # API v1
  namespace :api do
    namespace :v1 do
      resources :cohorts do
        member do
          post :start_signing
        end
      end
      resources :enrollments
      resources :students, only: [:show, :update]
      resources :sponsors, only: [:show]
      resources :webhooks, only: [:create]
    end
  end

  # Devise (existing)
  devise_for :users
end
```

---

## 🎯 File Naming Conventions

### Models
- **Singular**: `cohort.rb`, not `cohorts.rb`
- **Snake case**: `cohort_enrollment.rb`
- **Table name**: Plural (Rails convention)

### Controllers
- **Plural**: `cohorts_controller.rb`
- **Namespaced**: `tp/cohorts_controller.rb`
- **API versioned**: `api/v1/cohorts_controller.rb`

### Views
- **Controller-based**: `app/views/tp/cohorts/`
- **Template names**: `index.html.erb`, `show.html.erb`, `_form.html.erb`

### JavaScript
- **Components**: PascalCase (`CohortCard.vue`)
- **Stores**: camelCase (`cohortStore.js`)
- **API**: PascalCase (`CohortsAPI`)
- **Views**: PascalCase (`CohortList.vue`)

### Tests
- **Models**: `model_name_spec.rb`
- **Controllers**: `controller_name_spec.rb`
- **Requests**: `request_name_spec.rb`
- **System**: `feature_name_spec.rb`
- **JavaScript**: `ComponentName.spec.js`

---

## 🔧 Configuration Files

### Gemfile
```ruby
# Core
gem 'rails', '~> 7.0'

# Database
gem 'pg', '~> 1.4'

# Authentication
gem 'devise', '~> 4.8'
gem 'devise-two-factor'
gem 'cancancan', '~> 3.0'

# Background Jobs
gem 'sidekiq', '~> 7.0'

# PDF
gem 'hexapdf', '~> 0.15'

# API
gem 'jbuilder'

# Security
gem 'rack-attack'
```

### package.json
```json
{
  "name": "flo-doc",
  "dependencies": {
    "vue": "^3.3.0",
    "pinia": "^2.1.0",
    "axios": "^1.6.0",
    "tailwindcss": "^3.4.17",
    "daisyui": "^3.9.4"
  },
  "devDependencies": {
    "@vue/test-utils": "^2.4.0",
    "vitest": "^1.0.0"
  }
}
```

### docker-compose.yml
```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "3000:3000"
    depends_on:
      - db
      - redis
      - minio
    environment:
      DATABASE_URL: postgresql://postgres:password@db:5432/flo_doc
      REDIS_URL: redis://redis:6379

  db:
    image: postgres:14
    environment:
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine

  minio:
    image: minio/minio
    command: server /data
    ports:
      - "9000:9000"

  mailhog:
    image: mailhog/mailhog
    ports:
      - "1025:1025"
      - "8025:8025"

volumes:
  postgres_data:
```

---

## 📊 Source Tree Reference

For complete file tree with explanations, see: `docs/architecture/source-tree.md`

---

## 🎯 Development Workflow

### Adding a New Model
1. Create migration: `rails g migration CreateTableName`
2. Create model: `rails g model TableName`
3. Add associations & validations
4. Write model specs
5. Run migration: `rails db:migrate`

### Adding a New Controller
1. Create controller: `rails g controller Namespace/Name`
2. Add routes
3. Add authentication/authorization
4. Write controller specs
5. Test manually

### Adding a New Vue Component
1. Create component file in appropriate portal folder
2. Add to view or register globally
3. Write component spec
4. Test in browser

### Running Tests
```bash
# Ruby tests
bundle exec rspec spec/models/cohort_spec.rb

# JavaScript tests
yarn test spec/javascript/tp/views/CohortList.spec.js

# All tests
bundle exec rspec
yarn test
```

---

## 🔍 Key Principles

1. **Convention Over Configuration**: Follow Rails and Vue conventions
2. **Separation of Concerns**: Keep models, controllers, views separate
3. **DRY**: Reuse code via concerns, mixins, and components
4. **Testability**: Design for easy testing
5. **Maintainability**: Clear structure, good naming, documentation

---

## 📚 Related Documents

- **Tech Stack**: `docs/architecture/tech-stack.md`
- **Data Models**: `docs/architecture/data-models.md`
- **Coding Standards**: `docs/architecture/coding-standards.md`
- **Source Tree**: `docs/architecture/source-tree.md`

---

**Document Status**: ✅ Complete
**Ready for**: Implementation
# Coding Standards - FloDoc Architecture

**Document**: Ruby, Vue, and Testing Conventions
**Version**: 1.0
**Last Updated**: 2026-01-14

---

## 📋 Overview

This document defines the coding standards and conventions for the FloDoc project. Following these standards ensures consistency, maintainability, and quality across the codebase.

---

## 🎯 Ruby/Rails Standards

### 1. Model Conventions

#### File Naming
```ruby
# ✅ Correct
app/models/cohort.rb
app/models/cohort_enrollment.rb
app/models/institution.rb

# ❌ Wrong
app/models/Cohort.rb
app/models/cohort_enrollment_model.rb
```

#### Class Definition
```ruby
# ✅ Correct
class Cohort < ApplicationRecord
  # Code here
end

# ❌ Wrong
class CohortModel < ApplicationRecord
  # Code here
end
```

#### Inheritance & Includes
```ruby
# ✅ Correct
class Cohort < ApplicationRecord
  include SoftDeletable
  strip_attributes

  # Associations, validations, etc.
end

# All models must inherit from ApplicationRecord
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # Default scope for soft deletes
  default_scope { where(deleted_at: nil) }
end
```

#### Associations
```ruby
# ✅ Correct - Use explicit naming
class Cohort < ApplicationRecord
  belongs_to :institution
  belongs_to :template

  has_many :cohort_enrollments, dependent: :destroy
  has_many :students, -> { where(role: 'student') },
           class_name: 'CohortEnrollment'
end

# ✅ Correct - Through associations
class Institution < ApplicationRecord
  has_many :cohorts
  has_many :cohort_enrollments, through: :cohorts
  has_many :students, through: :cohort_enrollments
end

# ❌ Wrong - Implicit class names
class Cohort < ApplicationRecord
  has_many :enrollments  # Should be :cohort_enrollments
end
```

#### Validations
```ruby
# ✅ Correct - Order matters
class Cohort < ApplicationRecord
  validates :name, presence: true
  validates :program_type, presence: true,
            inclusion: { in: %w[learnership internship candidacy] }
  validates :status, inclusion: { in: %w[draft active completed] }

  # Custom validations
  validate :sponsor_email_format

  private

  def sponsor_email_format
    return if sponsor_email =~ URI::MailTo::EMAIL_REGEXP
    errors.add(:sponsor_email, 'must be a valid email')
  end
end

# ✅ Correct - Conditional validations
class CohortEnrollment < ApplicationRecord
  validates :student_id, presence: true, if: :requires_student_id?

  def requires_student_id?
    cohort.program_type == 'learnership'
  end
end
```

#### Scopes
```ruby
# ✅ Correct - Use lambdas
class Cohort < ApplicationRecord
  scope :active, -> { where(status: 'active') }
  scope :completed, -> { where(status: 'completed') }
  scope :for_institution, ->(institution) { where(institution: institution) }
  scope :recent, -> { order(created_at: :desc) }

  # Complex scopes
  scope :ready_for_sponsor, -> {
    where.not(tp_signed_at: nil)
         .where.not(students_completed_at: nil)
         .where(status: 'active')
  }
end

# ❌ Wrong - Procs without lambdas
scope :active, { where(status: 'active') }
```

#### Callbacks
```ruby
# ✅ Correct - Use private methods
class CohortEnrollment < ApplicationRecord
  before_create :generate_token
  after_commit :send_welcome_email, on: :create

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def send_welcome_email
    CohortMailer.welcome(self).deliver_later
  end
end

# ❌ Wrong - Logic in callbacks
class CohortEnrollment < ApplicationRecord
  before_create do
    # Complex business logic here - bad practice
    self.token = SecureRandom.urlsafe_base64(32)
    # More logic...
  end
end
```

#### Query Methods
```ruby
# ✅ Correct - Use ActiveRecord methods
class Cohort < ApplicationRecord
  def self.with_pending_enrollments
    joins(:cohort_enrollments)
      .where(cohort_enrollments: { status: ['waiting', 'in_progress'] })
      .distinct
  end

  def pending_count
    cohort_enrollments.where(status: ['waiting', 'in_progress']).count
  end

  def all_students_completed?
    cohort_enrollments.students.where.not(status: 'complete').empty?
  end
end

# ❌ Wrong - Raw SQL without need
def self.with_pending_enrollments
  find_by_sql("SELECT * FROM cohorts WHERE ...")
end
```

---

### 2. Controller Conventions

#### Namespace Organization
```ruby
# ✅ Correct - Namespace for portals
class tp::CohortsController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource

  # Actions...
end

class Student::EnrollmentController < ApplicationController
  skip_before_action :authenticate_user!

  # Actions...
end

# ❌ Wrong - Flat structure
class TpCohortsController < ApplicationController
  # ...
end
```

#### Strong Parameters
```ruby
# ✅ Correct - Explicit parameter whitelisting
class tp::CohortsController < ApplicationController
  private

  def cohort_params
    params.require(:cohort).permit(
      :name,
      :program_type,
      :sponsor_email,
      :template_id,
      required_student_uploads: []
    )
  end
end

# ❌ Wrong - Too permissive
def cohort_params
  params.require(:cohort).permit!
end
```

#### Before Actions
```ruby
# ✅ Correct - Order matters
class tp::CohortsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_institution
  before_action :set_cohort, only: [:show, :edit, :update, :destroy]
  before_action :authorize_cohort, only: [:show, :edit, :update, :destroy]

  private

  def set_institution
    @institution = current_user.institution
  end

  def set_cohort
    @cohort = @institution.cohorts.find(params[:id])
  end

  def authorize_cohort
    authorize! :manage, @cohort
  end
end
```

#### Action Methods
```ruby
# ✅ Correct - Keep actions focused
class tp::CohortsController < ApplicationController
  def index
    @cohorts = current_institution.cohorts.recent
  end

  def show
    # @cohort set by before_action
  end

  def create
    @cohort = current_institution.cohorts.new(cohort_params)
    if @cohort.save
      redirect_to tp_cohort_path(@cohort), notice: 'Created'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def cohort_params
    params.require(:cohort).permit(:name, :program_type, :sponsor_email, :template_id)
  end
end

# ❌ Wrong - Fat actions
def create
  @cohort = current_institution.cohorts.new(cohort_params)
  # 20 lines of validation logic
  # 10 lines of email sending
  # 15 lines of redirect logic
  # All should be in model or service object
end
```

---

### 3. API Controller Standards

```ruby
# ✅ Correct - API base controller
class Api::V1::BaseController < ActionController::API
  before_action :authenticate_api!
  rescue_from StandardError, with: :handle_error

  private

  def authenticate_api!
    token = request.headers['Authorization']&.split(' ')&.last
    @current_user = User.find_by(jwt_token: token)
    return if @current_user

    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  def current_institution
    @current_user&.institution
  end

  def handle_error(exception)
    Rails.logger.error(exception)
    render json: { error: exception.message }, status: :internal_server_error
  end
end

# ✅ Correct - API resource controller
class Api::V1::CohortsController < Api::V1::BaseController
  def index
    @cohorts = current_institution.cohorts
    render json: @cohorts
  end

  def show
    @cohort = current_institution.cohorts.find(params[:id])
    render json: @cohort
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

### 4. Service Objects (For Complex Logic)

```ruby
# ✅ Correct - Service object pattern
# app/services/cohort_workflow_service.rb
class CohortWorkflowService
  def initialize(cohort)
    @cohort = cohort
  end

  def advance_to_active
    return false unless @cohort.draft?

    @cohort.update!(status: 'active')
    CohortMailer.activated(@cohort).deliver_later
    true
  end

  def ready_for_sponsor?
    @cohort.students_completed_at.present? &&
    @cohort.tp_signed_at.present? &&
    @cohort.cohort_enrollments.students.any?
  end

  def finalize!
    return false unless ready_for_sponsor?

    @cohort.update!(status: 'completed', finalized_at: Time.current)
    CohortMailer.finalized(@cohort).deliver_later
    true
  end
end

# Usage in controller
class tp::CohortsController < ApplicationController
  def start_signing
    @cohort = current_institution.cohorts.find(params[:id])
    service = CohortWorkflowService.new(@cohort)

    if service.advance_to_active
      redirect_to tp_cohort_path(@cohort), notice: 'Cohort activated'
    else
      redirect_to tp_cohort_path(@cohort), alert: 'Cannot activate'
    end
  end
end
```

---

### 5. Mailer Standards

```ruby
# ✅ Correct - Mailer conventions
class CohortMailer < ApplicationMailer
  default from: 'noreply@flodoc.com'

  def activated(cohort)
    @cohort = cohort
    @institution = cohort.institution

    mail(
      to: cohort.sponsor_email,
      subject: "Cohort #{cohort.name} is Ready for Review"
    )
  end

  def welcome(enrollment)
    @enrollment = enrollment
    @cohort = enrollment.cohort

    mail(
      to: enrollment.student_email,
      subject: "Welcome to #{cohort.name}"
    )
  end
end

# app/views/cohort_mailer/activated.html.erb
<h1>Hello <%= @institution.contact_person %>,</h1>

<p>
  The cohort <strong><%= @cohort.name %></strong> is now active.
  Students can begin enrolling.
</p>

<%= link_to 'View Cohort', tp_cohort_url(@cohort) %>
```

---

## 🎨 Vue.js Standards

### 1. Component Structure

#### File Organization
```
app/javascript/
├── tp/
│   ├── views/              # Page-level components
│   ├── components/         # Reusable components
│   ├── stores/             # Pinia stores
│   └── api/                # API clients
```

#### Component Naming
```vue
<!-- ✅ Correct - PascalCase for components -->
<!-- app/javascript/tp/components/CohortCard.vue -->
<template>
  <div class="cohort-card">
    <h3>{{ cohort.name }}</h3>
  </div>
</template>

<script setup>
defineProps({
  cohort: {
    type: Object,
    required: true
  }
})
</script>

<!-- ❌ Wrong -->
<!-- app/javascript/tp/components/cohort-card.vue (kebab-case) -->
```

#### View Components
```vue
<!-- ✅ Correct - Page-level view -->
<!-- app/javascript/tp/views/CohortList.vue -->
<template>
  <div class="cohort-list">
    <Header title="Cohorts" />

    <div v-if="loading" class="loading">
      <Spinner />
    </div>

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
import Header from '@/tp/components/layout/Header.vue'
import CohortCard from '@/tp/components/CohortCard.vue'
import Spinner from '@/components/ui/Spinner.vue'

const cohortStore = useCohortStore()
const loading = ref(true)

onMounted(async () => {
  await cohortStore.fetchCohorts()
  loading.value = false
})

function viewCohort(id) {
  // Navigate to detail
}
</script>

<style scoped>
.cohort-list {
  padding: 2rem;
  max-width: 1200px;
  margin: 0 auto;
}
</style>
```

---

### 2. Composition API Standards

```vue
<!-- ✅ Correct - Composition API with setup -->
<script setup>
import { ref, computed, onMounted } from 'vue'
import { storeToRefs } from 'pinia'
import { useCohortStore } from '@/tp/stores/cohortStore'

// Store
const cohortStore = useCohortStore()
const { cohorts, loading, error } = storeToRefs(cohortStore)

// Local state
const searchQuery = ref('')
const filterStatus = ref('all')

// Computed
const filteredCohorts = computed(() => {
  let results = cohorts.value

  if (searchQuery.value) {
    results = results.filter(c =>
      c.name.toLowerCase().includes(searchQuery.value.toLowerCase())
    )
  }

  if (filterStatus.value !== 'all') {
    results = results.filter(c => c.status === filterStatus.value)
  }

  return results
})

// Methods
const refresh = async () => {
  await cohortStore.fetchCohorts()
}

// Lifecycle
onMounted(() => {
  refresh()
})
</script>

<!-- ❌ Wrong - Options API (unless necessary) -->
<script>
export default {
  data() {
    return {
      searchQuery: '',
      filterStatus: 'all'
    }
  },
  computed: {
    filteredCohorts() {
      // ...
    }
  },
  methods: {
    refresh() {
      // ...
    }
  },
  mounted() {
    this.refresh()
  }
}
</script>
```

---

### 3. Props & Events

```vue
<!-- ✅ Correct - Props with validation -->
<template>
  <div class="cohort-card" @click="$emit('select', cohort.id)">
    <h3>{{ title }}</h3>
    <p>{{ cohort.name }}</p>
  </div>
</template>

<script setup>
const props = defineProps({
  cohort: {
    type: Object,
    required: true,
    validator: (value) => {
      return ['id', 'name', 'status'].every(key => key in value)
    }
  },
  title: {
    type: String,
    default: 'Cohort Details'
  }
})

const emit = defineEmits(['select'])
</script>

<!-- ✅ Correct - Destructuring props -->
<script setup>
const { cohort, title = 'Default' } = defineProps({
  cohort: Object,
  title: String
})
</script>
```

---

### 4. Pinia Stores

```javascript
// ✅ Correct - Pinia store structure
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

  getters: {
    activeCohorts: (state) => {
      return state.cohorts.filter(c => c.status === 'active')
    },

    completedCohorts: (state) => {
      return state.cohorts.filter(c => c.status === 'completed')
    },

    getCohortById: (state) => {
      return (id) => state.cohorts.find(c => c.id === id)
    }
  },

  actions: {
    async fetchCohorts() {
      this.loading = true
      this.error = null
      try {
        this.cohorts = await CohortsAPI.getAll()
      } catch (err) {
        this.error = err.message
        throw err
      } finally {
        this.loading = false
      }
    },

    async fetchCohort(id) {
      this.loading = true
      try {
        this.currentCohort = await CohortsAPI.get(id)
      } finally {
        this.loading = false
      }
    },

    async createCohort(data) {
      const cohort = await CohortsAPI.create(data)
      this.cohorts.unshift(cohort)
      return cohort
    },

    async updateCohort(id, data) {
      const cohort = await CohortsAPI.update(id, data)
      const index = this.cohorts.findIndex(c => c.id === id)
      if (index !== -1) {
        this.cohorts[index] = cohort
      }
      return cohort
    },

    async startSigning(id) {
      const cohort = await CohortsAPI.startSigning(id)
      const index = this.cohorts.findIndex(c => c.id === id)
      if (index !== -1) {
        this.cohorts[index] = cohort
      }
      return cohort
    },

    // Optimistic update
    async deleteCohort(id) {
      const index = this.cohorts.findIndex(c => c.id === id)
      if (index === -1) return

      const deleted = this.cohorts[index]
      this.cohorts.splice(index, 1)

      try {
        await CohortsAPI.delete(id)
      } catch (err) {
        // Rollback on error
        this.cohorts.splice(index, 0, deleted)
        throw err
      }
    }
  }
})
```

---

### 5. API Client Standards

```javascript
// ✅ Correct - API client with error handling
// app/javascript/tp/api/cohorts.js
import axios from 'axios'

const api = axios.create({
  baseURL: '/api/v1',
  headers: {
    'Content-Type': 'application/json'
  }
})

// Request interceptor for auth
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('auth_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Handle unauthorized
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export const CohortsAPI = {
  async getAll() {
    const response = await api.get('/cohorts')
    return response.data
  },

  async get(id) {
    const response = await api.get(`/cohorts/${id}`)
    return response.data
  },

  async create(data) {
    const response = await api.post('/cohorts', data)
    return response.data
  },

  async update(id, data) {
    const response = await api.patch(`/cohorts/${id}`, data)
    return response.data
  },

  async startSigning(id) {
    const response = await api.post(`/cohorts/${id}/start_signing`)
    return response.data
  },

  async delete(id) {
    await api.delete(`/cohorts/${id}`)
  }
}
```

---

### 6. Template Standards

```vue
<!-- ✅ Correct - Template structure -->
<template>
  <div class="container">
    <!-- Loading state -->
    <div v-if="loading" class="loading-state">
      <Spinner size="large" />
      <p>Loading cohorts...</p>
    </div>

    <!-- Error state -->
    <div v-else-if="error" class="error-state">
      <Alert type="error" :message="error" @dismiss="clearError" />
    </div>

    <!-- Empty state -->
    <div v-else-if="cohorts.length === 0" class="empty-state">
      <Empty message="No cohorts found" />
      <Button @click="createFirstCohort">Create First Cohort</Button>
    </div>

    <!-- Content -->
    <div v-else class="cohort-grid">
      <CohortCard
        v-for="cohort in filteredCohorts"
        :key="cohort.id"
        :cohort="cohort"
        @select="viewCohort"
      />
    </div>
  </div>
</template>

<!-- ❌ Wrong - Complex logic in template -->
<template>
  <div>
    <div v-if="loading && !error && cohorts.length === 0">Loading...</div>
    <div v-else-if="!loading && error">Error</div>
    <!-- Too complex -->
  </div>
</template>
```

---

### 7. Conditional Rendering

```vue
<!-- ✅ Correct - Multiple approaches -->
<template>
  <!-- v-if for conditional DOM -->
  <div v-if="isVisible">Content</div>

  <!-- v-show for toggling visibility -->
  <div v-show="isVisible">Content</div>

  <!-- v-else -->
  <div v-if="isAuthenticated">Dashboard</div>
  <div v-else>Login Required</div>

  <!-- v-else-if -->
  <div v-if="status === 'loading'">Loading...</div>
  <div v-else-if="status === 'error'">Error</div>
  <div v-else>Content</div>

  <!-- Computed for complex conditions -->
  <div v-if="shouldShowContent">Content</div>
</template>

<script setup>
const shouldShowContent = computed(() => {
  return !loading && !error && cohorts.length > 0
})
</script>
```

---

### 8. Styling Standards

```vue
<!-- ✅ Correct - Scoped styles with Tailwind -->
<template>
  <div class="cohort-card p-4 bg-white rounded-lg shadow">
    <h3 class="text-xl font-bold text-gray-900">{{ cohort.name }}</h3>
    <span :class="statusClass" class="badge">{{ cohort.status }}</span>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  cohort: Object
})

const statusClass = computed(() => {
  const base = 'px-2 py-1 rounded-full text-xs font-semibold '
  switch (props.cohort.status) {
    case 'active':
      return base + 'bg-green-100 text-green-800'
    case 'completed':
      return base + 'bg-blue-100 text-blue-800'
    default:
      return base + 'bg-gray-100 text-gray-800'
  }
})
</script>

<style scoped>
.cohort-card {
  transition: transform 0.2s;
}

.cohort-card:hover {
  transform: translateY(-2px);
}
</style>
```

---

## 🧪 Testing Standards

### 1. RSpec (Ruby)

#### Model Specs
```ruby
# spec/models/cohort_spec.rb
require 'rails_helper'

RSpec.describe Cohort, type: :model do
  # Factory usage
  let(:institution) { create(:institution) }
  let(:template) { create(:template) }
  let(:cohort) { build(:cohort, institution: institution, template: template) }

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:program_type) }
    it { should validate_inclusion_of(:status).in_array(%w[draft active completed]) }

    it 'validates sponsor email format' do
      cohort.sponsor_email = 'invalid'
      expect(cohort).not_to be_valid
      expect(cohort.errors[:sponsor_email]).to include('must be a valid email')
    end
  end

  describe 'associations' do
    it { should belong_to(:institution) }
    it { should belong_to(:template) }
    it { should have_many(:cohort_enrollments) }
  end

  describe 'scopes' do
    let!(:active_cohort) { create(:cohort, status: 'active') }
    let!(:draft_cohort) { create(:cohort, status: 'draft') }

    it '.active returns only active cohorts' do
      expect(Cohort.active).to include(active_cohort)
      expect(Cohort.active).not_to include(draft_cohort)
    end
  end

  describe 'instance methods' do
    describe '#ready_for_sponsor?' do
      it 'returns true when all conditions met' do
        cohort = create(:cohort,
          tp_signed_at: Time.current,
          students_completed_at: Time.current,
          status: 'active'
        )
        create(:cohort_enrollment, cohort: cohort, role: 'student')

        expect(cohort.ready_for_sponsor?).to be true
      end

      it 'returns false when students not completed' do
        cohort = create(:cohort, tp_signed_at: Time.current)
        expect(cohort.ready_for_sponsor?).to be false
      end
    end
  end

  describe 'callbacks' do
    it 'sends activation email when status changes to active' do
      cohort = create(:cohort, status: 'draft')
      expect(CohortMailer).to receive(:activated).with(cohort).and_call_original

      cohort.update!(status: 'active')
    end
  end
end
```

#### Controller Specs
```ruby
# spec/controllers/tp/cohorts_controller_spec.rb
require 'rails_helper'

RSpec.describe tp::CohortsController, type: :controller do
  let(:user) { create(:user, :tp_admin) }
  let(:institution) { user.institution }

  before do
    sign_in user
  end

  describe 'GET #index' do
    let!(:cohort) { create(:cohort, institution: institution) }

    it 'returns http success' do
      get :index
      expect(response).to have_http_status(:ok)
    end

    it 'assigns cohorts' do
      get :index
      expect(assigns(:cohorts)).to include(cohort)
    end
  end

  describe 'POST #create' do
    let(:template) { create(:template, account: user.account) }

    context 'with valid params' do
      let(:valid_params) do
        {
          name: 'New Cohort',
          program_type: 'learnership',
          sponsor_email: 'sponsor@example.com',
          template_id: template.id
        }
      end

      it 'creates a cohort' do
        expect {
          post :create, params: { cohort: valid_params }
        }.to change(Cohort, :count).by(1)
      end

      it 'redirects to cohort show' do
        post :create, params: { cohort: valid_params }
        expect(response).to redirect_to(tp_cohort_path(assigns(:cohort)))
      end
    end

    context 'with invalid params' do
      it 'renders new template' do
        post :create, params: { cohort: { name: '' } }
        expect(response).to render_template(:new)
      end
    end
  end
end
```

#### Request Specs (API)
```ruby
# spec/requests/api/v1/cohorts_spec.rb
require 'rails_helper'

RSpec.describe 'API v1 Cohorts', type: :request do
  let(:user) { create(:user, :tp_admin) }
  let(:headers) { { 'Authorization' => "Bearer #{user.generate_jwt}" } }

  describe 'GET /api/v1/cohorts' do
    let!(:cohort) { create(:cohort, institution: user.institution) }

    it 'returns cohorts' do
      get '/api/v1/cohorts', headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response.size).to eq(1)
      expect(json_response.first['name']).to eq(cohort.name)
    end
  end

  describe 'POST /api/v1/cohorts' do
    let(:template) { create(:template, account: user.account) }

    it 'creates a cohort' do
      params = {
        name: 'API Cohort',
        program_type: 'internship',
        sponsor_email: 'api@example.com',
        template_id: template.id
      }

      expect {
        post '/api/v1/cohorts', headers: headers, params: params
      }.to change(Cohort, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_response['name']).to eq('API Cohort')
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
```

---

### 2. Vue Component Specs

```javascript
// spec/javascript/tp/components/CohortCard.spec.js
import { mount, flushPromises } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import CohortCard from '@/tp/components/CohortCard.vue'

describe('CohortCard', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  const createWrapper = (props = {}) => {
    return mount(CohortCard, {
      props: {
        cohort: {
          id: 1,
          name: 'Test Cohort',
          status: 'active',
          ...props
        },
        ...props
      }
    })
  }

  it('renders cohort name', () => {
    const wrapper = createWrapper()
    expect(wrapper.text()).toContain('Test Cohort')
  })

  it('emits select event on click', async () => {
    const wrapper = createWrapper()
    await wrapper.trigger('click')

    expect(wrapper.emitted('select')).toBeTruthy()
    expect(wrapper.emitted('select')[0]).toEqual([1])
  })

  it('displays correct status badge', () => {
    const wrapper = createWrapper({ status: 'active' })
    const badge = wrapper.find('.badge')

    expect(badge.text()).toBe('active')
    expect(badge.classes()).toContain('bg-green-100')
  })

  it('handles missing cohort gracefully', () => {
    const wrapper = mount(CohortCard, {
      props: { cohort: null }
    })

    expect(wrapper.text()).toContain('No cohort data')
  })
})
```

---

### 3. Store Specs

```javascript
// spec/javascript/tp/stores/cohortStore.spec.js
import { createPinia, setActivePinia } from 'pinia'
import { useCohortStore } from '@/tp/stores/cohortStore'
import { CohortsAPI } from '@/tp/api/cohorts'

// Mock API
vi.mock('@/tp/api/cohorts')

describe('CohortStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  describe('actions', () => {
    describe('fetchCohorts', () => {
      it('loads cohorts successfully', async () => {
        const mockCohorts = [
          { id: 1, name: 'Cohort 1' },
          { id: 2, name: 'Cohort 2' }
        ]

        CohortsAPI.getAll.mockResolvedValue(mockCohorts)

        const store = useCohortStore()
        await store.fetchCohorts()

        expect(store.cohorts).toEqual(mockCohorts)
        expect(store.loading).toBe(false)
      })

      it('handles errors', async () => {
        CohortsAPI.getAll.mockRejectedValue(new Error('API Error'))

        const store = useCohortStore()
        await store.fetchCohorts()

        expect(store.error).toBe('API Error')
        expect(store.loading).toBe(false)
      })
    })

    describe('createCohort', () => {
      it('adds cohort to list', async () => {
        const newCohort = { id: 3, name: 'New Cohort' }
        CohortsAPI.create.mockResolvedValue(newCohort)

        const store = useCohortStore()
        store.cohorts = [{ id: 1, name: 'Existing' }]

        const result = await store.createCohort({ name: 'New Cohort' })

        expect(result).toEqual(newCohort)
        expect(store.cohorts).toHaveLength(2)
        expect(store.cohorts[0].id).toBe(3) // Added to beginning
      })
    })
  })

  describe('getters', () => {
    it('filters active cohorts', () => {
      const store = useCohortStore()
      store.cohorts = [
        { id: 1, status: 'active' },
        { id: 2, status: 'draft' },
        { id: 3, status: 'active' }
      ]

      expect(store.activeCohorts).toHaveLength(2)
      expect(store.activeCohorts.every(c => c.status === 'active')).toBe(true)
    })
  })
})
```

---

### 4. System/Integration Specs

```ruby
# spec/system/tp_cohort_workflow_spec.rb
require 'rails_helper'

RSpec.describe 'TP Cohort Workflow', type: :system do
  let(:user) { create(:user, :tp_admin) }
  let(:template) { create(:template, account: user.account) }

  before do
    sign_in user
    visit tp_root_path
  end

  scenario 'TP admin creates a cohort' do
    click_link 'Cohorts'
    click_link 'New Cohort'

    fill_in 'Name', with: '2026 Q1 Learnership'
    select 'Learnership', from: 'Program Type'
    fill_in 'Sponsor Email', with: 'sponsor@example.com'
    select template.name, from: 'Template'

    click_button 'Create Cohort'

    expect(page).to have_content('Cohort created')
    expect(page).to have_content('2026 Q1 Learnership')
  end

  scenario 'TP admin manages students' do
    cohort = create(:cohort, institution: user.institution)
    visit tp_cohort_path(cohort)

    click_link 'Manage Students'

    fill_in 'Email', with: 'student@example.com'
    fill_in 'Name', with: 'John'
    fill_in 'Surname', with: 'Doe'
    click_button 'Add Student'

    expect(page).to have_content('student@example.com')
    expect(page).to have_content('John Doe')
  end

  scenario 'Complete cohort workflow' do
    cohort = create(:cohort, institution: user.institution)
    create_list(:cohort_enrollment, 3, cohort: cohort, status: 'complete')

    visit tp_cohort_path(cohort)

    click_button 'Start Signing Phase'
    expect(page).to have_content('Signing phase started')

    click_button 'Finalize Cohort'
    expect(page).to have_content('Cohort finalized')
    expect(cohort.reload.status).to eq('completed')
  end
end
```

---

### 5. Test Data (Factories)

```ruby
# spec/factories/institutions.rb
FactoryBot.define do
  factory :institution do
    name { "TechPro Training Academy" }
    email { "admin@techpro.co.za" }
    contact_person { "Jane Smith" }
    phone { "+27 11 123 4567" }
    settings { {} }
  end
end

# spec/factories/cohorts.rb
FactoryBot.define do
  factory :cohort do
    association :institution
    association :template

    name { "2026 Q1 Learnership" }
    program_type { "learnership" }
    sponsor_email { "sponsor@example.com" }
    required_student_uploads { ["id_copy", "matric"] }
    status { "draft" }

    trait :active do
      status { "active" }
    end

    trait :completed do
      status { "completed" }
      tp_signed_at { Time.current }
      students_completed_at { Time.current }
      sponsor_completed_at { Time.current }
      finalized_at { Time.current }
    end
  end
end

# spec/factories/cohort_enrollments.rb
FactoryBot.define do
  factory :cohort_enrollment do
    association :cohort
    association :submission

    student_email { "student@example.com" }
    student_name { "John" }
    student_surname { "Doe" }
    status { "waiting" }
    role { "student" }

    trait :completed do
      status { "complete" }
      completed_at { Time.current }
    end
  end
end
```

---

## 📋 General Standards

### 1. Git Commit Messages

```
# ✅ Correct
git commit -m "Add Story 1.1: Database Schema Extension"

git commit -m "Fix: Handle nil values in cohort status check"

git commit -m "Refactor: Extract cohort workflow to service object"

# ❌ Wrong
git commit -m "fixed stuff"
git commit -m "wip"
git commit -m "changes"
```

### 2. File Organization

```
# ✅ Correct - Logical grouping
app/models/
  institution.rb
  cohort.rb
  cohort_enrollment.rb
  concerns/
    soft_deletable.rb
    feature_flag_check.rb

# ❌ Wrong - Flat or mixed
app/models/
  institution.rb
  cohort.rb
  cohort_enrollment.rb
  soft_deletable.rb  # Should be in concerns/
  user.rb            # Should be grouped with other existing models
```

### 3. Comments & Documentation

```ruby
# ✅ Correct - Clear, concise comments
class Cohort < ApplicationRecord
  # Workflow states:
  # - draft: Being configured by TP
  # - active: Students can enroll
  # - completed: All phases done
  validates :status, inclusion: { in: %w[draft active completed] }

  # Returns cohorts ready for sponsor signing
  def self.ready_for_sponsor
    where.not(tp_signed_at: nil)
         .where.not(students_completed_at: nil)
  end
end

# ❌ Wrong - Obvious or outdated comments
class Cohort < ApplicationRecord
  # This is a model
  # TODO: Update this
  validates :status, inclusion: { in: %w[draft active completed] }
end
```

---

## 🎯 Quality Checklist

### Ruby Code
- [ ] Models inherit from `ApplicationRecord`
- [ ] All associations have explicit class names if needed
- [ ] Validations are present and specific
- [ ] Scopes use lambdas
- [ ] Callbacks are in private methods
- [ ] Strong parameters are used in controllers
- [ ] Before actions are ordered correctly
- [ ] Service objects for complex logic

### Vue Code
- [ ] Components use PascalCase
- [ ] Composition API with `<script setup>`
- [ ] Props have validators
- [ ] Stores use Pinia patterns
- [ ] API clients handle errors
- [ ] Templates are readable
- [ ] Scoped styles used
- [ ] v-if vs v-show used appropriately

### Testing
- [ ] Models have unit tests
- [ ] Controllers have request specs
- [ ] API has integration tests
- [ ] Vue components have unit tests
- [ ] Stores have unit tests
- [ ] Critical paths have system tests
- [ ] Factories are used for test data
- [ ] Tests are isolated and independent

---

## 📚 Related Documents

- **Tech Stack**: `docs/architecture/tech-stack.md`
- **Data Models**: `docs/architecture/data-models.md`
- **Project Structure**: `docs/architecture/project-structure.md`

---

**Document Status**: ✅ Complete
**Enforcement**: RuboCop (Ruby), ESLint (Vue)
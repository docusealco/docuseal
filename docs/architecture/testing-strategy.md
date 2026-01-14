# Testing Strategy - FloDoc Architecture

**Document**: Comprehensive Testing Approach
**Version**: 1.0
**Last Updated**: 2026-01-14

---

## 🎯 Testing Philosophy

**Quality Gates**: Every story must pass all tests before deployment
**Test Pyramid**: Unit > Integration > E2E
**Coverage Target**: 80% minimum, 90% for critical paths
**CI/CD**: All tests run on every commit

---

## 📊 Test Pyramid

```
                    ┌─────────────┐
                    │    E2E      │  5-10%  (Critical Paths Only)
                    │   System    │
                    └─────────────┘
                           ▲
                    ┌─────────────┐
                    │ Integration │  20-30%
                    │   Request   │
                    │   Component │
                    └─────────────┘
                           ▲
                    ┌─────────────┐
                    │    Unit     │  60-70%
                    │   Model     │
                    │  Component  │
                    │  Store/API  │
                    └─────────────┘
```

---

## 🧪 Ruby/Rails Testing (RSpec)

### 1. Model Tests (Unit)

**Location**: `spec/models/`

**Coverage**:
- Validations
- Associations
- Scopes
- Callbacks
- Instance methods
- Class methods

**Example**:
```ruby
# spec/models/cohort_spec.rb
require 'rails_helper'

RSpec.describe Cohort, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:program_type) }
    it { should validate_inclusion_of(:status).in_array(%w[draft active completed]) }

    it 'validates sponsor email format' do
      cohort = build(:cohort, sponsor_email: 'invalid')
      expect(cohort).not_to be_valid
      expect(cohort.errors[:sponsor_email]).to include('must be a valid email')
    end
  end

  describe 'associations' do
    it { should belong_to(:institution) }
    it { should belong_to(:template) }
    it { should have_many(:cohort_enrollments).dependent(:destroy) }
  end

  describe 'scopes' do
    let!(:active_cohort) { create(:cohort, status: 'active') }
    let!(:draft_cohort) { create(:cohort, status: 'draft') }

    it '.active returns only active cohorts' do
      expect(Cohort.active).to include(active_cohort)
      expect(Cohort.active).not_to include(draft_cohort)
    end
  end

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

  describe 'callbacks' do
    it 'sends activation email when status changes to active' do
      cohort = create(:cohort, status: 'draft')
      expect(CohortMailer).to receive(:activated).with(cohort).and_call_original

      cohort.update!(status: 'active')
    end
  end
end
```

**Run**:
```bash
bundle exec rspec spec/models/cohort_spec.rb
```

---

### 2. Controller Tests (Integration)

**Location**: `spec/controllers/`

**Coverage**:
- Authentication
- Authorization
- Request handling
- Response codes
- Redirects
- Flash messages

**Example**:
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

    it 'renders index template' do
      get :index
      expect(response).to render_template(:index)
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

      it 'sets correct institution' do
        post :create, params: { cohort: valid_params }
        expect(assigns(:cohort).institution).to eq(institution)
      end
    end

    context 'with invalid params' do
      it 'renders new template' do
        post :create, params: { cohort: { name: '' } }
        expect(response).to render_template(:new)
      end

      it 'does not create cohort' do
        expect {
          post :create, params: { cohort: { name: '' } }
        }.not_to change(Cohort, :count)
      end
    end

    context 'unauthorized user' do
      before do
        sign_out user
        sign_in create(:user, :regular_user)
      end

      it 'denies access' do
        post :create, params: { cohort: valid_params }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('not authorized')
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:cohort) { create(:cohort, institution: institution) }

    it 'deletes the cohort' do
      expect {
        delete :destroy, params: { id: cohort.id }
      }.to change(Cohort, :count).by(-1)
    end

    it 'redirects to index' do
      delete :destroy, params: { id: cohort.id }
      expect(response).to redirect_to(tp_cohorts_path)
    end
  end
end
```

**Run**:
```bash
bundle exec rspec spec/controllers/tp/cohorts_controller_spec.rb
```

---

### 3. Request/API Tests

**Location**: `spec/requests/api/v1/`

**Coverage**:
- Authentication
- Request/response format
- Status codes
- Error handling
- Rate limiting

**Example**:
```ruby
# spec/requests/api/v1/cohorts_spec.rb
require 'rails_helper'

RSpec.describe 'API v1 Cohorts', type: :request do
  let(:user) { create(:user, :tp_admin) }
  let(:headers) { { 'Authorization' => "Bearer #{user.generate_jwt}" } }

  describe 'GET /api/v1/cohorts' do
    let!(:cohort) { create(:cohort, institution: user.institution) }
    let!(:other_cohort) { create(:cohort) } # Different institution

    it 'returns cohorts for current institution only' do
      get '/api/v1/cohorts', headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response.size).to eq(1)
      expect(json_response.first['id']).to eq(cohort.id)
      expect(json_response.map { |c| c['id'] }).not_to include(other_cohort.id)
    end

    it 'returns correct JSON structure' do
      get '/api/v1/cohorts', headers: headers

      cohort_data = json_response.first
      expect(cohort_data).to include('id', 'name', 'status', 'program_type')
      expect(cohort_data['name']).to eq(cohort.name)
    end

    context 'with status filter' do
      let!(:active_cohort) { create(:cohort, institution: user.institution, status: 'active') }

      it 'filters by status' do
        get '/api/v1/cohorts?status=active', headers: headers

        expect(json_response.size).to eq(1)
        expect(json_response.first['status']).to eq('active')
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        get '/api/v1/cohorts'

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to eq('Unauthorized')
      end
    end
  end

  describe 'POST /api/v1/cohorts' do
    let(:template) { create(:template, account: user.account) }

    context 'valid request' do
      let(:params) do
        {
          name: 'API Cohort',
          program_type: 'internship',
          sponsor_email: 'api@example.com',
          template_id: template.id
        }
      end

      it 'creates a cohort' do
        expect {
          post '/api/v1/cohorts', headers: headers, params: params
        }.to change(Cohort, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_response['name']).to eq('API Cohort')
      end
    end

    context 'invalid request' do
      it 'returns validation errors' do
        post '/api/v1/cohorts', headers: headers, params: { name: '' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to be_present
      end
    end

    context 'rate limiting' do
      it 'throttles excessive requests' do
        101.times do
          post '/api/v1/cohorts', headers: headers, params: valid_params
        end

        expect(response).to have_http_status(:too_many_requests)
      end
    end
  end

  describe 'POST /api/v1/cohorts/:id/start_signing' do
    let(:cohort) { create(:cohort, institution: user.institution, status: 'draft') }

    it 'transitions cohort to active' do
      post "/api/v1/cohorts/#{cohort.id}/start_signing", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response['status']).to eq('active')
      expect(json_response['tp_signed_at']).not_to be_nil
    end

    it 'sends activation email' do
      expect {
        post "/api/v1/cohorts/#{cohort.id}/start_signing", headers: headers
      }.to have_enqueued_mail(CohortMailer, :activated)
    end
  end

  def json_response
    JSON.parse(response.body)
  end

  def valid_params
    {
      name: 'Test Cohort',
      program_type: 'learnership',
      sponsor_email: 'test@example.com',
      template_id: template.id
    }
  end
end
```

**Run**:
```bash
bundle exec rspec spec/requests/api/v1/cohorts_spec.rb
```

---

### 4. System/Feature Tests

**Location**: `spec/system/`

**Coverage**:
- User workflows
- Browser interactions
- JavaScript functionality
- Multi-step processes

**Example**:
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

  scenario 'TP admin creates and activates a cohort' do
    # Navigate to cohorts
    click_link 'Cohorts'
    expect(page).to have_current_path(tp_cohorts_path)

    # Create cohort
    click_link 'New Cohort'
    expect(page).to have_current_path(new_tp_cohort_path)

    fill_in 'Name', with: '2026 Q1 Learnership'
    select 'Learnership', from: 'Program Type'
    fill_in 'Sponsor Email', with: 'sponsor@example.com'
    select template.name, from: 'Template'

    click_button 'Create Cohort'

    # Verify creation
    expect(page).to have_content('Cohort created')
    expect(page).to have_content('2026 Q1 Learnership')
    expect(page).to have_content('draft')

    # Activate cohort
    click_button 'Start Signing Phase'
    expect(page).to have_content('Cohort is now active')
    expect(page).to have_content('active')

    cohort = Cohort.last
    expect(cohort.status).to eq('active')
    expect(cohort.tp_signed_at).not_to be_nil
  end

  scenario 'Bulk student enrollment' do
    cohort = create(:cohort, institution: user.institution)

    visit tp_cohort_path(cohort)
    click_link 'Manage Students'

    # Add multiple students
    fill_in 'Email', with: 'student1@example.com'
    fill_in 'Name', with: 'John'
    fill_in 'Surname', with: 'Doe'
    click_button 'Add Student'

    expect(page).to have_content('student1@example.com')

    # Add second student
    fill_in 'Email', with: 'student2@example.com'
    fill_in 'Name', with: 'Jane'
    fill_in 'Surname', with: 'Smith'
    click_button 'Add Student'

    expect(page).to have_content('student2@example.com')
    expect(cohort.cohort_enrollments.count).to eq(2)
  end

  scenario 'Complete end-to-end workflow' do
    # Create cohort
    cohort = create(:cohort, institution: user.institution)
    create_list(:cohort_enrollment, 3, cohort: cohort, status: 'complete')

    visit tp_cohort_path(cohort)

    # Verify all students completed
    expect(page).to have_content('Completed: 3')

    # Start signing phase
    click_button 'Start Signing Phase'
    expect(page).to have_content('Signing phase started')

    # Finalize
    click_button 'Finalize Cohort'
    expect(page).to have_content('Cohort finalized')

    cohort.reload
    expect(cohort.status).to eq('completed')
    expect(cohort.finalized_at).not_to be_nil
  end
end
```

**Run**:
```bash
bundle exec rspec spec/system/tp_cohort_workflow_spec.rb
```

---

## 🎨 Vue.js Testing

### 1. Component Unit Tests

**Location**: `spec/javascript/tp/components/`

**Framework**: Vue Test Utils + Vitest

**Coverage**:
- Props validation
- Event emission
- Conditional rendering
- User interactions
- Computed properties

**Example**:
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
          student_count: 15,
          completed_count: 10,
          ...props
        },
        ...props
      }
    })
  }

  it('renders cohort information', () => {
    const wrapper = createWrapper()
    expect(wrapper.text()).toContain('Test Cohort')
    expect(wrapper.text()).toContain('15 students')
    expect(wrapper.text()).toContain('10 completed')
  })

  it('displays correct status badge', () => {
    const activeWrapper = createWrapper({ status: 'active' })
    expect(activeWrapper.find('.badge').classes()).toContain('bg-green-100')

    const draftWrapper = createWrapper({ status: 'draft' })
    expect(draftWrapper.find('.badge').classes()).toContain('bg-gray-100')
  })

  it('emits select event on click', async () => {
    const wrapper = createWrapper()
    await wrapper.trigger('click')

    expect(wrapper.emitted('select')).toBeTruthy()
    expect(wrapper.emitted('select')[0]).toEqual([1])
  })

  it('shows progress bar', () => {
    const wrapper = createWrapper()
    const progress = wrapper.find('.progress-bar')
    expect(progress.exists()).toBe(true)
    expect(progress.text()).toContain('66%')
  })

  it('handles missing data gracefully', () => {
    const wrapper = mount(CohortCard, {
      props: { cohort: null }
    })
    expect(wrapper.text()).toContain('No cohort data')
  })
})
```

**Run**:
```bash
yarn test spec/javascript/tp/components/CohortCard.spec.js
```

---

### 2. Store Tests (Pinia)

**Location**: `spec/javascript/tp/stores/`

**Coverage**:
- State management
- Actions (async operations)
- Getters (computed state)
- Error handling

**Example**:
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
          { id: 1, name: 'Cohort 1', status: 'active' },
          { id: 2, name: 'Cohort 2', status: 'draft' }
        ]

        CohortsAPI.getAll.mockResolvedValue(mockCohorts)

        const store = useCohortStore()
        await store.fetchCohorts()

        expect(store.cohorts).toEqual(mockCohorts)
        expect(store.loading).toBe(false)
        expect(store.error).toBeNull()
      })

      it('handles API errors', async () => {
        CohortsAPI.getAll.mockRejectedValue(new Error('Network error'))

        const store = useCohortStore()
        await store.fetchCohorts()

        expect(store.error).toBe('Network error')
        expect(store.loading).toBe(false)
        expect(store.cohorts).toEqual([])
      })

      it('sets loading state', async () => {
        let resolvePromise
        const promise = new Promise(resolve => {
          resolvePromise = resolve
        })

        CohortsAPI.getAll.mockReturnValue(promise)

        const store = useCohortStore()
        const fetchPromise = store.fetchCohorts()

        expect(store.loading).toBe(true)

        resolvePromise([{ id: 1, name: 'Test' }])
        await fetchPromise

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

      it('handles validation errors', async () => {
        const error = { response: { data: { errors: { name: ["can't be blank"] } } } }
        CohortsAPI.create.mockRejectedValue(error)

        const store = useCohortStore()

        await expect(
          store.createCohort({ name: '' })
        ).rejects.toThrow()

        expect(store.error).toBeDefined()
      })
    })

    describe('startSigning', () => {
      it('updates cohort status', async () => {
        const updatedCohort = { id: 1, name: 'Test', status: 'active' }
        CohortsAPI.startSigning.mockResolvedValue(updatedCohort)

        const store = useCohortStore()
        store.cohorts = [{ id: 1, name: 'Test', status: 'draft' }]

        await store.startSigning(1)

        expect(store.cohorts[0].status).toBe('active')
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

    it('finds cohort by ID', () => {
      const store = useCohortStore()
      store.cohorts = [
        { id: 1, name: 'Cohort 1' },
        { id: 2, name: 'Cohort 2' }
      ]

      const found = store.getCohortById(2)
      expect(found).toEqual({ id: 2, name: 'Cohort 2' })
    })
  })
})
```

**Run**:
```bash
yarn test spec/javascript/tp/stores/cohortStore.spec.js
```

---

### 3. API Client Tests

**Location**: `spec/javascript/tp/api/`

**Coverage**:
- Request formatting
- Response handling
- Error handling
- Authentication headers

**Example**:
```javascript
// spec/javascript/tp/api/cohorts.spec.js
import { CohortsAPI } from '@/tp/api/cohorts'
import axios from 'axios'

// Mock axios
vi.mock('axios')

describe('CohortsAPI', () => {
  beforeEach(() => {
    axios.create.mockReturnValue(axios)
  })

  describe('getAll', () => {
    it('returns cohorts', async () => {
      const mockResponse = { data: [{ id: 1, name: 'Test' }] }
      axios.get.mockResolvedValue(mockResponse)

      const result = await CohortsAPI.getAll()

      expect(axios.get).toHaveBeenCalledWith('/api/v1/cohorts')
      expect(result).toEqual([{ id: 1, name: 'Test' }])
    })

    it('handles query parameters', async () => {
      axios.get.mockResolvedValue({ data: [] })

      await CohortsAPI.getAll({ status: 'active', page: 2 })

      expect(axios.get).toHaveBeenCalledWith('/api/v1/cohorts', {
        params: { status: 'active', page: 2 }
      })
    })
  })

  describe('create', () => {
    it('posts data correctly', async () => {
      const cohortData = { name: 'New Cohort', status: 'draft' }
      const mockResponse = { data: { id: 1, ...cohortData } }
      axios.post.mockResolvedValue(mockResponse)

      const result = await CohortsAPI.create(cohortData)

      expect(axios.post).toHaveBeenCalledWith('/api/v1/cohorts', cohortData)
      expect(result).toEqual({ id: 1, ...cohortData })
    })
  })

  describe('error handling', () => {
    it('throws on 401', async () => {
      axios.get.mockRejectedValue({
        response: { status: 401, data: { error: 'Unauthorized' } }
      })

      await expect(CohortsAPI.getAll()).rejects.toThrow()
    })

    it('throws on network error', async () => {
      axios.get.mockRejectedValue(new Error('Network Error'))

      await expect(CohortsAPI.getAll()).rejects.toThrow('Network Error')
    })
  })
})
```

---

### 4. View/Integration Tests

**Location**: `spec/javascript/tp/views/`

**Coverage**:
- Full component lifecycle
- Store integration
- API calls
- User flows

**Example**:
```javascript
// spec/javascript/tp/views/CohortList.spec.js
import { mount, flushPromises } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import CohortList from '@/tp/views/CohortList.vue'
import { useCohortStore } from '@/tp/stores/cohortStore'

vi.mock('@/tp/stores/cohortStore')

describe('CohortList', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('displays loading state', () => {
    const wrapper = mount(CohortList)
    expect(wrapper.text()).toContain('Loading')
  })

  it('displays cohorts after loading', async () => {
    const mockCohorts = [
      { id: 1, name: 'Cohort 1', status: 'active' },
      { id: 2, name: 'Cohort 2', status: 'draft' }
    ]

    const store = useCohortStore()
    store.cohorts = mockCohorts
    store.loading = false

    const wrapper = mount(CohortList)
    await flushPromises()

    expect(wrapper.text()).toContain('Cohort 1')
    expect(wrapper.text()).toContain('Cohort 2')
  })

  it('handles empty state', async () => {
    const store = useCohortStore()
    store.cohorts = []
    store.loading = false

    const wrapper = mount(CohortList)
    await flushPromises()

    expect(wrapper.text()).toContain('No cohorts found')
  })

  it('handles errors', async () => {
    const store = useCohortStore()
    store.error = 'Failed to load cohorts'
    store.loading = false

    const wrapper = mount(CohortList)
    await flushPromises()

    expect(wrapper.text()).toContain('Error')
    expect(wrapper.text()).toContain('Failed to load')
  })
})
```

---

## 🔌 Integration Tests

### 1. Request Flow Tests

**Location**: `spec/integration/`

**Coverage**:
- Full request/response cycle
- Database state changes
- Email delivery
- Background jobs

**Example**:
```ruby
# spec/integration/cohort_workflow_spec.rb
require 'rails_helper'

RSpec.describe 'Cohort Workflow Integration', type: :request do
  let(:user) { create(:user, :tp_admin) }
  let(:template) { create(:template, account: user.account) }

  it 'completes full cohort lifecycle' do
    # 1. Create cohort
    post '/api/v1/cohorts',
      headers: { 'Authorization' => "Bearer #{user.generate_jwt}" },
      params: {
        name: 'Full Workflow Test',
        program_type: 'learnership',
        sponsor_email: 'sponsor@example.com',
        template_id: template.id
      }

    expect(response).to have_http_status(:created)
    cohort_id = json_response['id']

    # 2. Add students
    post "/api/v1/cohorts/#{cohort_id}/enrollments",
      headers: { 'Authorization' => "Bearer #{user.generate_jwt}" },
      params: {
        students: [
          { email: 'student1@example.com', name: 'John', surname: 'Doe' },
          { email: 'student2@example.com', name: 'Jane', surname: 'Smith' }
        ]
      }

    expect(response).to have_http_status(:created)
    expect(json_response['created']).to eq(2)

    # 3. Student completes enrollment
    enrollment = CohortEnrollment.find_by(student_email: 'student1@example.com')
    patch "/api/v1/enrollments/#{enrollment.id}",
      params: {
        token: enrollment.token,
        values: { full_name: 'John Doe' }
      }

    expect(response).to have_http_status(:ok)

    # 4. Mark all as complete
    CohortEnrollment.where(cohort_id: cohort_id).update_all(status: 'complete')

    # 5. Start signing phase
    post "/api/v1/cohorts/#{cohort_id}/start_signing",
      headers: { 'Authorization' => "Bearer #{user.generate_jwt}" }

    expect(response).to have_http_status(:ok)
    expect(json_response['status']).to eq('active')

    # 6. Sponsor signs
    cohort = Cohort.find(cohort_id)
    post "/api/v1/sponsor/#{cohort.sponsor_token}/sign",
      params: { signature: 'Sponsor Name', agree_to_terms: true }

    expect(response).to have_http_status(:ok)
    expect(json_response['signed_count']).to eq(2)

    # 7. Finalize
    post "/api/v1/cohorts/#{cohort_id}/finalize",
      headers: { 'Authorization' => "Bearer #{user.generate_jwt}" }

    expect(response).to have_http_status(:ok)
    expect(json_response['status']).to eq('completed')

    # 8. Verify final state
    cohort.reload
    expect(cohort.status).to eq('completed')
    expect(cohort.finalized_at).not_to be_nil
  end
end
```

---

## 🌐 End-to-End Tests

**Location**: `spec/e2e/` or `spec/system/`

**Framework**: Playwright or Cypress

**Coverage**:
- Real browser automation
- Complete user journeys
- Cross-browser testing
- Visual regression (optional)

**Example (Playwright)**:
```javascript
// spec/e2e/tp-cohort-workflow.spec.js
const { test, expect } = require('@playwright/test')

test.describe('TP Cohort Workflow', () => {
  test.beforeEach(async ({ page }) => {
    // Login
    await page.goto('http://localhost:3000/login')
    await page.fill('input[name="email"]', 'admin@example.com')
    await page.fill('input[name="password"]', 'password')
    await page.click('button[type="submit"]')
    await expect(page).toHaveURL(/.*dashboard/)
  })

  test('complete cohort lifecycle', async ({ page }) => {
    // Navigate to cohorts
    await page.click('text=Cohorts')
    await expect(page).toHaveURL(/.*cohorts/)

    // Create cohort
    await page.click('text=New Cohort')
    await page.fill('input[name="name"]', 'E2E Test Cohort')
    await page.selectOption('select[name="program_type"]', 'learnership')
    await page.fill('input[name="sponsor_email"]', 'sponsor@example.com')
    await page.click('button[type="submit"]')

    // Verify creation
    await expect(page.locator('text=E2E Test Cohort')).toBeVisible()
    await expect(page.locator('text=draft')).toBeVisible()

    // Add students
    await page.click('text=Manage Students')
    await page.fill('input[name="email"]', 'student@example.com')
    await page.fill('input[name="name"]', 'John')
    await page.fill('input[name="surname"]', 'Doe')
    await page.click('button:has-text("Add Student")')

    await expect(page.locator('text=student@example.com')).toBeVisible()

    // Activate cohort
    await page.click('text=Start Signing Phase')
    await expect(page.locator('text=active')).toBeVisible()

    // Verify in database
    const cohort = await page.evaluate(() => {
      return fetch('/api/v1/cohorts?status=active')
        .then(r => r.json())
        .then(data => data.data.find(c => c.name === 'E2E Test Cohort'))
    })

    expect(cohort).toBeDefined()
    expect(cohort.status).toBe('active')
  })
})
```

---

## 🧪 Test Data Management

### 1. Factories

**Location**: `spec/factories/`

**Example**:
```ruby
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
      tp_signed_at { Time.current }
    end

    trait :completed do
      status { "completed" }
      tp_signed_at { Time.current }
      students_completed_at { Time.current }
      sponsor_completed_at { Time.current }
      finalized_at { Time.current }
    end

    trait :with_students do
      after(:create) do |cohort|
        create_list(:cohort_enrollment, 3, cohort: cohort)
      end
    end
  end
end
```

### 2. Fixtures (for static data)

**Location**: `spec/fixtures/`

**Example**:
```yaml
# spec/fixtures/institutions.yml
techpro:
  name: "TechPro Training Academy"
  email: "admin@techpro.co.za"
  contact_person: "Jane Smith"
```

### 3. Database Cleaner

**Location**: `spec/support/database_cleaner.rb`

```ruby
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, type: :system) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
```

---

## 📊 Coverage & Quality

### 1. SimpleCov (Ruby)

**Configuration**: `.simplecov`

```ruby
require 'simplecov'

SimpleCov.start 'rails' do
  minimum_coverage 80
  maximum_coverage_drop 5

  add_filter 'spec/'
  add_filter 'config/initializers/'
  add_filter 'lib/tasks/'

  add_group 'Models', 'app/models'
  add_group 'Controllers', 'app/controllers'
  add_group 'Mailers', 'app/mailers'
  add_group 'Jobs', 'app/jobs'
  add_group 'Services', 'app/services'
end
```

**Run**:
```bash
bundle exec rspec --format documentation
open coverage/index.html
```

### 2. JavaScript Coverage

**Configuration**: `vitest.config.js`

```javascript
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    globals: true,
    environment: 'jsdom',
    coverage: {
      reporter: ['text', 'json', 'html'],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80
      },
      exclude: [
        'node_modules/',
        'spec/',
        '**/*.spec.js'
      ]
    }
  }
})
```

**Run**:
```bash
yarn test --coverage
open coverage/index.html
```

---

## 🔄 CI/CD Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/test.yml
name: Test Suite

on: [push, pull_request]

jobs:
  rspec:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: password
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v3

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true

      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'yarn'

      - name: Install dependencies
        run: |
          bundle install
          yarn install

      - name: Setup database
        env:
          DATABASE_URL: postgresql://postgres:password@localhost:5432/flo_doc_test
          RAILS_ENV: test
        run: |
          bundle exec rails db:create
          bundle exec rails db:schema:load

      - name: Run Ruby tests
        env:
          DATABASE_URL: postgresql://postgres:password@localhost:5432/flo_doc_test
          RAILS_ENV: test
        run: bundle exec rspec --format documentation

      - name: Run JavaScript tests
        run: yarn test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/coverage.xml, ./coverage/lcov.info
```

---

## 📋 Test Checklist

### Before Committing
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Coverage meets minimum (80%)
- [ ] No regressions in existing tests
- [ ] New tests for new functionality
- [ ] System tests for critical paths

### Before Merging
- [ ] All CI checks pass
- [ ] Code review completed
- [ ] QA review completed
- [ ] Performance tests pass (if applicable)
- [ ] Security tests pass (if applicable)

---

## 🎯 Test Execution Commands

```bash
# All Ruby tests
bundle exec rspec

# Specific model
bundle exec rspec spec/models/cohort_spec.rb

# Specific controller
bundle exec rspec spec/controllers/tp/cohorts_controller_spec.rb

# API tests
bundle exec rspec spec/requests/api/v1/cohorts_spec.rb

# System tests
bundle exec rspec spec/system/

# All JavaScript tests
yarn test

# Specific component
yarn test spec/javascript/tp/components/CohortCard.spec.js

# With coverage
bundle exec rspec --format documentation
yarn test --coverage

# Watch mode (JavaScript)
yarn test --watch

# Run only failing tests
bundle exec rspec --only-failures
```

---

## 📚 Related Documents

- **Coding Standards**: `docs/architecture/coding-standards.md`
- **Data Models**: `docs/architecture/data-models.md`
- **API Design**: `docs/architecture/api-design.md`

---

**Document Status**: ✅ Complete
**Test Coverage Target**: 80% minimum, 90% for critical paths
**Next Review**: After Phase 1 Implementation
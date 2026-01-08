<template>
  <div class="institution-list">
    <div class="header">
      <h2>Training Institutions</h2>
      <button v-if="canCreate" @click="$emit('create')" class="btn-primary">
        + New Institution
      </button>
    </div>

    <div v-if="loading" class="loading-state">
      <div class="spinner"></div>
      <p>Loading institutions...</p>
    </div>

    <div v-else-if="error" class="error-state">
      <p>{{ error }}</p>
      <button @click="loadInstitutions" class="btn-secondary">Retry</button>
    </div>

    <div v-else-if="institutions.length === 0" class="empty-state">
      <div class="empty-icon">🏢</div>
      <h3>No Institutions Yet</h3>
      <p>You don't have access to any institutions yet.</p>
      <button v-if="canCreate" @click="$emit('create')" class="btn-primary">
        Create Your First Institution
      </button>
    </div>

    <div v-else class="institutions-grid">
      <div
        v-for="institution in institutions"
        :key="institution.id"
        class="institution-card"
        @click="$emit('select', institution.id)"
      >
        <div class="card-header">
          <div class="institution-name">{{ institution.name }}</div>
          <div class="role-badge" :class="institution.role">
            {{ formatRole(institution.role) }}
          </div>
        </div>

        <div class="card-body">
          <div v-if="institution.registration_number" class="info-row">
            <span class="label">Reg #:</span>
            <span class="value">{{ institution.registration_number }}</span>
          </div>
          <div v-if="institution.contact_email" class="info-row">
            <span class="label">Email:</span>
            <span class="value">{{ institution.contact_email }}</span>
          </div>
        </div>

        <div class="card-footer">
          <span class="created-date">
            Created {{ formatDate(institution.created_at) }}
          </span>
          <span class="arrow">→</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import institutionClient from '../../api/institutionClient';

const props = defineProps({
  canCreate: {
    type: Boolean,
    default: false
  }
});

const emit = defineEmits(['create', 'select']);

const institutions = ref([]);
const loading = ref(true);
const error = ref('');

onMounted(() => {
  loadInstitutions();
});

async function loadInstitutions() {
  loading.value = true;
  error.value = '';

  try {
    const response = await institutionClient.getInstitutions();
    institutions.value = response.institutions || [];
  } catch (err) {
    error.value = err.message || 'Failed to load institutions';
  } finally {
    loading.value = false;
  }
}

function formatRole(role) {
  const roleMap = {
    'cohort_super_admin': 'Super Admin',
    'cohort_admin': 'Admin',
    'admin': 'Admin',
    'member': 'Member'
  };
  return roleMap[role] || role;
}

function formatDate(dateString) {
  const date = new Date(dateString);
  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  });
}
</script>

<style scoped>
.institution-list {
  max-width: 1000px;
  margin: 0 auto;
  padding: 20px;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.header h2 {
  margin: 0;
  color: #1a202c;
  font-size: 24px;
  font-weight: 600;
}

.btn-primary {
  background: #3182ce;
  color: white;
  border: none;
  padding: 10px 16px;
  border-radius: 6px;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-primary:hover {
  background: #2c5282;
}

.btn-secondary {
  background: #e2e8f0;
  color: #2d3748;
  border: none;
  padding: 8px 14px;
  border-radius: 6px;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-secondary:hover {
  background: #cbd5e0;
}

.loading-state,
.error-state,
.empty-state {
  text-align: center;
  padding: 60px 20px;
  background: white;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.loading-state p {
  color: #718096;
  margin-top: 16px;
}

.error-state p {
  color: #c53030;
  margin-bottom: 16px;
}

.empty-state .empty-icon {
  font-size: 48px;
  margin-bottom: 16px;
}

.empty-state h3 {
  margin: 0 0 8px 0;
  color: #2d3748;
}

.empty-state p {
  color: #718096;
  margin-bottom: 20px;
}

.spinner {
  border: 3px solid #e2e8f0;
  border-top: 3px solid #3182ce;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 1s linear infinite;
  margin: 0 auto;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.institutions-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 16px;
}

.institution-card {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 16px;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  flex-direction: column;
}

.institution-card:hover {
  border-color: #3182ce;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  transform: translateY(-2px);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 12px;
}

.institution-name {
  font-weight: 600;
  color: #1a202c;
  font-size: 16px;
  flex: 1;
  margin-right: 8px;
}

.role-badge {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  white-space: nowrap;
}

.role-badge.cohort_super_admin {
  background: #fef5e7;
  color: #744210;
}

.role-badge.cohort_admin {
  background: #ebf8ff;
  color: #2c5282;
}

.role-badge.admin {
  background: #f0fff4;
  color: #22543d;
}

.card-body {
  flex: 1;
  margin-bottom: 12px;
}

.info-row {
  display: flex;
  justify-content: space-between;
  font-size: 13px;
  margin-bottom: 4px;
}

.info-row .label {
  color: #718096;
  font-weight: 500;
}

.info-row .value {
  color: #2d3748;
  font-weight: 500;
}

.card-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 12px;
  border-top: 1px solid #e2e8f0;
  font-size: 12px;
}

.created-date {
  color: #718096;
}

.arrow {
  color: #3182ce;
  font-weight: 600;
  opacity: 0;
  transition: opacity 0.2s;
}

.institution-card:hover .arrow {
  opacity: 1;
}
</style>
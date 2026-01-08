<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-content">
      <div class="modal-header">
        <h3>Invite Admin</h3>
        <button class="close-btn" @click="$emit('close')">×</button>
      </div>

      <form @submit.prevent="handleSubmit" class="invite-form">
        <div class="form-group">
          <label for="email">Email Address *</label>
          <input
            type="email"
            id="email"
            v-model="form.email"
            required
            placeholder="admin@institution.com"
            :disabled="loading"
          />
        </div>

        <div class="form-group">
          <label for="role">Role *</label>
          <select id="role" v-model="form.role" required :disabled="loading">
            <option value="">Select a role...</option>
            <option value="cohort_admin">Cohort Admin</option>
            <option value="cohort_super_admin">Super Admin</option>
          </select>
        </div>

        <div class="role-info">
          <div class="info-box" v-if="form.role === 'cohort_admin'">
            <strong>Cohort Admin:</strong> Can manage cohorts and view institution data
          </div>
          <div class="info-box super-admin" v-if="form.role === 'cohort_super_admin'">
            <strong>Super Admin:</strong> Full access including admin management and settings
          </div>
        </div>

        <div class="form-actions">
          <button type="button" @click="$emit('close')" :disabled="loading" class="btn-secondary">
            Cancel
          </button>
          <button type="submit" :disabled="loading || !formValid" class="btn-primary">
            {{ loading ? 'Sending...' : 'Send Invitation' }}
          </button>
        </div>

        <div v-if="error" class="error-message">
          {{ error }}
        </div>

        <div v-if="success" class="success-message">
          {{ success }}
        </div>

        <div v-if="rateLimitWarning" class="warning-message">
          ⚠️ {{ rateLimitWarning }}
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue';
import institutionClient from '../../api/institutionClient';

const props = defineProps({
  institutionId: {
    type: Number,
    required: true
  }
});

const emit = defineEmits(['close', 'success']);

const form = ref({
  email: '',
  role: ''
});

const loading = ref(false);
const error = ref('');
const success = ref('');
const rateLimitWarning = ref('');

const formValid = computed(() => {
  return form.value.email && form.value.role;
});

// Watch for email changes to check rate limit
watch(() => form.value.email, async (newEmail) => {
  if (newEmail && newEmail.includes('@')) {
    // Could add real-time rate limit check here
    rateLimitWarning.value = '';
  }
});

async function handleSubmit() {
  loading.value = true;
  error.value = '';
  success.value = '';
  rateLimitWarning.value = '';

  try {
    await institutionClient.createInvitation(
      props.institutionId,
      form.value.email,
      form.value.role
    );

    success.value = `Invitation sent to ${form.value.email}`;

    // Reset form after success
    setTimeout(() => {
      form.value = { email: '', role: '' };
      emit('success');
    }, 1500);

  } catch (err) {
    if (err.message.includes('429') || err.message.includes('Too many')) {
      rateLimitWarning.value = 'Maximum 5 pending invitations per email. Please wait or revoke existing invitations.';
      error.value = 'Rate limit exceeded';
    } else {
      error.value = err.message || 'Failed to send invitation';
    }
  } finally {
    loading.value = false;
  }
}
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 8px;
  width: 90%;
  max-width: 500px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid #e2e8f0;
  background: #f7fafc;
}

.modal-header h3 {
  margin: 0;
  color: #2d3748;
  font-size: 18px;
  font-weight: 600;
}

.close-btn {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: #718096;
  padding: 0;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
}

.close-btn:hover {
  background: #e2e8f0;
  color: #2d3748;
}

.invite-form {
  padding: 20px;
}

.form-group {
  margin-bottom: 16px;
}

.form-group label {
  display: block;
  margin-bottom: 6px;
  color: #4a5568;
  font-weight: 500;
  font-size: 14px;
}

.form-group input,
.form-group select {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #cbd5e0;
  border-radius: 6px;
  font-size: 14px;
  transition: border-color 0.2s;
}

.form-group input:focus,
.form-group select:focus {
  outline: none;
  border-color: #3182ce;
  box-shadow: 0 0 0 3px rgba(49, 130, 206, 0.1);
}

.form-group input:disabled,
.form-group select:disabled {
  background-color: #f7fafc;
  cursor: not-allowed;
}

.role-info {
  margin: 12px 0;
  min-height: 40px;
}

.info-box {
  background: #ebf8ff;
  color: #2c5282;
  padding: 10px 12px;
  border-radius: 6px;
  font-size: 13px;
  border-left: 3px solid #3182ce;
}

.info-box.super-admin {
  background: #fff5f5;
  color: #742a2a;
  border-left-color: #e53e3e;
}

.form-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 20px;
  padding-top: 20px;
  border-top: 1px solid #e2e8f0;
}

.btn-primary,
.btn-secondary {
  padding: 10px 16px;
  border-radius: 6px;
  font-weight: 500;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
  border: none;
}

.btn-primary {
  background: #3182ce;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #2c5282;
}

.btn-primary:disabled {
  background: #a0aec0;
  cursor: not-allowed;
}

.btn-secondary {
  background: #e2e8f0;
  color: #2d3748;
}

.btn-secondary:hover:not(:disabled) {
  background: #cbd5e0;
}

.btn-secondary:disabled {
  background: #e2e8f0;
  opacity: 0.6;
  cursor: not-allowed;
}

.error-message {
  background: #fed7d7;
  color: #c53030;
  padding: 10px 12px;
  border-radius: 6px;
  margin-top: 12px;
  border: 1px solid #feb2b2;
  font-size: 13px;
}

.success-message {
  background: #c6f6d5;
  color: #22543d;
  padding: 10px 12px;
  border-radius: 6px;
  margin-top: 12px;
  border: 1px solid #9ae6b4;
  font-size: 13px;
}

.warning-message {
  background: #feebc8;
  color: #7c2d12;
  padding: 10px 12px;
  border-radius: 6px;
  margin-top: 12px;
  border: 1px solid #fbd38d;
  font-size: 13px;
}
</style>
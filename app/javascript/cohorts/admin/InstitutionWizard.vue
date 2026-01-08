<template>
  <div class="institution-wizard">
    <div class="wizard-header">
      <h2>{{ isEditing ? 'Edit Institution' : 'Create New Institution' }}</h2>
      <p class="subtitle">Set up training institution details and management</p>
    </div>

    <form @submit.prevent="handleSubmit" class="wizard-form">
      <div class="form-section">
        <h3>Basic Information</h3>

        <div class="form-group">
          <label for="name">Institution Name *</label>
          <input
            type="text"
            id="name"
            v-model="form.name"
            required
            placeholder="e.g., Tech Training Academy"
            :disabled="loading"
          />
        </div>

        <div class="form-group">
          <label for="registration_number">Registration Number</label>
          <input
            type="text"
            id="registration_number"
            v-model="form.registration_number"
            placeholder="Optional registration number"
            :disabled="loading"
          />
        </div>
      </div>

      <div class="form-section">
        <h3>Contact Information</h3>

        <div class="form-group">
          <label for="contact_email">Contact Email</label>
          <input
            type="email"
            id="contact_email"
            v-model="form.contact_email"
            placeholder="contact@institution.com"
            :disabled="loading"
          />
        </div>

        <div class="form-group">
          <label for="contact_phone">Contact Phone</label>
          <input
            type="tel"
            id="contact_phone"
            v-model="form.contact_phone"
            placeholder="+1234567890"
            :disabled="loading"
          />
        </div>

        <div class="form-group">
          <label for="address">Address</label>
          <textarea
            id="address"
            v-model="form.address"
            rows="3"
            placeholder="Full address"
            :disabled="loading"
          ></textarea>
        </div>
      </div>

      <div class="form-actions">
        <button type="button" @click="$emit('cancel')" :disabled="loading" class="btn-secondary">
          Cancel
        </button>
        <button type="submit" :disabled="loading" class="btn-primary">
          {{ loading ? 'Saving...' : (isEditing ? 'Update Institution' : 'Create Institution') }}
        </button>
      </div>

      <div v-if="error" class="error-message">
        {{ error }}
      </div>

      <div v-if="success" class="success-message">
        {{ success }}
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import institutionClient from '../../api/institutionClient';

const props = defineProps({
  institution: {
    type: Object,
    default: null
  }
});

const emit = defineEmits(['success', 'cancel']);

const form = ref({
  name: '',
  registration_number: '',
  contact_email: '',
  contact_phone: '',
  address: ''
});

const loading = ref(false);
const error = ref('');
const success = ref('');

const isEditing = computed(() => !!props.institution);

onMounted(() => {
  if (props.institution) {
    // Populate form for editing
    form.value = {
      name: props.institution.name || '',
      registration_number: props.institution.registration_number || '',
      contact_email: props.institution.contact_email || '',
      contact_phone: props.institution.contact_phone || '',
      address: props.institution.address || ''
    };
  }
});

async function handleSubmit() {
  loading.value = true;
  error.value = '';
  success.value = '';

  try {
    let result;
    if (isEditing.value) {
      result = await institutionClient.updateInstitution(props.institution.id, form.value);
    } else {
      result = await institutionClient.createInstitution(form.value);
    }

    success.value = isEditing.value ? 'Institution updated successfully!' : 'Institution created successfully!';

    // Emit success after a brief delay to show the message
    setTimeout(() => {
      emit('success', result.institution || result);
    }, 1000);

  } catch (err) {
    error.value = err.message || 'An error occurred. Please try again.';
  } finally {
    loading.value = false;
  }
}
</script>

<style scoped>
.institution-wizard {
  max-width: 600px;
  margin: 0 auto;
  padding: 20px;
}

.wizard-header {
  margin-bottom: 30px;
  text-align: center;
}

.wizard-header h2 {
  margin: 0 0 8px 0;
  color: #1a202c;
  font-size: 24px;
  font-weight: 600;
}

.subtitle {
  color: #718096;
  margin: 0;
  font-size: 14px;
}

.wizard-form {
  background: white;
  padding: 24px;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.form-section {
  margin-bottom: 24px;
}

.form-section h3 {
  margin: 0 0 16px 0;
  color: #2d3748;
  font-size: 16px;
  font-weight: 600;
  border-bottom: 2px solid #e2e8f0;
  padding-bottom: 8px;
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
.form-group textarea {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #cbd5e0;
  border-radius: 6px;
  font-size: 14px;
  transition: border-color 0.2s;
}

.form-group input:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #3182ce;
  box-shadow: 0 0 0 3px rgba(49, 130, 206, 0.1);
}

.form-group input:disabled,
.form-group textarea:disabled {
  background-color: #f7fafc;
  cursor: not-allowed;
}

.form-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 24px;
  padding-top: 24px;
  border-top: 1px solid #e2e8f0;
}

.btn-primary,
.btn-secondary {
  padding: 10px 20px;
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
  padding: 12px;
  border-radius: 6px;
  margin-top: 16px;
  border: 1px solid #feb2b2;
}

.success-message {
  background: #c6f6d5;
  color: #22543d;
  padding: 12px;
  border-radius: 6px;
  margin-top: 16px;
  border: 1px solid #9ae6b4;
}
</style>
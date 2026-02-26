<template>
  <div
    class="modal modal-open items-start !animate-none overflow-y-auto"
  >
    <div
      class="absolute top-0 bottom-0 right-0 left-0"
      @click.prevent="$emit('close')"
    />
    <div class="modal-box pt-4 pb-6 px-6 mt-20 max-h-none w-full max-w-xl">
      <div class="flex justify-between items-center border-b pb-2 mb-2 font-medium">
        <span class="modal-title text-lg">
          {{ t('select_signing_order') }}
        </span>
        <a
          href="#"
          class="text-xl modal-close-button"
          @click.prevent="$emit('close')"
        >&times;</a>
      </div>
      <div>
        <form @submit.prevent="saveAndClose">
          <div class="space-y-2 mb-4">
            <label class="flex items-start space-x-3 p-3 border border-base-300 rounded-lg cursor-pointer hover:border-primary transition-colors">
              <input
                v-model="signingOrder"
                type="radio"
                value="employee_then_manager"
                class="radio radio-primary mt-1"
              >
              <div class="flex-1">
                <div>{{ firstParty }} completes the form first, then {{ secondParty }}</div>
              </div>
            </label>

            <label class="flex items-start space-x-3 p-3 border border-base-300 rounded-lg cursor-pointer hover:border-primary transition-colors">
              <input
                v-model="signingOrder"
                type="radio"
                value="manager_then_employee"
                class="radio radio-primary mt-1"
              >
              <div class="flex-1">
                <div>{{ secondParty }} completes the form first, then {{ firstParty }}</div>
              </div>
            </label>

            <label class="flex items-start space-x-3 p-3 border border-base-300 rounded-lg cursor-pointer hover:border-primary transition-colors">
              <input
                v-model="signingOrder"
                type="radio"
                value="simultaneous"
                class="radio radio-primary mt-1"
              >
              <div class="flex-1">
                <div>{{ t('simultaneous_signing_description') }}</div>
              </div>
            </label>
          </div>
          <button class="base-button w-full mt-4 modal-save-button">
            {{ t('save') }}
          </button>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'SigningOrderModal',
  inject: ['t', 'template', 'baseFetch', 'authenticityToken'],
  emits: ['close'],
  data () {
    return {
      signingOrder: this.template.preferences?.submitters_order || 'employee_then_manager'
    }
  },
  computed: {
    firstParty () {
      return this.template.submitters[0]?.name || this.t('first_party')
    },
    secondParty () {
      return this.template.submitters[1]?.name || this.t('second_party')
    }
  },
  methods: {
    saveAndClose () {
      if (!this.template.preferences) {
        this.template.preferences = {}
      }
      this.template.preferences.submitters_order = this.signingOrder

      const formData = new FormData()
      formData.append('template[preferences][submitters_order]', this.signingOrder)

      if (this.template?.partnership_context) {
        const context = this.template.partnership_context
        if (context.accessible_partnership_ids) {
          context.accessible_partnership_ids.forEach(id => {
            formData.append('accessible_partnership_ids[]', id)
          })
        }
        if (context.external_partnership_id) {
          formData.append('external_partnership_id', context.external_partnership_id)
        }
        if (context.external_account_id) {
          formData.append('external_account_id', context.external_account_id)
        }
      }

      this.baseFetch(`/templates/${this.template.id}/preferences`, {
        method: 'POST',
        body: formData
      }).then(() => {
        this.$emit('close')
      }).catch((error) => {
        console.error('Error saving signing order:', error)
        alert(this.t('failed_to_save_signing_order_please_try_again_or_contact_support'))
      })
    }
  }
}
</script>

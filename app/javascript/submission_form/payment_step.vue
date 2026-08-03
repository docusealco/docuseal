<template>
  <label
    v-if="!modelValue && !isProcessing"
    class="label text-xl sm:text-2xl py-0 mb-2 sm:mb-3.5 field-name-label"
  >
    <MarkdownContent
      v-if="field.title"
      :string="field.title"
    />
    <template v-else>{{ field.name || defaultName }}</template>
  </label>
  <div
    v-if="field.description"
    dir="auto"
    class="mb-4 px-1"
  >
    <MarkdownContent :string="field.description" />
  </div>
  <div>
    <input
      type="text"
      :value="modelValue"
      hidden
      :name="`values[${field.uuid}]`"
      class="hidden"
    >
    <div
      v-if="modelValue && !isProcessing"
      class=" text-2xl mb-2"
    >
      {{ t('already_paid') }}
    </div>
    <div v-else>
      <button
        v-if="isProcessing"
        type="button"
        disabled
        class="base-button w-full modal-save-button"
      >
        <IconLoader
          width="22"
          class="animate-spin"
        />
        <span>
          {{ t('processing') }}...
        </span>
      </button>
      <button
        v-else
        :id="field.uuid"
        type="button"
        class="btn text-white text-lg w-full"
        :class="[isPaypal ? 'bg-[#003087] hover:bg-[#012169]' : 'bg-[#7B73FF] hover:bg-[#0A2540]', { disabled: isCreatingCheckout }]"
        :disabled="isCreatingCheckout"
        @click.prevent="postCheckout"
      >
        <IconInnerShadowTop
          v-if="isCreatingCheckout"
          width="22"
          class="animate-spin"
        />
        <IconBrandPaypal
          v-else-if="isPaypal"
          width="22"
        />
        <IconBrandStripe
          v-else
          width="22"
        />
        <span>
          {{ isPaypal ? t('pay_with_paypal') : t('pay_with_stripe') }}
        </span>
      </button>
    </div>
  </div>
</template>

<script>
import { IconBrandStripe, IconBrandPaypal, IconInnerShadowTop, IconLoader } from '@tabler/icons-vue'
import MarkdownContent from './markdown_content'

export default {
  name: 'PaymentStep',
  components: {
    IconBrandStripe,
    IconBrandPaypal,
    MarkdownContent,
    IconInnerShadowTop,
    IconLoader
  },
  inject: ['baseUrl', 't'],
  props: {
    modelValue: {
      type: String,
      required: false,
      default: ''
    },
    field: {
      type: Object,
      required: true
    },
    readonlyValues: {
      type: Object,
      required: false,
      default: () => ({})
    },
    values: {
      type: Object,
      required: true
    },
    fields: {
      type: Array,
      required: false,
      default: () => []
    },
    submitterSlug: {
      type: String,
      required: true
    },
    provider: {
      type: String,
      required: false,
      default: ''
    }
  },
  emits: ['focus', 'submit', 'update:model-value', 'attached'],
  data () {
    return {
      isCreatingCheckout: false,
      isProcessing: false,
      isMathLoaded: false
    }
  },
  computed: {
    fieldsUuidIndex () {
      return this.fields.reduce((acc, field) => {
        acc[field.uuid] = field

        return acc
      }, {})
    },
    queryParams () {
      return new URLSearchParams(window.location.search)
    },
    isPaypal () {
      return this.provider === 'paypal'
    },
    paymentEndpoint () {
      return this.isPaypal ? '/api/paypal_payments' : '/api/stripe_payments'
    },
    sessionId () {
      return this.queryParams.get('stripe_session_id') || this.queryParams.get('paypal_order_id') || (this.isPaypal && this.queryParams.get('token'))
    },
    defaultName () {
      if (this.field.preferences?.price_id || this.field.preferences?.payment_link_id) {
        return ''
      }

      const { price, currency } = this.field.preferences || {}

      const formatter = new Intl.NumberFormat([], {
        style: 'currency',
        currency
      })

      if (this.field.preferences?.formula) {
        if (this.isMathLoaded) {
          return this.t('pay') + ' ' + formatter.format(this.calculateFormula())
        } else {
          return ''
        }
      } else {
        return this.t('pay') + ' ' + formatter.format(price)
      }
    }
  },
  async mounted () {
    if (this.sessionId) {
      this.isProcessing = true

      this.$emit('submit')
    }

    if (!this.sessionId) {
      this.postCheckout({ checkStatus: true })
    }

    if (this.field.preferences?.formula) {
      const { Calculator } = await import('./calculator')

      this.math = new Calculator()

      this.isMathLoaded = true
    }
  },
  methods: {
    normalizedPaymentUrl () {
      const url = new URL(window.location.href)
      const keys = ['stripe_session_id', 'paypal_order_id', 'field_uuid']

      if (this.isPaypal) {
        keys.push('token', 'PayerID')
      }

      keys.forEach((key) => url.searchParams.delete(key))

      return url.toString()
    },
    normalizedPaymentParams () {
      window.history.replaceState({}, document.title, this.normalizedPaymentUrl())
    },
    calculateFormula () {
      const transformedFormula = this.normalizeFormula(this.field.preferences.formula).replace(/{{(.*?)}}/g, (match, uuid) => {
        return this.readonlyValues[uuid] || this.values[uuid] || 0.0
      })

      return this.math.evaluate(transformedFormula.toLowerCase())
    },
    normalizeFormula (formula, depth = 0) {
      if (depth > 10) return formula

      return formula.replace(/{{(.*?)}}/g, (match, uuid) => {
        if (this.fieldsUuidIndex[uuid]) {
          return `(${this.normalizeFormula(this.fieldsUuidIndex[uuid].preferences.formula, depth + 1)})`
        } else {
          return match
        }
      })
    },
    async submit () {
      if (this.sessionId) {
        return fetch(this.baseUrl + this.paymentEndpoint + '/' + this.sessionId, {
          method: 'PUT',
          body: JSON.stringify({
            submitter_slug: this.submitterSlug
          }),
          headers: { 'Content-Type': 'application/json' }
        }).then(async (resp) => {
          if (resp.status === 422 || resp.status === 500) {
            this.isProcessing = false

            const data = await resp.json()

            if (data.error) {
              alert(data.error)
            }

            return Promise.reject(new Error(data.error))
          }

          const attachment = await resp.json()

          this.isProcessing = false

          this.normalizedPaymentParams()

          this.$emit('update:model-value', attachment.uuid)
          this.$emit('attached', attachment)

          return resp
        })
      } else {
        return Promise.resolve({})
      }
    },
    postCheckout ({ checkStatus } = {}) {
      this.isCreatingCheckout = true

      fetch(this.baseUrl + this.paymentEndpoint, {
        method: 'POST',
        body: JSON.stringify({
          submitter_slug: this.submitterSlug,
          field_uuid: this.field.uuid,
          check_status: checkStatus,
          referer: this.normalizedPaymentUrl()
        }),
        headers: { 'Content-Type': 'application/json' }
      }).then(async (resp) => {
        if (resp.status === 422 || resp.status === 500) {
          const data = await resp.json()

          alert(data.message || 'Unexpected error')

          return Promise.reject(new Error(data.message))
        }

        const { url } = await resp.json()

        const link = document.createElement('a')

        link.href = url

        if (url) {
          link.click()
        }
      }).finally(() => {
        this.isCreatingCheckout = false
      })
    }
  }
}
</script>

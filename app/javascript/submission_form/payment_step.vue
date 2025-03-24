<template>
  <label
    v-if="!modelValue && !sessionId"
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
      v-if="modelValue && !sessionId"
      class=" text-2xl mb-2"
    >
      {{ t('already_paid') }}
    </div>
    <div v-else>
      <button
        v-if="sessionId"
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
        class="btn bg-[#7B73FF] text-white hover:bg-[#0A2540] text-lg w-full"
        :class="{ disabled: isCreatingCheckout }"
        :disabled="isCreatingCheckout"
        @click.prevent="postCheckout"
      >
        <IconInnerShadowTop
          v-if="isCreatingCheckout"
          width="22"
          class="animate-spin"
        />
        <IconBrandStripe
          v-else
          width="22"
        />
        <span>
          {{ t('pay_with_strip') }}
        </span>
      </button>
    </div>
  </div>
</template>

<script>
import { IconBrandStripe, IconInnerShadowTop, IconLoader } from '@tabler/icons-vue'
import MarkdownContent from './markdown_content'

export default {
  name: 'PaymentStep',
  components: {
    IconBrandStripe,
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
    values: {
      type: Object,
      required: true
    },
    submitterSlug: {
      type: String,
      required: true
    }
  },
  emits: ['focus', 'submit', 'update:model-value', 'attached'],
  data () {
    return {
      isCreatingCheckout: false,
      isMathLoaded: false
    }
  },
  computed: {
    queryParams () {
      return new URLSearchParams(window.location.search)
    },
    sessionId () {
      return this.queryParams.get('stripe_session_id')
    },
    defaultName () {
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
      this.$emit('submit')
    }

    if (!this.sessionId) {
      this.postCheckout({ checkStatus: true })
    }

    if (this.field.preferences?.formula) {
      const {
        create,
        evaluateDependencies,
        addDependencies,
        subtractDependencies,
        divideDependencies,
        multiplyDependencies,
        powDependencies,
        roundDependencies,
        absDependencies,
        sinDependencies,
        tanDependencies,
        cosDependencies
      } = await import('mathjs')

      this.math = create({
        evaluateDependencies,
        addDependencies,
        subtractDependencies,
        divideDependencies,
        multiplyDependencies,
        powDependencies,
        roundDependencies,
        absDependencies,
        sinDependencies,
        tanDependencies,
        cosDependencies
      })

      this.isMathLoaded = true
    }
  },
  methods: {
    calculateFormula () {
      const transformedFormula = this.field.preferences.formula.replace(/{{(.*?)}}/g, (match, uuid) => {
        return this.values[uuid] || 0.0
      })

      return this.math.evaluate(transformedFormula.toLowerCase())
    },
    async submit () {
      if (this.sessionId) {
        return fetch(this.baseUrl + '/api/stripe_payments/' + this.sessionId, {
          method: 'PUT',
          body: JSON.stringify({
            submitter_slug: this.submitterSlug
          }),
          headers: { 'Content-Type': 'application/json' }
        }).then(async (resp) => {
          if (resp.status === 422 || resp.status === 500) {
            const data = await resp.json()

            alert(data.error || 'Unexpected error')

            return Promise.reject(new Error(data.error))
          }

          const attachment = await resp.json()

          window.history.replaceState({}, document.title, window.location.pathname)

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

      fetch(this.baseUrl + '/api/stripe_payments', {
        method: 'POST',
        body: JSON.stringify({
          submitter_slug: this.submitterSlug,
          field_uuid: this.field.uuid,
          check_status: checkStatus,
          referer: document.location.href
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

<template>
  <label class="label text-xl sm:text-2xl py-0 mb-2 sm:mb-3.5 field-name-label">
    <MarkdownContent
      v-if="field.title"
      :string="field.title"
    />
    <template v-else>{{ field.name || t('identity_verification') }}</template>
  </label>
  <div
    v-if="field.description"
    dir="auto"
    class="mb-4 px-1 field-description-text"
  >
    <MarkdownContent :string="field.description" />
  </div>
  <div
    v-if="emptyValueRequiredStep && emptyValueRequiredStep[0] !== field"
    class="px-1 field-description-text"
  >
    {{ t('complete_all_required_fields_to_proceed_with_identity_verification') }}
  </div>
  <div v-else>
    <div
      v-if="isLoading"
      class="w-full flex space-x-2 justify-center mb-2"
    >
      <IconInnerShadowTop
        width="40"
        class="animate-spin h-10"
      />
    </div>
    <div v-else-if="redirectUrl">
      <a
        :href="redirectUrl"
        target="_blank"
        class="white-button w-full"
      >
        {{ t('verify_id') }}
      </a>
    </div>
    <div
      ref="widgetContainer"
    />
  </div>
</template>

<script>
import MarkdownContent from './markdown_content'
import { IconInnerShadowTop } from '@tabler/icons-vue'
import phoneData from './phone_data'

export default {
  name: 'VerificationStep',
  components: {
    MarkdownContent,
    IconInnerShadowTop
  },
  inject: ['baseUrl', 't'],
  props: {
    modelValue: {
      type: String,
      required: false,
      default: ''
    },
    submitter: {
      type: Object,
      required: true
    },
    field: {
      type: Object,
      required: true
    },
    emptyValueRequiredStep: {
      type: Object,
      required: false,
      default: null
    },
    values: {
      type: Object,
      required: true
    },
    locale: {
      type: String,
      required: false,
      default: 'en'
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
      isMathLoaded: false,
      redirectUrl: '',
      isLoading: false,
      eidEasyData: {}
    }
  },
  computed: {
    countryCode () {
      const browserTimeZone = Intl.DateTimeFormat().resolvedOptions().timeZone
      const browserTz = browserTimeZone.split('/')[1]
      const country = phoneData.find(([a, b, c, e, tz]) => tz.includes(browserTz))

      return country[0]
    },
    browserCountry () {
      return (navigator.language || navigator.userLanguage || 'en').split('-')[1]
    },
    widgetSettings () {
      return {
        clientId: this.eidEasyData.client_id,
        docId: this.eidEasyData.doc_id,
        language: this.locale,
        countryCode: this.countryCode,
        enabledMethods: {
          signature: this.eidEasyData.available_methods
        },
        selectedMethod: null,
        enabledCountries: 'all',
        onSuccess: (data) => {
          this.$emit('submit')
        },
        onFail: (error) => {
          console.error(error)
        }
      }
    }
  },
  async mounted () {
    this.isLoading = true

    if (new URLSearchParams(window.location.search).get('submit') === 'true') {
      this.$emit('submit')
    } else {
      Promise.all([
        import('@eid-easy/eideasy-widget'),
        this.start()
      ]).finally(() => {
        this.isLoading = false
      })
    }
  },
  methods: {
    start () {
      return fetch(this.baseUrl + `/api/identity_verification/${this.field.uuid}`, {
        method: 'PUT',
        body: JSON.stringify({
          submitter_slug: this.submitterSlug
        }),
        headers: { 'Content-Type': 'application/json' }
      }).then(async (resp) => {
        this.eidEasyData = await resp.json()

        if (this.eidEasyData.available_methods[0] === 'itsme-qes-signature' &&
            this.eidEasyData.available_methods.length === 1) {
          const redirectUrl = new URL('https://id.eideasy.com/sign_contract_external')

          redirectUrl.searchParams.append('client_id', this.eidEasyData.client_id)
          redirectUrl.searchParams.append('doc_id', this.eidEasyData.doc_id)
          redirectUrl.searchParams.append('country', this.countryCode)
          redirectUrl.searchParams.append('lang', this.locale)

          this.redirectUrl = redirectUrl.toString()
        } else {
          const eidEasyWidget = document.createElement('eideasy-widget')

          for (const key in this.widgetSettings) {
            eidEasyWidget[key] = this.widgetSettings[key]
          }

          this.$refs.widgetContainer.innerHTML = ''
          this.$refs.widgetContainer.appendChild(eidEasyWidget)
        }
      })
    },
    async submit () {
      return fetch(this.baseUrl + '/api/identity_verification', {
        method: 'POST',
        body: JSON.stringify({
          submitter_slug: this.submitterSlug
        }),
        headers: { 'Content-Type': 'application/json' }
      }).then(async (resp) => {
        return resp
      })
    }
  }
}
</script>

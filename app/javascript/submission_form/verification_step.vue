<template>
  <label
    class="label text-2xl mb-2"
  >
    <MarkdownContent
      v-if="field.title"
      :string="field.title"
    />
    <template v-else>{{ field.name || t('identity_verification') }}</template>
  </label>
  <div
    v-if="field.description"
    dir="auto"
    class="mb-4 px-1"
  >
    <MarkdownContent :string="field.description" />
  </div>
  <div
    v-if="emptyValueRequiredStep && emptyValueRequiredStep[0] !== field"
    class="px-1"
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
      isLoading: false,
      eidEasyData: {}
    }
  },
  computed: {
    countryCode () {
      const browserTimeZone = Intl.DateTimeFormat().resolvedOptions().timeZone
      const browserTz = browserTimeZone.split('/')[1]
      const country = phoneData.find(([a, b, c, tz]) => tz.includes(browserTz))

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
        countryCode: this.browserCountry,
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

    Promise.all([
      import('@eid-easy/eideasy-widget'),
      this.start()
    ]).finally(() => {
      this.isLoading = false
    })
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

        const eidEasyWidget = document.createElement('eideasy-widget')

        for (const key in this.widgetSettings) {
          eidEasyWidget[key] = this.widgetSettings[key]
        }

        this.$refs.widgetContainer.innerHTML = ''
        this.$refs.widgetContainer.appendChild(eidEasyWidget)
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

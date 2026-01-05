<template>
  <label
    v-if="!error"
    class="label text-xl sm:text-2xl py-0 mb-2 sm:mb-3.5 field-name-label"
  >
    <MarkdownContent
      v-if="field.title"
      :string="field.title"
    />
    <template v-else>{{ field.name || 'Knowledge Based Authentication' }}</template>
    <span
      v-if="questions"
      class="float-right text-base font-normal text-neutral-500 mt-1 whitespace-nowrap"
    >
      Question {{ currentQuestionIndex + 1 }} / {{ questions.length }}
    </span>
  </label>
  <div
    v-if="field.description"
    dir="auto"
    class="mb-4 px-1 field-description-text"
  >
    <MarkdownContent :string="field.description" />
  </div>
  <div
    v-if="isRequiredFieldEmpty"
    class="px-1 field-description-text"
  >
    {{ t('complete_all_required_fields_to_proceed_with_identity_verification') }}
  </div>
  <div
    v-if="error"
    class="mb-4 text-center"
  >
    <div class="text-xl mb-4">
      {{ error }}
    </div>
    <button
      class="base-button w-full flex justify-center submit-form-button"
      @click="restartKba"
    >
      {{ questions ? 'Restart KBA' : 'Retry' }}
    </button>
  </div>
  <div
    v-if="isLoading"
    class="w-full flex space-x-2 justify-center mb-2"
  >
    <IconInnerShadowTop
      width="40"
      class="animate-spin h-10"
    />
  </div>
  <div v-else-if="questions && !error">
    <form @submit.prevent="nextQuestion">
      <div class="mb-6 px-1">
        <p class="font-semibold mb-4 text-lg">{{ currentQuestion.prompt }}</p>
        <div class="space-y-3.5 mx-auto">
          <div
            v-for="(answer, index) in currentQuestion.answers"
            :key="`${currentQuestion.id}_${index}`"
          >
            <label
              :for="`${currentQuestion.id}_${index}`"
              class="flex items-center space-x-3 radio-label"
            >
              <input
                :id="`${currentQuestion.id}_${index}`"
                v-model="answers[currentQuestion.id]"
                type="radio"
                :name="currentQuestion.id"
                :value="answer.text"
                class="base-radio !h-7 !w-7"
                required
              >
              <span class="text-xl">{{ answer.text }}</span>
            </label>
          </div>
        </div>
      </div>
      <div class="mt-6">
        <button
          type="submit"
          class="base-button w-full flex justify-center submit-form-button"
          :disabled="isSubmitting || !answers[currentQuestion.id]"
        >
          <span class="flex">
            <IconInnerShadowTop
              v-if="isSubmitting"
              class="mr-1 animate-spin"
            />
            <span>
              {{ isLastQuestion ? (isSubmitting ? t('submitting_') : t('complete')) : t('next') }}
            </span><span
              v-if="isSubmitting"
              class="w-6 flex justify-start mr-1"
            ><span>...</span></span>
          </span>
        </button>
      </div>
    </form>
  </div>
  <div v-else-if="!error && !isRequiredFieldEmpty">
    <form @submit.prevent="startKba">
      <div class="grid grid-cols-6 gap-x-2 md:gap-x-4 md:gap-y-2 mb-4">
        <div class="col-span-3">
          <label
            for="kba_fn"
            class="label text-sm md:text-base"
          >First Name</label>
          <input
            id="kba_fn"
            v-model="form.fn"
            type="text"
            class="input input-bordered !h-10 w-full bg-white"
            required
          >
        </div>
        <div class="col-span-3">
          <label
            for="kba_ln"
            class="label text-sm md:text-base"
          >Last Name</label>
          <input
            id="kba_ln"
            v-model="form.ln"
            type="text"
            class="input input-bordered !h-10 w-full bg-white"
            required
          >
        </div>
        <div class="col-span-6">
          <label
            for="kba_addr"
            class="label text-sm md:text-base"
          >Address</label>
          <input
            id="kba_addr"
            v-model="form.addr"
            type="text"
            class="input input-bordered !h-10 w-full bg-white"
            required
          >
        </div>
        <div class="col-span-2">
          <label
            for="kba_city"
            class="label text-sm md:text-base"
          >City</label>
          <input
            id="kba_city"
            v-model="form.city"
            type="text"
            class="input input-bordered !h-10 w-full bg-white"
            required
          >
        </div>
        <div class="col-span-2">
          <label
            for="kba_state"
            class="label text-sm md:text-base"
          >State</label>
          <select
            id="kba_state"
            v-model="form.state"
            class="select select-bordered !h-10 min-h-[2.5rem] w-full bg-white font-normal !text-base"
            required
          >
            <option
              value=""
              disabled
            >
              Select State
            </option>
            <option
              v-for="state in states"
              :key="state.code"
              :value="state.code"
            >
              {{ state.name }}
            </option>
          </select>
        </div>
        <div class="col-span-2">
          <label
            for="kba_zip"
            class="label text-sm md:text-base"
          >Zip</label>
          <input
            id="kba_zip"
            v-model="form.zip"
            type="text"
            class="input input-bordered !h-10 w-full bg-white"
            required
          >
        </div>
        <div class="col-span-3">
          <label
            for="kba_phone"
            class="label text-sm md:text-base"
          >Phone</label>
          <input
            id="kba_phone"
            v-model="form.phone"
            type="text"
            class="input input-bordered !h-10 w-full bg-white"
            required
          >
        </div>
        <div class="col-span-3">
          <label
            for="kba_email"
            class="label text-sm md:text-base"
          >Email</label>
          <input
            id="kba_email"
            v-model="form.email"
            type="email"
            class="input input-bordered !h-10 w-full bg-white"
            required
          >
        </div>
        <div class="col-span-3">
          <label
            for="kba_dob"
            class="label text-sm md:text-base"
          >DOB</label>
          <input
            id="kba_dob"
            v-model="form.dob"
            type="date"
            class="input input-bordered !h-10 md:w-full bg-white"
            required
          >
        </div>
        <div class="col-span-3">
          <label
            for="kba_ssn"
            class="label text-sm md:text-base"
          >SSN</label>
          <input
            id="kba_ssn"
            v-model="form.ssn"
            type="text"
            class="input input-bordered !h-10 w-full bg-white"
            required
          >
        </div>
      </div>
      <div class="mt-6">
        <button
          type="submit"
          class="base-button w-full flex justify-center submit-form-button"
          :disabled="isLoading"
        >
          <span class="flex">
            <IconInnerShadowTop
              v-if="isLoading"
              class="mr-1 animate-spin"
            />
            <span>
              {{ isLoading ? 'Loading...' : 'Start Verification' }}
            </span><span
              v-if="isLoading"
              class="w-6 flex justify-start mr-1"
            ><span>...</span></span>
          </span>
        </button>
      </div>
    </form>
  </div>
</template>

<script>
import MarkdownContent from './markdown_content'
import { IconInnerShadowTop } from '@tabler/icons-vue'

export default {
  name: 'KbaStep',
  components: {
    MarkdownContent,
    IconInnerShadowTop
  },
  inject: ['baseUrl', 't'],
  props: {
    field: {
      type: Object,
      required: true
    },
    submitter: {
      type: Object,
      required: true
    },
    submitterSlug: {
      type: String,
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
    }
  },
  emits: ['submit'],
  data () {
    return {
      isLoading: false,
      isSubmitting: false,
      questions: null,
      currentQuestionIndex: 0,
      token: null,
      reference: null,
      answers: {},
      error: null,
      form: {
        fn: '',
        ln: '',
        addr: '',
        city: '',
        state: '',
        zip: '',
        dob: '',
        ssn: '',
        phone: '',
        email: ''
      }
    }
  },
  computed: {
    currentQuestion () {
      return this.questions ? this.questions[this.currentQuestionIndex] : null
    },
    isRequiredFieldEmpty () {
      return this.emptyValueRequiredStep && this.emptyValueRequiredStep[0] !== this.field
    },
    states () {
      return [
        { code: 'AL', name: 'Alabama' },
        { code: 'AK', name: 'Alaska' },
        { code: 'AZ', name: 'Arizona' },
        { code: 'AR', name: 'Arkansas' },
        { code: 'CA', name: 'California' },
        { code: 'CO', name: 'Colorado' },
        { code: 'CT', name: 'Connecticut' },
        { code: 'DE', name: 'Delaware' },
        { code: 'DC', name: 'District of Columbia' },
        { code: 'FL', name: 'Florida' },
        { code: 'GA', name: 'Georgia' },
        { code: 'HI', name: 'Hawaii' },
        { code: 'ID', name: 'Idaho' },
        { code: 'IL', name: 'Illinois' },
        { code: 'IN', name: 'Indiana' },
        { code: 'IA', name: 'Iowa' },
        { code: 'KS', name: 'Kansas' },
        { code: 'KY', name: 'Kentucky' },
        { code: 'LA', name: 'Louisiana' },
        { code: 'ME', name: 'Maine' },
        { code: 'MD', name: 'Maryland' },
        { code: 'MA', name: 'Massachusetts' },
        { code: 'MI', name: 'Michigan' },
        { code: 'MN', name: 'Minnesota' },
        { code: 'MS', name: 'Mississippi' },
        { code: 'MO', name: 'Missouri' },
        { code: 'MT', name: 'Montana' },
        { code: 'NE', name: 'Nebraska' },
        { code: 'NV', name: 'Nevada' },
        { code: 'NH', name: 'New Hampshire' },
        { code: 'NJ', name: 'New Jersey' },
        { code: 'NM', name: 'New Mexico' },
        { code: 'NY', name: 'New York' },
        { code: 'NC', name: 'North Carolina' },
        { code: 'ND', name: 'North Dakota' },
        { code: 'OH', name: 'Ohio' },
        { code: 'OK', name: 'Oklahoma' },
        { code: 'OR', name: 'Oregon' },
        { code: 'PA', name: 'Pennsylvania' },
        { code: 'RI', name: 'Rhode Island' },
        { code: 'SC', name: 'South Carolina' },
        { code: 'SD', name: 'South Dakota' },
        { code: 'TN', name: 'Tennessee' },
        { code: 'TX', name: 'Texas' },
        { code: 'UT', name: 'Utah' },
        { code: 'VT', name: 'Vermont' },
        { code: 'VA', name: 'Virginia' },
        { code: 'WA', name: 'Washington' },
        { code: 'WV', name: 'West Virginia' },
        { code: 'WI', name: 'Wisconsin' },
        { code: 'WY', name: 'Wyoming' }
      ]
    },
    isLastQuestion () {
      return this.questions && this.currentQuestionIndex === this.questions.length - 1
    }
  },
  methods: {
    nextQuestion () {
      if (this.isLastQuestion) {
        this.$emit('submit')
      } else {
        this.currentQuestionIndex++
      }
    },
    restartKba () {
      this.questions = null
      this.token = null
      this.reference = null
      this.answers = {}
      this.currentQuestionIndex = 0
      this.error = null
    },
    async startKba () {
      this.isLoading = true
      this.error = null

      try {
        const payload = { ...this.form, submitter_slug: this.submitterSlug }

        if (payload.dob) {
          payload.dob = payload.dob.replace(/-/g, '')
        }

        if (payload.ssn) {
          payload.ssn = payload.ssn.replace(/\D/g, '')
        }

        if (payload.phone) {
          payload.phone = payload.phone.replace(/^\+1/, '')
        }

        const resp = await fetch(this.baseUrl + '/api/kba', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        })

        if (!resp.ok) throw new Error('Failed to start KBA')

        const data = await resp.json()

        if (data.result && data.result.action === 'FAIL') {
          if (data.result.detail === 'NO MATCH') {
            throw new Error('Unfortunately, we were unable to start Knowledge Based Authentication with the details provided. Please review and confirm that all your personal details are correct.')
          }

          throw new Error(data.result.detail || 'KBA Start Failed')
        }

        if (data.output && data.output.questions && data.output.questions.questions) {
          this.questions = data.output.questions.questions
          this.token = data.continuations.questions.template.token
          this.reference = data.meta.reference

          this.questions.forEach(q => {
            this.answers[q.id] = null
          })
        } else {
          throw new Error('Invalid KBA response')
        }
      } catch (e) {
        this.error = e.message
      } finally {
        this.isLoading = false
      }
    },
    async submit () {
      this.isSubmitting = true
      this.error = null

      const formattedAnswers = Object.keys(this.answers).reduce((acc, key) => {
        acc[key] = [this.answers[key]]

        return acc
      }, {})

      try {
        const resp = await fetch(this.baseUrl + `/api/kba/${this.field.uuid}`, {
          method: 'PUT',
          body: JSON.stringify({
            token: this.token,
            answers: formattedAnswers,
            reference: this.reference,
            submitter_slug: this.submitterSlug
          }),
          headers: { 'Content-Type': 'application/json' }
        })

        const data = await resp.json()

        if (data.result?.action !== 'PASS') {
          this.error = 'Knowledge Based Authentication Failed - make sure you provide correct answers for the Knowledge Based authentication.'

          throw new Error('Knowledge Based Authentication Failed')
        }

        if (!resp.ok) {
          this.error = 'Failed to submit answers'

          throw new Error('Failed to submit answers')
        }

        return resp
      } finally {
        this.isSubmitting = false
      }
    }
  }
}
</script>

<template>
  <FieldAreas
    ref="areas"
    :steps="stepFields"
    :values="values"
    :attachments-index="attachmentsIndex"
    :with-label="!isAnonymousChecboxes"
    :current-step="currentStepFields"
    @focus-step="[saveStep(), goToStep($event, false, true), currentField.type !== 'checkbox' ? isFormVisible = true : '']"
  />
  <button
    v-if="!isFormVisible"
    class="btn btn-neutral flex text-white absolute rounded-none border-x-0 md:border md:rounded-full bottom-0 w-full md:mb-4 text-base"
    @click.prevent="isFormVisible = true"
  >
    {{ t('submit_form') }}
    <IconArrowsDiagonal
      class="absolute right-0 mr-4"
      :width="20"
      :height="20"
    />
  </button>
  <div
    v-show="isFormVisible"
    id="form_container"
    class="shadow-md bg-base-100 absolute bottom-0 md:bottom-4 w-full border-base-200 border p-4 rounded"
    :style="{ backgroundColor: backgroundColor }"
  >
    <button
      v-if="!isCompleted"
      class="absolute right-0 mr-2 mt-2 top-0 hidden md:block"
      title="Minimize"
      @click.prevent="isFormVisible = false"
    >
      <IconArrowsDiagonalMinimize2
        :width="20"
        :height="20"
      />
    </button>
    <div>
      <form
        v-if="!isCompleted"
        ref="form"
        :action="submitPath"
        method="post"
        class="md:mx-16"
        @submit.prevent="submitStep"
      >
        <input
          type="hidden"
          name="authenticity_token"
          :value="authenticityToken"
        >
        <input
          value="put"
          name="_method"
          type="hidden"
        >
        <div class="md:mt-4">
          <div v-if="['cells', 'text'].includes(currentField.type)">
            <TextStep
              :key="currentField.uuid"
              v-model="values[currentField.uuid]"
              :field="currentField"
              @focus="$refs.areas.scrollIntoField(currentField)"
            />
          </div>
          <DateStep
            v-else-if="currentField.type === 'date'"
            :key="currentField.uuid"
            v-model="values[currentField.uuid]"
            :field="currentField"
            @focus="$refs.areas.scrollIntoField(currentField)"
          />
          <div v-else-if="currentField.type === 'select'">
            <label
              v-if="currentField.name"
              :for="currentField.uuid"
              class="label text-2xl mb-2"
            >{{ currentField.name }}
              <template v-if="!currentField.required">({{ t('optional') }})</template>
            </label>
            <div
              v-else
              class="py-1"
            />
            <select
              :id="currentField.uuid"
              :required="currentField.required"
              class="select base-input !text-2xl w-full text-center font-normal"
              :name="`values[${currentField.uuid}]`"
              @change="values[currentField.uuid] = $event.target.value"
              @focus="$refs.areas.scrollIntoField(currentField)"
            >
              <option
                value=""
                :selected="!values[currentField.uuid]"
              >
                {{ t('select_your_option') }}
              </option>
              <option
                v-for="option in currentField.options"
                :key="option.uuid"
                :selected="values[currentField.uuid] == option.value"
                :value="option.value"
              >
                {{ option.value }}
              </option>
            </select>
          </div>
          <div v-else-if="currentField.type === 'radio'">
            <label
              v-if="currentField.name"
              :for="currentField.uuid"
              class="label text-2xl mb-2"
            >{{ currentField.name }}
              <template v-if="!currentField.required">({{ t('optional') }})</template>
            </label>
            <div class="flex w-full">
              <div class="space-y-3.5 mx-auto">
                <div
                  v-for="option in currentField.options"
                  :key="option.uuid"
                >
                  <label
                    :for="option.uuid"
                    class="flex items-center space-x-3"
                  >
                    <input
                      :id="option.uuid"
                      v-model="values[currentField.uuid]"
                      type="radio"
                      class="base-radio !h-7 !w-7"
                      :name="`values[${currentField.uuid}]`"
                      :value="option.value"
                      :required="currentField.required"
                    >
                    <span class="text-xl">
                      {{ option.value }}
                    </span>
                  </label>
                </div>
              </div>
            </div>
          </div>
          <MultiSelectStep
            v-else-if="currentField.type === 'multiple'"
            :key="currentField.uuid"
            v-model="values[currentField.uuid]"
            :field="currentField"
          />
          <div
            v-else-if="currentField.type === 'checkbox'"
            class="flex w-full max-h-44 overflow-y-auto"
          >
            <input
              type="hidden"
              name="cast_boolean"
              value="true"
            >
            <div
              class="space-y-3.5 mx-auto"
            >
              <template v-if="isAnonymousChecboxes">
                <span class="text-xl">
                  {{ t('complete_hightlighted_checkboxes_and_click') }} <span class="font-semibold">{{ stepFields.length === currentStep + 1 ? t('submit') : t('next') }}</span>.
                </span>
                <input
                  v-for="field in currentStepFields"
                  :key="field.uuid"
                  type="hidden"
                  :name="`values[${field.uuid}]`"
                  :value="!!values[field.uuid]"
                >
              </template>
              <template v-else>
                <div
                  v-for="(field, index) in currentStepFields"
                  :key="field.uuid"
                >
                  <label
                    :for="field.uuid"
                    class="flex items-center space-x-3"
                  >
                    <input
                      type="hidden"
                      :name="`values[${field.uuid}]`"
                      :value="!!values[field.uuid]"
                    >
                    <input
                      :id="field.uuid"
                      type="checkbox"
                      class="base-checkbox !h-7 !w-7"
                      :oninvalid="`this.setCustomValidity('${t('please_check_the_box_to_continue')}')`"
                      :onchange="`this.setCustomValidity(validity.valueMissing ? '${t('please_check_the_box_to_continue')}' : '');`"
                      :required="field.required"
                      :checked="!!values[field.uuid]"
                      @click="[$refs.areas.scrollIntoField(field), values[field.uuid] = !values[field.uuid]]"
                    >
                    <span class="text-xl">
                      {{ field.name || field.type + ' ' + (index + 1) }}
                    </span>
                  </label>
                </div>
              </template>
            </div>
          </div>
          <ImageStep
            v-else-if="currentField.type === 'image' || currentField.type === 'stamp'"
            :key="currentField.uuid"
            v-model="values[currentField.uuid]"
            :field="currentField"
            :is-direct-upload="isDirectUpload"
            :attachments-index="attachmentsIndex"
            :submitter-slug="submitterSlug"
            @attached="[attachments.push($event), $refs.areas.scrollIntoField(currentField)]"
          />
          <SignatureStep
            v-else-if="currentField.type === 'signature'"
            ref="currentStep"
            :key="currentField.uuid"
            v-model="values[currentField.uuid]"
            :field="currentField"
            :previous-value="previousSignatureValue"
            :is-direct-upload="isDirectUpload"
            :with-typed-signature="withTypedSignature"
            :attachments-index="attachmentsIndex"
            :submitter-slug="submitterSlug"
            @attached="attachments.push($event)"
            @start="$refs.areas.scrollIntoField(currentField)"
            @minimize="isFormVisible = false"
          />
          <InitialsStep
            v-else-if="currentField.type === 'initials'"
            ref="currentStep"
            :key="currentField.uuid"
            v-model="values[currentField.uuid]"
            :field="currentField"
            :previous-value="previousInitialsValue"
            :is-direct-upload="isDirectUpload"
            :attachments-index="attachmentsIndex"
            :submitter-slug="submitterSlug"
            @attached="attachments.push($event)"
            @start="$refs.areas.scrollIntoField(currentField)"
            @focus="$refs.areas.scrollIntoField(currentField)"
            @minimize="isFormVisible = false"
          />
          <AttachmentStep
            v-else-if="currentField.type === 'file'"
            :key="currentField.uuid"
            v-model="values[currentField.uuid]"
            :is-direct-upload="isDirectUpload"
            :field="currentField"
            :attachments-index="attachmentsIndex"
            :submitter-slug="submitterSlug"
            @attached="[attachments.push($event), $refs.areas.scrollIntoField(currentField)]"
          />
          <PhoneStep
            v-else-if="currentField.type === 'phone'"
            ref="currentStep"
            :key="currentField.uuid"
            v-model="values[currentField.uuid]"
            :field="currentField"
            :default-value="submitter.phone"
            :submitter-slug="submitterSlug"
            @focus="$refs.areas.scrollIntoField(currentField)"
            @submit="submitStep"
          />
          <PaymentStep
            v-else-if="currentField.type === 'payment'"
            ref="currentStep"
            :key="currentField.uuid"
            v-model="values[currentField.uuid]"
            :field="currentField"
            :submitter-slug="submitterSlug"
            @attached="attachments.push($event)"
            @focus="$refs.areas.scrollIntoField(currentField)"
            @submit="submitStep"
          />
        </div>
        <div
          v-if="currentField.type !== 'payment' || submittedValues[currentField.uuid]"
          class="mt-6 md:mt-8"
        >
          <button
            ref="submitButton"
            type="submit"
            class="base-button w-full flex justify-center"
            :disabled="isButtonDisabled"
          >
            <span class="flex">
              <IconInnerShadowTop
                v-if="isSubmitting"
                class="mr-1 animate-spin"
              />
              <span v-if="stepFields.length === currentStep + 1">
                {{ t('submit') }}
              </span>
              <span v-else>
                {{ t('next') }}
              </span><span
                v-if="isSubmitting"
                class="w-6 flex justify-start mr-1"
              ><span>...</span></span>
            </span>
          </button>
          <div
            v-if="showFillAllRequiredFields"
            class="text-center mt-1"
          >
            {{ t('please_fill_all_required_fields') }}
          </div>
        </div>
      </form>
      <FormCompleted
        v-else
        :is-demo="isDemo"
        :attribution="attribution"
        :completed-button="completedButton"
        :with-send-copy-button="withSendCopyButton"
        :with-download-button="withDownloadButton"
        :with-confetti="withConfetti"
        :can-send-email="canSendEmail && !!submitter.email"
        :submitter-slug="submitterSlug"
      />
      <div class="flex justify-center">
        <div class="flex items-center mt-5 mb-1">
          <a
            v-for="(step, index) in stepFields"
            :key="step[0].uuid"
            href="#"
            class="inline border border-base-300 h-3 w-3 rounded-full mx-1"
            :class="{ 'bg-base-300': index === currentStep, 'bg-base-content': (index < currentStep && stepFields[index].every((f) => !f.required || ![null, undefined, ''].includes(values[f.uuid]))) || isCompleted, 'bg-white': index > currentStep }"
            @click.prevent="isCompleted ? '' : [saveStep(), goToStep(step, true)]"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import FieldAreas from './areas'
import ImageStep from './image_step'
import SignatureStep from './signature_step'
import InitialsStep from './initials_step'
import AttachmentStep from './attachment_step'
import MultiSelectStep from './multi_select_step'
import PhoneStep from './phone_step'
import PaymentStep from './payment_step'
import TextStep from './text_step'
import DateStep from './date_step'
import FormCompleted from './completed'
import { IconInnerShadowTop, IconArrowsDiagonal, IconArrowsDiagonalMinimize2 } from '@tabler/icons-vue'
import { t } from './i18n'

export default {
  name: 'SubmissionForm',
  components: {
    FieldAreas,
    ImageStep,
    SignatureStep,
    AttachmentStep,
    InitialsStep,
    MultiSelectStep,
    IconInnerShadowTop,
    DateStep,
    IconArrowsDiagonal,
    TextStep,
    PhoneStep,
    PaymentStep,
    IconArrowsDiagonalMinimize2,
    FormCompleted
  },
  provide () {
    return {
      baseUrl: this.baseUrl,
      t: this.t
    }
  },
  props: {
    submitter: {
      type: Object,
      required: true
    },
    canSendEmail: {
      type: Boolean,
      required: false,
      default: false
    },
    attachments: {
      type: Array,
      required: false,
      default: () => []
    },
    onComplete: {
      type: Function,
      required: false,
      default () {
        return () => {}
      }
    },
    withConfetti: {
      type: Boolean,
      required: false,
      default: false
    },
    withTypedSignature: {
      type: Boolean,
      required: false,
      default: true
    },
    baseUrl: {
      type: String,
      required: false,
      default: ''
    },
    fields: {
      type: Array,
      required: false,
      default: () => []
    },
    backgroundColor: {
      type: String,
      required: false,
      default: ''
    },
    isDirectUpload: {
      type: Boolean,
      required: false,
      default: false
    },
    allowToSkip: {
      type: Boolean,
      required: false,
      default: false
    },
    goToLast: {
      type: Boolean,
      required: false,
      default: true
    },
    isDemo: {
      type: Boolean,
      required: false,
      default: false
    },
    attribution: {
      type: Boolean,
      required: false,
      default: true
    },
    values: {
      type: Object,
      required: false,
      default: () => ({})
    },
    withSendCopyButton: {
      type: Boolean,
      required: false,
      default: true
    },
    withDownloadButton: {
      type: Boolean,
      required: false,
      default: true
    },
    completedButton: {
      type: Object,
      required: false,
      default: () => ({})
    }
  },
  data () {
    return {
      isCompleted: false,
      isFormVisible: true,
      showFillAllRequiredFields: false,
      currentStep: 0,
      isSubmitting: false,
      submittedValues: {},
      recalculateButtonDisabledKey: ''
    }
  },
  computed: {
    currentStepFields () {
      return this.stepFields[this.currentStep]
    },
    queryParams () {
      return new URLSearchParams(window.location.search)
    },
    authenticityToken () {
      return document.querySelector('meta[name="csrf-token"]')?.content
    },
    submitterSlug () {
      return this.submitter.slug
    },
    previousSignatureValue () {
      const signatureField = [...this.fields].reverse().find((field) => field.type === 'signature' && !!this.values[field.uuid])

      return this.values[signatureField?.uuid]
    },
    previousInitialsValue () {
      const initialsField = [...this.fields].reverse().find((field) => field.type === 'initials' && !!this.values[field.uuid])

      return this.values[initialsField?.uuid]
    },
    isAnonymousChecboxes () {
      return this.currentField.type === 'checkbox' && this.currentStepFields.every((e) => !e.name) && this.currentStepFields.length > 4
    },
    isButtonDisabled () {
      if (this.recalculateButtonDisabledKey) {
        return this.isSubmitting ||
        (this.currentField.required && ['image', 'file'].includes(this.currentField.type) && !this.values[this.currentField.uuid]?.length) ||
        (this.currentField.required && this.currentField.type === 'signature' && !this.values[this.currentField.uuid]?.length && this.$refs.currentStep && !this.$refs.currentStep.isSignatureStarted) ||
        (this.currentField.required && this.currentField.type === 'initials' && !this.values[this.currentField.uuid]?.length && this.$refs.currentStep && !this.$refs.currentStep.isInitialsStarted)
      } else {
        return false
      }
    },
    currentField () {
      return this.currentStepFields[0]
    },
    stepFields () {
      return this.fields.filter((f) => !f.readonly).reduce((acc, f) => {
        const prevStep = acc[acc.length - 1]

        if (f.type === 'checkbox' && Array.isArray(prevStep) && prevStep[0].type === 'checkbox') {
          prevStep.push(f)
        } else {
          acc.push([f])
        }

        return acc
      }, [])
    },
    attachmentsIndex () {
      return this.attachments.reduce((acc, a) => {
        acc[a.uuid] = a

        return acc
      }, {})
    },
    submitPath () {
      return `/s/${this.submitterSlug}`
    }
  },
  mounted () {
    this.submittedValues = JSON.parse(JSON.stringify(this.values))

    this.fields.forEach((field) => {
      if (field.default_value && !field.readonly) {
        this.values[field.uuid] = field.default_value
      }
    })

    if (this.queryParams.get('field_uuid')) {
      const stepIndex = this.stepFields.findIndex((fields) => {
        return fields.some((f) => f.uuid === this.queryParams.get('field_uuid'))
      })

      this.currentStep = Math.max(stepIndex, 0)
    } else if (this.goToLast) {
      const requiredEmptyStepIndex = this.stepFields.indexOf(this.stepFields.find((fields) => fields.some((f) => f.required && !this.submittedValues[f.uuid])))
      const lastFilledStepIndex = this.stepFields.indexOf([...this.stepFields].reverse().find((fields) => fields.some((f) => !!this.submittedValues[f.uuid]))) + 1

      const indexesList = [this.stepFields.length - 1]

      if (requiredEmptyStepIndex !== -1) {
        indexesList.push(requiredEmptyStepIndex)
      }

      if (lastFilledStepIndex !== -1) {
        indexesList.push(lastFilledStepIndex)
      }

      this.currentStep = Math.min(...indexesList)
    }

    if (/iPhone|iPad|iPod/i.test(navigator.userAgent)) {
      this.$nextTick(() => {
        const root = this.$root.$el.parentNode.getRootNode()
        const scrollbox = root.getElementById('scrollbox')
        const parent = root.body || root.querySelector('div')

        parent.style.overflow = 'hidden'

        scrollbox.classList.add('h-full', 'overflow-y-auto')
        scrollbox.parentNode.classList.add('h-screen', 'overflow-y-auto')
        scrollbox.parentNode.style.maxHeight = '-webkit-fill-available'
      })
    }

    this.$nextTick(() => {
      this.recalculateButtonDisabledKey = Math.random()

      Promise.all([
        this.maybeTrackEmailClick(),
        this.maybeTrackSmsClick()
      ]).finally(() => {
        this.trackViewForm()
      })
    })
  },
  methods: {
    t,
    maybeTrackEmailClick () {
      const { queryParams } = this

      if (queryParams.has('t')) {
        const t = queryParams.get('t')

        queryParams.delete('t')
        const newUrl = [window.location.pathname, queryParams.toString()].filter(Boolean).join('?')
        window.history.replaceState({}, document.title, newUrl)

        return fetch(this.baseUrl + '/api/submitter_email_clicks', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            t,
            submitter_slug: this.submitterSlug
          })
        })
      } else {
        return Promise.resolve({})
      }
    },
    maybeTrackSmsClick () {
      const { queryParams } = this

      if (queryParams.has('c')) {
        const c = queryParams.get('c')

        queryParams.delete('c')
        const newUrl = [window.location.pathname, queryParams.toString()].filter(Boolean).join('?')
        window.history.replaceState({}, document.title, newUrl)

        return fetch(this.baseUrl + '/api/submitter_sms_clicks', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            c,
            submitter_slug: this.submitterSlug
          })
        })
      } else {
        return Promise.resolve({})
      }
    },
    trackViewForm () {
      fetch(this.baseUrl + '/api/submitter_form_views', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          submitter_slug: this.submitterSlug
        })
      })
    },
    goToStep (step, scrollToArea = false, clickUpload = false) {
      this.currentStep = this.stepFields.indexOf(step)
      this.showFillAllRequiredFields = false

      this.$nextTick(() => {
        this.recalculateButtonDisabledKey = Math.random()

        if (scrollToArea) {
          this.$refs.areas.scrollIntoField(step[0])
        }

        this.$refs.form.querySelector('input[type="date"], input[type="text"], select')?.focus()

        if (clickUpload && !this.values[this.currentField.uuid] && ['file', 'image'].includes(this.currentField.type)) {
          this.$refs.form.querySelector('input[type="file"]')?.click()
        }
      })
    },
    saveStep (formData) {
      const currentFieldUuid = this.currentField.uuid

      if (this.isCompleted) {
        return Promise.resolve({})
      } else {
        return fetch(this.baseUrl + this.submitPath, {
          method: 'POST',
          body: formData || new FormData(this.$refs.form)
        }).then((response) => {
          if (response.status === 200) {
            this.submittedValues[currentFieldUuid] = this.values[currentFieldUuid]
          }

          return response
        })
      }
    },
    async submitStep () {
      this.isSubmitting = true

      const stepPromise = ['signature', 'phone', 'initials', 'payment'].includes(this.currentField.type)
        ? this.$refs.currentStep.submit
        : () => Promise.resolve({})

      stepPromise().then(async () => {
        const emptyRequiredField = this.stepFields.find((fields, index) => {
          return index < this.currentStep && fields[0].required && (fields[0].type === 'phone' || !this.allowToSkip) && !this.submittedValues[fields[0].uuid]
        })

        const formData = new FormData(this.$refs.form)
        const isLastStep = this.currentStep === this.stepFields.length - 1

        if (isLastStep && !emptyRequiredField) {
          formData.append('completed', 'true')
        }

        await this.saveStep(formData).then(async (response) => {
          if (response.status === 422 || response.status === 500) {
            const data = await response.json()

            alert(data.error || 'Value is invalid')

            return Promise.reject(new Error(data.error))
          }

          if (isLastStep) {
            this.isSecondWalkthrough = true
          }

          const nextStep = (isLastStep && emptyRequiredField) || this.stepFields[this.currentStep + 1]

          if (nextStep) {
            this.goToStep(nextStep, true)

            if (emptyRequiredField === nextStep) {
              this.showFillAllRequiredFields = true
            }
          } else {
            this.isCompleted = true

            const respData = await response.text()

            if (respData) {
              this.onComplete(JSON.parse(respData))
            }
          }
        }).catch(error => {
          console.error(error)
        }).finally(() => {
          this.isSubmitting = false
        })
      }).catch(error => {
        console.log(error)
      }).finally(() => {
        this.isSubmitting = false
      })
    }
  }
}
</script>

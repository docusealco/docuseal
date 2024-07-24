<template>
  <FieldAreas
    ref="areas"
    :steps="stepFields"
    :values="values"
    :with-field-placeholder="withFieldPlaceholder"
    :submitter="submitter"
    :scroll-el="scrollEl"
    :with-signature-id="withSignatureId"
    :attachments-index="attachmentsIndex"
    :with-label="!isAnonymousChecboxes && showFieldNames"
    :current-step="currentStepFields"
    :scroll-padding="scrollPadding"
    @focus-step="[saveStep(), currentField.type !== 'checkbox' ? isFormVisible = true : '', goToStep($event, false, true)]"
  />
  <FormulaFieldAreas
    v-if="formulaFields.length"
    :fields="formulaFields"
    :values="values"
  />
  <button
    v-if="!isFormVisible"
    id="expand_form_button"
    class="btn btn-neutral flex text-white absolute bottom-0 w-full mb-3"
    style="width: 96%; margin-left: 2%"
    @click.prevent="[isFormVisible = true, scrollIntoField(currentField)]"
  >
    <template v-if="['initials', 'signature'].includes(currentField.type)">
      <IconWritingSign stroke-width="1.5" />
      {{ t('sign_now') }}
    </template>
    <template v-else-if="alwaysMinimize">
      {{ t('next') }}
    </template>
    <template v-else>
      {{ t('submit_form') }}
    </template>
    <IconArrowsDiagonal
      class="absolute right-0 mr-4"
      :width="20"
      :height="20"
    />
  </button>
  <div
    v-show="isFormVisible"
    id="form_container"
    class="shadow-md bg-base-100 absolute bottom-0 w-full border-base-200 border p-4 rounded"
    :class="{ 'md:bottom-4': isBreakpointMd }"
    :style="{ backgroundColor: backgroundColor }"
  >
    <button
      v-if="!isCompleted"
      id="minimize_form_button"
      class="absolute right-0 mr-2 mt-2 top-0 hidden md:block"
      :title="t('minimize')"
      @click.prevent="isFormVisible = false"
    >
      <IconArrowsDiagonalMinimize2
        :width="20"
        :height="20"
      />
    </button>
    <div
      :class="{ 'md:px-4': isBreakpointMd }"
    >
      <form
        v-if="!isCompleted"
        ref="form"
        :action="submitPath"
        method="post"
        class="mx-auto"
        :style="{ maxWidth: isBreakpointMd ? '582px' : '' }"
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
              :show-field-names="showFieldNames"
              :field="currentField"
              @focus="scrollIntoField(currentField)"
            />
          </div>
          <NumberStep
            v-else-if="currentField.type === 'number'"
            :key="currentField.uuid"
            v-model="values[currentField.uuid]"
            :show-field-names="showFieldNames"
            :field="currentField"
            @focus="scrollIntoField(currentField)"
          />
          <DateStep
            v-else-if="currentField.type === 'date'"
            :key="currentField.uuid"
            v-model="values[currentField.uuid]"
            :show-field-names="showFieldNames"
            :field="currentField"
            @focus="scrollIntoField(currentField)"
          />
          <div v-else-if="currentField.type === 'select'">
            <label
              v-if="showFieldNames && (currentField.name || currentField.title)"
              :for="currentField.uuid"
              dir="auto"
              class="label text-2xl"
              :class="{ 'mb-2': !currentField.description }"
            >
              <MarkdownContent
                v-if="currentField.title"
                :string="currentField.title"
              />
              <template v-else>
                {{ currentField.name }}
                <template v-if="!currentField.required">({{ t('optional') }})</template>
              </template>
            </label>
            <div
              v-else
              class="py-1"
            />
            <div
              v-if="currentField.description"
              dir="auto"
              class="mb-3 px-1"
            >
              <MarkdownContent :string="currentField.description" />
            </div>
            <AppearsOn :field="currentField" />
            <select
              :id="currentField.uuid"
              dir="auto"
              :required="currentField.required"
              class="select base-input !text-2xl w-full text-center font-normal"
              :name="`values[${currentField.uuid}]`"
              @change="values[currentField.uuid] = $event.target.value"
              @focus="scrollIntoField(currentField)"
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
              v-if="showFieldNames && (currentField.name || currentField.title)"
              :for="currentField.uuid"
              dir="auto"
              class="label text-2xl"
              :class="{ 'mb-2': !currentField.description }"
            >
              <MarkdownContent
                v-if="currentField.title"
                :string="currentField.title"
              />
              <template v-else>
                {{ currentField.name }}
                <template v-if="!currentField.required">({{ t('optional') }})</template>
              </template>
            </label>
            <div
              v-if="currentField.description"
              dir="auto"
              class="mb-3 px-1"
            >
              <MarkdownContent :string="currentField.description" />
            </div>
            <div class="flex w-full max-h-44 overflow-y-auto">
              <div
                v-if="!showFieldNames || (currentField.options.every((e) => !e.value) && currentField.options.length > 4)"
                class="text-xl px-1"
              >
                <span
                  @click="scrollIntoField(currentField)"
                >
                  {{ t('complete_hightlighted_checkboxes_and_click') }} <span class="font-semibold">{{ stepFields.length === currentStep + 1 ? t('submit') : t('next') }}</span>.
                </span>
              </div>
              <div
                class="space-y-3.5 mx-auto"
                :class="{ hidden: !showFieldNames || (currentField.options.every((e) => !e.value) && currentField.options.length > 4) }"
              >
                <div
                  v-for="(option, index) in currentField.options"
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
                      :value="option.value || `${t('option')} ${index + 1}`"
                      :required="currentField.required"
                      @click="scrollIntoField(currentField)"
                    >
                    <span class="text-xl">
                      {{ option.value || `${t('option')} ${index + 1}` }}
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
            :show-field-names="showFieldNames"
            :is-last-step="stepFields.length === currentStep + 1"
            :field="currentField"
          />
          <div
            v-else-if="currentField.type === 'checkbox'"
          >
            <div
              v-if="currentField.description"
              dir="auto"
              class="mb-3 px-1"
            >
              <MarkdownContent :string="currentField.description" />
            </div>
            <div
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
                <template v-if="isAnonymousChecboxes || !showFieldNames">
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
                        @click="[scrollIntoField(field), values[field.uuid] = !values[field.uuid]]"
                      >
                      <span
                        v-if="field.title"
                        class="text-xl"
                      >
                        <MarkdownContent :string="field.title" />
                      </span>
                      <span
                        v-else
                        class="text-xl"
                      >
                        {{ field.name || field.type + ' ' + (index + 1) }}
                      </span>
                    </label>
                  </div>
                </template>
              </div>
            </div>
          </div>
          <ImageStep
            v-else-if="currentField.type === 'image' || currentField.type === 'stamp'"
            :key="currentField.uuid"
            v-model="values[currentField.uuid]"
            :field="currentField"
            :dry-run="dryRun"
            :attachments-index="attachmentsIndex"
            :submitter-slug="submitterSlug"
            :show-field-names="showFieldNames"
            @attached="[attachments.push($event), scrollIntoField(currentField)]"
          />
          <SignatureStep
            v-else-if="currentField.type === 'signature'"
            ref="currentStep"
            :key="currentField.uuid"
            v-model="values[currentField.uuid]"
            :field="currentField"
            :previous-value="previousSignatureValueFor(currentField) || previousSignatureValue"
            :with-typed-signature="withTypedSignature"
            :remember-signature="rememberSignature"
            :attachments-index="attachmentsIndex"
            :button-text="buttonText"
            :dry-run="dryRun"
            :with-disclosure="withDisclosure"
            :with-qr-button="withQrButton"
            :submitter="submitter"
            :show-field-names="showFieldNames"
            @attached="attachments.push($event)"
            @start="scrollIntoField(currentField)"
            @minimize="isFormVisible = false"
          />
          <InitialsStep
            v-else-if="currentField.type === 'initials'"
            ref="currentStep"
            :key="currentField.uuid"
            v-model="values[currentField.uuid]"
            :field="currentField"
            :dry-run="dryRun"
            :previous-value="previousInitialsValue"
            :attachments-index="attachmentsIndex"
            :show-field-names="showFieldNames"
            :submitter-slug="submitterSlug"
            @attached="attachments.push($event)"
            @start="scrollIntoField(currentField)"
            @focus="scrollIntoField(currentField)"
            @minimize="isFormVisible = false"
          />
          <AttachmentStep
            v-else-if="currentField.type === 'file'"
            :key="currentField.uuid"
            v-model="values[currentField.uuid]"
            :dry-run="dryRun"
            :field="currentField"
            :attachments-index="attachmentsIndex"
            :submitter-slug="submitterSlug"
            @attached="[attachments.push($event), scrollIntoField(currentField)]"
          />
          <PhoneStep
            v-else-if="currentField.type === 'phone'"
            ref="currentStep"
            :key="currentField.uuid"
            v-model="values[currentField.uuid]"
            :field="currentField"
            :locale="language?.toLowerCase() || browserLanguage"
            :show-field-names="showFieldNames"
            :verified-value="phoneVerifiedValues[currentField.uuid]"
            :default-value="submitter.phone"
            :submitter-slug="submitterSlug"
            @focus="scrollIntoField(currentField)"
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
            @focus="scrollIntoField(currentField)"
            @submit="submitStep"
          />
        </div>
        <div
          v-if="currentField.type !== 'payment' || submittedValues[currentField.uuid]"
          :class="currentField.type === 'signature' ? 'mt-2' : 'mt-6 md:mt-8'"
        >
          <button
            id="submit_form_button"
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
              <span>
                {{ buttonText }}
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
        :completed-button="completedRedirectUrl ? {} : completedButton"
        :completed-message="completedRedirectUrl ? {} : completedMessage"
        :with-send-copy-button="withSendCopyButton && !completedRedirectUrl"
        :with-download-button="withDownloadButton && !completedRedirectUrl && !dryRun"
        :with-confetti="withConfetti"
        :can-send-email="canSendEmail && !!submitter.email"
        :submitter-slug="submitterSlug"
      />
      <div
        v-if="stepFields.length < 80"
        class="flex justify-center"
      >
        <div class="flex items-center mt-4 mb-1 flex-wrap">
          <a
            v-for="(step, index) in stepFields"
            :key="step[0].uuid"
            href="#"
            class="inline border border-base-300 h-3 w-3 rounded-full mx-1 mt-1"
            :class="{ 'bg-base-300': index === currentStep, 'bg-base-content': (index < currentStep && stepFields[index].every((f) => !f.required || ![null, undefined, ''].includes(values[f.uuid]))) || isCompleted, 'bg-white': index > currentStep }"
            @click.prevent="isCompleted ? '' : [saveStep(), goToStep(step, true)]"
          />
        </div>
      </div>
      <div
        v-else
        class="mt-5"
      />
    </div>
  </div>
</template>

<script>
import FieldAreas from './areas'
import FormulaFieldAreas from './formula_areas'
import ImageStep from './image_step'
import SignatureStep from './signature_step'
import InitialsStep from './initials_step'
import AttachmentStep from './attachment_step'
import MultiSelectStep from './multi_select_step'
import PhoneStep from './phone_step'
import PaymentStep from './payment_step'
import TextStep from './text_step'
import NumberStep from './number_step'
import DateStep from './date_step'
import MarkdownContent from './markdown_content'
import FormCompleted from './completed'
import { IconInnerShadowTop, IconArrowsDiagonal, IconWritingSign, IconArrowsDiagonalMinimize2 } from '@tabler/icons-vue'
import AppearsOn from './appears_on'
import i18n from './i18n'

const isEmpty = (obj) => {
  if (obj == null) return true

  if (Array.isArray(obj)) {
    return obj.length === 0
  }

  if (typeof obj === 'string') {
    return obj.trim().length === 0
  }

  if (typeof obj === 'object') {
    return Object.keys(obj).length === 0
  }

  if (obj === false) {
    return true
  }

  return false
}

export default {
  name: 'SubmissionForm',
  components: {
    FieldAreas,
    ImageStep,
    SignatureStep,
    AppearsOn,
    IconWritingSign,
    AttachmentStep,
    InitialsStep,
    MultiSelectStep,
    IconInnerShadowTop,
    DateStep,
    IconArrowsDiagonal,
    TextStep,
    NumberStep,
    FormulaFieldAreas,
    PhoneStep,
    MarkdownContent,
    PaymentStep,
    IconArrowsDiagonalMinimize2,
    FormCompleted
  },
  provide () {
    return {
      baseUrl: this.baseUrl,
      scrollIntoArea: this.scrollIntoArea,
      scrollIntoField: this.scrollIntoField,
      t: this.t
    }
  },
  props: {
    submitter: {
      type: Object,
      required: true
    },
    withSignatureId: {
      type: Boolean,
      required: false,
      default: false
    },
    scrollPadding: {
      type: String,
      required: false,
      default: '-80px'
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
    withFieldPlaceholder: {
      type: Boolean,
      required: false,
      default: false
    },
    scrollEl: {
      type: Object,
      required: false,
      default: null
    },
    onComplete: {
      type: Function,
      required: false,
      default () {
        return () => {}
      }
    },
    expand: {
      type: Boolean,
      required: false,
      default: null
    },
    rememberSignature: {
      type: Boolean,
      required: false,
      default: false
    },
    minimize: {
      type: Boolean,
      required: false,
      default: false
    },
    withDisclosure: {
      type: Boolean,
      required: false,
      default: false
    },
    reuseSignature: {
      type: Boolean,
      required: false,
      default: true
    },
    withConfetti: {
      type: Boolean,
      required: false,
      default: false
    },
    autoscrollFields: {
      type: Boolean,
      required: false,
      default: true
    },
    showFieldNames: {
      type: Boolean,
      required: false,
      default: true
    },
    withQrButton: {
      type: Boolean,
      required: false,
      default: false
    },
    withTypedSignature: {
      type: Boolean,
      required: false,
      default: true
    },
    isBreakpointMd: {
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
    previousSignatureValue: {
      type: String,
      required: false,
      default: ''
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
    dryRun: {
      type: Boolean,
      required: false,
      default: false
    },
    attribution: {
      type: Boolean,
      required: false,
      default: true
    },
    language: {
      type: String,
      required: false,
      default: ''
    },
    values: {
      type: Object,
      required: false,
      default: () => ({})
    },
    authenticityToken: {
      type: String,
      required: false,
      default: ''
    },
    i18n: {
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
    completedRedirectUrl: {
      type: String,
      required: false,
      default: ''
    },
    completedButton: {
      type: Object,
      required: false,
      default: () => ({})
    },
    completedMessage: {
      type: Object,
      required: false,
      default: () => ({})
    }
  },
  data () {
    return {
      isCompleted: false,
      isFormVisible: this.expand !== false,
      showFillAllRequiredFields: false,
      currentStep: 0,
      enableScrollIntoField: true,
      phoneVerifiedValues: {},
      orientation: screen?.orientation?.type,
      isSubmitting: false,
      submittedValues: {},
      recalculateButtonDisabledKey: ''
    }
  },
  computed: {
    isMobile () {
      return /android|iphone|ipad/i.test(navigator.userAgent)
    },
    buttonText () {
      if (this.alwaysMinimize || this.stepFields.length === this.currentStep + 1) {
        return this.t('submit')
      } else {
        return this.t('next')
      }
    },
    alwaysMinimize () {
      return this.minimize || (this.orientation?.includes('landscape') && this.isMobile && parseInt(window.innerHeight) < 550)
    },
    currentStepFields () {
      return this.stepFields[this.currentStep] || []
    },
    browserLanguage () {
      return (navigator.language || navigator.userLanguage || 'en').split('-')[0]
    },
    queryParams () {
      return new URLSearchParams(window.location.search)
    },
    submitterSlug () {
      return this.submitter.slug
    },
    fieldsUuidIndex () {
      return this.fields.reduce((acc, f) => {
        acc[f.uuid] = f

        return acc
      }, {})
    },
    previousInitialsValue () {
      if (this.reuseSignature !== false) {
        const initialsField = [...this.fields].reverse().find((field) => field.type === 'initials' && !!this.values[field.uuid])

        return this.values[initialsField?.uuid]
      } else {
        return null
      }
    },
    isAnonymousChecboxes () {
      return this.currentField.type === 'checkbox' && this.currentStepFields.every((e) => !e.name && !e.required) && this.currentStepFields.length > 4
    },
    isButtonDisabled () {
      if (this.recalculateButtonDisabledKey) {
        return this.isSubmitting ||
        (this.currentField.required && ['image', 'file', 'multiple'].includes(this.currentField.type) && !this.values[this.currentField.uuid]?.length) ||
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

        if (this.checkFieldConditions(f)) {
          if (f.type === 'checkbox' && Array.isArray(prevStep) && prevStep[0].type === 'checkbox' && !f.description) {
            prevStep.push(f)
          } else {
            acc.push([f])
          }
        }

        return acc
      }, [])
    },
    formulaFields () {
      return this.fields.filter((f) => f.preferences?.formula)
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
  watch: {
    expand (value) {
      this.isFormVisible = value
    },
    currentStepFields (value) {
      if (isEmpty(value) && this.currentStep > 0) {
        this.currentStep -= 1
      }
    }
  },
  beforeUnmount () {
    screen?.orientation?.removeEventListener('change', this.onOrientationChange)
  },
  mounted () {
    this.submittedValues = JSON.parse(JSON.stringify(this.values))

    screen?.orientation.addEventListener('change', this.onOrientationChange)

    this.fields.forEach((field) => {
      if (field.default_value && !field.readonly) {
        this.values[field.uuid] ||= field.default_value
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

    if (document.body?.clientWidth >= 768 && this.expand !== true && ['signature', 'initials', 'file', 'image'].includes(this.currentField?.type)) {
      this.isFormVisible = false
    }

    if (this.alwaysMinimize) {
      this.isFormVisible = false
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

      if (!this.dryRun) {
        Promise.all([
          this.maybeTrackEmailClick(),
          this.maybeTrackSmsClick()
        ]).finally(() => {
          this.trackViewForm()
        })
      }
    })
  },
  methods: {
    t (key) {
      return this.i18n[key] || i18n[this.language?.toLowerCase()]?.[key] || i18n[this.browserLanguage]?.[key] || i18n.en[key] || key
    },
    onOrientationChange (event) {
      this.orientation = event.target.type
    },
    checkFieldConditions (field) {
      if (field.conditions?.length) {
        return field.conditions.reduce((acc, c) => {
          if (['empty', 'unchecked'].includes(c.action)) {
            return acc && isEmpty(this.values[c.field_uuid])
          } else if (['not_empty', 'checked'].includes(c.action)) {
            return acc && !isEmpty(this.values[c.field_uuid])
          } else if (['equal', 'contains'].includes(c.action)) {
            const field = this.fieldsUuidIndex[c.field_uuid]
            const option = field.options.find((o) => o.uuid === c.value)
            const values = [this.values[c.field_uuid]].flat()

            return acc && values.includes(this.optionValue(option, field.options.indexOf(option)))
          } else if (['not_equal', 'does_not_contain'].includes(c.action)) {
            const field = this.fieldsUuidIndex[c.field_uuid]
            const option = field.options.find((o) => o.uuid === c.value)
            const values = [this.values[c.field_uuid]].flat()

            return acc && !values.includes(this.optionValue(option, field.options.indexOf(option)))
          } else {
            return acc
          }
        }, true)
      } else {
        return true
      }
    },
    optionValue (option, index) {
      if (option.value) {
        return option.value
      } else {
        return `${this.t('option')} ${index + 1}`
      }
    },
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
    previousSignatureValueFor (field) {
      if (this.reuseSignature !== false) {
        const signatureField = [...this.fields].reverse().find((f) =>
          f.type === 'signature' && field.preferences?.format === f.preferences?.format && !!this.values[f.uuid]
        )

        return this.values[signatureField?.uuid]
      } else {
        return null
      }
    },
    goToStep (step, scrollToArea = false, clickUpload = false) {
      this.currentStep = this.stepFields.indexOf(step)
      this.showFillAllRequiredFields = false

      this.$nextTick(() => {
        this.recalculateButtonDisabledKey = Math.random()

        if (!this.isCompleted) {
          if (scrollToArea) {
            this.scrollIntoField(step[0])
          }

          this.enableScrollIntoField = false
          this.$refs.form.querySelector('input[type="date"], input[type="number"], input[type="text"], select')?.focus()
          this.enableScrollIntoField = true

          if (clickUpload && !this.values[this.currentField.uuid] && ['file', 'image'].includes(this.currentField.type)) {
            this.$refs.form.querySelector('input[type="file"]')?.click()
          }
        }
      })
    },
    saveStep (formData) {
      const currentFieldUuids = this.currentStepFields.map((f) => f.uuid)
      const currentFieldType = this.currentField.type

      if (this.dryRun) {
        currentFieldUuids.forEach((fieldUuid) => {
          this.submittedValues[fieldUuid] = this.values[fieldUuid]
        })

        return Promise.resolve({})
      } else if (this.isCompleted) {
        return Promise.resolve({})
      } else {
        return fetch(this.baseUrl + this.submitPath, {
          method: 'POST',
          body: formData || new FormData(this.$refs.form)
        }).then((response) => {
          if (response.status === 200) {
            currentFieldUuids.forEach((fieldUuid) => {
              this.submittedValues[fieldUuid] = this.values[fieldUuid]

              if (currentFieldType === 'phone') {
                this.phoneVerifiedValues[fieldUuid] = this.values[fieldUuid]
              }
            })
          }

          return response
        })
      }
    },
    scrollIntoField (field) {
      if (this.enableScrollIntoField) {
        return this.$refs.areas.scrollIntoField(field)
      }
    },
    scrollIntoArea (area) {
      return this.$refs.areas.scrollIntoArea(area)
    },
    async submitStep () {
      this.isSubmitting = true

      const stepPromise = ['signature', 'phone', 'initials', 'payment'].includes(this.currentField.type)
        ? this.$refs.currentStep.submit
        : () => Promise.resolve({})

      stepPromise().then(async () => {
        const emptyRequiredField = this.stepFields.find((fields, index) => {
          if (index >= this.currentStep) {
            return false
          }

          return fields.some((f) => {
            return f.required && (f.type === 'phone' || !this.allowToSkip) && isEmpty(this.submittedValues[f.uuid])
          })
        })

        const formData = new FormData(this.$refs.form)
        const isLastStep = this.currentStep === this.stepFields.length - 1

        if (isLastStep && !emptyRequiredField) {
          formData.append('completed', 'true')
        }

        let saveStepRequest

        if (!isLastStep && this.phoneVerifiedValues[this.currentField.uuid] && this.phoneVerifiedValues[this.currentField.uuid] === this.values[this.currentField.uuid]) {
          saveStepRequest = Promise.resolve({})
        } else {
          saveStepRequest = this.saveStep(formData)
        }

        await saveStepRequest.then(async (response) => {
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
            if (this.alwaysMinimize) {
              this.isFormVisible = false
            }

            this.goToStep(nextStep, this.autoscrollFields)

            if (emptyRequiredField === nextStep) {
              this.showFillAllRequiredFields = true
            }
          } else {
            this.isCompleted = true

            const respData = await response.text()

            if (respData) {
              this.onComplete(JSON.parse(respData))
            }

            if (this.completedRedirectUrl) {
              window.location.href = this.completedRedirectUrl
            }
          }
        }).catch(error => {
          console.error(error)
        }).finally(() => {
          this.isSubmitting = false
        })
      }).catch(error => {
        if (error?.message === 'Image too small') {
          alert('Signature is too small - please redraw.')
        } else {
          console.log(error)
        }
      }).finally(() => {
        this.isSubmitting = false
      })
    }
  }
}
</script>

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
  <FieldAreas
    :steps="readonlyConditionalFields.map((e) => [e])"
    :values="readonlyConditionalFieldValues"
    :submitter="submitter"
    :attachments-index="attachmentsIndex"
    :submittable="false"
  />
  <FormulaFieldAreas
    v-if="formulaFields.length"
    :fields="formulaFields"
    :readonly-values="readonlyConditionalFieldValues"
    :values="values"
  />
  <Teleport
    v-if="completeButtonToRef"
    :to="completeButtonToRef"
  >
    <span
      v-if="(emptyValueRequiredStep && ((stepFields.length - 1) !== currentStep || currentStepFields !== emptyValueRequiredStep)) || isCompleted"
      class="tooltip-left"
      :class="{ tooltip: !isCompleted }"
      :data-tip="t('fill_all_required_fields_to_complete')"
    >
      <button
        class="btn btn-sm btn-neutral text-white px-4 w-full flex justify-center btn-disabled pointer-events-auto"
        @click="[isFormVisible = true, !isCompleted && goToStep(stepFields.indexOf(emptyValueRequiredStep), true, false)]"
      >
        {{ t('complete') }}
      </button>
    </span>
    <button
      v-else
      id="complete_form_button"
      class="btn btn-sm btn-neutral text-white px-4 w-full flex justify-center"
      form="steps_form"
      type="submit"
      name="completed"
      value="true"
      :disabled="isSubmittingComplete"
    >
      <span class="flex items-center">
        <IconInnerShadowTop
          v-if="isSubmittingComplete"
          class="mr-1 animate-spin w-5 h-5"
        />
        <span>
          {{ t('complete') }}
        </span>
      </span>
    </button>
  </Teleport>
  <button
    v-if="!isFormVisible"
    id="expand_form_button"
    class="btn btn-neutral flex text-white absolute bottom-0 w-full mb-3 expand-form-button"
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
    <template v-else-if="isShowContinue">
      {{ t('continue') }}
    </template>
    <template v-else>
      {{ t('start_now') }}
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
    class="shadow-md bg-base-100 absolute bottom-0 w-full border-base-200 border p-4 rounded form-container overflow-hidden"
    :class="{ 'md:bottom-4': isBreakpointMd }"
    :style="{ backgroundColor: backgroundColor }"
  >
    <button
      v-if="!isCompleted"
      id="minimize_form_button"
      class="absolute right-0 top-0 minimize-form-button"
      :class="currentField?.description?.length > 100 ? 'mr-1 mt-1 md:mr-2 md:mt-2': 'mr-2 mt-2 hidden md:block'"
      :title="t('minimize')"
      @click.prevent="minimizeForm"
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
        v-if="!isCompleted && !isInvite"
        id="steps_form"
        ref="form"
        :action="submitPath"
        method="post"
        class="mx-auto steps-form"
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
            @submit="!isSubmitting && submitStep()"
            @focus="scrollIntoField(currentField)"
          />
          <div v-else-if="currentField.type === 'select'">
            <label
              v-if="showFieldNames && (currentField.name || currentField.title)"
              :for="currentField.uuid"
              dir="auto"
              class="label text-xl sm:text-2xl py-0 mb-2 sm:mb-3.5 field-name-label"
              :class="{ 'mb-2': !currentField.description }"
            >
              <MarkdownContent
                v-if="currentField.title"
                :string="currentField.title"
              />
              <template v-else>
                {{ currentField.name }}
              </template>
              <template v-if="!currentField.required">
                <span :class="{ 'hidden sm:inline': (currentField.title || currentField.name).length > 20 }">
                  ({{ t('optional') }})
                </span>
              </template>
            </label>
            <div
              v-else
              class="py-1"
            />
            <div
              v-if="currentField.description"
              dir="auto"
              class="mb-3 px-1 field-description-text"
            >
              <MarkdownContent :string="currentField.description" />
            </div>
            <AppearsOn :field="currentField" />
            <select
              :id="currentField.uuid"
              dir="auto"
              :required="currentField.required"
              class="select base-input !text-2xl w-full text-center font-normal"
              :class="{ 'text-gray-300': !values[currentField.uuid] }"
              :name="`values[${currentField.uuid}]`"
              @change="values[currentField.uuid] = $event.target.value"
              @focus="scrollIntoField(currentField)"
            >
              <option
                value=""
                :selected="!values[currentField.uuid]"
                class="text-gray-300"
              >
                {{ t('select_your_option') }}
              </option>
              <option
                v-for="option in currentField.options"
                :key="option.uuid"
                :selected="values[currentField.uuid] == option.value"
                :value="option.value"
                class="text-base-content"
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
              class="label text-xl sm:text-2xl py-0 mb-2 sm:mb-3.5 field-name-label"
              :class="{ 'mb-2': !currentField.description }"
            >
              <MarkdownContent
                v-if="currentField.title"
                :string="currentField.title"
              />
              <template v-else>
                {{ currentField.name }}
              </template>
              <template v-if="!currentField.required">
                <span :class="{ 'hidden sm:inline': (currentField.title || currentField.name).length > 20 }">
                  ({{ t('optional') }})
                </span>
              </template>
            </label>
            <div
              v-if="currentField.description"
              dir="auto"
              class="mb-3 px-1 field-description-text"
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
                  {{ t('complete_hightlighted_checkboxes_and_click') }} <span class="font-semibold">{{ submitButtonText }}</span>.
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
                    class="flex items-center space-x-3 radio-label"
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
              class="mb-3 px-1 field-description-text"
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
                    {{ t('complete_hightlighted_checkboxes_and_click') }} <span class="font-semibold">{{ submitButtonText }}</span>.
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
                      class="flex items-center space-x-3 checkbox-label"
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
            :reason="values[currentField.preferences?.reason_field_uuid]"
            :field="currentField"
            :previous-value="previousSignatureValueFor(currentField) || previousSignatureValue"
            :with-typed-signature="withTypedSignature"
            :remember-signature="rememberSignature"
            :attachments-index="attachmentsIndex"
            :require-signing-reason="requireSigningReason"
            :button-text="submitButtonText"
            :dry-run="dryRun"
            :with-disclosure="withDisclosure"
            :with-qr-button="withQrButton"
            :submitter="submitter"
            :show-field-names="showFieldNames"
            @update:reason="values[currentField.preferences?.reason_field_uuid] = $event"
            @attached="attachments.push($event)"
            @start="scrollIntoField(currentField)"
            @minimize="minimizeForm"
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
            @minimize="minimizeForm"
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
            @submit="!isSubmitting && submitStep()"
          />
          <PaymentStep
            v-else-if="currentField.type === 'payment'"
            ref="currentStep"
            :key="currentField.uuid"
            v-model="values[currentField.uuid]"
            :field="currentField"
            :submitter-slug="submitterSlug"
            :values="values"
            @attached="attachments.push($event)"
            @focus="scrollIntoField(currentField)"
            @submit="!isSubmitting && submitStep()"
          />
          <VerificationStep
            v-else-if="currentField.type === 'verification'"
            ref="currentStep"
            :key="currentField.uuid"
            :locale="language?.toLowerCase() || browserLanguage"
            :submitter="submitter"
            :empty-value-required-step="emptyValueRequiredStep"
            :field="currentField"
            :submitter-slug="submitterSlug"
            :values="values"
            @focus="scrollIntoField(currentField)"
            @submit="!isSubmitting && submitStep()"
          />
        </div>
        <div
          v-if="(currentField.type !== 'payment' && currentField.type !== 'verification') || submittedValues[currentField.uuid]"
          :class="currentField.type === 'signature' ? 'mt-2' : 'mt-4 md:mt-6'"
        >
          <button
            id="submit_form_button"
            ref="submitButton"
            type="submit"
            class="base-button w-full flex justify-center submit-form-button"
            :disabled="isButtonDisabled"
          >
            <span class="flex">
              <IconInnerShadowTop
                v-if="isSubmitting"
                class="mr-1 animate-spin"
              />
              <span>
                {{ submitButtonText }}
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
      <InviteForm
        v-else-if="isInvite"
        :submitters="inviteSubmitters"
        :optional-submitters="optionalInviteSubmitters"
        :submitter-slug="submitterSlug"
        :authenticity-token="authenticityToken"
        :url="baseUrl + submitPath + '/invite'"
        :style="{ maxWidth: isBreakpointMd ? '582px' : '' }"
        @success="[isInvite = false, performComplete($event)]"
      />
      <FormCompleted
        v-else
        :is-demo="isDemo"
        :attribution="attribution"
        :has-signature-fields="stepFields.some((fields) => fields.some((f) => ['signature', 'initials'].includes(f.type)))"
        :has-multiple-documents="hasMultipleDocuments"
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
        class="flex justify-center mt-3 sm:mt-4 mb-0 sm:mb-1"
      >
        <div class="flex items-center flex-wrap steps-progress">
          <a
            v-for="(step, index) in stepFields"
            :key="step[0].uuid"
            href="#"
            class="inline border border-base-300 h-3 w-3 rounded-full mx-1 mt-1"
            :class="{ 'bg-base-300 steps-progress-current': index === currentStep, 'bg-base-content': (index < currentStep && stepFields[index].every((f) => !f.required || ![null, undefined, ''].includes(values[f.uuid]))) || isCompleted, 'bg-white': index > currentStep }"
            @click.prevent="isCompleted ? '' : [saveStep(), goToStep(index, true)]"
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
import VerificationStep from './verification_step'
import TextStep from './text_step'
import NumberStep from './number_step'
import DateStep from './date_step'
import MarkdownContent from './markdown_content'
import InviteForm from './invite_form'
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
    VerificationStep,
    InviteForm,
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
    inviteSubmitters: {
      type: Array,
      required: false,
      default: () => []
    },
    optionalInviteSubmitters: {
      type: Array,
      required: false,
      default: () => []
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
    orderAsOnPage: {
      type: Boolean,
      required: false,
      default: false
    },
    requireSigningReason: {
      type: Boolean,
      required: false,
      default: false
    },
    canSendEmail: {
      type: Boolean,
      required: false,
      default: false
    },
    completeButtonToRef: {
      type: Object,
      required: false,
      default: null
    },
    schema: {
      type: Array,
      required: false,
      default: () => []
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
      isInvite: false,
      isFormVisible: this.expand !== false,
      showFillAllRequiredFields: false,
      currentStep: 0,
      isShowContinue: false,
      enableScrollIntoField: true,
      phoneVerifiedValues: {},
      orientation: screen?.orientation?.type,
      isSubmitting: false,
      isSubmittingComplete: false,
      submittedValues: {},
      recalculateButtonDisabledKey: ''
    }
  },
  computed: {
    isMobile () {
      const isMobileSafariIos = 'ontouchstart' in window && navigator.maxTouchPoints > 0 && /AppleWebKit/i.test(navigator.userAgent)

      return isMobileSafariIos || /android|iphone|ipad/i.test(navigator.userAgent)
    },
    readonlyConditionalFieldValues () {
      return this.readonlyConditionalFields.reduce((acc, f) => {
        acc[f.uuid] = (this.values[f.uuid] || f.default_value)

        return acc
      }, {})
    },
    attachmentConditionsIndex () {
      return this.schema.reduce((acc, item) => {
        if (item.conditions?.length) {
          if (item.conditions.every((c) => this.fieldsUuidIndex[c.field_uuid])) {
            acc[item.attachment_uuid] = this.checkFieldConditions(item)
          } else {
            acc[item.attachment_uuid] = true
          }
        } else {
          acc[item.attachment_uuid] = true
        }

        return acc
      }, {})
    },
    emptyValueRequiredStep () {
      return this.stepFields.find((fields, index) => {
        return fields.some((f) => {
          return f.required && isEmpty(this.values[f.uuid])
        })
      })
    },
    submitButtonText () {
      if (this.alwaysMinimize) {
        return this.t('submit')
      } else if (this.stepFields.length === this.currentStep + 1) {
        if (this.currentField.type === 'signature') {
          return this.t('sign_and_complete')
        } else {
          return this.t('complete')
        }
      } else {
        return this.t('next')
      }
    },
    alwaysMinimize () {
      return this.minimize || (this.orientation?.includes('landscape') && this.isMobile && parseInt(window.innerHeight) < 550)
    },
    hasMultipleDocuments () {
      return Object.keys(
        this.stepFields.reduce((acc, fields) => {
          fields.forEach((f) => {
            f.areas?.forEach((a) => {
              acc[a.attachment_uuid] = 1
            })
          })
          return acc
        }, {})
      ).filter(Boolean).length > 1
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
    readonlyConditionalFields () {
      return this.fields.filter((f) => f.readonly && f.conditions?.length && this.checkFieldConditions(f) && this.checkFieldDocumentsConditions(f))
    },
    stepFields () {
      const verificationFields = []

      const sortedFields = this.fields.reduce((acc, f) => {
        if (f.type === 'verification') {
          verificationFields.push(f)
        } else if (!f.readonly) {
          acc.push(f)
        }

        return acc
      }, [])

      if (this.orderAsOnPage) {
        const fieldAreasIndex = {}
        const attachmentUuids = Object.keys(this.attachmentConditionsIndex)

        const sortArea = (aArea, bArea) => {
          if (aArea.attachment_uuid === bArea.attachment_uuid) {
            if (aArea.page === bArea.page) {
              if (Math.abs(aArea.y - bArea.y) < 0.01) {
                if (aArea.x === bArea.x) {
                  return 0
                } else {
                  return aArea.x - bArea.x
                }
              } else {
                return aArea.y - bArea.y
              }
            } else {
              return aArea.page - bArea.page
            }
          } else {
            return attachmentUuids.indexOf(aArea.attachment_uuid) - attachmentUuids.indexOf(bArea.attachment_uuid)
          }
        }

        sortedFields.sort((aField, bField) => {
          const aArea = (fieldAreasIndex[aField.uuid] ||= [...(aField.areas || [])].sort(sortArea)[0])
          const bArea = (fieldAreasIndex[bField.uuid] ||= [...(bField.areas || [])].sort(sortArea)[0])

          return sortArea(aArea, bArea)
        })
      }

      if (verificationFields.length) {
        sortedFields.push(verificationFields.pop())
      }

      return sortedFields.reduce((acc, f) => {
        const prevStep = acc[acc.length - 1]

        if (this.checkFieldConditions(f) && this.checkFieldDocumentsConditions(f)) {
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
      return this.fields.filter((f) => f.preferences?.formula && f.type !== 'payment' && this.checkFieldConditions(f) && this.checkFieldDocumentsConditions(f))
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
    },
    attachmentConditionsIndex: {
      deep: true,
      immediate: true,
      handler (value) {
        this.$nextTick(() => {
          const root = this.$root.$el.parentNode.getRootNode()

          for (const key in value) {
            const doc = root.querySelector(`[id="document-${key}"`)

            if (doc) {
              doc.classList.toggle('hidden', !value[key])
            }
          }
        })
      }
    }
  },
  beforeUnmount () {
    screen?.orientation?.removeEventListener('change', this.onOrientationChange)
  },
  mounted () {
    this.submittedValues = JSON.parse(JSON.stringify(this.values))

    screen?.orientation?.addEventListener('change', this.onOrientationChange)

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
      this.minimizeForm()
    }

    if (this.alwaysMinimize) {
      this.minimizeForm()
    }

    const isMobile = 'ontouchstart' in window && navigator.maxTouchPoints > 0 && /AppleWebKit|android/i.test(navigator.userAgent)

    if (isMobile || /iPhone|iPad|iPod/i.test(navigator.userAgent)) {
      this.$nextTick(() => {
        const root = this.$root.$el.parentNode.getRootNode()
        const scrollbox = root.getElementById('scrollbox')
        const parent = root.body || root.querySelector('div')

        parent.style.overflow = 'hidden'

        scrollbox.classList.add('h-full', 'overflow-y-auto')
        scrollbox.parentNode.classList.add('h-screen', 'h-[100dvh]', 'overflow-y-auto')
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
    checkFieldDocumentsConditions (field) {
      if (field.areas?.length) {
        return field.areas.some((area) => {
          return this.attachmentConditionsIndex[area.attachment_uuid]
        })
      } else {
        return true
      }
    },
    checkFieldConditions (field) {
      if (field.conditions?.length) {
        const result = field.conditions.reduce((acc, cond) => {
          if (cond.operation === 'or') {
            acc.push(acc.pop() || this.checkFieldCondition(cond))
          } else {
            acc.push(this.checkFieldCondition(cond))
          }

          return acc
        }, [])

        return !result.includes(false)
      } else {
        return true
      }
    },
    checkFieldCondition (condition) {
      const field = this.fieldsUuidIndex[condition.field_uuid]

      if (['not_empty', 'checked', 'equal', 'contains'].includes(condition.action) && field && !this.checkFieldConditions(field)) {
        return false
      }

      const defaultValue = !field || isEmpty(field.default_value) ? null : field.default_value

      if (['empty', 'unchecked'].includes(condition.action)) {
        return isEmpty(this.values[condition.field_uuid] ?? defaultValue)
      } else if (['not_empty', 'checked'].includes(condition.action)) {
        return !isEmpty(this.values[condition.field_uuid] ?? defaultValue)
      } else if (['equal', 'contains'].includes(condition.action) && field) {
        if (field.options) {
          const option = field.options.find((o) => o.uuid === condition.value)
          const values = [this.values[condition.field_uuid] ?? defaultValue].flat()

          return values.includes(this.optionValue(option, field.options.indexOf(option)))
        } else {
          return [this.values[condition.field_uuid] ?? defaultValue].flat().includes(condition.value)
        }
      } else if (['not_equal', 'does_not_contain'].includes(condition.action) && field) {
        const option = field.options.find((o) => o.uuid === condition.value)
        const values = [this.values[condition.field_uuid] ?? defaultValue].flat()

        return !values.includes(this.optionValue(option, field.options.indexOf(option)))
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
    goToStep (stepIndex, scrollToArea = false, clickUpload = false) {
      this.currentStep = stepIndex
      this.showFillAllRequiredFields = false

      this.$nextTick(() => {
        this.recalculateButtonDisabledKey = Math.random()

        if (!this.isCompleted) {
          if (scrollToArea) {
            this.$nextTick(() => {
              setTimeout(() => this.scrollIntoField(this.currentField), 1)
            })
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

      if (!formData && !this.$refs.form.checkValidity() && currentFieldUuids.every((fieldUuid) => isEmpty(this.submittedValues[fieldUuid]) || !isEmpty(this.values[fieldUuid]))) {
        return
      }

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
    async submitStep (e) {
      this.isSubmitting = true

      const forceComplete = e?.submitter?.getAttribute('name') === 'completed'

      if (forceComplete) {
        this.isSubmittingComplete = true
      }

      const submitStep = this.currentStep

      const stepPromise = ['signature', 'phone', 'initials', 'payment', 'verification'].includes(this.currentField.type)
        ? this.$refs.currentStep.submit
        : () => Promise.resolve({})

      stepPromise().then(async () => {
        const emptyRequiredField = this.stepFields.find((fields, index) => {
          if (forceComplete ? index === submitStep : index >= submitStep) {
            return false
          }

          return fields.some((f) => {
            return f.required && (f.type === 'phone' || !this.allowToSkip) && isEmpty(this.submittedValues[f.uuid])
          })
        })

        const formData = new FormData(this.$refs.form)
        const isLastStep = (submitStep === this.stepFields.length - 1) || forceComplete

        if (isLastStep && !emptyRequiredField && !this.inviteSubmitters.length && !this.optionalInviteSubmitters.length) {
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

            if (data.field_uuid) {
              const field = this.fieldsUuidIndex[data.field_uuid]

              if (field) {
                const step = this.stepFields.findIndex((fields) => fields.includes(field))

                if (step !== -1) {
                  this.goToStep(step, this.autoscrollFields)

                  this.showFillAllRequiredFields = true
                }
              }

              return Promise.reject(new Error('Required field: ' + data.field_uuid))
            } else if (data.error) {
              const i18nKey = data.error.replace(/\s+/g, '_').toLowerCase()

              alert(this.t(i18nKey) !== i18nKey ? this.t(i18nKey) : data.error)
            } else {
              alert(this.t('value_is_invalid'))
            }

            return Promise.reject(new Error(data.error))
          }

          const nextStep = (isLastStep && emptyRequiredField) || (forceComplete ? null : this.stepFields[submitStep + 1])

          if (nextStep) {
            if (this.alwaysMinimize) {
              this.minimizeForm()
            }

            this.goToStep(this.stepFields.indexOf(nextStep), this.autoscrollFields)

            if (emptyRequiredField === nextStep) {
              this.showFillAllRequiredFields = true
            }
          } else if (this.inviteSubmitters.length || this.optionalInviteSubmitters.length) {
            this.isInvite = true
          } else {
            this.performComplete(response)
          }
        }).catch(error => {
          console.error(error)
        }).finally(() => {
          this.isSubmitting = false
          this.isSubmittingComplete = false
        })
      }).catch(error => {
        console.log(error)
      }).finally(() => {
        this.isSubmitting = false
        this.isSubmittingComplete = false
      })
    },
    minimizeForm () {
      this.isFormVisible = false
      this.isShowContinue = true
    },
    async performComplete (resp) {
      this.isCompleted = true

      if (resp?.text) {
        const respData = await resp.text()

        if (respData) {
          this.onComplete(JSON.parse(respData))
        }
      }

      if (this.completedRedirectUrl) {
        window.location.href = this.completedRedirectUrl
      }
    }
  }
}
</script>

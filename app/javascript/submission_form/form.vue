<template>
  <FieldAreas
    ref="areas"
    :steps="stepFields"
    :values="values"
    :attachments-index="attachmentsIndex"
    :current-step="currentStepFields"
    @focus-step="[saveStep(), goToStep($event, false, true), currentField.type !== 'checkbox' ? isFormVisible = true : '']"
  />
  <button
    v-if="!isFormVisible"
    class="btn btn-neutral text-white absolute rounded-none border-x-0 md:border md:rounded-full bottom-0 w-full md:mb-4 text-base"
    @click.prevent="isFormVisible = true"
  >
    Submit Form
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
            <label
              v-if="currentField.name"
              :for="currentField.uuid"
              class="label text-2xl mb-2"
            >{{ currentField.name }}
              <template v-if="!currentField.required">(optional)</template>
            </label>
            <div
              v-else
              class="py-1"
            />
            <div>
              <input
                :id="currentField.uuid"
                v-model="values[currentField.uuid]"
                class="base-input !text-2xl w-full"
                :required="currentField.required"
                :placeholder="`Type here...${currentField.required ? '' : ' (optional)'}`"
                type="text"
                :name="`values[${currentField.uuid}]`"
                @focus="$refs.areas.scrollIntoField(currentField)"
              >
            </div>
          </div>
          <div v-else-if="currentField.type === 'date'">
            <label
              v-if="currentField.name"
              :for="currentField.uuid"
              class="label text-2xl mb-2"
            >{{ currentField.name }}
              <template v-if="!currentField.required">(optional)</template>
            </label>
            <div
              v-else
              class="py-1"
            />
            <div class="text-center">
              <input
                :id="currentField.uuid"
                v-model="values[currentField.uuid]"
                class="base-input !text-2xl text-center w-full"
                :required="currentField.required"
                type="date"
                :name="`values[${currentField.uuid}]`"
                @focus="$refs.areas.scrollIntoField(currentField)"
              >
            </div>
          </div>
          <div v-else-if="currentField.type === 'select'">
            <label
              v-if="currentField.name"
              :for="currentField.uuid"
              class="label text-2xl mb-2"
            >{{ currentField.name }}
              <template v-if="!currentField.required">(optional)</template>
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
                Select your option
              </option>
              <option
                v-for="(option, index) in currentField.options"
                :key="index"
                :selected="values[currentField.uuid] == option"
                :value="option"
              >
                {{ option }}
              </option>
            </select>
          </div>
          <div v-else-if="currentField.type === 'radio'">
            <label
              v-if="currentField.name"
              :for="currentField.uuid"
              class="label text-2xl mb-2"
            >{{ currentField.name }}
              <template v-if="!currentField.required">(optional)</template>
            </label>
            <div class="flex w-full">
              <div class="space-y-3.5 mx-auto">
                <div
                  v-for="(option, index) in currentField.options"
                  :key="index"
                >
                  <label
                    :for="currentField.uuid + option"
                    class="flex items-center space-x-3"
                  >
                    <input
                      :id="currentField.uuid + option"
                      v-model="values[currentField.uuid]"
                      type="radio"
                      class="base-radio !h-7 !w-7"
                      :name="`values[${currentField.uuid}]`"
                      :value="option"
                      :required="currentField.required"
                    >
                    <span class="text-xl">
                      {{ option }}
                    </span>
                  </label>
                </div>
              </div>
            </div>
          </div>
          <MultiSelectStep
            v-else-if="currentField.type === 'multiple'"
            v-model="values[currentField.uuid]"
            :field="currentField"
          />
          <div
            v-else-if="currentField.type === 'checkbox'"
            class="flex w-full"
          >
            <input
              type="hidden"
              name="cast_boolean"
              value="true"
            >
            <div
              class="space-y-3.5 mx-auto"
            >
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
                    :checked="!!values[field.uuid]"
                    @click="[$refs.areas.scrollIntoField(field), values[field.uuid] = !values[field.uuid]]"
                  >
                  <span class="text-xl">
                    {{ field.name || field.type + ' ' + (index + 1) }}
                  </span>
                </label>
              </div>
            </div>
          </div>
          <ImageStep
            v-else-if="currentField.type === 'image'"
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
            v-model="values[currentField.uuid]"
            :field="currentField"
            :is-direct-upload="isDirectUpload"
            :attachments-index="attachmentsIndex"
            :submitter-slug="submitterSlug"
            @attached="attachments.push($event)"
            @start="$refs.areas.scrollIntoField(currentField)"
            @minimize="isFormVisible = false"
          />
          <AttachmentStep
            v-else-if="currentField.type === 'file'"
            v-model="values[currentField.uuid]"
            :is-direct-upload="isDirectUpload"
            :field="currentField"
            :attachments-index="attachmentsIndex"
            :submitter-slug="submitterSlug"
            @attached="[attachments.push($event), $refs.areas.scrollIntoField(currentField)]"
          />
        </div>
        <div class="mt-6 md:mt-8">
          <button
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
                Submit
              </span>
              <span v-else>
                Next
              </span><span
                v-if="isSubmitting"
                class="w-6 flex justify-start mr-1"
              ><span>...</span></span>
            </span>
          </button>
        </div>
      </form>
      <FormCompleted
        v-else
        :is-demo="isDemo"
        :can-send-email="canSendEmail"
        :submitter-slug="submitterSlug"
      />
      <div class="flex justify-center">
        <div class="flex items-center mt-5 mb-1">
          <a
            v-for="(step, index) in stepFields"
            :key="step[0].uuid"
            href="#"
            class="inline border border-base-300 h-3 w-3 rounded-full mx-1"
            :class="{ 'bg-base-300': index === currentStep, 'bg-base-content': index < currentStep || isCompleted, 'bg-white': index > currentStep }"
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
import AttachmentStep from './attachment_step'
import MultiSelectStep from './multi_select_step'
import FormCompleted from './completed'
import { IconInnerShadowTop, IconArrowsDiagonal, IconArrowsDiagonalMinimize2 } from '@tabler/icons-vue'

export default {
  name: 'SubmissionForm',
  components: {
    FieldAreas,
    ImageStep,
    SignatureStep,
    AttachmentStep,
    MultiSelectStep,
    IconInnerShadowTop,
    IconArrowsDiagonal,
    IconArrowsDiagonalMinimize2,
    FormCompleted
  },
  props: {
    submitterSlug: {
      type: String,
      required: true
    },
    canSendEmail: {
      type: Boolean,
      required: false,
      default: false
    },
    submitterUuid: {
      type: String,
      required: true
    },
    attachments: {
      type: Array,
      required: false,
      default: () => []
    },
    fields: {
      type: Array,
      required: false,
      default: () => []
    },
    authenticityToken: {
      type: String,
      required: true
    },
    isDirectUpload: {
      type: Boolean,
      required: true,
      default: false
    },
    isDemo: {
      type: Boolean,
      required: true,
      default: false
    },
    values: {
      type: Object,
      required: false,
      default: () => ({})
    }
  },
  data () {
    return {
      isCompleted: false,
      isFormVisible: true,
      currentStep: 0,
      isSubmitting: false
    }
  },
  computed: {
    currentStepFields () {
      return this.stepFields[this.currentStep]
    },
    isButtonDisabled () {
      return this.isSubmitting ||
        (this.currentField.required && ['image', 'file'].includes(this.currentField.type) && !this.values[this.currentField.uuid]?.length) ||
        (this.currentField.required && this.currentField.type === 'signature' && !this.values[this.currentField.uuid]?.length && this.$refs.currentStep && !this.$refs.currentStep.isSignatureStarted)
    },
    currentField () {
      return this.currentStepFields[0]
    },
    stepFields () {
      return this.fields.reduce((acc, f) => {
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
    this.currentStep = Math.min(
      this.stepFields.indexOf([...this.stepFields].reverse().find((fields) => fields.some((f) => !!this.values[f.uuid]))) + 1,
      this.stepFields.length - 1
    )

    if (/iPhone|iPad|iPod/i.test(navigator.userAgent)) {
      document.body.style.overflow = 'hidden'

      window.scrollbox.classList.add('h-full', 'overflow-y-auto')
      window.scrollbox.parentNode.classList.add('h-screen', 'overflow-y-auto')
    }
  },
  methods: {
    goToStep (step, scrollToArea = false, clickUpload = false) {
      this.currentStep = this.stepFields.indexOf(step)

      this.$nextTick(() => {
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
      if (this.isCompleted) {
        return Promise.resolve({})
      } else {
        return fetch(this.submitPath, {
          method: 'POST',
          body: formData || new FormData(this.$refs.form)
        })
      }
    },
    async submitStep () {
      this.isSubmitting = true

      const stepPromise = this.currentField.type === 'signature'
        ? this.$refs.currentStep.submit
        : () => Promise.resolve({})

      await stepPromise()

      const formData = new FormData(this.$refs.form)

      if (this.currentStep === this.stepFields.length - 1) {
        formData.append('completed', 'true')
      }

      this.saveStep(formData).then(response => {
        const nextStep = this.stepFields[this.currentStep + 1]

        if (nextStep) {
          this.goToStep(this.stepFields[this.currentStep + 1], true)
        } else {
          this.isCompleted = true
        }
      }).catch(error => {
        console.error('Error submitting form:', error)
      }).finally(() => {
        this.isSubmitting = false
      })
    }
  }
}
</script>

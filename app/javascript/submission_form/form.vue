<template>
  <FieldAreas
    ref="areas"
    :fields="submitterFields"
    :values="values"
    :attachments-index="attachmentsIndex"
    :current-field="currentField"
    @focus-field="goToField($event, false, true)"
  />
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
      v-if="currentStep === submitterFields.length - 1"
      type="hidden"
      name="completed"
      value="true"
    >
    <input
      value="put"
      name="_method"
      type="hidden"
    >
    <div class="mt-4">
      <div v-if="currentField.type === 'text'">
        <label
          v-if="currentField.name"
          :for="currentField.uuid"
          class="label text-2xl mb-2"
        >{{ currentField.name }}</label>
        <div>
          <input
            :id="currentField.uuid"
            v-model="values[currentField.uuid]"
            autofocus
            class="base-input !text-2xl w-full"
            :required="currentField.required"
            placeholder="Type here..."
            type="text"
            :name="`values[${currentField.uuid}]`"
          >
        </div>
      </div>
      <div v-else-if="currentField.type === 'date'">
        <label
          v-if="currentField.name"
          :for="currentField.uuid"
          class="label text-2xl mb-2"
        >{{ currentField.name }}</label>
        <div>
          <input
            :id="currentField.uuid"
            v-model="values[currentField.uuid]"
            class="base-input !text-2xl w-full text-center"
            autofocus
            :required="currentField.required"
            type="date"
            :name="`values[${currentField.uuid}]`"
          >
        </div>
      </div>
      <div v-else-if="currentField.type === 'select'">
        <label
          v-if="currentField.name"
          :for="currentField.uuid"
          class="label text-2xl mb-2"
        >{{ currentField.name }}</label>
        <select
          :id="currentField.uuid"
          :required="true"
          class="select base-input !text-2xl w-full text-center font-normal"
          :name="`values[${currentField.uuid}]`"
          @change="values[currentField.uuid] = $event.target.value"
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
      <div v-else-if="currentField.type === 'radio' && currentField.options?.length">
        <label
          v-if="currentField.name"
          :for="currentField.uuid"
          class="label text-2xl mb-2"
        >{{ currentField.name }}</label>
        <div class="space-y-3.5">
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
                required
              >
              <span class="text-xl">
                {{ option }}
              </span>
            </label>
          </div>
        </div>
      </div>
      <CheckboxStep
        v-else-if="currentField.type === 'checkbox' && currentField.options?.length"
        v-model="values[currentField.uuid]"
        :field="currentField"
      />
      <div v-else-if="['radio', 'checkbox'].includes(currentField.type)">
        <div class="flex justify-center">
          <label
            :for="currentField.uuid"
            class="flex items-center space-x-3"
          >
            <input
              :id="currentField.uuid"
              :model-value="values[currentField.uuid]"
              :type="currentField.type"
              :name="`values[${currentField.uuid}]`"
              :value="true"
              class="!h-7 !w-7"
              :class="{'base-radio' : currentField.type === 'radio', 'base-checkbox': currentField.type === 'checkbox'}"
              :checked="!!values[currentField.uuid]"
              @click="values[currentField.uuid] = !values[currentField.uuid]"
            >
            <span class="text-xl">
              {{ currentField.name || currentField.type }}
            </span>
          </label>
        </div>
      </div>
      <ImageStep
        v-else-if="currentField.type === 'image'"
        v-model="values[currentField.uuid]"
        :field="currentField"
        :attachments-index="attachmentsIndex"
        :submitter-slug="submitterSlug"
        @attached="attachments.push($event)"
      />
      <SignatureStep
        v-else-if="currentField.type === 'signature'"
        ref="currentStep"
        v-model="values[currentField.uuid]"
        :field="currentField"
        :attachments-index="attachmentsIndex"
        :submitter-slug="submitterSlug"
        @attached="attachments.push($event)"
      />
      <AttachmentStep
        v-else-if="currentField.type === 'file'"
        v-model="values[currentField.uuid]"
        :field="currentField"
        :attachments-index="attachmentsIndex"
        :submitter-slug="submitterSlug"
        @attached="attachments.push($event)"
      />
    </div>
    <div class="mt-8">
      <button
        type="submit"
        class="base-button w-full"
      >
        <span v-if="isSubmitting">
          Submitting...
        </span>
        <span v-else>
          Submit
        </span>
      </button>
    </div>
    <div class="flex justify-center">
      <div class="flex items-center mt-5 mb-1">
        <a
          v-for="(field, index) in submitterFields"
          :key="field.uuid"
          href="#"
          class="inline border border-base-300 h-3 w-3 rounded-full mx-1"
          :class="{ 'bg-base-200': index === currentStep, 'bg-base-content': index < currentStep, 'bg-white': index > currentStep }"
          @click.prevent="goToField(field, true)"
        />
      </div>
    </div>
  </form>
  <FormCompleted
    v-else
    :submitter-slug="submitterSlug"
  />
</template>

<script>
import FieldAreas from './areas'
import ImageStep from './image_step'
import SignatureStep from './signature_step'
import AttachmentStep from './attachment_step'
import CheckboxStep from './checkbox_step'
import FormCompleted from './completed'

export default {
  name: 'SubmissionForm',
  components: {
    FieldAreas,
    ImageStep,
    SignatureStep,
    AttachmentStep,
    CheckboxStep,
    FormCompleted
  },
  props: {
    submitterSlug: {
      type: String,
      required: true
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
    values: {
      type: Object,
      required: false,
      default: () => ({})
    }
  },
  data () {
    return {
      isCompleted: false,
      currentStep: 0,
      isSubmitting: false
    }
  },
  computed: {
    currentField () {
      return this.submitterFields[this.currentStep]
    },
    submitterFields () {
      return this.fields.filter((f) => f.submitter_uuid === this.submitterUuid)
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
      this.submitterFields.indexOf([...this.submitterFields].reverse().find((field) => !!this.values[field.uuid])) + 1,
      this.submitterFields.length - 1
    )
  },
  methods: {
    goToField (field, scrollToArea = false, clickUpload = false) {
      this.currentStep = this.submitterFields.indexOf(field)

      this.$nextTick(() => {
        if (scrollToArea) {
          this.$refs.areas.scrollIntoField(field)
        }

        this.$refs.form.querySelector('input[type="date"], input[type="text"], select')?.focus()

        if (clickUpload && !this.values[this.currentField.uuid]) {
          this.$refs.form.querySelector('input[type="file"]')?.click()
        }
      })
    },
    async submitStep () {
      this.isSubmitting = true

      const stepPromise = this.currentField.type === 'signature'
        ? this.$refs.currentStep.submit
        : () => Promise.resolve({})

      await stepPromise()

      return fetch(this.submitPath, {
        method: 'POST',
        body: new FormData(this.$refs.form)
      }).then(response => {
        const nextField = this.submitterFields[this.currentStep + 1]

        if (nextField) {
          this.goToField(this.submitterFields[this.currentStep + 1], true)
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

<template>
  <FieldAreas
    ref="areas"
    :fields="fields"
    :values="values"
    :attachments-index="attachmentsIndex"
    @focus-field="goToField"
  />
  <button
    v-if="currentStep !== 0"
    @click="goToField(fields[currentStep - 1], true)"
  >
    Back
  </button>
  {{ currentField.type }}
  <form
    v-if="!isCompleted"
    ref="form"
    :action="submitPath"
    method="post"
    @submit.prevent="submitStep"
  >
    <input
      type="hidden"
      name="authenticity_token"
      :value="authenticityToken"
    >
    <input
      v-if="currentStep === fields.length - 1"
      type="hidden"
      name="completed"
      value="true"
    >
    <input
      value="put"
      name="_method"
      type="hidden"
    >
    <div>
      <template v-if="currentField.type === 'text'">
        <label :for="currentField.uuid">{{ currentField.name || 'Text' }}</label>
        <div>
          <input
            :id="currentField.uuid"
            v-model="values[currentField.uuid]"
            autofocus
            class="text-xl"
            :required="currentField.required"
            type="text"
            :name="`values[${currentField.uuid}]`"
          >
        </div>
      </template>
      <template v-else-if="currentField.type === 'date'">
        <label :for="currentField.uuid">{{ currentField.name || 'Date' }}</label>
        <div>
          <input
            :id="currentField.uuid"
            v-model="values[currentField.uuid]"
            class="text-xl"
            autofocus
            :required="currentField.required"
            type="date"
            :name="`values[${currentField.uuid}]`"
          >
        </div>
      </template>
      <template v-else-if="currentField.type === 'select'">
        <label :for="currentField.uuid">{{ currentField.name || 'Date' }}</label>
        <select
          :id="currentField.uuid"
          v-model="values[currentField.uuid]"
          :required="currentField.required"
          :name="`values[${currentField.uuid}]`"
        >
          <option
            value=""
            disabled
            :selected="!values[currentField.uuid]"
          >
            Select your option
          </option>
          <option
            v-for="(option, index) in currentField.options"
            :key="index"
            :select="values[currentField.uuid] == option"
            :value="option"
          >
            {{ option }}
          </option>
        </select>
      </template>
      <template v-else-if="currentField.type === 'radio'">
        <div
          v-for="(option, index) in currentField.options"
          :key="index"
        >
          <label :for="currentField.uuid + option">
            <input
              :id="currentField.uuid + option"
              v-model="values[currentField.uuid]"
              type="radio"
              :name="`values[${currentField.uuid}]`"
              :value="option"
            >
            {{ option }}
          </label>
        </div>
      </template>
      <CheckboxStep
        v-else-if="currentField.type === 'checkbox'"
        v-model="values[currentField.uuid]"
        :field="currentField"
      />
      <ImageStep
        v-else-if="currentField.type === 'image'"
        v-model="values[currentField.uuid]"
        :field="currentField"
        :attachments-index="attachmentsIndex"
        :submission-slug="submissionSlug"
        @attached="attachments.push($event)"
      />
      <SignatureStep
        v-else-if="currentField.type === 'signature'"
        ref="currentStep"
        v-model="values[currentField.uuid]"
        :field="currentField"
        :attachments-index="attachmentsIndex"
        :submission-slug="submissionSlug"
        @attached="attachments.push($event)"
      />
      <AttachmentStep
        v-else-if="currentField.type === 'attachment'"
        v-model="values[currentField.uuid]"
        :field="currentField"
        :attachments-index="attachmentsIndex"
        :submission-slug="submissionSlug"
        @attached="attachments.push($event)"
      />
    </div>
    <div>
      <button type="submit">
        <span v-if="isSubmitting">
          Submitting...
        </span>
        <span v-else>
          Submit
        </span>
      </button>
    </div>
  </form>
  <FormCompleted
    v-else
    :submission-slug="submissionSlug"
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
  name: 'FlowForm',
  components: {
    FieldAreas,
    ImageStep,
    SignatureStep,
    AttachmentStep,
    CheckboxStep,
    FormCompleted
  },
  props: {
    submissionSlug: {
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
      return this.fields[this.currentStep]
    },
    attachmentsIndex () {
      return this.attachments.reduce((acc, a) => {
        acc[a.uuid] = a

        return acc
      }, {})
    },
    submitPath () {
      return `/l/${this.submissionSlug}`
    }
  },
  mounted () {
    this.currentStep = Math.min(
      this.fields.indexOf([...this.fields].reverse().find((field) => !!this.values[field.uuid])) + 1,
      this.fields.length - 1
    )
  },
  methods: {
    goToField (field, scrollToArea = false) {
      this.currentStep = this.fields.indexOf(field)

      this.$nextTick(() => {
        if (scrollToArea) {
          this.$refs.areas.scrollIntoField(field)
        }

        this.$refs.form.querySelector('input[type="date"], input[type="text"], select')?.focus()
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
        const nextField = this.fields[this.currentStep + 1]

        if (nextField) {
          this.goToField(this.fields[this.currentStep + 1], true)
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

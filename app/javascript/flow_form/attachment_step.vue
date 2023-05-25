<template>
  <div>
    <template v-if="modelValue.length">
      <div
        v-for="(val, index) in modelValue"
        :key="index"
      >
        <a
          v-if="val"
          :href="attachmentsIndex[val].url"
        >
          {{ attachmentsIndex[val].filename }}
        </a>
        <input
          :value="val"
          type="hidden"
          :name="`values[${field.uuid}][]`"
        >
        <button
          v-if="modelValue"
          @click.prevent="removeAttachment(val)"
        >
          Remove
        </button>
      </div>
    </template>
    <template v-else>
      <input
        value=""
        type="hidden"
        :name="`values[${field.uuid}][]`"
      >
    </template>
    <FileDropzone
      :message="'Attachments'"
      :submission-slug="submissionSlug"
      @upload="onUpload"
    />
  </div>
</template>

<script>
import FileDropzone from './dropzone'

export default {
  name: 'AttachmentStep',
  components: {
    FileDropzone
  },
  props: {
    field: {
      type: Object,
      required: true
    },
    submissionSlug: {
      type: String,
      required: true
    },
    attachmentsIndex: {
      type: Object,
      required: false,
      default: () => ({})
    },
    modelValue: {
      type: Array,
      required: false,
      default: () => []
    }
  },
  emits: ['attached', 'update:model-value'],
  methods: {
    removeAttachment (uuid) {
      this.modelValue.splice(this.modelValue.indexOf(uuid), 1)

      this.$emit('update:model-value', this.modelValue)
    },
    onUpload (attachments) {
      attachments.forEach((attachment) => {
        this.$emit('attached', attachment)
      })

      this.$emit('update:model-value', [...this.modelValue, ...attachments.map(a => a.uuid)])
    }
  }
}
</script>

<template>
  <div>
    <img
      v-if="modelValue"
      class="w-80"
      :src="attachmentsIndex[modelValue].url"
    >
    <button
      v-if="modelValue"
      @click.prevent="remove"
    >
      Remove
    </button>
    <input
      :value="modelValue"
      type="hidden"
      :name="`values[${field.uuid}]`"
    >
    <FileDropzone
      :message="'Image'"
      :submission-slug="submissionSlug"
      :accept="'image/*'"
      @upload="onImageUpload"
    />
  </div>
</template>

<script>
import FileDropzone from './dropzone'
export default {
  name: 'ImageStep',
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
      type: String,
      required: false,
      default: ''
    }
  },
  emits: ['attached', 'update:model-value'],
  methods: {
    remove () {
      this.$emit('update:model-value', '')
    },
    onImageUpload (attachments) {
      this.$emit('attached', attachments[0])

      this.$emit('update:model-value', attachments[0].uuid)
    }
  }
}
</script>

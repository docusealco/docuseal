<template>
  <label
    :for="inputId"
    class="btn btn-neutral btn-xs text-white transition-none replace-document-button"
    :class="{ 'opacity-100': isLoading }"
  >
    {{ message }}
    <form
      ref="form"
      class="hidden"
    >
      <input
        :id="inputId"
        ref="input"
        name="files[]"
        type="file"
        :accept="acceptFileTypes"
        @change="upload"
      >
    </form>
  </label>
</template>

<script>
import Upload from './upload'

export default {
  name: 'ReplaceDocument',
  inject: ['baseFetch', 't'],
  props: {
    templateId: {
      type: [Number, String],
      required: true
    },
    acceptFileTypes: {
      type: String,
      required: false,
      default: 'image/*, application/pdf'
    }
  },
  emits: ['success'],
  data () {
    return {
      isLoading: false
    }
  },
  computed: {
    inputId () {
      return 'el' + Math.random().toString(32).split('.')[1]
    },
    uploadUrl () {
      return `/templates/${this.templateId}/documents`
    },
    message () {
      if (this.isLoading) {
        return this.t('uploading_')
      } else {
        return this.t('replace')
      }
    }
  },
  methods: {
    upload: Upload.methods.upload
  }
}
</script>

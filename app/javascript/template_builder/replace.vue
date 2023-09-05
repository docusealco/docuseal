<template>
  <label
    :for="inputId"
    class="btn btn-neutral btn-xs text-white transition-none"
    :class="{ 'opacity-100': isLoading || isProcessing }"
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
  inject: ['baseFetch'],
  props: {
    templateId: {
      type: [Number, String],
      required: true
    },
    acceptFileTypes: {
      type: String,
      required: false,
      default: 'image/*, application/pdf'
    },
    isDirectUpload: {
      type: Boolean,
      required: true,
      default: false
    }
  },
  emits: ['success'],
  data () {
    return {
      isLoading: false,
      isProcessing: false
    }
  },
  computed: {
    inputId () {
      return 'el' + Math.random().toString(32).split('.')[1]
    },
    message () {
      if (this.isLoading) {
        return 'Uploading...'
      } else if (this.isProcessing) {
        return 'Processing...'
      } else {
        return 'Replace'
      }
    }
  },
  mounted () {
    if (this.isDirectUpload) {
      import('@rails/activestorage')
    }
  },
  methods: {
    upload: Upload.methods.upload
  }
}
</script>

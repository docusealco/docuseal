<template>
  <div
    class="flex h-60 w-full"
    @dragover.prevent
    @drop.prevent="onDropFiles"
  >
    <label
      id="document_dropzone"
      class="w-full relative hover:bg-base-200/30 rounded-md border border-2 border-base-content/10 border-dashed"
      :for="inputId"
      :class="{ 'opacity-50': isLoading || isProcessing }"
    >
      <div class="absolute top-0 right-0 left-0 bottom-0 flex items-center justify-center">
        <div class="flex flex-col items-center">
          <IconInnerShadowTop
            v-if="isLoading || isProcessing"
            class="animate-spin"
            :width="40"
            :height="40"
          />
          <IconCloudUpload
            v-else
            :width="40"
            :height="40"
          />
          <div
            v-if="message"
            class="font-medium text-lg mb-1"
          >
            {{ message }}
          </div>
          <div class="text-sm">
            <span class="font-medium">{{ t('click_to_upload') }}</span> {{ t('or_drag_and_drop_files') }}
          </div>
        </div>
      </div>
      <form
        ref="form"
        class="hidden"
      >
        <input
          :id="inputId"
          ref="input"
          type="file"
          name="files[]"
          :accept="acceptFileTypes"
          multiple
          @change="upload"
        >
      </form>
    </label>
  </div>
</template>

<script>
import Upload from './upload'
import { IconCloudUpload, IconInnerShadowTop } from '@tabler/icons-vue'

export default {
  name: 'FileDropzone',
  components: {
    IconCloudUpload,
    IconInnerShadowTop
  },
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
        return this.t('uploading')
      } else if (this.isProcessing) {
        return this.t('processing_')
      } else if (this.acceptFileTypes === 'image/*, application/pdf') {
        return this.t('add_pdf_documents_or_images')
      } else {
        return this.t('add_documents_or_images')
      }
    }
  },
  methods: {
    upload: Upload.methods.upload,
    onDropFiles (e) {
      if (this.acceptFileTypes !== 'image/*, application/pdf' || [...e.dataTransfer.files].every((f) => f.type.match(/(?:image\/)|(?:application\/pdf)/))) {
        this.$refs.input.files = e.dataTransfer.files

        this.upload()
      } else {
        alert('Only PDF and images are supported.')
      }
    }
  }
}
</script>

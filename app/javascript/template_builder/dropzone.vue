<template>
  <div
    class="flex h-60 w-full"
    @dragover.prevent
    @dragenter="isDragEntering = true"
    @dragleave="isDragEntering = false"
    @drop.prevent="onDropFiles"
  >
    <label
      id="document_dropzone"
      class="w-full relative rounded-md border-2 border-base-content/10 border-dashed"
      :for="inputId"
      :class="[{ 'opacity-50': isLoading || isProcessing, 'hover:bg-base-200': !hoverClass }, isDragEntering && hoverClass ? hoverClass : '']"
    >
      <div class="absolute top-0 right-0 left-0 bottom-0 flex items-center justify-center pointer-events-none">
        <div class="flex flex-col items-center">
          <IconInnerShadowTop
            v-if="isLoading || isProcessing"
            class="animate-spin"
            :width="40"
            :height="40"
          />
          <component
            :is="icon"
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
          <div
            v-if="withDescription"
            class="text-sm"
          >
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
import { IconCloudUpload, IconFilePlus, IconFileSymlink, IconFiles, IconInnerShadowTop } from '@tabler/icons-vue'

export default {
  name: 'FileDropzone',
  components: {
    IconFilePlus,
    IconCloudUpload,
    IconInnerShadowTop,
    IconFileSymlink,
    IconFiles
  },
  inject: ['baseFetch', 't'],
  props: {
    templateId: {
      type: [Number, String],
      required: true
    },
    icon: {
      type: String,
      required: false,
      default: 'IconCloudUpload'
    },
    hoverClass: {
      type: String,
      required: false,
      default: null
    },
    cloneTemplateOnUpload: {
      type: Boolean,
      required: false,
      default: false
    },
    withDescription: {
      type: Boolean,
      required: false,
      default: true
    },
    header: {
      type: Object,
      required: false,
      default: () => ({})
    },
    acceptFileTypes: {
      type: String,
      required: false,
      default: 'image/*, application/pdf'
    }
  },
  emits: ['success', 'error', 'loading', 'processing'],
  data () {
    return {
      isLoading: false,
      isProcessing: false,
      isDragEntering: false
    }
  },
  computed: {
    inputId () {
      return 'el' + Math.random().toString(32).split('.')[1]
    },
    uploadUrl () {
      if (this.cloneTemplateOnUpload) {
        return `/templates/${this.templateId}/replace_documents`
      } else {
        return `/templates/${this.templateId}/documents`
      }
    },
    message () {
      if (this.isLoading) {
        return this.t('uploading')
      } else if (this.isProcessing) {
        return this.t('processing_')
      } else if (this.acceptFileTypes === 'image/*, application/pdf') {
        return this.header.pdf_documents_or_images || this.header.documents_or_images || this.t('add_pdf_documents_or_images')
      } else {
        return this.header.documents_or_images || this.t('add_documents_or_images')
      }
    }
  },
  watch: {
    isLoading (value) {
      this.$emit('loading', value)
    },
    isProcessing (value) {
      this.$emit('processing', value)
    }
  },
  methods: {
    upload: Upload.methods.upload,
    onDropFiles (e) {
      if (this.acceptFileTypes !== 'image/*, application/pdf' || [...e.dataTransfer.files].every((f) => f.type.match(/(?:image\/)|(?:application\/pdf)/))) {
        this.$refs.input.files = e.dataTransfer.files

        this.upload()
      } else {
        alert(this.t('only_pdf_and_images_are_supported'))
      }
    }
  }
}
</script>

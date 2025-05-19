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
      :class="{ 'opacity-50': isLoading, 'hover:bg-base-200/50': withHoverClass && !isDragEntering, 'bg-base-200/50 border-base-content/30': isDragEntering }"
    >
      <div class="absolute top-0 right-0 left-0 bottom-0 flex items-center justify-center pointer-events-none">
        <div class="flex flex-col items-center">
          <IconInnerShadowTop
            v-if="isLoading"
            class="animate-spin"
            :width="40"
            :height="40"
          />
          <component
            :is="icon"
            v-else
            class="stroke-[1.5px]"
            :width="40"
            :height="40"
          />
          <div
            v-if="message"
            class="text-lg mb-1"
            :class="{ 'mt-1': !withDescription, 'font-medium': withDescription }"
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
    withHoverClass: {
      type: Boolean,
      required: false,
      default: true
    },
    icon: {
      type: String,
      required: false,
      default: 'IconCloudUpload'
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
    title: {
      type: String,
      required: false,
      default: ''
    },
    acceptFileTypes: {
      type: String,
      required: false,
      default: 'image/*, application/pdf'
    }
  },
  emits: ['success', 'error', 'loading'],
  data () {
    return {
      isLoading: false,
      isDragEntering: false
    }
  },
  computed: {
    inputId () {
      return 'el' + Math.random().toString(32).split('.')[1]
    },
    uploadUrl () {
      if (this.cloneTemplateOnUpload) {
        return `/templates/${this.templateId}/clone_and_replace`
      } else {
        return `/templates/${this.templateId}/documents`
      }
    },
    message () {
      if (this.isLoading) {
        return this.t('uploading')
      } else if (this.acceptFileTypes === 'image/*, application/pdf') {
        return this.title || this.t('add_pdf_documents_or_images')
      } else {
        return this.title || this.t('add_documents_or_images')
      }
    }
  },
  watch: {
    isLoading (value) {
      this.$emit('loading', value)
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

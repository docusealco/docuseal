<template>
  <div
    v-if="isDragging || isLoading"
    class="modal modal-open"
  >
    <div class="flex flex-col gap-2 p-4 items-center bg-base-100 h-full max-h-[85vh] max-w-6xl rounded-2xl w-full">
      <Dropzone
        class="flex-1 h-full"
        icon="IconFilePlus"
        :template-id="templateId"
        :accept-file-types="acceptFileTypes"
        :with-hover-class="false"
        :with-description="false"
        :title="t('add_a_new_document')"
        type="add_files"
        @loading="isLoading = $event"
        @success="$emit('add', $event)"
        @error="$emit('error', $event)"
      />
      <div class="flex-1 flex gap-2 w-full">
        <Dropzone
          class="flex-1 h-full"
          icon="IconFileSymlink"
          :template-id="templateId"
          :accept-file-types="acceptFileTypes"
          :with-hover-class="false"
          :with-description="false"
          :title="t('replace_existing_document')"
          @loading="isLoading = $event"
          @success="$emit('replace', $event)"
          @error="$emit('error', $event)"
        />
        <Dropzone
          v-if="withReplaceAndClone"
          class="flex-1 h-full"
          icon="IconFiles"
          :template-id="templateId"
          :accept-file-types="acceptFileTypes"
          :with-hover-class="false"
          :with-description="false"
          :clone-template-on-upload="true"
          :title="t('clone_and_replace_documents')"
          @loading="isLoading = $event"
          @success="$emit('replace-and-clone', $event)"
          @error="$emit('error', $event)"
        />
      </div>
    </div>
  </div>
</template>

<script>
import Dropzone from './dropzone'

export default {
  name: 'HoverDropzone',
  components: {
    Dropzone
  },
  inject: ['t'],
  props: {
    isDragging: {
      type: Boolean,
      required: true,
      default: false
    },
    templateId: {
      type: [Number, String],
      required: true
    },
    withReplaceAndClone: {
      type: Boolean,
      required: false,
      default: true
    },
    acceptFileTypes: {
      type: String,
      required: false,
      default: 'image/*, application/pdf'
    }
  },
  emits: ['add', 'replace', 'replace-and-clone', 'error'],
  data () {
    return {
      isLoading: false
    }
  }
}
</script>

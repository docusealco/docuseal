<template>
  <div class="inline-flex items-stretch replace-document-control">
    <label
      :for="inputId"
      class="btn btn-neutral btn-xs text-white transition-none replace-document-button"
      :class="[{ 'opacity-100': isLoading }, showGoogleDriveDropdown ? 'rounded-r-none pr-1.5' : '']"
    >
      {{ message }}
    </label>
    <span
      v-if="showGoogleDriveDropdown"
      class="dropdown dropdown-end"
      @click.stop
    >
      <label
        tabindex="0"
        class="btn btn-neutral btn-xs text-white rounded-l-none border-l border-white/30 px-1 transition-none cursor-pointer flex items-center"
      >
        <IconChevronDown
          width="12"
          stroke-width="2.5"
        />
      </label>
      <ul
        tabindex="0"
        :style="{  minWidth: '130px', backgroundColor: backgroundColor }"
        class="mt-1.5 dropdown-content p-1 shadow-lg rounded-lg border border-neutral-200 z-50 bg-white"
      >
        <li>
          <button
            type="button"
            class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center justify-between text-sm"
            @click.prevent="openGoogleDriveModal"
          >
            <IconBrandGoogleDrive class="w-4 h-4 flex-shrink-0" />
            <span>Google Drive</span>
          </button>
        </li>
      </ul>
    </span>
    <form
      ref="form"
      class="hidden"
    >
      <input
        v-if="googleDriveFile"
        name="google_drive_file_ids[]"
        :value="googleDriveFile.id"
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
    <GoogleDrivePickerModal
      v-if="showGoogleDriveModal"
      v-model:loading="isLoadingGoogleDrive"
      :template-id="templateId"
      :authenticity-token="authenticityToken"
      :modal-container-el="modalContainerEl"
      @close="showGoogleDriveModal = false"
      @picked="onGoogleDrivePicked"
    />
  </div>
</template>

<script>
import Upload from './upload'
import GoogleDrivePickerModal from './google_drive_picker_modal'
import { IconChevronDown, IconBrandGoogleDrive } from '@tabler/icons-vue'

export default {
  name: 'ReplaceDocument',
  components: {
    IconChevronDown,
    IconBrandGoogleDrive,
    GoogleDrivePickerModal
  },
  inject: ['baseFetch', 't', 'backgroundColor'],
  props: {
    templateId: {
      type: [Number, String],
      required: true
    },
    authenticityToken: {
      type: String,
      required: false,
      default: ''
    },
    googleDriveFileId: {
      type: String,
      required: false,
      default: ''
    },
    withGoogleDrive: {
      type: Boolean,
      required: false,
      default: false
    },
    acceptFileTypes: {
      type: String,
      required: false,
      default: 'image/*, application/pdf, application/zip, application/json'
    }
  },
  emits: ['success'],
  data () {
    return {
      isLoading: false,
      isLoadingGoogleDrive: true,
      googleDriveFile: null,
      showGoogleDriveModal: false
    }
  },
  computed: {
    inputId () {
      return 'el' + Math.random().toString(32).split('.')[1]
    },
    showGoogleDriveDropdown () {
      return this.withGoogleDrive && !!this.googleDriveFileId
    },
    uploadUrl () {
      return `/templates/${this.templateId}/documents`
    },
    modalContainerEl () {
      return this.$el.getRootNode().querySelector('#docuseal_modal_container')
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
    upload: Upload.methods.upload,
    openGoogleDriveModal () {
      this.showGoogleDriveModal = true
      this.isLoadingGoogleDrive = true
      this.googleDriveFile = null
      this.$el.getRootNode().activeElement?.blur()
    },
    onGoogleDrivePicked (files) {
      this.googleDriveFile = files[0]

      this.$nextTick(() => {
        this.upload({ path: `/templates/${this.templateId}/google_drive_documents` }).then((resp) => {
          if (resp.ok) {
            this.showGoogleDriveModal = false
          }
        }).finally(() => {
          this.isLoadingGoogleDrive = false
          this.googleDriveFile = null
        })
      })
    }
  }
}
</script>

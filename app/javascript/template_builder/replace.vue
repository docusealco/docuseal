<template>
  <div
    class="inline-flex items-stretch replace-document-control"
    :class="{ 'opacity-100': isLoading }"
  >
    <label
      :for="inputId"
      class="btn btn-neutral btn-xs transition-none replace-document-button"
      :class="{ 'opacity-100': isLoading, 'pr-0': showGoogleDriveDropdown && !isLoading }"
    >
      <div class="flex items-center justify-between w-full h-full">
        <span class="flex items-center space-x-2 w-full justify-center text-white">
          {{ message }}
        </span>
        <span
          v-if="showGoogleDriveDropdown && !isLoading"
          class="dropdown dropdown-end inline h-full"
          style="width: 30px"
        >
          <label
            tabindex="0"
            class="flex items-center h-full cursor-pointer text-white"
          >
            <IconChevronDown class="w-4 h-4 flex-shrink-0" />
          </label>
          <ul
            tabindex="0"
            :style="{ backgroundColor }"
            class="dropdown-content p-2 mt-2 shadow menu text-base mb-1 rounded-box text-right !text-base-content"
          >
            <li>
              <button
                type="button"
                @click.prevent="openGoogleDriveModal"
              >
                <IconBrandGoogleDrive class="w-4 h-4 flex-shrink-0" />
                <span class="whitespace-nowrap text-sm normal-case font-medium">Google Drive</span>
              </button>
            </li>
          </ul>
        </span>
      </div>
    </label>
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
        @change="upload()"
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

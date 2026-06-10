<template>
  <div>
    <label
      id="add_document_button"
      :for="inputId"
      class="btn btn-outline w-full add-document-button px-0"
      :class="{ 'btn-disabled': isLoading }"
    >
      <div
        class="flex items-center justify-between w-full h-full"
      >
        <span
          class="flex items-center space-x-2 w-full justify-center"
          :class="{ 'pl-3': withGoogleDrive }"
        >
          <IconInnerShadowTop
            v-if="isLoading"
            width="20"
            class="animate-spin"
          />
          <IconUpload
            v-else
            width="20"
          />
          <span v-if="isLoading">
            {{ t('uploading_') }}
          </span>
          <span
            v-else
            class="mr-1 whitespace-nowrap truncate"
          >
            {{ t('add_document') }}
          </span>
        </span>
        <span
          v-if="withGoogleDrive"
          class="dropdown dropdown-end dropdown-top inline h-full"
          style="width: 33px"
        >
          <label
            tabindex="0"
            class="flex items-center h-full cursor-pointer"
          >
            <IconChevronDown class="w-5 h-5 flex-shrink-0" />
          </label>
          <ul
            tabindex="0"
            :style="{ backgroundColor }"
            class="dropdown-content p-2 mt-2 shadow menu text-base mb-1 rounded-box text-right !text-base-content"
          >
            <li>
              <button
                type="button"
                @click="openGoogleDriveModal"
              >
                <IconBrandGoogleDrive class="w-5 h-5 flex-shrink-0" />
                <span class="whitespace-nowrap text-sm normal-case font-medium">Google Drive</span>
              </button>
            </li>
          </ul>
        </span>
      </div>
    </label>
    <GoogleDrivePickerModal
      v-if="showGoogleDriveModal"
      v-model:loading="isLoadingGoogleDrive"
      :template-id="templateId"
      :authenticity-token="authenticityToken"
      :modal-container-el="modalContainerEl"
      :reopen-after-auth="true"
      @close="showGoogleDriveModal = false"
      @picked="onGoogleDrivePicked"
    />
    <form
      ref="form"
      class="hidden"
    >
      <input
        v-for="file in googleDriveFiles"
        :key="file.id"
        name="google_drive_file_ids[]"
        :value="file.id"
      >
      <input
        :id="inputId"
        ref="input"
        name="files[]"
        type="file"
        :accept="acceptFileTypes"
        multiple
        @change="upload()"
      >
    </form>
  </div>
</template>

<script>
import { IconUpload, IconInnerShadowTop, IconChevronDown, IconBrandGoogleDrive } from '@tabler/icons-vue'
import GoogleDrivePickerModal from './google_drive_picker_modal'

function convertImage (sourceFile, targetType, quality) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()

    reader.onload = function (event) {
      const img = new Image()

      img.onload = function () {
        const canvas = document.createElement('canvas')
        const ctx = canvas.getContext('2d')

        canvas.width = img.width
        canvas.height = img.height
        ctx.drawImage(img, 0, 0)
        canvas.toBlob(function (blob) {
          const ext = targetType === 'image/jpeg' ? '.jpg' : '.png'
          const newFile = new File([blob], sourceFile.name.replace(/\.\w+$/, ext), { type: targetType })
          resolve(newFile)
        }, targetType, quality)
      }

      img.onerror = () => reject(new Error(`browser cannot decode ${sourceFile.type || sourceFile.name}`))

      img.src = event.target.result
    }
    reader.onerror = reject
    reader.readAsDataURL(sourceFile)
  })
}

export async function convertUnsupportedImages (files) {
  const converted = []

  for (const file of Array.from(files)) {
    let result = file

    try {
      if (['image/bmp', 'image/vnd.microsoft.icon', 'image/svg+xml', 'image/gif'].includes(file.type)) {
        result = await convertImage(file, 'image/png')
      } else if (['image/heic', 'image/heif', 'image/heic-sequence', 'image/heif-sequence', 'image/avif', 'image/avif-sequence', 'image/webp'].includes(file.type)) {
        result = await convertImage(file, 'image/jpeg', 0.9)
      }
    } catch (e) {
      alert(e.message)
    }

    converted.push(result)
  }

  return converted
}

async function convertImagesInInput (input) {
  if (!input.files || input.files.length === 0) return

  const originals = Array.from(input.files)
  const converted = await convertUnsupportedImages(originals)

  if (converted.some((file, index) => file !== originals[index])) {
    const dt = new DataTransfer()

    converted.forEach((file) => dt.items.add(file))

    input.files = dt.files
  }
}

export default {
  name: 'DocumentsUpload',
  components: {
    IconUpload,
    IconInnerShadowTop,
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
  emits: ['success', 'error'],
  data () {
    return {
      isLoading: false,
      isLoadingGoogleDrive: true,
      googleDriveFiles: [],
      showGoogleDriveModal: false
    }
  },
  computed: {
    inputId () {
      return 'el' + Math.random().toString(32).split('.')[1]
    },
    queryParams () {
      return new URLSearchParams(window.location.search)
    },
    uploadUrl () {
      return `/templates/${this.templateId}/documents`
    },
    modalContainerEl () {
      return this.$el.getRootNode().querySelector('#docuseal_modal_container')
    }
  },
  mounted () {
    if (this.queryParams.get('google_drive_open') === '1') {
      this.openGoogleDriveModal()

      window.history.replaceState({}, document.title, window.location.pathname)
    }
  },
  methods: {
    openGoogleDriveModal () {
      this.showGoogleDriveModal = true
      this.isLoadingGoogleDrive = true
    },
    onGoogleDrivePicked (files) {
      this.googleDriveFiles = files

      this.$nextTick(() => {
        this.upload({ path: `/templates/${this.templateId}/google_drive_documents` }).then((resp) => {
          if (resp.ok) {
            this.showGoogleDriveModal = false
          }
        }).finally(() => {
          this.isLoadingGoogleDrive = false
          this.googleDriveFiles = []
        })
      })
    },
    async upload ({ path } = {}) {
      this.isLoading = true

      if (this.$refs.input) {
        await convertImagesInInput(this.$refs.input)
      }

      return this.baseFetch(path || this.uploadUrl, {
        method: 'POST',
        headers: { Accept: 'application/json' },
        body: new FormData(this.$refs.form)
      }).then((resp) => {
        if (resp.ok) {
          resp.json().then((data) => {
            this.$emit('success', data)

            if (this.$refs.input) {
              this.$refs.input.value = ''
            }

            this.isLoading = false
          })
        } else if (resp.status === 422) {
          resp.json().then((data) => {
            if (data.status === 'pdf_encrypted') {
              const formData = new FormData(this.$refs.form)

              formData.append('password', prompt(this.t('enter_pdf_password')))

              this.baseFetch(this.uploadUrl, {
                method: 'POST',
                body: formData
              }).then(async (resp) => {
                if (resp.ok) {
                  this.$emit('success', await resp.json())
                  this.$refs.input.value = ''
                  this.isLoading = false
                } else {
                  alert(this.t('wrong_password'))

                  this.$emit('error', await resp.json().error)
                  this.isLoading = false
                }
              })
            } else if (data.status === 'google_drive_file_missing') {
              alert(data.error)
              this.$emit('error', data.error)
              this.isLoading = false
            } else {
              this.$emit('error', data.error)
              this.isLoading = false
            }
          })
        } else {
          resp.json().then((data) => {
            this.$emit('error', data.error)
            this.isLoading = false
          })
        }

        return resp
      }).catch(() => {
        this.isLoading = false
      })
    }
  }
}
</script>

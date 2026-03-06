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
    <Teleport
      v-if="showGoogleDriveModal"
      :to="modalContainerEl"
    >
      <div
        class="modal modal-open items-start !animate-none overflow-y-auto"
      >
        <div
          class="absolute top-0 bottom-0 right-0 left-0"
          @click.prevent="showGoogleDriveModal = false"
        />
        <div class="modal-box pt-4 pb-6 px-6 mt-20 max-h-none w-full max-w-xl">
          <div class="flex justify-between items-center border-b pb-2 mb-2 font-medium">
            <span class="modal-title">
              Google Drive
            </span>
            <a
              href="#"
              class="text-xl modal-close-button"
              @click.prevent="showGoogleDriveModal = false"
            >&times;</a>
          </div>
          <div>
            <form
              v-if="showGoogleDriveOauthButton"
              method="post"
              :action="googleDriveOauthPath"
              @submit="isConnectGoogleDriveClicked = true"
            >
              <input
                type="hidden"
                name="authenticity_token"
                :value="authenticityToken"
                autocomplete="off"
              >
              <button
                id="gdrive_oauth_button"
                class="btn bg-white btn-outline w-full text-base font-medium mt-4"
                data-turbo="false"
                type="submit"
                :disabled="isConnectGoogleDriveClicked"
              >
                <span v-if="isConnectGoogleDriveClicked">
                  <span class="flex items-center justify-center space-x-2">
                    <IconInnerShadowTop class="animate-spin" />
                    <span class="">Submitting...</span>
                  </span>
                </span>
                <span
                  v-else
                >
                  <span class="flex items-center justify-center space-x-2">
                    <IconBrandGoogleDrive />
                    <span>Connect Google Drive</span>
                  </span>
                </span>
              </button>
            </form>
            <div
              v-else
              class="relative"
            >
              <iframe
                class="border border-base-300 rounded-lg"
                style="width: 100%; height: 440px; background: white;"
                src="/template_google_drive"
              />
              <div v-if="isLoadingGoogleDrive">
                <div
                  class="bg-white absolute top-0 bottom-0 left-0 right-0 opacity-80 rounded-lg"
                  style="margin: 1px"
                />
                <div class="absolute top-0 bottom-0 left-0 right-0 flex items-center justify-center">
                  <IconInnerShadowTop class="animate-spin" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
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
        @change="upload"
      >
    </form>
  </div>
</template>

<script>
import { IconUpload, IconInnerShadowTop, IconChevronDown, IconBrandGoogleDrive } from '@tabler/icons-vue'

export default {
  name: 'DocumentsUpload',
  components: {
    IconUpload,
    IconInnerShadowTop,
    IconChevronDown,
    IconBrandGoogleDrive
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
      default: 'image/*, application/pdf, application/zip'
    }
  },
  emits: ['success', 'error'],
  data () {
    return {
      isLoading: false,
      isConnectGoogleDriveClicked: false,
      isLoadingGoogleDrive: false,
      googleDriveFiles: [],
      showGoogleDriveModal: false,
      showGoogleDriveOauthButton: false
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
    googleDriveOauthPath () {
      const params = {
        access_type: 'offline',
        include_granted_scopes: 'true',
        prompt: 'consent',
        scope: [
          'https://www.googleapis.com/auth/userinfo.email',
          'https://www.googleapis.com/auth/drive.file'
        ].join(' '),
        state: new URLSearchParams({
          redir: `/templates/${this.templateId}/edit?google_drive_open=1`
        }).toString()
      }

      const query = new URLSearchParams(params).toString()

      return `/auth/google_oauth2?${query}`
    },
    modalContainerEl () {
      return this.$el.getRootNode().querySelector('#docuseal_modal_container')
    }
  },
  mounted () {
    window.addEventListener('message', this.messageHandler)

    if (this.queryParams.get('google_drive_open') === '1') {
      this.openGoogleDriveModal()

      window.history.replaceState({}, document.title, window.location.pathname)
    }
  },
  beforeUnmount () {
    window.removeEventListener('message', this.messageHandler)
  },
  methods: {
    openGoogleDriveModal () {
      this.showGoogleDriveModal = true
      this.isLoadingGoogleDrive = true
    },
    messageHandler (event) {
      if (event.data.type === 'google-drive-files-picked') {
        this.googleDriveFiles = event.data.files || []

        this.$nextTick(() => {
          this.isLoadingGoogleDrive = true

          this.upload({ path: `/templates/${this.templateId}/google_drive_documents` }).then((resp) => {
            if (resp.ok) {
              this.showGoogleDriveModal = false
            }
          }).finally(() => {
            this.isLoadingGoogleDrive = false
          })
        })
      } else if (event.data.type === 'google-drive-picker-loaded') {
        this.isLoadingGoogleDrive = false
      } else if (event.data.type === 'google-drive-picker-request-oauth') {
        this.showGoogleDriveOauthButton = true
      }
    },
    async upload ({ path } = {}) {
      this.isLoading = true

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

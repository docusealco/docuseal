<template>
  <Teleport :to="modalContainerEl">
    <div
      class="modal modal-open items-start !animate-none overflow-y-auto"
    >
      <div
        class="absolute top-0 bottom-0 right-0 left-0"
        @click.prevent="$emit('close')"
      />
      <div class="modal-box pt-4 pb-6 px-6 mt-20 max-h-none w-full max-w-xl">
        <div class="flex justify-between items-center border-b pb-2 mb-2 font-medium">
          <span class="modal-title">
            Google Drive
          </span>
          <a
            href="#"
            class="text-xl modal-close-button"
            @click.prevent="$emit('close')"
          >&times;</a>
        </div>
        <div>
          <form
            v-if="showOauthButton"
            method="post"
            :action="oauthPath"
            @submit="isConnectClicked = true"
          >
            <input
              type="hidden"
              name="authenticity_token"
              :value="authenticityToken"
              autocomplete="off"
            >
            <button
              class="btn bg-white btn-outline w-full text-base font-medium mt-4"
              data-turbo="false"
              type="submit"
              :disabled="isConnectClicked"
            >
              <span v-if="isConnectClicked">
                <span class="flex items-center justify-center space-x-2">
                  <IconInnerShadowTop class="animate-spin" />
                  <span>{{ t('submitting') }}...</span>
                </span>
              </span>
              <span v-else>
                <span class="flex items-center justify-center space-x-2">
                  <IconBrandGoogleDrive />
                  <span>{{ t('connect_google_drive') }}</span>
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
            <div v-if="loading">
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
</template>

<script>
import { IconBrandGoogleDrive, IconInnerShadowTop } from '@tabler/icons-vue'

export default {
  name: 'GoogleDrivePickerModal',
  components: {
    IconBrandGoogleDrive,
    IconInnerShadowTop
  },
  inject: ['t'],
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
    reopenAfterAuth: {
      type: Boolean,
      required: false,
      default: false
    },
    modalContainerEl: {
      type: [Object, String],
      required: true
    },
    loading: {
      type: Boolean,
      required: false,
      default: true
    }
  },
  emits: ['close', 'picked', 'update:loading'],
  data () {
    return {
      isConnectClicked: false,
      showOauthButton: false
    }
  },
  computed: {
    oauthPath () {
      const redir = this.reopenAfterAuth
        ? `/templates/${this.templateId}/edit?google_drive_open=1`
        : `/templates/${this.templateId}/edit`

      const params = {
        access_type: 'offline',
        include_granted_scopes: 'true',
        prompt: 'consent',
        scope: [
          'https://www.googleapis.com/auth/userinfo.email',
          'https://www.googleapis.com/auth/drive.file'
        ].join(' '),
        oauth_data: new URLSearchParams({ redir }).toString()
      }

      return `/auth/google_oauth2?${new URLSearchParams(params).toString()}`
    }
  },
  mounted () {
    window.addEventListener('message', this.messageHandler)
  },
  beforeUnmount () {
    window.removeEventListener('message', this.messageHandler)
  },
  methods: {
    messageHandler (event) {
      if (event.data.type === 'google-drive-files-picked') {
        const files = event.data.files || []

        if (!files.length) return

        this.$emit('update:loading', true)
        this.$emit('picked', files)
      } else if (event.data.type === 'google-drive-picker-loaded') {
        this.$emit('update:loading', false)
      } else if (event.data.type === 'google-drive-picker-request-oauth') {
        this.showOauthButton = true
        this.$emit('update:loading', false)
      }
    }
  }
}
</script>

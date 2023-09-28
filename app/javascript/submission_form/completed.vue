<template>
  <div class="mx-auto max-w-md flex flex-col">
    <p class="font-medium text-2xl flex items-center space-x-1.5 mx-auto">
      <IconCircleCheck
        class="inline text-green-600"
        :width="30"
        :height="30"
      />
      <span>
        {{ t('form_has_been_completed') }}
      </span>
    </p>
    <div class="space-y-3 mt-5">
      <button
        v-if="canSendEmail && !isDemo"
        class="white-button !h-auto flex items-center space-x-1 w-full"
        :disabled="isSendingCopy"
        @click.prevent="sendCopyToEmail"
      >
        <IconInnerShadowTop
          v-if="isSendingCopy"
          class="animate-spin"
        />
        <IconMail v-else />
        <span>
          {{ t('send_copy_via_email') }}
        </span>
      </button>
      <button
        v-if="!isWebView"
        class="base-button flex items-center space-x-1 w-full"
        :disabled="isDownloading"
        @click.prevent="download"
      >
        <IconInnerShadowTop
          v-if="isDownloading"
          class="animate-spin"
        />
        <IconDownload v-else />
        <span>
          {{ t('download') }}
        </span>
      </button>
      <a
        v-if="isDemo"
        target="_blank"
        href="https://github.com/docusealco/docuseal"
        class="white-button flex items-center space-x-1 w-full"
      >
        <IconBrandGithub />
        <span>
          Star on Github
        </span>
      </a>
      <a
        v-if="completedButton.url"
        :href="completedButton.url"
        class="white-button flex items-center space-x-1 w-full"
      >
        <span>
          {{ completedButton.title || 'Back to Website' }}
        </span>
      </a>
      <a
        v-if="isDemo"
        href="https://docuseal.co/sign_up"
        class="white-button flex items-center space-x-1 w-full"
      >
        <IconLogin />
        <span>
          {{ t('create_a_free_account') }}
        </span>
      </a>
    </div>
    <div
      v-if="attribution"
      class="text-center mt-4"
    >
      {{ t('signed_with') }}
      <a
        href="https://www.docuseal.co"
        target="_blank"
        class="underline"
      >DocuSeal</a> - {{ t('open_source_documents_software') }}
    </div>
  </div>
</template>

<script>
import { IconCircleCheck, IconBrandGithub, IconMail, IconDownload, IconInnerShadowTop, IconLogin } from '@tabler/icons-vue'

export default {
  name: 'FormCompleted',
  components: {
    IconCircleCheck,
    IconInnerShadowTop,
    IconBrandGithub,
    IconMail,
    IconLogin,
    IconDownload
  },
  inject: ['baseUrl', 't'],
  props: {
    submitterSlug: {
      type: String,
      required: true
    },
    isDemo: {
      type: Boolean,
      required: false,
      default: false
    },
    attribution: {
      type: Boolean,
      required: false,
      default: true
    },
    withConfetti: {
      type: Boolean,
      required: false,
      default: false
    },
    canSendEmail: {
      type: Boolean,
      required: false,
      default: false
    },
    completedButton: {
      type: Object,
      required: false,
      default: () => ({})
    }
  },
  data () {
    return {
      isSendingCopy: false,
      isDownloading: false
    }
  },
  computed: {
    isWebView () {
      return /webview|wv|ip((?!.*Safari)|(?=.*like Safari))/i.test(window.navigator.userAgent)
    }
  },
  async mounted () {
    if (this.withConfetti) {
      const { default: confetti } = await import('canvas-confetti')

      confetti({
        particleCount: 50,
        startVelocity: 30,
        spread: 140
      })
    }
  },
  methods: {
    sendCopyToEmail () {
      this.isSendingCopy = true

      fetch(this.baseUrl + `/send_submission_email.json?submitter_slug=${this.submitterSlug}`, {
        method: 'POST'
      }).then(() => {
        alert(this.t('email_has_been_sent'))
      }).finally(() => {
        this.isSendingCopy = false
      })
    },
    download () {
      this.isDownloading = true

      fetch(this.baseUrl + `/submitters/${this.submitterSlug}/download`).then((response) => response.json()).then((urls) => {
        const fileRequests = urls.map((url) => {
          return () => {
            return fetch(url).then(async (resp) => {
              const blobUrl = URL.createObjectURL(await resp.blob())
              const link = document.createElement('a')

              link.href = blobUrl
              link.setAttribute('download', decodeURI(url.split('/').pop()))

              link.click()

              URL.revokeObjectURL(url)
            })
          }
        })

        fileRequests.reduce(
          (prevPromise, request) => prevPromise.then(() => request()),
          Promise.resolve()
        )

        this.isDownloading = false
      })
    }
  }
}
</script>

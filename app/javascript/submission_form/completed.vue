<template>
  <div
    class="mx-auto max-w-md flex flex-col"
    dir="auto"
  >
    <div class="font-medium text-2xl flex items-center space-x-1.5 mx-auto">
      <IconCircleCheck
        class="inline text-green-600"
        :width="30"
        :height="30"
      />
      <span>
        {{ completedMessage.title || t('form_has_been_completed') }}
      </span>
    </div>
    <div
      v-if="completedMessage.body"
      class="mt-2"
    >
      <MarkdownContent
        :string="completedMessage.body"
      />
    </div>
    <div class="space-y-3 mt-5">
      <a
        v-if="completedButton.url"
        :href="sanitizeHref(completedButton.url)"
        rel="noopener noreferrer nofollow"
        class="white-button flex items-center w-full"
      >
        <span>
          {{ completedButton.title || 'Back to Website' }}
        </span>
      </a>
      <button
        v-if="canSendEmail && !isDemo && withSendCopyButton"
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
        v-if="!isWebView && withDownloadButton"
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
        href="https://www.docuseal.co/start"
        target="_blank"
        class="underline"
      >DocuSeal</a> - {{ t('open_source_documents_software') }}
    </div>
  </div>
</template>

<script>
import { IconCircleCheck, IconBrandGithub, IconMail, IconDownload, IconInnerShadowTop, IconLogin } from '@tabler/icons-vue'
import MarkdownContent from './markdown_content'

export default {
  name: 'FormCompleted',
  components: {
    MarkdownContent,
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
    withDownloadButton: {
      type: Boolean,
      required: false,
      default: true
    },
    withSendCopyButton: {
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
    },
    completedMessage: {
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

      fetch(this.baseUrl + `/submitters/${this.submitterSlug}/download`).then(async (response) => {
        if (response.ok) {
          const urls = await response.json()
          const isSafariIos = /iPhone|iPad|iPod/i.test(navigator.userAgent)

          if (isSafariIos && urls.length > 1) {
            this.downloadSafariIos(urls)
          } else {
            this.downloadUrls(urls)
          }
        } else {
          alert('Failed to download files')
        }
      })
    },
    downloadUrls (urls) {
      const fileRequests = urls.map((url) => {
        return () => {
          return fetch(url).then(async (resp) => {
            const blobUrl = URL.createObjectURL(await resp.blob())
            const link = document.createElement('a')

            link.href = blobUrl
            link.setAttribute('download', decodeURI(url.split('/').pop()))

            link.click()

            URL.revokeObjectURL(blobUrl)
          })
        }
      })

      fileRequests.reduce(
        (prevPromise, request) => prevPromise.then(() => request()),
        Promise.resolve()
      ).finally(() => {
        this.isDownloading = false
      })
    },
    sanitizeHref (href) {
      if (href && href.trim().match(/^((?:https?:\/\/)|\/)/)) {
        return href.replace(/javascript:/g, '')
      }
    },
    downloadSafariIos (urls) {
      const fileRequests = urls.map((url) => {
        return fetch(url).then(async (resp) => {
          const blob = await resp.blob()
          const blobUrl = URL.createObjectURL(blob.slice(0, blob.size, 'application/octet-stream'))
          const link = document.createElement('a')

          link.href = blobUrl
          link.setAttribute('download', decodeURI(url.split('/').pop()))

          return link
        })
      })

      Promise.all(fileRequests).then((links) => {
        links.forEach((link, index) => {
          setTimeout(() => {
            link.click()

            URL.revokeObjectURL(link.href)
          }, index * 50)
        })
      }).finally(() => {
        this.isDownloading = false
      })
    }
  }
}
</script>

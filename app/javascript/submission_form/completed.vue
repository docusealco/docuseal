<template>
  <div class="mx-auto max-w-md flex flex-col">
    <p class="font-medium text-2xl flex items-center space-x-1.5 mx-auto">
      <IconCircleCheck
        class="inline text-green-600"
        :width="30"
        :height="30"
      />
      <span>
        Form has been completed!
      </span>
    </p>
    <div class="space-y-3 mt-5">
      <button
        v-if="canSendEmail && !isDemo"
        class="white-button flex items-center space-x-1 w-full"
        :disabled="isSendingCopy"
        @click.prevent="sendCopyToEmail"
      >
        <IconInnerShadowTop
          v-if="isSendingCopy"
          class="animate-spin"
        />
        <IconMail v-else />
        <span>
          Send copy via email
        </span>
      </button>
      <button
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
          Download
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
          Create a Free Account
        </span>
      </a>
    </div>
    <div class="text-center mt-4">
      Signed with
      <a
        href="https://www.docuseal.co"
        target="_blank"
        class="underline"
      >DocuSeal</a> - open source documents software
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
  inject: ['baseUrl'],
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
    withConfetti: {
      type: Boolean,
      required: false,
      default: false
    },
    canSendEmail: {
      type: Boolean,
      required: false,
      default: false
    }
  },
  data () {
    return {
      isSendingCopy: false,
      isDownloading: false
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
        alert('Email has been sent')
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

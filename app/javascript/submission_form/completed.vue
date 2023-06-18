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
    </div>
  </div>
</template>

<script>
import { IconCircleCheck, IconMail, IconDownload, IconInnerShadowTop } from '@tabler/icons-vue'
import confetti from 'canvas-confetti'

export default {
  name: 'FormCompleted',
  components: {
    IconCircleCheck,
    IconInnerShadowTop,
    IconMail,
    IconDownload
  },
  props: {
    submitterSlug: {
      type: String,
      required: true
    }
  },
  data () {
    return {
      isSendingCopy: false,
      isDownloading: false
    }
  },
  mounted () {
    confetti({
      particleCount: 50,
      startVelocity: 30,
      spread: 140
    })
  },
  methods: {
    sendCopyToEmail () {
      this.isSendingCopy = true

      fetch(`/send_submission_email.json?submitter_slug=${this.submitterSlug}`, {
        method: 'POST'
      }).then(() => {
        alert('Email has been sent')
      }).finally(() => {
        this.isSendingCopy = false
      })
    },
    download () {
      this.isDownloading = true

      fetch(`/submitters/${this.submitterSlug}/download`).then((response) => response.json()).then((urls) => {
        urls.forEach((url) => {
          fetch(url).then(async (resp) => {
            const blobUrl = URL.createObjectURL(await resp.blob())
            const link = document.createElement('a')

            link.href = blobUrl
            link.setAttribute('download', resp.headers.get('content-disposition').split('"')[1])

            link.click()

            URL.revokeObjectURL(url)
          })
        })
      }).finally(() => {
        this.isDownloading = false
      })
    }
  }
}
</script>

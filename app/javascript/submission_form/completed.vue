<template>
  <div>
    <p>
      Form completed - thanks!
    </p>
    <button @click.prevent="sendCopyToEmail">
      <span v-if="isSendingCopy">
        Sending
      </span>
      <span>
        Send copy to email
      </span>
    </button>
    <button @click.prevent="download">
      <span v-if="isDownloading">
        Downloading
      </span>
      <span>
        Download copy
      </span>
    </button>
  </div>
</template>

<script>
export default {
  name: 'FormCompleted',
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
  methods: {
    sendCopyToEmail () {
      this.isSendingCopy = true

      fetch(`/send_submission_email.json?submitter_slug=${this.submitterSlug}`, {
        method: 'POST'
      }).finally(() => {
        this.isSendingCopy = false
      })
    },
    download () {
      this.isDownloading = true

      fetch(`/submitters/${this.submitterSlug}/download`).then(async (response) => {
        const blob = new Blob([await response.text()], { type: `${response.headers.get('content-type')};charset=utf-8;` })
        const url = URL.createObjectURL(blob)
        const link = document.createElement('a')

        link.href = url
        link.setAttribute('download', response.headers.get('content-disposition').split('"')[1])

        link.click()

        URL.revokeObjectURL(url)
      }).finally(() => {
        this.isDownloading = false
      })
    }
  }
}
</script>

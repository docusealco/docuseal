<template>
  <input
    ref="input"
    type="file"
    multiple
    @change="upload"
  >
</template>

<script>
import { DirectUpload } from '@rails/activestorage'

export default {
  name: 'DocumentsUpload',
  props: {
    flowId: {
      type: [Number, String],
      required: true
    }
  },
  emits: ['success'],
  methods: {
    async upload () {
      const blobs = await Promise.all(
        Array.from(this.$refs.input.files).map(async (file) => {
          const upload = new DirectUpload(
            file,
            '/direct_uploads',
            this.$refs.input
          )

          return new Promise((resolve, reject) => {
            upload.create((error, blob) => {
              if (error) {
                console.error(error)

                return reject(error)
              } else {
                return resolve(blob)
              }
            })
          }).catch((error) => {
            console.error(error)
          })
        })
      )

      fetch(`/api/flows/${this.flowId}/documents`, {
        method: 'POST',
        body: JSON.stringify({ blobs }),
        headers: { 'Content-Type': 'application/json' }
      }).then(resp => resp.json()).then((data) => {
        this.$emit('success', data)
        this.$refs.input.value = ''
      })
    }
  }
}
</script>

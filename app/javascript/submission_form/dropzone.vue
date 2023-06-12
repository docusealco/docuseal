<template>
  <div
    class="flex h-20 w-full"
    @dragover.prevent
    @drop.prevent="onDropFiles"
  >
    <label
      :for="inputId"
      class="w-full"
    >
      Upload
      {{ message }}
    </label>
    <input
      :id="inputId"
      ref="input"
      :multiple="multiple"
      :accept="accept"
      type="file"
      class="hidden"
      @change="onSelectFiles"
    >
  </div>
</template>

<script>
import { DirectUpload } from '@rails/activestorage'

export default {
  name: 'FileDropzone',
  props: {
    message: {
      type: String,
      required: true
    },
    submitterSlug: {
      type: String,
      required: true
    },
    accept: {
      type: String,
      required: false,
      default: '*/*'
    },
    multiple: {
      type: Boolean,
      required: false,
      default: false
    }
  },
  emits: ['upload'],
  computed: {
    inputId () {
      return 'el' + Math.random().toString(32).split('.')[1]
    }
  },
  methods: {
    onDropFiles (e) {
      this.uploadFiles(e.dataTransfer.files)
    },
    onSelectFiles (e) {
      e.preventDefault()

      this.uploadFiles(this.$refs.input.files).then(() => {
        this.$refs.input.value = ''
      })
    },
    async uploadFiles (files) {
      const blobs = await Promise.all(
        Array.from(files).map(async (file) => {
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

      return await Promise.all(
        blobs.map((blob) => {
          return fetch('/api/attachments', {
            method: 'POST',
            body: JSON.stringify({
              name: 'attachments',
              blob_signed_id: blob.signed_id,
              submitter_slug: this.submitterSlug
            }),
            headers: { 'Content-Type': 'application/json' }
          }).then(resp => resp.json()).then((data) => {
            return data
          })
        })).then((result) => {
        this.$emit('upload', result)
      })
    }
  }
}
</script>

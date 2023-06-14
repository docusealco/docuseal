<template>
  <div
    class="flex h-32 w-full"
    @dragover.prevent
    @drop.prevent="onDropFiles"
  >
    <label
      :for="inputId"
      class="w-full relative bg-base-300 hover:bg-base-200 rounded-md border border-base-content border-dashed"
    >
      <div class="absolute top-0 right-0 left-0 bottom-0 flex items-center justify-center">
        <div class="flex flex-col items-center">
          <IconCloudUpload
            :width="30"
            :height="30"
          />
          <div
            v-if="message"
            class="font-medium mb-1"
          >
            {{ message }}
          </div>
          <div class="text-xs">
            <span class="font-medium">Click to upload</span> or drag and drop
          </div>
        </div>
      </div>
      <input
        :id="inputId"
        ref="input"
        :multiple="multiple"
        :accept="accept"
        type="file"
        class="hidden"
        @change="onSelectFiles"
      >
    </label>
  </div>
</template>

<script>
import { DirectUpload } from '@rails/activestorage'
import { IconCloudUpload } from '@tabler/icons-vue'

export default {
  name: 'FileDropzone',
  components: {
    IconCloudUpload
  },
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
        if (this.$refs.input) {
          this.$refs.input.value = ''
        }
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

<template>
  <div>
    <label
      :for="inputId"
      class="btn btn-outline w-full"
      :class="{ 'btn-disabled': isLoading || isProcessing }"
    >
      <IconInnerShadowTop
        v-if="isLoading || isProcessing"
        width="20"
        class="animate-spin"
      />
      <IconUpload
        v-else
        width="20"
      />
      <span v-if="isLoading">
        Uploading...
      </span>
      <span v-else-if="isProcessing">
        Processing...
      </span>
      <span v-else>
        Add Document
      </span>
    </label>
    <input
      :id="inputId"
      ref="input"
      type="file"
      class="hidden"
      accept="image/*, application/pdf"
      multiple
      @change="upload"
    >
  </div>
</template>

<script>
import { IconUpload, IconInnerShadowTop } from '@tabler/icons-vue'

export default {
  name: 'DocumentsUpload',
  components: {
    IconUpload,
    IconInnerShadowTop
  },
  props: {
    templateId: {
      type: [Number, String],
      required: true
    }
  },
  emits: ['success'],
  data () {
    return {
      isLoading: false,
      isProcessing: false
    }
  },
  computed: {
    inputId () {
      return 'el' + Math.random().toString(32).split('.')[1]
    }
  },
  mounted () {
    import('@rails/activestorage')
  },
  methods: {
    async upload () {
      this.isLoading = true

      const { DirectUpload } = await import('@rails/activestorage')

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
      ).finally(() => {
        this.isLoading = false
      })

      this.isProcessing = true

      fetch(`/api/templates/${this.templateId}/documents`, {
        method: 'POST',
        body: JSON.stringify({ blobs }),
        headers: { 'Content-Type': 'application/json' }
      }).then(resp => resp.json()).then((data) => {
        this.$emit('success', data)
        this.$refs.input.value = ''
      }).finally(() => {
        this.isProcessing = false
      })
    }
  }
}
</script>

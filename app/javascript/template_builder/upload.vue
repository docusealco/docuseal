<template>
  <div>
    <label
      :for="inputId"
      class="btn btn-outline w-full"
      :class="{ 'btn-disabled': isLoading }"
    >
      <IconUpload
        width="20"
        class="mr-2"
      />
      Add Document
    </label>
    <input
      :id="inputId"
      ref="input"
      type="file"
      class="hidden"
      accept=".pdf"
      multiple
      @change="upload"
    >
  </div>
</template>

<script>
import { DirectUpload } from '@rails/activestorage'
import { IconUpload } from '@tabler/icons-vue'

export default {
  name: 'DocumentsUpload',
  components: {
    IconUpload
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
      isLoading: false
    }
  },
  computed: {
    inputId () {
      return 'el' + Math.random().toString(32).split('.')[1]
    }
  },
  methods: {
    async upload () {
      this.isLoading = true

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

      fetch(`/api/templates/${this.templateId}/documents`, {
        method: 'POST',
        body: JSON.stringify({ blobs }),
        headers: { 'Content-Type': 'application/json' }
      }).then(resp => resp.json()).then((data) => {
        this.$emit('success', data)
        this.$refs.input.value = ''
      }).finally(() => {
        this.isLoading = false
      })
    }
  }
}
</script>

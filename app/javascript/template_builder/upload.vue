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
        {{ t('uploading_') }}
      </span>
      <span v-else-if="isProcessing">
        {{ t('processing_') }}
      </span>
      <span v-else>
        {{ t('add_document') }}
      </span>
    </label>
    <form
      ref="form"
      class="hidden"
    >
      <input
        :id="inputId"
        ref="input"
        name="files[]"
        type="file"
        :accept="acceptFileTypes"
        multiple
        @change="upload"
      >
    </form>
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
  inject: ['baseFetch', 't'],
  props: {
    templateId: {
      type: [Number, String],
      required: true
    },
    acceptFileTypes: {
      type: String,
      required: false,
      default: 'image/*, application/pdf'
    },
    isDirectUpload: {
      type: Boolean,
      required: true,
      default: false
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
    if (this.isDirectUpload) {
      import('@rails/activestorage')
    }
  },
  methods: {
    async upload () {
      this.isLoading = true

      if (this.isDirectUpload) {
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

        this.baseFetch(`/templates/${this.templateId}/documents`, {
          method: 'POST',
          body: JSON.stringify({ blobs }),
          headers: { 'Content-Type': 'application/json' }
        }).then((resp) => {
          if (resp.ok) {
            resp.json().then((data) => {
              this.$emit('success', data)
              this.$refs.input.value = ''
            })
          } else if (resp.status === 422) {
            resp.json().then((data) => {
              if (data.error === 'PDF encrypted') {
                this.baseFetch(`/templates/${this.templateId}/documents`, {
                  method: 'POST',
                  body: JSON.stringify({ blobs, password: prompt('Enter PDF password') }),
                  headers: { 'Content-Type': 'application/json' }
                }).then(async (resp) => {
                  if (resp.ok) {
                    this.$emit('success', await resp.json())
                    this.$refs.input.value = ''
                  } else {
                    alert('Wrong password')
                  }
                })
              }
            })
          }
        }).finally(() => {
          this.isProcessing = false
        })
      } else {
        this.baseFetch(`/templates/${this.templateId}/documents`, {
          method: 'POST',
          body: new FormData(this.$refs.form)
        }).then((resp) => {
          if (resp.ok) {
            resp.json().then((data) => {
              this.$emit('success', data)
              this.$refs.input.value = ''
            })
          } else if (resp.status === 422) {
            resp.json().then((data) => {
              if (data.error === 'PDF encrypted') {
                const formData = new FormData(this.$refs.form)

                formData.append('password', prompt('Enter PDF password'))

                this.baseFetch(`/templates/${this.templateId}/documents`, {
                  method: 'POST',
                  body: formData
                }).then(async (resp) => {
                  if (resp.ok) {
                    this.$emit('success', await resp.json())
                    this.$refs.input.value = ''
                  } else {
                    alert('Wrong password')
                  }
                })
              }
            })
          }
        }).finally(() => {
          this.isLoading = false
        })
      }
    }
  }
}
</script>

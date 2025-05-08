<template>
  <div>
    <label
      id="add_document_button"
      :for="inputId"
      class="btn btn-outline w-full add-document-button"
      :class="{ 'btn-disabled': isLoading }"
    >
      <IconInnerShadowTop
        v-if="isLoading"
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
    }
  },
  emits: ['success', 'error'],
  data () {
    return {
      isLoading: false
    }
  },
  computed: {
    inputId () {
      return 'el' + Math.random().toString(32).split('.')[1]
    },
    uploadUrl () {
      return `/templates/${this.templateId}/documents`
    }
  },
  methods: {
    async upload () {
      this.isLoading = true

      this.baseFetch(this.uploadUrl, {
        method: 'POST',
        headers: { Accept: 'application/json' },
        body: new FormData(this.$refs.form)
      }).then((resp) => {
        if (resp.ok) {
          resp.json().then((data) => {
            this.$emit('success', data)
            this.$refs.input.value = ''
            this.isLoading = false
          })
        } else if (resp.status === 422) {
          resp.json().then((data) => {
            if (data.status === 'pdf_encrypted') {
              const formData = new FormData(this.$refs.form)

              formData.append('password', prompt(this.t('enter_pdf_password')))

              this.baseFetch(this.uploadUrl, {
                method: 'POST',
                body: formData
              }).then(async (resp) => {
                if (resp.ok) {
                  this.$emit('success', await resp.json())
                  this.$refs.input.value = ''
                  this.isLoading = false
                } else {
                  alert(this.t('wrong_password'))

                  this.$emit('error', await resp.json().error)
                  this.isLoading = false
                }
              })
            } else {
              this.$emit('error', data.error)
              this.isLoading = false
            }
          })
        } else {
          resp.json().then((data) => {
            this.$emit('error', data.error)
            this.isLoading = false
          })
        }
      }).catch(() => {
        this.isLoading = false
      })
    }
  }
}
</script>

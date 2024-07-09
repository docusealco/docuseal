<template>
  <div>
    <label
      id="add_document_button"
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
  methods: {
    async upload () {
      this.isLoading = true

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
</script>

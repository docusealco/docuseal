<template>
  <div>
    <div class="flex justify-between items-center w-full mb-2">
      <label
        class="label text-2xl"
      >{{ field.name || 'Signature' }}</label>
      <button
        v-if="modelValue"
        class="btn btn-outline btn-sm"
        @click.prevent="remove"
      >
        <IconReload :width="16" />
        Redraw
      </button>
      <button
        v-else
        class="btn btn-outline btn-sm"
        @click.prevent="clear"
      >
        <IconReload :width="16" />
        Clear
      </button>
    </div>
    <input
      :value="modelValue"
      type="hidden"
      :name="`values[${field.uuid}]`"
    >
    <img
      v-if="modelValue"
      :src="attachmentsIndex[modelValue].url"
      class="w-full bg-white border border-base-300 rounded"
    >
    <canvas
      v-show="!modelValue"
      ref="canvas"
      class="bg-white border border-base-300 rounded"
    />
  </div>
</template>

<script>
import { IconReload } from '@tabler/icons-vue'

export default {
  name: 'SignatureStep',
  components: {
    IconReload
  },
  props: {
    field: {
      type: Object,
      required: true
    },
    submitterSlug: {
      type: String,
      required: true
    },
    isDirectUpload: {
      type: Boolean,
      required: true,
      default: false
    },
    attachmentsIndex: {
      type: Object,
      required: false,
      default: () => ({})
    },
    modelValue: {
      type: String,
      required: false,
      default: ''
    }
  },
  emits: ['attached', 'update:model-value'],
  data () {
    return {
      isSignatureStarted: false
    }
  },
  async mounted () {
    this.$nextTick(() => {
      this.$refs.canvas.width = this.$refs.canvas.parentNode.clientWidth
      this.$refs.canvas.height = this.$refs.canvas.parentNode.clientWidth / 3
    })

    if (this.isDirectUpload) {
      import('@rails/activestorage')
    }

    const { default: SignaturePad } = await import('signature_pad')

    this.pad = new SignaturePad(this.$refs.canvas)

    this.pad.addEventListener('beginStroke', () => {
      this.isSignatureStarted = true
    })
  },
  methods: {
    remove () {
      this.$emit('update:model-value', '')
    },
    clear () {
      this.pad.clear()

      this.isSignatureStarted = false
    },
    async submit () {
      if (this.modelValue) {
        return Promise.resolve({})
      }

      return new Promise((resolve) => {
        this.$refs.canvas.toBlob(async (blob) => {
          const file = new File([blob], 'signature.png', { type: 'image/png' })

          if (this.isDirectUpload) {
            const { DirectUpload } = await import('@rails/activestorage')

            new DirectUpload(
              file,
              '/direct_uploads'
            ).create((_error, data) => {
              fetch('/api/attachments', {
                method: 'POST',
                body: JSON.stringify({
                  submitter_slug: this.submitterSlug,
                  blob_signed_id: data.signed_id,
                  name: 'attachments'
                }),
                headers: { 'Content-Type': 'application/json' }
              }).then((resp) => resp.json()).then((attachment) => {
                this.$emit('update:model-value', attachment.uuid)
                this.$emit('attached', attachment)

                return resolve(attachment)
              })
            })
          } else {
            const formData = new FormData()

            formData.append('file', file)
            formData.append('submitter_slug', this.submitterSlug)
            formData.append('name', 'attachments')

            return fetch('/api/attachments', {
              method: 'POST',
              body: formData
            }).then((resp) => resp.json()).then((attachment) => {
              this.$emit('update:model-value', attachment.uuid)
              this.$emit('attached', attachment)

              return resolve(attachment)
            })
          }
        }, 'image/png')
      })
    }
  }
}
</script>

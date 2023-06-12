<template>
  <div>
    <input
      :value="modelValue"
      type="hidden"
      :name="`values[${field.uuid}]`"
    >
    <img
      v-if="modelValue"
      :src="attachmentsIndex[modelValue].url"
    >
    <canvas
      v-show="!modelValue"
      ref="canvas"
    />
    <button
      v-if="modelValue"
      @click.prevent="remove"
    >
      Redraw
    </button>
    <button
      v-else
      @click.prevent="clear"
    >
      Clear
    </button>
  </div>
</template>

<script>
import SignaturePad from 'signature_pad'
import { DirectUpload } from '@rails/activestorage'

export default {
  name: 'SignatureStep',
  props: {
    field: {
      type: Object,
      required: true
    },
    submitterSlug: {
      type: String,
      required: true
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
  mounted () {
    this.pad = new SignaturePad(this.$refs.canvas)
  },
  methods: {
    remove () {
      this.$emit('update:model-value', '')
    },
    clear () {
      this.pad.clear()
    },
    submit () {
      if (this.modelValue) {
        return Promise.resolve({})
      }

      return new Promise((resolve) => {
        this.$refs.canvas.toBlob((blob) => {
          const file = new File([blob], 'signature.png', { type: 'image/png' })

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
        }, 'image/png')
      })
    }
  }
}
</script>

<template>
  <div>
    <div class="flex justify-between items-center w-full mb-2">
      <label
        class="label text-2xl"
      >{{ field.name || 'Signature' }}</label>
      <div class="space-x-2">
        <span
          class="tooltip"
          data-tip="Type text"
        >
          <button
            class="btn btn-sm btn-circle"
            :class="{ 'btn-neutral': isTextSignature, 'btn-outline': !isTextSignature }"
            @click.prevent="toggleTextInput"
          >
            <IconTextSize :width="16" />
          </button>
        </span>
        <span
          class="tooltip"
          data-tip="Take photo"
        >
          <label
            class="btn btn-outline btn-sm btn-circle"
          >
            <IconCamera :width="16" />
            <input
              type="file"
              hidden
              accept="image/*"
              @change="drawImage"
            >
          </label>
        </span>
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
    <input
      v-if="isTextSignature"
      ref="textInput"
      class="base-input !text-2xl w-full mt-6"
      :required="field.required"
      :placeholder="`Type signature here...`"
      type="text"
      @input="updateWrittenSignature"
    >
  </div>
</template>

<script>
import { IconReload, IconCamera, IconTextSize } from '@tabler/icons-vue'

export default {
  name: 'SignatureStep',
  components: {
    IconReload,
    IconCamera,
    IconTextSize
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
      isSignatureStarted: false,
      isTextSignature: false
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

      if (this.$refs.textInput) {
        this.$refs.textInput.value = ''
      }
    },
    updateWrittenSignature (e) {
      this.isSignatureStarted = true

      const canvas = this.$refs.canvas
      const context = canvas.getContext('2d')

      const fontFamily = 'Arial'
      const fontSize = '44px'
      const fontStyle = 'italic'
      const fontWeight = ''

      context.font = fontStyle + ' ' + fontWeight + ' ' + fontSize + ' ' + fontFamily
      context.textAlign = 'center'

      context.clearRect(0, 0, canvas.width, canvas.height)
      context.fillText(e.target.value, canvas.width / 2, canvas.height / 2 + 11)
    },
    toggleTextInput () {
      this.isTextSignature = !this.isTextSignature

      if (this.isTextSignature) {
        this.$nextTick(() => this.$refs.textInput.focus())
      }
    },
    drawImage (event) {
      this.isSignatureStarted = true

      const file = event.target.files[0]

      if (file && file.type.match('image.*')) {
        const reader = new FileReader()

        reader.onload = (event) => {
          const img = new Image()

          img.src = event.target.result

          img.onload = () => {
            const canvas = this.$refs.canvas
            const context = canvas.getContext('2d')

            const aspectRatio = img.width / img.height

            let targetWidth = canvas.width
            let targetHeight = canvas.height

            if (canvas.width / canvas.height > aspectRatio) {
              targetWidth = canvas.height * aspectRatio
            } else {
              targetHeight = canvas.width / aspectRatio
            }

            if (targetHeight > targetWidth) {
              const scale = targetHeight / targetWidth
              targetWidth = targetWidth * scale
              targetHeight = targetHeight * scale
            }

            const x = (canvas.width - targetWidth) / 2
            const y = (canvas.height - targetHeight) / 2

            context.clearRect(0, 0, canvas.width, canvas.height)
            context.drawImage(img, x, y, targetWidth, targetHeight)
          }
        }

        reader.readAsDataURL(file)
      }
    },
    cropCanvasAndExportToPNG (canvas) {
      const ctx = canvas.getContext('2d')

      const width = canvas.width
      const height = canvas.height

      let topmost = height
      let bottommost = 0
      let leftmost = width
      let rightmost = 0

      const imageData = ctx.getImageData(0, 0, width, height)
      const pixels = imageData.data

      for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
          const pixelIndex = (y * width + x) * 4
          const alpha = pixels[pixelIndex + 3]
          if (alpha !== 0) {
            topmost = Math.min(topmost, y)
            bottommost = Math.max(bottommost, y)
            leftmost = Math.min(leftmost, x)
            rightmost = Math.max(rightmost, x)
          }
        }
      }

      const croppedWidth = rightmost - leftmost + 1
      const croppedHeight = bottommost - topmost + 1

      const croppedCanvas = document.createElement('canvas')
      croppedCanvas.width = croppedWidth
      croppedCanvas.height = croppedHeight
      const croppedCtx = croppedCanvas.getContext('2d')

      croppedCtx.drawImage(canvas, leftmost, topmost, croppedWidth, croppedHeight, 0, 0, croppedWidth, croppedHeight)

      return new Promise((resolve, reject) => {
        croppedCanvas.toBlob((blob) => {
          if (blob) {
            resolve(blob)
          } else {
            reject(new Error('Failed to create a PNG blob.'))
          }
        }, 'image/png')
      })
    },
    async submit () {
      if (this.modelValue) {
        return Promise.resolve({})
      }

      return new Promise((resolve) => {
        this.cropCanvasAndExportToPNG(this.$refs.canvas).then(async (blob) => {
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
        })
      })
    }
  }
}
</script>

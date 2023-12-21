<template>
  <div
    class="absolute"
    style="z-index: 50;"
    :style="{ ...mySignatureStyle }"
  >
    <div class="flex justify-between items-center w-full mb-2">
      <label
        class="label text-2xl"
      >{{ field.name || t('signature') }}</label>
      <div class="space-x-2 flex">
        <span
          v-if="isTextSignature"
          class="tooltip"
          :data-tip="t('draw_signature')"
        >
          <a
            id="type_text_button"
            href="#"
            class="btn btn-outline btn-sm font-medium"
            @click.prevent="toggleTextInput"
          >
            <IconSignature :width="16" />
          </a>
        </span>
        <span
          v-else
          class="tooltip"
          :data-tip="t('type_text')"
        >
          <a
            id="type_text_button"
            href="#"
            class="btn btn-outline btn-sm font-medium"
            @click.prevent="toggleTextInput"
          >
            <IconTextSize :width="16" />
          </a>
        </span>
        <span
          class="tooltip"
          data-tip="Take photo"
        >
          <label
            class="btn btn-outline btn-sm font-medium"
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
        <a
          v-if="modelValue || computedPreviousValue"
          href="#"
          class="tooltip btn btn-outline btn-sm font-medium"
          :data-tip="'redraw'"
          @click.prevent="remove"
        >
          <IconReload :width="16" />
        </a>
        <a
          v-else
          href="#"
          class="tooltip btn btn-outline btn-sm font-medium"
          :data-tip="'clear'"
          @click.prevent="clear"
        >
          <IconReload :width="16" />
        </a>
        <div
          class="tooltip btn btn-outline btn-sm font-medium"
          :data-tip="'close'"
          @click="$emit('hide')"
        >
          <IconTrashX :width="16" />
        </div>
      </div>
    </div>
    <input
      :value="modelValue || computedPreviousValue"
      type="hidden"
    >
    <img
      v-if="modelValue || computedPreviousValue"
      :src="attachmentsIndex[modelValue || computedPreviousValue]?.url"
      class="mx-auto bg-white border border-base-300 rounded max-h-72 w-full"
    >
    <canvas
      v-show="!modelValue && !computedPreviousValue"
      ref="canvas"
      style="padding: 1px; 0"
      class="bg-white border border-base-300 rounded-2xl w-full"
    />
    <input
      v-if="isTextSignature"
      id="signature_text_input"
      ref="textInput"
      class="base-input !text-2xl w-full mt-6"
      :placeholder="`${t('type_signature_here')}...`"
      type="text"
      @input="updateWrittenSignature"
    >
    <button
      class="btn btn-outline w-full mt-2"
      @click="submit"
    >
      <span> Submit </span>
    </button>
  </div>
</template>

<script>
import { IconReload, IconCamera, IconSignature, IconTextSize, IconTrashX } from '@tabler/icons-vue'
import { cropCanvasAndExportToPNG } from './crop_canvas'
import SignaturePad from 'signature_pad'

let isFontLoaded = false

export default {
  name: 'MySignature',
  components: {
    IconReload,
    IconCamera,
    IconTextSize,
    IconSignature,
    IconTrashX
  },
  inject: ['baseUrl', 't'],
  props: {
    field: {
      type: Object,
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
    previousValue: {
      type: String,
      required: false,
      default: ''
    },
    modelValue: {
      type: String,
      required: false,
      default: ''
    },
    template: {
      type: Object,
      required: true
    },
    mySignatureStyle: {
      type: Object,
      required: true
    }
  },
  emits: ['attached', 'update:model-value', 'start', 'hide'],
  data () {
    return {
      isSignatureStarted: !!this.previousValue,
      isUsePreviousValue: true,
      isTextSignature: false
    }
  },
  computed: {
    computedPreviousValue () {
      if (this.isUsePreviousValue) {
        return this.previousValue
      } else {
        return null
      }
    }
  },
  async mounted () {
    this.$nextTick(() => {
      if (this.$refs.canvas) {
        this.$refs.canvas.width = this.$refs.canvas?.parentNode?.clientWidth
        this.$refs.canvas.height = this.$refs.canvas?.parentNode?.clientWidth / 3
      }
    })

    if (this.isDirectUpload) {
      import('@rails/activestorage')
    }

    if (this.$refs.canvas) {
      this.pad = new SignaturePad(this.$refs.canvas)

      this.pad.addEventListener('beginStroke', () => {
        this.isSignatureStarted = true

        this.$emit('start')
      })
    }
  },
  methods: {
    remove () {
      this.$emit('update:model-value', '')

      this.isUsePreviousValue = false
      this.isSignatureStarted = false
    },
    loadFont () {
      if (!isFontLoaded) {
        const font = new FontFace('Dancing Script', `url(${this.baseUrl}/fonts/DancingScript.otf) format("opentype")`)

        font.load().then((loadedFont) => {
          document.fonts.add(loadedFont)

          isFontLoaded = true
        }).catch((error) => {
          console.error('Font loading failed:', error)
        })
      }
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

      const fontFamily = 'Dancing Script'
      const fontSize = '38px'
      const fontStyle = 'italic'
      const fontWeight = ''

      context.font = fontStyle + ' ' + fontWeight + ' ' + fontSize + ' ' + fontFamily
      context.textAlign = 'center'

      context.clearRect(0, 0, canvas.width, canvas.height)
      context.fillText(e.target.value, canvas.width / 2, canvas.height / 2 + 11)
    },
    toggleTextInput () {
      this.remove()
      this.isTextSignature = !this.isTextSignature

      if (this.isTextSignature) {
        this.$nextTick(() => {
          this.$refs.textInput.focus()

          this.loadFont()

          this.$emit('start')
        })
      }
    },
    drawImage (event) {
      this.remove()
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

            this.$emit('start')
          }
        }

        reader.readAsDataURL(file)
      }
    },
    async submit () {
      if (this.modelValue || this.computedPreviousValue) {
        if (this.computedPreviousValue) {
          this.$emit('update:model-value', this.computedPreviousValue)
        }

        return Promise.resolve({})
      }

      return new Promise((resolve) => {
        cropCanvasAndExportToPNG(this.$refs.canvas).then(async (blob) => {
          const file = new File([blob], 'my_signature.png', { type: 'image/png' })

          if (this.isDirectUpload) {
            const { DirectUpload } = await import('@rails/activestorage')

            new DirectUpload(
              file,
              '/direct_uploads'
            ).create((_error, data) => {
              fetch(this.baseUrl + '/api/attachments', {
                method: 'POST',
                body: JSON.stringify({
                  template_slug: this.template.slug,
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
            formData.append('template_slug', this.template.slug)
            formData.append('name', 'attachments')

            return fetch(this.baseUrl + '/api/attachments', {
              method: 'POST',
              body: formData
            }).then((resp) => resp.json()).then((attachment) => {
              this.$emit('attached', attachment)
              this.$emit('update:model-value', attachment.uuid)

              return resolve(attachment)
            })
          }
        })
      })
    }
  }
}
</script>

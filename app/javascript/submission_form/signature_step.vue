<template>
  <div dir="auto">
    <div class="flex justify-between items-center w-full mb-2">
      <label
        class="label text-2xl"
      >{{ showFieldNames && field.name ? field.name : t('signature') }}</label>
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
            <span class="hidden sm:inline">
              {{ t('draw') }}
            </span>
          </a>
        </span>
        <span
          v-else-if="withTypedSignature"
          class="tooltip ml-2"
          :data-tip="t('type_text')"
        >
          <a
            id="type_text_button"
            href="#"
            class="btn btn-outline btn-sm font-medium"
            @click.prevent="toggleTextInput"
          >
            <IconTextSize :width="16" />
            <span class="hidden sm:inline">
              {{ t('type') }}
            </span>
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
            <span class="hidden sm:inline">
              {{ t('upload') }}
            </span>
          </label>
        </span>
        <a
          v-if="modelValue || computedPreviousValue"
          href="#"
          class="btn btn-outline btn-sm font-medium"
          @click.prevent="remove"
        >
          <IconReload :width="16" />
          {{ t('redraw') }}
        </a>
        <a
          v-else
          href="#"
          class="btn btn-outline btn-sm font-medium"
          @click.prevent="clear"
        >
          <IconReload :width="16" />
          {{ t('clear') }}
        </a>
        <a
          href="#"
          title="Minimize"
          class="py-1.5 inline md:hidden"
          @click.prevent="$emit('minimize')"
        >
          <IconArrowsDiagonalMinimize2
            :width="20"
            :height="20"
          />
        </a>
      </div>
    </div>
    <AppearsOn :field="field" />
    <input
      :value="modelValue || computedPreviousValue"
      type="hidden"
      :name="`values[${field.uuid}]`"
    >
    <img
      v-if="modelValue || computedPreviousValue"
      :src="attachmentsIndex[modelValue || computedPreviousValue].url"
      class="mx-auto bg-white border border-base-300 rounded max-h-72"
    >
    <canvas
      v-show="!modelValue && !computedPreviousValue"
      ref="canvas"
      style="padding: 1px; 0"
      class="bg-white border border-base-300 rounded-2xl"
    />
    <input
      v-if="isTextSignature"
      id="signature_text_input"
      ref="textInput"
      class="base-input !text-2xl w-full mt-6"
      :required="field.required"
      :placeholder="`${t('type_signature_here')}...`"
      type="text"
      @input="updateWrittenSignature"
    >
  </div>
</template>

<script>
import { IconReload, IconCamera, IconSignature, IconTextSize, IconArrowsDiagonalMinimize2 } from '@tabler/icons-vue'
import { cropCanvasAndExportToPNG } from './crop_canvas'
import SignaturePad from 'signature_pad'
import AppearsOn from './appears_on'

let isFontLoaded = false

export default {
  name: 'SignatureStep',
  components: {
    AppearsOn,
    IconReload,
    IconCamera,
    IconTextSize,
    IconSignature,
    IconArrowsDiagonalMinimize2
  },
  inject: ['baseUrl', 't'],
  props: {
    field: {
      type: Object,
      required: true
    },
    submitterSlug: {
      type: String,
      required: true
    },
    showFieldNames: {
      type: Boolean,
      required: false,
      default: true
    },
    isDirectUpload: {
      type: Boolean,
      required: true,
      default: false
    },
    withTypedSignature: {
      type: Boolean,
      required: false,
      default: true
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
    }
  },
  emits: ['attached', 'update:model-value', 'start', 'minimize'],
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
        this.$refs.canvas.width = this.$refs.canvas.parentNode.clientWidth
        this.$refs.canvas.height = this.$refs.canvas.parentNode.clientWidth / 3
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
          const file = new File([blob], 'signature.png', { type: 'image/png' })

          if (this.isDirectUpload) {
            const { DirectUpload } = await import('@rails/activestorage')

            new DirectUpload(
              file,
              '/direct_uploads'
            ).create((_error, data) => {
              fetch(this.baseUrl + '/api/attachments', {
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

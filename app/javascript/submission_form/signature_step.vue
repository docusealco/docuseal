<template>
  <div
    dir="auto"
    class="relative"
  >
    <div
      class="flex justify-between items-center w-full"
      :class="{ 'mb-2': !field.description }"
    >
      <label
        class="label text-2xl"
      >
        <MarkdownContent
          v-if="field.title"
          :string="field.title"
        />
        <template v-else>
          {{ showFieldNames && field.name ? field.name : t('signature') }}
        </template>
      </label>
      <div class="space-x-2 flex">
        <span
          v-if="isTextSignature && field.preferences?.format !== 'typed'"
          class="tooltip"
          :data-tip="t('draw_signature')"
        >
          <a
            id="type_text_button"
            href="#"
            class="btn btn-outline btn-sm font-medium"
            @click.prevent="[toggleTextInput(), hideQr()]"
          >
            <IconSignature :width="16" />
            <span class="hidden sm:inline">
              {{ t('draw') }}
            </span>
          </a>
        </span>
        <span
          v-else-if="withTypedSignature && field.preferences?.format !== 'typed' && field.preferences?.format !== 'drawn'"
          class="tooltip ml-2"
          :data-tip="t('type_text')"
        >
          <a
            id="type_text_button"
            href="#"
            class="btn btn-outline btn-sm font-medium inline-flex flex-nowrap"
            @click.prevent="[toggleTextInput(), hideQr()]"
          >
            <IconTextSize :width="16" />
            <span class="hidden sm:inline">
              {{ t('type') }}
            </span>
          </a>
        </span>
        <span
          v-if="field.preferences?.format !== 'typed' && field.preferences?.format !== 'drawn'"
          class="tooltip"
          :data-tip="t('take_photo')"
        >
          <label
            class="btn btn-outline btn-sm font-medium inline-flex flex-nowrap"
          >
            <IconCamera :width="16" />
            <input
              :key="uploadImageInputKey"
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
        <span
          v-if="withQrButton && !modelValue && !computedPreviousValue && field.preferences?.format !== 'typed'"
          class=" tooltip"
          :data-tip="t('drawn_signature_on_a_touchscreen_device')"
        >
          <a
            href="#"
            class="btn btn-sm btn-neutral font-medium hidden md:flex"
            :class="{ 'btn-outline': !isShowQr, 'text-white': isShowQr }"
            @click.prevent="isShowQr ? hideQr() : [isTextSignature = false, showQr()]"
          >
            <IconQrcode
              :width="19"
              :height="19"
            />
          </a>
        </span>
        <a
          href="#"
          :title="t('minimize')"
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
    <div
      v-if="field.description"
      dir="auto"
      class="mb-3 px-1"
    >
      <MarkdownContent :string="field.description" />
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
      class="mx-auto bg-white border border-base-300 rounded max-h-44"
    >
    <div class="relative">
      <div
        v-if="!modelValue && !computedPreviousValue && !isShowQr && !isTextSignature && isSignatureStarted"
        class="absolute top-0.5 right-0.5"
      >
        <a
          href="#"
          class="btn btn-ghost font-medium btn-xs md:btn-sm"
          @click.prevent="[clear(), hideQr()]"
        >
          <IconReload :width="16" />
          {{ t('clear') }}
        </a>
      </div>
      <canvas
        v-show="!modelValue && !computedPreviousValue"
        ref="canvas"
        style="padding: 1px; 0"
        class="bg-white border border-base-300 rounded-2xl w-full"
      />
      <div
        v-if="isShowQr"
        class="top-0 bottom-0 right-0 left-0 absolute bg-white rounded-2xl m-0.5"
      />
      <div
        v-if="isShowQr"
        class="top-0 bottom-0 right-0 left-0 absolute bg-base-content/10 rounded-2xl"
      >
        <div
          class="absolute top-1.5 right-1.5 tooltip"
        >
          <a
            href="#"
            class="btn btn-sm btn-circle btn-normal btn-outline"
            @click.prevent="hideQr"
          >
            <IconX />
          </a>
        </div>
        <div class="flex items-center justify-center w-full h-full p-4">
          <div
            class="bg-white p-4 rounded-xl h-full"
          >
            <canvas
              ref="qrCanvas"
              class="h-full"
              width="132"
              height="132"
            />
          </div>
        </div>
      </div>
    </div>
    <input
      v-if="isTextSignature"
      id="signature_text_input"
      ref="textInput"
      class="base-input !text-2xl w-full mt-6"
      :required="field.required && !isSignatureStarted"
      :placeholder="`${t('type_signature_here')}...`"
      type="text"
      @input="updateWrittenSignature"
    >
    <div
      v-if="isShowQr"
      dir="auto"
      class="text-base-content/60 text-xs text-center w-full mt-1"
    >
      {{ t('scan_the_qr_code_with_the_camera_app_to_open_the_form_on_mobile_and_draw_your_signature') }}
    </div>
    <div
      v-else-if="withDisclosure"
      dir="auto"
      class="text-base-content/60 text-xs text-center w-full mt-1"
    >
      {{ t('by_clicking_you_agree_to_the').replace('{button}', buttonText.charAt(0).toUpperCase() + buttonText.slice(1)) }} <a
        href="https://www.docuseal.co/esign-disclosure"
        target="_blank"
      >
        <span class="inline md:hidden">
          {{ t('esignature_disclosure') }}
        </span>
        <span class="hidden md:inline">
          {{ t('electronic_signature_disclosure') }}
        </span>
      </a>
    </div>
    <div
      v-else
      class="mt-5 md:mt-7"
    />
  </div>
</template>

<script>
import { IconReload, IconCamera, IconSignature, IconTextSize, IconArrowsDiagonalMinimize2, IconQrcode, IconX } from '@tabler/icons-vue'
import { cropCanvasAndExportToPNG } from './crop_canvas'
import SignaturePad from 'signature_pad'
import AppearsOn from './appears_on'
import MarkdownContent from './markdown_content'

let isFontLoaded = false

const scale = 3

export default {
  name: 'SignatureStep',
  components: {
    AppearsOn,
    IconReload,
    IconCamera,
    IconQrcode,
    MarkdownContent,
    IconX,
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
    submitter: {
      type: Object,
      required: true
    },
    showFieldNames: {
      type: Boolean,
      required: false,
      default: true
    },
    dryRun: {
      type: Boolean,
      required: false,
      default: false
    },
    withDisclosure: {
      type: Boolean,
      required: false,
      default: false
    },
    withQrButton: {
      type: Boolean,
      required: false,
      default: false
    },
    buttonText: {
      type: String,
      required: false,
      default: 'Submit'
    },
    withTypedSignature: {
      type: Boolean,
      required: false,
      default: true
    },
    rememberSignature: {
      type: Boolean,
      required: false,
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
    }
  },
  emits: ['attached', 'update:model-value', 'start', 'minimize'],
  data () {
    return {
      isSignatureStarted: !!this.previousValue,
      isShowQr: false,
      isUsePreviousValue: true,
      isTextSignature: this.field.preferences?.format === 'typed',
      uploadImageInputKey: Math.random().toString()
    }
  },
  computed: {
    submitterSlug () {
      return this.submitter.slug
    },
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
        this.$refs.canvas.width = this.$refs.canvas.parentNode.clientWidth * scale
        this.$refs.canvas.height = this.$refs.canvas.parentNode.clientWidth * scale / 3

        this.$refs.canvas.getContext('2d').scale(scale, scale)
      }
    })

    if (this.$refs.canvas) {
      this.pad = new SignaturePad(this.$refs.canvas)

      this.pad.addEventListener('endStroke', () => {
        this.isSignatureStarted = true

        this.$emit('start')
      })

      this.intersectionObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            this.$refs.canvas.width = this.$refs.canvas.parentNode.clientWidth * scale
            this.$refs.canvas.height = this.$refs.canvas.parentNode.clientWidth * scale / 3

            this.$refs.canvas.getContext('2d').scale(scale, scale)

            this.intersectionObserver?.disconnect()
          }
        })
      })

      this.intersectionObserver.observe(this.$refs.canvas)
    }
  },
  beforeUnmount () {
    this.intersectionObserver?.disconnect()
    this.stopCheckSignature()
  },
  methods: {
    remove () {
      this.$emit('update:model-value', '')

      this.isUsePreviousValue = false
      this.isSignatureStarted = false
    },
    loadFont () {
      if (!isFontLoaded) {
        const font = new FontFace('Dancing Script', `url(${this.baseUrl}/fonts/DancingScript-Regular.otf) format("opentype")`)

        font.load().then((loadedFont) => {
          document.fonts.add(loadedFont)

          isFontLoaded = true
        }).catch((error) => {
          console.error('Font loading failed:', error)
        })
      }
    },
    showQr () {
      this.isShowQr = true

      this.$nextTick(() => {
        import('qr-creator').then(({ default: Qr }) => {
          if (this.$refs.qrCanvas) {
            Qr.render({
              text: `${document.location.origin}/p/${this.submitterSlug}?f=${this.field.uuid.split('-')[0]}`,
              radius: 0.0,
              ecLevel: 'H',
              background: null,
              size: 132
            }, this.$refs.qrCanvas)
          }
        })
      })

      this.startCheckSignature()
    },
    hideQr () {
      this.isShowQr = false

      this.stopCheckSignature()
    },
    startCheckSignature () {
      const after = JSON.stringify(new Date())

      this.checkSignatureInterval = setInterval(() => {
        this.checkSignature({ after })
      }, 2000)
    },
    stopCheckSignature () {
      if (this.checkSignatureInterval) {
        clearInterval(this.checkSignatureInterval)
      }
    },
    checkSignature (params = {}) {
      return fetch(this.baseUrl + '/s/' + this.submitterSlug + '/values?field_uuid=' + this.field.uuid + '&after=' + params.after, {
        method: 'GET'
      }).then(async (resp) => {
        const { attachment } = await resp.json()

        if (attachment?.uuid) {
          this.$emit('attached', attachment)
          this.$emit('update:model-value', attachment.uuid)
          this.hideQr()
        }
      })
    },
    clear () {
      this.pad.clear()

      this.isSignatureStarted = false

      if (this.$refs.textInput) {
        this.$refs.textInput.value = ''
        this.$refs.textInput.focus()
      }
    },
    updateWrittenSignature (e) {
      this.isSignatureStarted = !!e.target.value

      const canvas = this.$refs.canvas
      const context = canvas.getContext('2d')

      const fontFamily = 'Dancing Script'
      const initialFontSize = 44
      const fontStyle = 'italic'
      const fontWeight = ''

      const setFontSize = (size) => {
        context.font = `${fontStyle} ${fontWeight} ${size}px ${fontFamily}`
      }

      const adjustFontSizeToFit = (text, maxWidth, initialSize) => {
        let size = initialSize

        setFontSize(size)

        while (context.measureText(text).width > maxWidth && size > 1) {
          size -= 1
          setFontSize(size)
        }
      }

      adjustFontSizeToFit(e.target.value, canvas.width / scale, initialFontSize)

      context.textAlign = 'center'
      context.clearRect(0, 0, canvas.width / scale, canvas.height / scale)
      context.fillText(e.target.value, canvas.width / 2 / scale, canvas.height / 2 / scale + 11)
    },
    toggleTextInput () {
      this.remove()
      this.clear()
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
            const canvasWidth = canvas.width / scale
            const canvasHeight = canvas.height / scale

            let targetWidth = canvasWidth
            let targetHeight = canvasHeight

            if (canvasWidth / canvasHeight > aspectRatio) {
              targetWidth = canvasHeight * aspectRatio
            } else {
              targetHeight = canvasWidth / aspectRatio
            }

            if (targetHeight > targetWidth) {
              const scale = targetHeight / targetWidth
              targetWidth = targetWidth * scale
              targetHeight = targetHeight * scale
            }

            const x = (canvasWidth - targetWidth) / 2
            const y = (canvasHeight - targetHeight) / 2

            setTimeout(() => {
              context.clearRect(0, 0, canvasWidth, canvasHeight)
              context.drawImage(img, x, y, targetWidth, targetHeight)

              this.$emit('start')
            }, 50)
          }
        }

        reader.readAsDataURL(file)

        this.uploadImageInputKey = Math.random().toString()
      }
    },
    maybeSetSignedUuid (signedUuid) {
      try {
        if (window.localStorage && signedUuid && this.rememberSignature) {
          const values = window.localStorage.getItem('signed_signature_uuids')

          let data

          if (values) {
            data = JSON.parse(values)
          } else {
            data = {}
          }

          data[this.submitter.email] = signedUuid

          window.localStorage.setItem('signed_signature_uuids', JSON.stringify(data))
        }
      } catch (e) {
        console.error(e)
      }
    },
    async submit () {
      if (this.modelValue || this.computedPreviousValue) {
        if (this.computedPreviousValue) {
          this.$emit('update:model-value', this.computedPreviousValue)
        }

        return Promise.resolve({})
      }

      return new Promise((resolve, reject) => {
        cropCanvasAndExportToPNG(this.$refs.canvas, { errorOnTooSmall: true }).then(async (blob) => {
          const file = new File([blob], 'signature.png', { type: 'image/png' })

          if (this.dryRun) {
            const reader = new FileReader()

            reader.readAsDataURL(file)

            reader.onloadend = () => {
              const attachment = { url: reader.result, uuid: Math.random().toString() }

              this.$emit('attached', attachment)
              this.$emit('update:model-value', attachment.uuid)

              resolve(attachment)
            }
          } else {
            const formData = new FormData()

            formData.append('file', file)
            formData.append('submitter_slug', this.submitterSlug)
            formData.append('name', 'attachments')
            formData.append('remember_signature', this.rememberSignature)

            return fetch(this.baseUrl + '/api/attachments', {
              method: 'POST',
              body: formData
            }).then((resp) => resp.json()).then((attachment) => {
              this.$emit('attached', attachment)
              this.$emit('update:model-value', attachment.uuid)

              this.maybeSetSignedUuid(attachment.signed_uuid)

              return resolve(attachment)
            })
          }
        }).catch((error) => {
          if (error.message === 'Image too small' && this.field.required === false) {
            return resolve({})
          } else {
            return reject(error)
          }
        })
      })
    }
  }
}
</script>

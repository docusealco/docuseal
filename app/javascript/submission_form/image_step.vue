<template>
  <div v-if="modelValue">
    <div class="flex justify-between items-end w-full mb-3.5 md:mb-4">
      <label
        v-if="showFieldNames"
        :for="field.uuid"
        class="label text-xl sm:text-2xl py-0"
      >
        <MarkdownContent
          v-if="field.title"
          :string="field.title"
        />
        <template v-else>
          {{ field.name || t('image') }}
        </template>
      </label>
      <button
        class="btn btn-outline btn-sm"
        @click.prevent="remove"
      >
        <IconReload :width="16" />
        {{ field.preferences?.only_with_camera ? t('retake') : t('reupload') }}
      </button>
    </div>
    <div>
      <img
        :src="attachmentsIndex[modelValue].url"
        class="h-52 border border-base-300 rounded mx-auto"
      >
    </div>
    <input
      :value="modelValue"
      type="hidden"
      :name="`values[${field.uuid}]`"
    >
  </div>
  <div
    v-if="!modelValue"
  >
    <div
      v-if="field.description"
      dir="auto"
      class="mb-3 px-1"
    >
      <MarkdownContent :string="field.description" />
    </div>
    <FileDropzone
      v-if="!field.preferences.only_with_camera || (isMobile && field.preferences.only_with_camera)"
      :message="`${field.preferences?.only_with_camera ? t('take') : t('upload')} ${(field.title || field.name) || (field.preferences?.only_with_camera ? t('photo') : t('image'))}${field.required ? '' : ` (${t('optional')})`}`"
      :submitter-slug="submitterSlug"
      :dry-run="dryRun"
      :accept="'image/*'"
      :only-with-camera="field.preferences?.only_with_camera === true"
      @upload="onImageUpload"
    />
      <div
        v-else
        class="relative"
      >
        <div
          class="bg-base-content/10 rounded-2xl"
        >
          <div
            class="flex items-center justify-center w-full h-full p-4"
          >
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
        <div
          dir="auto"
          class="text-base-content/60 text-xs text-center w-full mt-1"
        >
          {{ t('scan_the_qr_code_with_your_mobile_camera_app_to_open_the_form_and_take_a_photo') }}
        </div>
      </div>
  </div>
</template>

<script>
import FileDropzone from './dropzone'
import { IconReload } from '@tabler/icons-vue'
import MarkdownContent from './markdown_content'

export default {
  name: 'ImageStep',
  components: {
    FileDropzone,
    IconReload,
    MarkdownContent
  },
  inject: ['t'],
  props: {
    field: {
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
  methods: {
    remove () {
      this.$emit('update:model-value', '')
      this.showQr()
    },
    onImageUpload (attachments) {
      this.$emit('attached', attachments[0])
      this.$emit('update:model-value', attachments[0].uuid)
      this.stopCheckPhoto() //just in case
    },
    showQr() {
        this.$nextTick(() => {
            import('qr-creator').then(({ default: Qr }) => {
                if (this.$refs.qrCanvas && !this.isMobile) {
                    Qr.render({
                        text: `${document.location.origin}/t/${this.submitterSlug}?f=${this.field.uuid.split('-')[0]}`,
                        radius: 0.0,
                        ecLevel: 'H',
                        background: null,
                        size: 132
                    }, this.$refs.qrCanvas)
                    this.startCheckPhoto()
                }
            })
        })
    },
    startCheckPhoto() {
        const after = JSON.stringify(new Date())

        this.checkPhotoInterval = setInterval(() => {
            this.checkPhoto({ after })
        }, 2000)
    },
    stopCheckPhoto() {
        if (this.checkPhotoInterval) {
            clearInterval(this.checkPhotoInterval)
        }
    },
    checkPhoto(params = {}) {
        return fetch(document.location.origin + '/s/' + this.submitterSlug + '/values?field_uuid=' + this.field.uuid + '&after=' + params.after, {
            method: 'GET'
        }).then(async (resp) => {
            const { attachment } = await resp.json()

            if (attachment?.uuid) {
                this.$emit('attached', attachment)
                this.$emit('update:model-value', attachment.uuid)
                this.stopCheckPhoto()
            }
        })
    }
  },
  mounted() {
      this.showQr()
  },
  unmounted() {
      this.stopCheckPhoto()
  },
  computed: {
      isMobile() {
          return screen.width <= 760
      }
  }
}
</script>

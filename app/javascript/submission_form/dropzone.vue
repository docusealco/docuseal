<template>
  <div
    class="flex h-32 w-full"
    @dragover.prevent
    @drop.prevent="onDropFiles"
  >
    <label
      :for="inputId"
      class="w-full relative bg-base-300 hover:bg-base-200 rounded-md border border-base-content border-dashed"
      :class="{ 'opacity-50': isLoading }"
    >
      <div class="absolute top-0 right-0 left-0 bottom-0 flex items-center justify-center">
        <div class="flex flex-col items-center">
          <IconInnerShadowTop
            v-if="isLoading"
            class="animate-spin"
            :width="30"
            :height="30"
          />
          <IconCloudUpload
            v-else
            :width="30"
            :height="30"
          />
          <div
            v-if="message"
            class="font-medium mb-1"
          >
            {{ message }}
          </div>
          <div class="text-xs">
            <span class="font-medium">{{ t('click_to_upload') }}</span> {{ t('or_drag_and_drop_files') }}
          </div>
        </div>
      </div>
      <input
        :id="inputId"
        ref="input"
        :multiple="multiple"
        :accept="accept"
        type="file"
        class="hidden"
        @change="onSelectFiles"
      >
    </label>
  </div>
</template>

<script>
import { IconCloudUpload, IconInnerShadowTop } from '@tabler/icons-vue'

export default {
  name: 'FileDropzone',
  components: {
    IconCloudUpload,
    IconInnerShadowTop
  },
  inject: ['baseUrl', 't'],
  props: {
    message: {
      type: String,
      required: true
    },
    submitterSlug: {
      type: String,
      required: true
    },
    dryRun: {
      type: Boolean,
      required: false,
      default: false
    },
    accept: {
      type: String,
      required: false,
      default: '*/*'
    },
    multiple: {
      type: Boolean,
      required: false,
      default: false
    }
  },
  emits: ['upload'],
  data () {
    return {
      isLoading: false
    }
  },
  computed: {
    inputId () {
      return 'el' + Math.random().toString(32).split('.')[1]
    }
  },
  methods: {
    onDropFiles (e) {
      this.uploadFiles(e.dataTransfer.files)
    },
    onSelectFiles (e) {
      e.preventDefault()

      this.uploadFiles(this.$refs.input.files).then(() => {
        if (this.$refs.input) {
          this.$refs.input.value = ''
        }
      })
    },
    async uploadFiles (files) {
      this.isLoading = true

      return await Promise.all(
        Array.from(files).map(async (file) => {
          const formData = new FormData()

          if (this.dryRun) {
            return new Promise((resolve) => {
              const reader = new FileReader()

              reader.readAsDataURL(file)

              reader.onloadend = () => {
                resolve({
                  url: reader.result,
                  uuid: Math.random().toString(),
                  filename: file.name
                })
              }
            })
          } else {
            if (file.type === 'image/bmp') {
              file = await this.convertBmpToPng(file)
            }

            formData.append('file', file)
            formData.append('submitter_slug', this.submitterSlug)
            formData.append('name', 'attachments')

            return fetch(this.baseUrl + '/api/attachments', {
              method: 'POST',
              body: formData
            }).then(resp => resp.json()).then((data) => {
              return data
            })
          }
        })).then((result) => {
        this.$emit('upload', result)
      }).finally(() => {
        this.isLoading = false
      })
    },
    convertBmpToPng (bmpFile) {
      return new Promise((resolve, reject) => {
        const reader = new FileReader()

        reader.onload = function (event) {
          const img = new Image()

          img.onload = function () {
            const canvas = document.createElement('canvas')
            const ctx = canvas.getContext('2d')

            canvas.width = img.width
            canvas.height = img.height
            ctx.drawImage(img, 0, 0)
            canvas.toBlob(function (blob) {
              const newFile = new File([blob], bmpFile.name.replace(/\.\w+$/, '.png'), { type: 'image/png' })
              resolve(newFile)
            }, 'image/png')
          }

          img.src = event.target.result
        }
        reader.onerror = reject
        reader.readAsDataURL(bmpFile)
      })
    }
  }
}
</script>

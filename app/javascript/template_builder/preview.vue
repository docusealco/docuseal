<template>
  <div>
    <div class="relative">
      <img
        :src="previewImage.url"
        :width="previewImage.metadata.width"
        :height="previewImage.metadata.height"
        class="rounded border"
        loading="lazy"
      >
      <div
        class="group flex justify-end cursor-pointer top-0 bottom-0 left-0 right-0 absolute p-1"
        @click="$emit('scroll-to', item)"
      >
        <div
          v-if="editable"
          class="flex justify-between w-full"
        >
          <div style="width: 26px" />
          <div class="">
            <ReplaceButton
              v-if="withReplaceButton"
              :template-id="template.id"
              :accept-file-types="acceptFileTypes"
              class="opacity-0 group-hover:opacity-100"
              @click.stop
              @success="$emit('replace', { replaceSchemaItem: item, ...$event })"
            />
          </div>
          <div
            class="flex flex-col justify-between opacity-0 group-hover:opacity-100"
          >
            <div>
              <button
                class="btn border-base-200 bg-white text-base-content btn-xs rounded hover:text-base-100 hover:bg-base-content hover:border-base-content w-full transition-colors"
                style="width: 24px; height: 24px"
                @click.stop="$emit('remove', item)"
              >
                &times;
              </button>
            </div>
            <div
              v-if="withArrows"
              class="flex flex-col space-y-1"
            >
              <button
                class="btn border-base-200 bg-white text-base-content btn-xs rounded hover:text-base-100 hover:bg-base-content hover:border-base-content w-full transition-colors"
                style="width: 24px; height: 24px"
                @click.stop="$emit('up', item)"
              >
                &uarr;
              </button>
              <button
                class="btn border-base-200 bg-white text-base-content btn-xs rounded hover:text-base-100 hover:bg-base-content hover:border-base-content w-full transition-colors"
                style="width: 24px; height: 24px"
                @click.stop="$emit('down', item)"
              >
                &darr;
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="flex pb-2 pt-1.5">
      <Contenteditable
        :model-value="item.name"
        :icon-width="16"
        :editable="editable"
        style="max-width: 95%"
        class="mx-auto"
        @update:model-value="onUpdateName"
      />
    </div>
  </div>
</template>

<script>
import Contenteditable from './contenteditable'
import Upload from './upload'
import ReplaceButton from './replace'

export default {
  name: 'DocumentPreview',
  components: {
    Contenteditable,
    ReplaceButton
  },
  props: {
    item: {
      type: Object,
      required: true
    },
    template: {
      type: Object,
      required: true
    },
    document: {
      type: Object,
      required: true
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    },
    acceptFileTypes: {
      type: String,
      required: false,
      default: 'image/*, application/pdf'
    },
    withReplaceButton: {
      type: Boolean,
      required: true,
      default: true
    },
    withArrows: {
      type: Boolean,
      required: false,
      default: true
    }
  },
  emits: ['scroll-to', 'change', 'remove', 'up', 'down', 'replace'],
  computed: {
    previewImage () {
      return [...this.document.preview_images].sort((a, b) => parseInt(a.filename) - parseInt(b.filename))[0]
    }
  },
  methods: {
    upload: Upload.methods.upload,
    onUpdateName (value) {
      this.item.name = value

      this.$emit('change')
    }
  }
}
</script>

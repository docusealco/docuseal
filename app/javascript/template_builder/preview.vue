<template>
  <div>
    <div v-for="(previewImage, index) in sortedPreviewImages" :key="previewImage.id" class="relative">
      <img
        :src="previewImage.url"
        :width="previewImage.metadata.width"
        :height="previewImage.metadata.height"
        class="rounded border"
        loading="lazy"
      >
      <div class="absolute bottom-0 left-0 bg-white text-gray-700 p-1">
        {{ index + 1 }}
      </div>
      <div
        class="group flex justify-end cursor-pointer top-0 bottom-0 left-0 right-0 absolute p-1"
        @click="$emit('scroll-to', item, previewImage)"
      >
        <div
          v-if="editable && index==0"
          class="flex justify-between w-full"
        >
          <div
            v-if="sortedPreviewImages.length != 1"
            class="flex flex-col justify-between opacity-0 group-hover:opacity-100"
          >
            <button
              class="btn border-base-200 bg-white text-base-content btn-xs rounded hover:text-base-100 hover:bg-base-content hover:border-base-content w-full transition-colors"
              style="width: 24px; height: 24px"
              @click.stop="$emit('remove-image', item, previewImage.id)"
            >
              &times;
            </button>
          </div>
          <div class="">
            <ReplaceButton
              v-if="withReplaceButton"
              :is-direct-upload="isDirectUpload"
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
                class="btn border-base-200 bg-white text-base-content btn-xs rounded hover:text-base-100 hover:bg-red-500 hover:border-base-content w-full transition-colors"
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
                class="btn border-base-200 bg-white text-base-content btn-xs rounded hover:text-base-100 hover:bg-red-500 hover:border-base-content w-full transition-colors"
                style="width: 24px; height: 24px"
                @click.stop="$emit('up', item)"
              >
                &uarr;
              </button>
              <button
                class="btn border-base-200 bg-white text-base-content btn-xs rounded hover:text-base-100 hover:bg-red-500 hover:border-base-content w-full transition-colors"
                style="width: 24px; height: 24px"
                @click.stop="$emit('down', item)"
              >
                &darr;
              </button>
            </div>
          </div>
        </div>
        <div
          v-else
          class="flex justify-between w-full"
        >
          <div
            class="flex flex-col justify-between opacity-0 group-hover:opacity-100"
          >
            <button
              class="btn border-base-200 bg-white text-base-content btn-xs rounded hover:text-base-100 hover:bg-base-content hover:border-base-content w-full transition-colors"
              style="width: 24px; height: 24px"
              :class="{ disabled: isDeleting }"
              :disabled="isDeleting"
              @click.stop="$emit('remove-image', item, previewImage.id)"
            >
              <IconInnerShadowTop
                v-if="isDeleting"
                width="22"
                class="animate-spin"
              />
              &times;
            </button>
          </div>
        </div>
      </div>
    </div>
    <button
      class="btn btn-outline w-full mt-2"
      :class="{ disabled: isLoading }"
      :disabled="isLoading"
      @click="$emit('add-blank-page', item)"
    >
      <IconInnerShadowTop
        v-if="isLoading"
        width="22"
        class="animate-spin"
      />
      <span v-if="isLoading"> Add blank page </span>
      <span v-else>Add blank page</span>
    </button>

    <div class="flex pb-2 pt-1.5">
      <Contenteditable
        :model-value="item.name"
        :icon-width="16"
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
import { IconInnerShadowTop } from '@tabler/icons-vue'

export default {
  name: 'DocumentPreview',
  components: {
    Contenteditable,
    ReplaceButton,
    IconInnerShadowTop
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
    isDirectUpload: {
      type: Boolean,
      required: true,
      default: false
    },
    withArrows: {
      type: Boolean,
      required: false,
      default: true
    },
    isLoading: {
      type: Boolean,
      required: true,
      default: false
    },
    isDeleting: {
      type: Boolean,
      required: true,
      default: false
    }
  },
  emits: ['scroll-to', 'change', 'remove', 'up', 'down', 'replace', 'remove-image', 'add-blank-page'],
  computed: {
    sortedPreviewImages () {
      return [...this.document.preview_images].sort((a, b) => parseInt(a.filename) - parseInt(b.filename))
    }
  },
  mounted () {
    if (this.isDirectUpload) {
      import('@rails/activestorage')
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

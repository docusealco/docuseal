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
        class="group flex justify-end cursor-pointer top-0 bottom-0 left-0 right-0 absolute"
        @click="$emit('scroll-to', item)"
      >
        <div
          class="flex flex-col justify-between opacity-0 group-hover:opacity-100"
        >
          <div>
            <button
              class="px-1.5 rounded bg-white border border-red-400 text-red-400 hover:bg-red-50"
              @click.stop="$emit('remove', item)"
            >
              &times;
            </button>
          </div>
          <div
            v-if="withArrows"
            class="flex flex-col"
          >
            <button
              class="px-1.5"
              @click.stop="$emit('up', item)"
            >
              &uarr;
            </button>
            <button
              class="px-1.5"
              @click.stop="$emit('down', item)"
            >
              &darr;
            </button>
          </div>
        </div>
      </div>
    </div>
    <div class="flex py-2">
      <Contenteditable
        :model-value="item.name"
        :icon-width="16"
        class="mx-auto"
        @update:model-value="onUpdateName"
      />
    </div>
  </div>
</template>

<script>
import Contenteditable from './contenteditable'

export default {
  name: 'DocumentPreview',
  components: {
    Contenteditable
  },
  props: {
    item: {
      type: Object,
      required: true
    },
    document: {
      type: Object,
      required: true
    },
    withArrows: {
      type: Boolean,
      required: false,
      default: true
    }
  },
  emits: ['scroll-to', 'change', 'remove', 'up', 'down'],
  computed: {
    previewImage () {
      return this.document.preview_images[0]
    }
  },
  methods: {
    onUpdateName (value) {
      this.item.name = value

      this.$emit('change')
    }
  }
}
</script>

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
          <div class="rounded-bl rounded-tr bg-white border">
            <button
              class="rounded-bl rounded-tr hover:text-base-100 hover:bg-base-content w-full transition-colors"
              style="width: 24px"
              @click.stop="$emit('remove', item)"
            >
              &times;
            </button>
          </div>
          <div
            v-if="withArrows"
            class="flex flex-col border rounded-br rounded-tl bg-white divide-y"
          >
            <button
              class="rounded-tl hover:text-base-100 hover:bg-base-content w-full transition-colors"
              style="width: 24px"
              @click.stop="$emit('up', item)"
            >
              &uarr;
            </button>
            <button
              class="rounded-br hover:text-base-100 hover:bg-base-content w-full transition-colors"
              style="width: 24px"
              @click.stop="$emit('down', item)"
            >
              &darr;
            </button>
          </div>
        </div>
      </div>
    </div>
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

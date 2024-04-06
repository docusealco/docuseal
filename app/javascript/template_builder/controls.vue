<template>
  <div class="flex space-x-2">
    <Contenteditable
      class="w-full block mr-6"
      :model-value="item.name"
      :icon-width="16"
      @update:model-value="onUpdateName"
    />
    <ReplaceButton
      v-if="withReplaceButton"
      :template-id="template.id"
      :accept-file-types="acceptFileTypes"
      @click.stop
      @success="$emit('replace', { replaceSchemaItem: item, ...$event })"
    />
    <button
      v-if="withArrows"
      class="btn border-base-200 bg-white text-base-content btn-xs rounded hover:text-base-100 hover:bg-base-content hover:border-base-content w-full transition-colors"
      style="width: 24px; height: 24px"
      @click.stop="$emit('up', item)"
    >
      &uarr;
    </button>
    <button
      v-if="withArrows"
      class="btn border-base-200 bg-white text-base-content btn-xs rounded hover:text-base-100 hover:bg-base-content hover:border-base-content w-full transition-colors"
      style="width: 24px; height: 24px"
      @click.stop="$emit('down', item)"
    >
      &darr;
    </button>
    <button
      class="btn border-base-200 bg-white text-base-content btn-xs rounded hover:text-base-100 hover:bg-base-content hover:border-base-content w-full transition-colors"
      style="width: 24px; height: 24px"
      @click.stop="$emit('remove', item)"
    >
      &times;
    </button>
  </div>
</template>

<script>
import Contenteditable from './contenteditable'
import Upload from './upload'
import ReplaceButton from './replace'

export default {
  name: 'DocumentControls',
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
  emits: ['change', 'remove', 'up', 'down', 'replace'],
  methods: {
    upload: Upload.methods.upload,
    onUpdateName (value) {
      this.item.name = value

      this.$emit('change')
    }
  }
}
</script>

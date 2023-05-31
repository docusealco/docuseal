<template>
  <div>
    <Page
      v-for="(image, index) in sortedPreviewImages"
      :key="image.id"
      :number="index"
      :areas="areasIndex[index]"
      :is-draw="isDraw"
      :is-drag="isDrag"
      :class="{ 'cursor-crosshair': isDraw }"
      :image="image"
      @drop-field="$emit('drop-field', {...$event, attachment_uuid: document.uuid })"
      @draw="$emit('draw', {...$event, attachment_uuid: document.uuid })"
    />
  </div>
</template>
<script>
import Page from './page'

export default {
  name: 'TemplateDocument',
  components: {
    Page
  },
  props: {
    document: {
      type: Object,
      required: true
    },
    areasIndex: {
      type: Object,
      required: false,
      default: () => ({})
    },
    isDraw: {
      type: Boolean,
      required: false,
      default: false
    },
    isDrag: {
      type: Boolean,
      required: false,
      default: false
    }
  },
  emits: ['draw', 'drop-field'],
  computed: {
    sortedPreviewImages () {
      return [...this.document.preview_images].sort((a, b) => parseInt(a.filename) - parseInt(b.filename))
    }
  }
}
</script>

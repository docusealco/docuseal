<template>
  <Page
    v-for="(image, index) in sortedPreviewImages"
    :key="image.id"
    :number="index"
    :areas="areasIndex[index]"
    :is-draw="isDraw"
    :class="{ 'cursor-crosshair': isDraw }"
    :image="image"
    @draw="$emit('draw', {...$event, attachment_uuid: document.uuid })"
  />
</template>
<script>
import Page from './page'

export default {
  name: 'FlowDocument',
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
    }
  },
  emits: ['draw'],
  computed: {
    sortedPreviewImages () {
      return [...this.document.preview_images].sort((a, b) => parseInt(a.filename) - parseInt(b.filename))
    }
  }
}
</script>

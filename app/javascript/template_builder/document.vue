<template>
  <div>
    <Page
      v-for="(image, index) in sortedPreviewImages"
      :key="image.id"
      :ref="setPageRefs"
      :number="index"
      :editable="editable"
      :areas="areasIndex[index]"
      :is-drag="isDrag"
      :draw-field="drawField"
      :selected-submitter="selectedSubmitter"
      :image="image"
      @drop-field="$emit('drop-field', {...$event, attachment_uuid: document.uuid })"
      @remove-area="$emit('remove-area', $event)"
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
    selectedSubmitter: {
      type: Object,
      required: true
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    },
    drawField: {
      type: Object,
      required: false,
      default: null
    },
    baseUrl: {
      type: String,
      required: false,
      default: ''
    },
    isDrag: {
      type: Boolean,
      required: false,
      default: false
    }
  },
  emits: ['draw', 'drop-field', 'remove-area'],
  data () {
    return {
      pageRefs: []
    }
  },
  computed: {
    basePreviewUrl () {
      if (this.baseUrl) {
        return new URL(this.baseUrl).origin
      } else {
        return ''
      }
    },
    numberOfPages () {
      return this.document.metadata?.pdf?.number_of_pages || this.document.preview_images.length
    },
    sortedPreviewImages () {
      const lazyloadMetadata = this.document.preview_images[this.document.preview_images.length - 1].metadata

      return [...Array(this.numberOfPages).keys()].map((i) => {
        return this.previewImagesIndex[i] || {
          metadata: lazyloadMetadata,
          id: Math.random().toString(),
          url: this.basePreviewUrl + `/preview/${this.document.uuid}/${i}.jpg`
        }
      })
    },
    previewImagesIndex () {
      return this.document.preview_images.reduce((acc, e) => {
        acc[parseInt(e.filename)] = e

        return acc
      }, {})
    }
  },
  beforeUpdate () {
    this.pageRefs = []
  },
  methods: {
    scrollToArea (area) {
      this.pageRefs[area.page].areaRefs.find((e) => e.area === area).$el.scrollIntoView({ behavior: 'smooth', block: 'center' })
    },
    scrollIntoDocument (page) {
      const ref = this.pageRefs.find((e) => e.image.uuid === page.uuid)
      ref.$el.scrollIntoView({ behavior: 'smooth', block: 'start' })
    },
    setPageRefs (el) {
      if (el) {
        this.pageRefs.push(el)
      }
    }
  }
}
</script>

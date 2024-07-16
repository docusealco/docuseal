<template>
  <div>
    <Page
      v-for="(image, index) in sortedPreviewImages"
      :key="image.id"
      :ref="setPageRefs"
      :input-mode="inputMode"
      :number="index"
      :editable="editable"
      :areas="areasIndex[index]"
      :allow-draw="allowDraw"
      :is-drag="isDrag"
      :with-field-placeholder="withFieldPlaceholder"
      :default-fields="defaultFields"
      :default-submitters="defaultSubmitters"
      :draw-field="drawField"
      :draw-field-type="drawFieldType"
      :selected-submitter="selectedSubmitter"
      :image="image"
      @drop-field="$emit('drop-field', {...$event, attachment_uuid: document.uuid })"
      @remove-area="$emit('remove-area', $event)"
      @scroll-to="scrollToArea"
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
    inputMode: {
      type: Boolean,
      required: false,
      default: false
    },
    areasIndex: {
      type: Object,
      required: false,
      default: () => ({})
    },
    defaultFields: {
      type: Array,
      required: false,
      default: () => []
    },
    withFieldPlaceholder: {
      type: Boolean,
      required: false,
      default: false
    },
    drawFieldType: {
      type: String,
      required: false,
      default: ''
    },
    defaultSubmitters: {
      type: Array,
      required: false,
      default: () => []
    },
    allowDraw: {
      type: Boolean,
      required: false,
      default: true
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
          url: this.basePreviewUrl + `/preview/${this.document.signed_uuid || this.document.uuid}/${i}.jpg`
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
      this.$nextTick(() => {
        this.pageRefs[area.page].areaRefs.find((e) => e.area === area).$el.scrollIntoView({ behavior: 'smooth', block: 'center' })
      })
    },
    setPageRefs (el) {
      if (el) {
        this.pageRefs.push(el)
      }
    }
  }
}
</script>

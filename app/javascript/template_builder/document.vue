<template>
  <div>
    <div
      v-if="hasFullText"
      role="tablist"
      :aria-label="t('document_view_options')"
      class="flex border-b border-base-300 mb-2"
    >
      <button
        role="tab"
        type="button"
        :aria-selected="!textViewActive ? 'true' : 'false'"
        :tabindex="!textViewActive ? 0 : -1"
        :class="['px-4 py-2 text-sm border-b-2 -mb-px focus:ring-2 focus:ring-inset focus:ring-base-content/50', !textViewActive ? 'border-neutral text-base-content font-semibold' : 'border-transparent text-base-content font-medium']"
        @click="textViewActive = false"
        @keydown="onTabKeydown($event, false)"
      >
        {{ t('pdf_view') }}
      </button>
      <button
        role="tab"
        type="button"
        :aria-selected="textViewActive ? 'true' : 'false'"
        :tabindex="textViewActive ? 0 : -1"
        :class="['px-4 py-2 text-sm border-b-2 -mb-px focus:ring-2 focus:ring-inset focus:ring-base-content/50', textViewActive ? 'border-neutral text-base-content font-semibold' : 'border-transparent text-base-content font-medium']"
        @click="textViewActive = true"
        @keydown="onTabKeydown($event, true)"
      >
        {{ t('text_view') }}
      </button>
    </div>
    <template v-if="!textViewActive">
      <Page
        v-for="(image, index) in sortedPreviewImages"
        :key="image.id"
        :ref="setPageRefs"
        :input-mode="inputMode"
        :number="index"
        :editable="editable"
        :data-page="index"
        :areas="areasIndex[index]"
        :allow-draw="allowDraw"
        :with-signature-id="withSignatureId"
        :with-prefillable="withPrefillable"
        :is-drag="isDrag"
        :is-mobile="isMobile"
        :with-field-placeholder="withFieldPlaceholder"
        :default-fields="defaultFields"
        :drag-field-placeholder="dragFieldPlaceholder"
        :default-submitters="defaultSubmitters"
        :draw-field="drawField"
        :draw-field-type="drawFieldType"
        :draw-custom-field="drawCustomField"
        :selected-submitter="selectedSubmitter"
        :total-pages="sortedPreviewImages.length"
        :image="image"
        :attachment-uuid="document.uuid"
        :with-fields-detection="withFieldsDetection"
        :page-text="pagesText[String(index)]"
        @drop-field="$emit('drop-field', { ...$event, attachment_uuid: document.uuid })"
        @remove-area="$emit('remove-area', $event)"
        @copy-field="$emit('copy-field', $event)"
        @paste-field="$emit('paste-field', { ...$event, attachment_uuid: document.uuid })"
        @add-custom-field="$emit('add-custom-field', $event)"
        @set-draw="$emit('set-draw', $event)"
        @copy-selected-areas="$emit('copy-selected-areas')"
        @delete-selected-areas="$emit('delete-selected-areas')"
        @autodetect-fields="$emit('autodetect-fields', $event)"
        @scroll-to="scrollToArea"
        @draw="$emit('draw', { area: {...$event.area, attachment_uuid: document.uuid }, isTooSmall: $event.isTooSmall })"
      />
    </template>
    <div
      v-else
      role="tabpanel"
      class="prose max-w-none px-2 py-1"
    >
      <section
        v-for="[pageIndex, pageTextContent] in pagesTextEntries"
        :key="pageIndex"
        :aria-label="`${t('page')} ${Number(pageIndex) + 1}`"
      >
        <!-- eslint-disable-next-line vue/no-v-html -->
        <div v-html="pdfTextToHtml(pageTextContent)" />
      </section>
    </div>
  </div>
</template>
<script>
import Page from './page'
import { reactive } from 'vue'
import { pdfTextToHtml } from './pdf_text_to_html'

export default {
  name: 'TemplateDocument',
  components: {
    Page
  },
  inject: ['t'],
  props: {
    document: {
      type: Object,
      required: true
    },
    dragFieldPlaceholder: {
      type: Object,
      required: false,
      default: null
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
    withSignatureId: {
      type: Boolean,
      required: false,
      default: null
    },
    withPrefillable: {
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
    isMobile: {
      type: Boolean,
      required: false,
      default: false
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
    drawCustomField: {
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
    },
    withFieldsDetection: {
      type: Boolean,
      required: false,
      default: false
    }
  },
  emits: ['draw', 'drop-field', 'remove-area', 'paste-field', 'copy-field', 'copy-selected-areas', 'delete-selected-areas', 'autodetect-fields', 'add-custom-field', 'set-draw'],
  data () {
    return {
      pageRefs: [],
      textViewActive: false
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
      const lazyloadMetadata = this.document.preview_images[this.document.preview_images.length - 1]?.metadata || { width: 1400, height: 1812 }

      return [...Array(this.numberOfPages).keys()].map((i) => {
        return this.previewImagesIndex[i] || reactive({
          metadata: { ...lazyloadMetadata },
          id: Math.random().toString(),
          url: this.basePreviewUrl + `/preview/${this.document.signed_uuid || this.document.uuid}/${i}.jpg`
        })
      })
    },
    previewImagesIndex () {
      return this.document.preview_images.reduce((acc, e) => {
        acc[parseInt(e.filename)] = e

        return acc
      }, {})
    },
    pagesText () {
      return this.document.metadata?.pdf?.pages_text || {}
    },
    hasFullText () {
      const nPages = this.numberOfPages
      return nPages > 0 && Object.keys(this.pagesText).length >= nPages
    },
    pagesTextEntries () {
      return Object.entries(this.pagesText).sort((a, b) => Number(a[0]) - Number(b[0]))
    }
  },
  beforeUpdate () {
    this.pageRefs = []
  },
  methods: {
    pdfTextToHtml,
    onTabKeydown (e, currentIsTextView) {
      if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') {
        e.preventDefault()
        this.textViewActive = !currentIsTextView
        this.$nextTick(() => {
          const tabs = this.$el.querySelectorAll('[role="tab"]')
          const activeTab = Array.from(tabs).find((t) => t.getAttribute('aria-selected') === 'true')
          activeTab?.focus()
        })
      }
    },
    scrollToArea (area) {
      this.$nextTick(() => {
        const pageRef = this.pageRefs[area.page]

        if (pageRef && pageRef.areaRefs) {
          const areaRef = pageRef.areaRefs.find((e) => e.area === area)

          if (areaRef && areaRef.$el) {
            areaRef.$el.scrollIntoView({ behavior: 'smooth', block: 'center' })
          }
        }
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

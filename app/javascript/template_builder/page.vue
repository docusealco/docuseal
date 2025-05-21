<template>
  <div
    class="relative select-none"
    :class="{ 'cursor-crosshair': allowDraw }"
    :style="drawField ? 'touch-action: none' : ''"
  >
    <img
      ref="image"
      loading="lazy"
      :src="image.url"
      :width="width"
      :height="height"
      class="border rounded mb-4"
      @load="onImageLoad"
    >
    <div
      class="top-0 bottom-0 left-0 right-0 absolute"
      @pointerdown="onStartDraw"
    >
      <FieldArea
        v-for="(item, i) in areas"
        :key="i"
        :ref="setAreaRefs"
        :area="item.area"
        :input-mode="inputMode"
        :field="item.field"
        :editable="editable"
        :with-field-placeholder="withFieldPlaceholder"
        :default-field="defaultFieldsIndex[item.field.name]"
        :default-submitters="defaultSubmitters"
        :max-page="totalPages - 1"
        @start-resize="resizeDirection = $event"
        @stop-resize="resizeDirection = null"
        @remove="$emit('remove-area', item.area)"
        @scroll-to="$emit('scroll-to', $event)"
      />
      <FieldArea
        v-if="newArea"
        :is-draw="true"
        :field="{ submitter_uuid: selectedSubmitter.uuid, type: drawField?.type || dragFieldPlaceholder?.type || defaultFieldType }"
        :area="newArea"
      />
    </div>
    <div
      v-show="resizeDirection || isDrag || showMask || (drawField && isMobile) || fieldsDragFieldRef.value"
      id="mask"
      ref="mask"
      class="top-0 bottom-0 left-0 right-0 absolute"
      :class="{ 'z-10': !isMobile, 'cursor-grab': isDrag, 'cursor-nwse-resize': drawField, [resizeDirectionClasses[resizeDirection]]: !!resizeDirectionClasses }"
      @pointermove="onPointermove"
      @pointerdown="onStartDraw"
      @dragover.prevent="onDragover"
      @dragenter="onDragenter"
      @dragleave="newArea = null"
      @drop="onDrop"
      @pointerup="onPointerup"
    />
  </div>
</template>

<script>
import FieldArea from './area'

export default {
  name: 'TemplatePage',
  components: {
    FieldArea
  },
  inject: ['fieldTypes', 'defaultDrawFieldType', 'fieldsDragFieldRef', 'assignDropAreaSize'],
  props: {
    image: {
      type: Object,
      required: true
    },
    dragFieldPlaceholder: {
      type: Object,
      required: false,
      default: null
    },
    areas: {
      type: Array,
      required: false,
      default: () => []
    },
    inputMode: {
      type: Boolean,
      required: false,
      default: false
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
    totalPages: {
      type: Number,
      required: true
    },
    drawFieldType: {
      type: String,
      required: false,
      default: ''
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
    defaultSubmitters: {
      type: Array,
      required: false,
      default: () => []
    },
    drawField: {
      type: Object,
      required: false,
      default: null
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    },
    isDrag: {
      type: Boolean,
      required: false,
      default: false
    },
    number: {
      type: Number,
      required: true
    }
  },
  emits: ['draw', 'drop-field', 'remove-area', 'scroll-to'],
  data () {
    return {
      areaRefs: [],
      showMask: false,
      resizeDirection: null,
      newArea: null
    }
  },
  computed: {
    defaultFieldsIndex () {
      return this.defaultFields.reduce((acc, field) => {
        acc[field.name] = field

        return acc
      }, {})
    },
    defaultFieldType () {
      if (this.drawFieldType) {
        return this.drawFieldType
      } else if (this.defaultDrawFieldType && this.defaultDrawFieldType !== 'text') {
        return this.defaultDrawFieldType
      } else if (this.fieldTypes.length !== 0 && !this.fieldTypes.includes('text')) {
        return this.fieldTypes[0]
      } else {
        return 'text'
      }
    },
    isMobile () {
      const isMobileSafariIos = 'ontouchstart' in window && navigator.maxTouchPoints > 0 && /AppleWebKit/i.test(navigator.userAgent)

      return isMobileSafariIos || /android|iphone|ipad/i.test(navigator.userAgent)
    },
    resizeDirectionClasses () {
      return {
        nwse: 'cursor-nwse-resize',
        ew: 'cursor-ew-resize'
      }
    },
    width () {
      return this.image.metadata.width
    },
    height () {
      return this.image.metadata.height
    }
  },
  beforeUpdate () {
    this.areaRefs = []
  },
  methods: {
    onImageLoad (e) {
      e.target.setAttribute('width', e.target.naturalWidth)
      e.target.setAttribute('height', e.target.naturalHeight)
    },
    setAreaRefs (el) {
      if (el) {
        this.areaRefs.push(el)
      }
    },
    onDragenter (e) {
      this.newArea = {}

      this.assignDropAreaSize(this.newArea, this.dragFieldPlaceholder, {
        maskW: this.$refs.mask.clientWidth,
        maskH: this.$refs.mask.clientHeight
      })

      this.newArea.x = (e.offsetX - 6) / this.$refs.mask.clientWidth
      this.newArea.y = e.offsetY / this.$refs.mask.clientHeight - this.newArea.h / 2
    },
    onDragover (e) {
      this.newArea.x = (e.offsetX - 6) / this.$refs.mask.clientWidth
      this.newArea.y = e.offsetY / this.$refs.mask.clientHeight - this.newArea.h / 2
    },
    onDrop (e) {
      this.newArea = null

      this.$emit('drop-field', {
        x: e.offsetX,
        y: e.offsetY,
        maskW: this.$refs.mask.clientWidth,
        maskH: this.$refs.mask.clientHeight,
        page: this.number
      })
    },
    onStartDraw (e) {
      if (!this.allowDraw) {
        return
      }

      if (this.isMobile && !this.drawField) {
        return
      }

      if (!this.editable) {
        return
      }

      this.showMask = true

      this.$nextTick(() => {
        this.newArea = {
          initialX: e.offsetX / this.$refs.mask.clientWidth,
          initialY: e.offsetY / this.$refs.mask.clientHeight,
          x: e.offsetX / this.$refs.mask.clientWidth,
          y: e.offsetY / this.$refs.mask.clientHeight,
          w: 0,
          h: 0
        }
      })
    },
    onPointermove (e) {
      if (this.newArea) {
        const dx = e.offsetX / this.$refs.mask.clientWidth - this.newArea.initialX
        const dy = e.offsetY / this.$refs.mask.clientHeight - this.newArea.initialY

        if (dx > 0) {
          this.newArea.x = this.newArea.initialX
        } else {
          this.newArea.x = e.offsetX / this.$refs.mask.clientWidth
        }

        if (dy > 0) {
          this.newArea.y = this.newArea.initialY
        } else {
          this.newArea.y = e.offsetY / this.$refs.mask.clientHeight
        }

        if ((this.drawField?.type || this.drawFieldType) === 'cells') {
          this.newArea.cell_w = this.newArea.h * (this.$refs.mask.clientHeight / this.$refs.mask.clientWidth)
        }

        this.newArea.w = Math.abs(dx)
        this.newArea.h = Math.abs(dy)
      }
    },
    onPointerup (e) {
      if (this.newArea) {
        const area = {
          x: this.newArea.x,
          y: this.newArea.y,
          w: this.newArea.w,
          h: this.newArea.h,
          page: this.number
        }

        if ('cell_w' in this.newArea) {
          area.cell_w = this.newArea.cell_w
        }

        const dx = Math.abs(e.offsetX - this.$refs.mask.clientWidth * this.newArea.initialX)
        const dy = Math.abs(e.offsetY - this.$refs.mask.clientHeight * this.newArea.initialY)

        const isTooSmall = dx < 8 && dy < 8

        this.$emit('draw', { area, isTooSmall })
      }

      this.showMask = false
      this.newArea = null
    }
  }
}
</script>

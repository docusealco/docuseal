<template>
  <div
    class="relative select-none mb-4 before:border before:rounded before:top-0 before:bottom-0 before:left-0 before:right-0 before:absolute"
    :class="{ 'cursor-crosshair': allowDraw && editable && !isSelectMode, 'touch-none': !!drawField }"
    style="container-type: size"
    :style="{ aspectRatio: `${width} / ${height}`}"
  >
    <img
      ref="image"
      loading="lazy"
      :src="image.url"
      :width="width"
      :height="height"
      class="rounded"
      @load="onImageLoad"
    >
    <div
      class="top-0 bottom-0 left-0 right-0 absolute"
      @pointerdown="onStartDraw"
      @contextmenu="openContextMenu"
    >
      <SelectionBox
        v-if="showSelectionBox"
        :selection-box="selectionBox"
        :page-width="width"
        :page-height="height"
        :is-resizing="!!resizeDirection"
        :is-drawing="!!drawFieldType"
        :is-drag="isDrag"
        @move="onSelectionBoxMove"
        @contextmenu="openSelectionContextMenu"
        @close-context-menu="closeSelectionContextMenu"
      />
      <FieldArea
        v-for="(item, i) in areas"
        :key="i"
        :ref="setAreaRefs"
        :area="item.area"
        :input-mode="inputMode"
        :page-width="width"
        :page-height="height"
        :field="item.field"
        :editable="editable"
        :with-field-placeholder="withFieldPlaceholder"
        :with-signature-id="withSignatureId"
        :with-prefillable="withPrefillable"
        :default-field="defaultFieldsIndex[item.field.name]"
        :default-submitters="defaultSubmitters"
        :max-page="totalPages - 1"
        :is-select-mode="isSelectMode"
        @start-resize="resizeDirection = $event"
        @stop-resize="resizeDirection = null"
        @remove="$emit('remove-area', item.area)"
        @scroll-to="$emit('scroll-to', $event)"
        @contextmenu="openAreaContextMenu($event, item.area, item.field)"
      />
      <FieldArea
        v-if="newArea"
        :is-draw="true"
        :page-width="width"
        :page-height="height"
        :field="{ submitter_uuid: selectedSubmitter.uuid, type: drawField?.type || dragFieldPlaceholder?.type || defaultFieldType }"
        :area="newArea"
      />
      <div
        v-if="selectionRect"
        class="absolute outline-dashed outline-gray-400 pointer-events-none z-20"
        :style="selectionRectStyle"
      />
      <ContextMenu
        v-if="contextMenu"
        :context-menu="contextMenu"
        :field="contextMenu.field"
        :editable="editable"
        :with-fields-detection="withFieldsDetection"
        @copy="handleCopy"
        @delete="handleDelete"
        @paste="handlePaste"
        @autodetect-fields="handleAutodetectFields"
        @close="closeContextMenu"
      />
      <ContextMenu
        v-if="selectionContextMenu"
        :context-menu="selectionContextMenu"
        :editable="editable"
        :is-multi-selection="true"
        :selected-areas="selectedAreasRef.value"
        :template="template"
        @copy="handleSelectionCopy"
        @delete="handleSelectionDelete"
        @align="handleSelectionAlign"
        @close="closeSelectionContextMenu"
      />
    </div>
    <div
      v-show="resizeDirection || isDrag || showMask || (drawField && isMobile) || fieldsDragFieldRef.value || selectionRect"
      id="mask"
      ref="mask"
      class="top-0 bottom-0 left-0 right-0 absolute"
      :class="{ 'z-10': !isMobile, 'cursor-grab': isDrag, 'cursor-nwse-resize': drawField && !isSelectMode, [resizeDirectionClasses[resizeDirection]]: !!resizeDirectionClasses }"
      @pointermove="onPointermove"
      @pointerdown="onStartDraw"
      @contextmenu="openContextMenu"
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
import ContextMenu from './context_menu'
import SelectionBox from './selection_box'

export default {
  name: 'TemplatePage',
  components: {
    FieldArea,
    ContextMenu,
    SelectionBox
  },
  inject: ['fieldTypes', 'defaultDrawFieldType', 'fieldsDragFieldRef', 'assignDropAreaSize', 'selectedAreasRef', 'template', 'isSelectModeRef'],
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
    },
    attachmentUuid: {
      type: String,
      required: false,
      default: ''
    },
    withFieldsDetection: {
      type: Boolean,
      required: false,
      default: false
    }
  },
  emits: ['draw', 'drop-field', 'remove-area', 'copy-field', 'paste-field', 'scroll-to', 'copy-selected-areas', 'delete-selected-areas', 'align-selected-areas', 'autodetect-fields'],
  data () {
    return {
      areaRefs: [],
      showMask: false,
      resizeDirection: null,
      newArea: null,
      contextMenu: null,
      selectionRect: null,
      selectionContextMenu: null
    }
  },
  computed: {
    isSelectMode () {
      return this.isSelectModeRef.value && !this.drawFieldType && this.editable && !this.drawField
    },
    pageSelectedAreas () {
      if (!this.selectedAreasRef.value) return []

      return this.selectedAreasRef.value.filter((a) =>
        a.attachment_uuid === this.attachmentUuid && a.page === this.number
      )
    },
    showSelectionBox () {
      return this.pageSelectedAreas.length >= 2 && this.editable
    },
    minSelectionBoxHeight () {
      const ys = this.pageSelectedAreas.map((a) => a.y)

      return Math.max(...ys) - Math.min(...ys)
    },
    minSelectionBoxWidth () {
      const xs = this.pageSelectedAreas.map((a) => a.x)

      return Math.max(...xs) - Math.min(...xs)
    },
    selectionBox () {
      if (!this.pageSelectedAreas.length) return null

      const minX = Math.min(...this.pageSelectedAreas.map((a) => a.x))
      const minY = Math.min(...this.pageSelectedAreas.map((a) => a.y))
      const maxX = Math.max(...this.pageSelectedAreas.map((a) => a.x + a.w))
      const maxY = Math.max(...this.pageSelectedAreas.map((a) => a.y + a.h))

      return {
        x: minX,
        y: minY,
        w: Math.max(maxX - minX, this.minSelectionBoxWidth),
        h: Math.max(maxY - minY, this.minSelectionBoxHeight)
      }
    },
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
    },
    selectionRectStyle () {
      if (!this.selectionRect) return {}

      return {
        left: this.selectionRect.x * 100 + '%',
        top: this.selectionRect.y * 100 + '%',
        width: this.selectionRect.w * 100 + '%',
        height: this.selectionRect.h * 100 + '%'
      }
    }
  },
  beforeUpdate () {
    this.areaRefs = []
  },
  methods: {
    onImageLoad (e) {
      this.image.metadata.width = e.target.naturalWidth
      this.image.metadata.height = e.target.naturalHeight
    },
    openContextMenu (event) {
      if (!this.editable) {
        return
      }

      event.preventDefault()
      event.stopPropagation()

      const rect = this.$refs.image.getBoundingClientRect()

      this.newArea = null
      this.showMask = false

      this.contextMenu = {
        x: event.clientX,
        y: event.clientY,
        relativeX: (event.clientX - rect.left) / rect.width,
        relativeY: (event.clientY - rect.top) / rect.height
      }
    },
    openAreaContextMenu (event, area, field) {
      if (!this.editable) {
        return
      }

      event.preventDefault()
      event.stopPropagation()

      const rect = this.$refs.image.getBoundingClientRect()

      this.newArea = null
      this.showMask = false

      this.contextMenu = {
        x: event.clientX,
        y: event.clientY,
        relativeX: (event.clientX - rect.left) / rect.width,
        relativeY: (event.clientY - rect.top) / rect.height,
        area,
        field
      }
    },
    openSelectionContextMenu (event) {
      const rect = this.$el.getBoundingClientRect()

      this.selectionContextMenu = {
        x: event.clientX,
        y: event.clientY,
        relativeX: (event.clientX - rect.left) / rect.width,
        relativeY: (event.clientY - rect.top) / rect.height
      }
    },
    closeSelectionContextMenu () {
      this.selectionContextMenu = null
    },
    handleSelectionCopy () {
      this.$emit('copy-selected-areas')
      this.closeSelectionContextMenu()
    },
    handleSelectionDelete () {
      this.$emit('delete-selected-areas')
      this.closeSelectionContextMenu()
    },
    handleSelectionAlign (direction) {
      this.$emit('align-selected-areas', direction)
      this.closeSelectionContextMenu()
    },
    closeContextMenu () {
      this.contextMenu = null
      this.newArea = null
      this.showMask = false
    },
    handleCopy () {
      if (this.contextMenu.area) {
        this.selectedAreasRef.value = [this.contextMenu.area]

        this.$emit('copy-field')
      }

      this.closeContextMenu()
    },
    handleDelete () {
      if (this.contextMenu.area) {
        this.$emit('remove-area', this.contextMenu.area)
      }

      this.closeContextMenu()
    },
    handlePaste () {
      this.newArea = null
      this.showMask = false

      this.$emit('paste-field', {
        page: this.number,
        x: this.contextMenu.relativeX,
        y: this.contextMenu.relativeY
      })

      this.closeContextMenu()
    },
    handleAutodetectFields () {
      this.$emit('autodetect-fields', {
        page: this.number,
        attachmentUuid: this.attachmentUuid
      })

      this.closeContextMenu()
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
      if (e.button === 2) {
        return
      }

      if (this.selectedAreasRef.value.length >= 2) {
        this.selectedAreasRef.value = []
      }

      if (this.isSelectMode) {
        this.startSelectionRect(e)

        return
      }

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
    startSelectionRect (e) {
      this.selectedAreasRef.value = []

      this.showMask = true

      this.$nextTick(() => {
        const x = e.offsetX / this.$refs.mask.clientWidth
        const y = e.offsetY / this.$refs.mask.clientHeight

        this.selectionRect = {
          initialX: x,
          initialY: y,
          x,
          y,
          w: 0,
          h: 0
        }
      })
    },
    onSelectionBoxMove (dx, dy) {
      let clampedDx = dx
      let clampedDy = dy

      this.pageSelectedAreas.forEach((area) => {
        const maxDxLeft = -area.x
        const maxDxRight = 1 - area.w - area.x
        const maxDyTop = -area.y
        const maxDyBottom = 1 - area.h - area.y

        if (dx < maxDxLeft) clampedDx = Math.max(clampedDx, maxDxLeft)
        if (dx > maxDxRight) clampedDx = Math.min(clampedDx, maxDxRight)
        if (dy < maxDyTop) clampedDy = Math.max(clampedDy, maxDyTop)
        if (dy > maxDyBottom) clampedDy = Math.min(clampedDy, maxDyBottom)
      })

      this.pageSelectedAreas.forEach((area) => {
        area.x += clampedDx
        area.y += clampedDy
      })
    },
    onPointermove (e) {
      if (this.selectionRect) {
        const dx = e.offsetX / this.$refs.mask.clientWidth - this.selectionRect.initialX
        const dy = e.offsetY / this.$refs.mask.clientHeight - this.selectionRect.initialY

        if (dx > 0) {
          this.selectionRect.x = this.selectionRect.initialX
        } else {
          this.selectionRect.x = e.offsetX / this.$refs.mask.clientWidth
        }

        if (dy > 0) {
          this.selectionRect.y = this.selectionRect.initialY
        } else {
          this.selectionRect.y = e.offsetY / this.$refs.mask.clientHeight
        }

        this.selectionRect.w = Math.abs(dx)
        this.selectionRect.h = Math.abs(dy)

        return
      }

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
      if (this.selectionRect) {
        const selRect = this.selectionRect
        const areasToSelect = this.areas || []

        areasToSelect.forEach((item) => {
          const area = item.area

          if (this.rectsOverlap(selRect, area)) {
            this.selectedAreasRef.value.push(area)
          }
        })

        this.selectionRect = null
      } else if (this.newArea) {
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
    },
    rectsOverlap (r1, r2) {
      return !(
        r1.x + r1.w < r2.x ||
        r2.x + r2.w < r1.x ||
        r1.y + r1.h < r2.y ||
        r2.y + r2.h < r1.y
      )
    }
  }
}
</script>

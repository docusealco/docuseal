<template>
  <span
    class="items-center select-none cursor-pointer relative overflow-visible text-base-content/80 font-sans"
    :class="[bgColorClass, iconOnlyField ? 'justify-center' : '']"
    :draggable="editable"
    :style="[nodeStyle]"
    @mousedown="selectArea"
    @dragstart="onDragStart"
    @contextmenu.prevent.stop="onContextMenu"
  >
    <span
      class="absolute inset-0 pointer-events-none border-solid"
      :class="borderColorClass"
      :style="{ borderWidth: (isSelected ? 1 : 0) + 'px' }"
    />
    <component
      :is="fieldIcons[field?.type || 'text']"
      v-if="field && !field.default_value"
      width="100%"
      height="100%"
      :stroke-width="1.5"
      :class="iconOnlyField ? 'shrink min-h-0 max-h-full max-w-6 opacity-70 m-auto p-0.5' : 'shrink min-h-0 max-h-full max-w-4 opacity-70 mx-0.5 pl-0.5'"
    />
    <span
      v-if="field?.default_value"
      class="text-xs overflow-hidden text-ellipsis whitespace-nowrap pr-1 font-normal pl-0.5"
    >
      <template v-if="field.default_value === '{{date}}'">
        {{ t('signing_date') }}
      </template>
      <template v-else>
        {{ field.default_value }}
      </template>
    </span>
    <span
      v-else-if="field && !iconOnlyField"
      class="text-xs overflow-hidden text-ellipsis whitespace-nowrap pr-1 opacity-70 font-normal pl-0.5"
    >{{ displayLabel }}</span>
    <span
      class="absolute rounded-full bg-white border border-gray-400 shadow-md cursor-nwse-resize z-10"
      :style="{ width: resizeHandleSize + 'px', height: resizeHandleSize + 'px', right: (-4 / zoom) + 'px', bottom: (-4 / zoom) + 'px' }"
      @pointerdown.prevent.stop="onResizeStart"
    />
  </span>
</template>

<script>
import FieldArea from './area'
import FieldType from './field_type'

export default {
  name: 'DynamicArea',
  props: {
    fieldUuid: {
      type: String,
      required: true
    },
    areaUuid: {
      type: String,
      required: true
    },
    template: {
      type: Object,
      required: true
    },
    nodeStyle: {
      type: Object,
      required: true
    },
    selectedAreasRef: {
      type: Object,
      required: true
    },
    getPos: {
      type: Function,
      required: true
    },
    editor: {
      type: Object,
      required: true
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    },
    getZoom: {
      type: Function,
      required: true
    },
    onAreaContextMenu: {
      type: Function,
      required: true
    },
    onAreaResize: {
      type: Function,
      required: true
    },
    onAreaDragStart: {
      type: Function,
      required: true
    },
    t: {
      type: Function,
      required: true
    },
    findFieldArea: {
      type: Function,
      required: true
    },
    getFieldTypeIndex: {
      type: Function,
      required: true
    }
  },
  data () {
    return {
      isResizing: false
    }
  },
  computed: {
    fieldArea () {
      return this.findFieldArea(this.areaUuid)
    },
    area () {
      return this.fieldArea?.area
    },
    field () {
      return this.fieldArea?.field
    },
    fieldIcons: FieldArea.computed.fieldIcons,
    fieldNames: FieldArea.computed.fieldNames,
    fieldLabels: FieldType.computed.fieldLabels,
    borderColors () {
      return [
        'border-red-500/80',
        'border-sky-500/80',
        'border-emerald-500/80',
        'border-yellow-300/80',
        'border-purple-600/80',
        'border-pink-500/80',
        'border-cyan-500/80',
        'border-orange-500/80',
        'border-lime-500/80',
        'border-indigo-500/80'
      ]
    },
    bgColors () {
      return [
        'bg-red-100',
        'bg-sky-100',
        'bg-emerald-100',
        'bg-yellow-100',
        'bg-purple-100',
        'bg-pink-100',
        'bg-cyan-100',
        'bg-orange-100',
        'bg-lime-100',
        'bg-indigo-100'
      ]
    },
    isSelected () {
      return this.selectedAreasRef.value.some((a) => a === this.area)
    },
    zoom () {
      return this.getZoom()
    },
    submitterIndex () {
      if (!this.field) return 0

      const submitter = this.template.submitters.find((s) => s.uuid === this.field.submitter_uuid)

      return submitter ? this.template.submitters.indexOf(submitter) : 0
    },
    borderColorClass () {
      return this.borderColors[this.submitterIndex % this.borderColors.length]
    },
    bgColorClass () {
      return this.bgColors[this.submitterIndex % this.bgColors.length]
    },
    resizeHandleSize () {
      return this.zoom > 0 ? Math.round(10 / this.zoom) : 10
    },
    iconOnlyField () {
      return ['radio', 'multiple', 'checkbox', 'initials'].includes(this.field?.type)
    },
    defaultName () {
      if (!this.field) return 'text'

      const typeIndex = this.getFieldTypeIndex(this.field)

      return `${this.fieldLabels[this.field.type] || this.fieldNames[this.field.type] || this.field.type} ${typeIndex + 1}`
    },
    displayLabel () {
      return this.field?.name || this.defaultName
    }
  },
  methods: {
    selectArea () {
      this.editor.commands.setNodeSelection(this.getPos())
    },
    onDragStart (e) {
      if (this.isResizing) {
        e.preventDefault()

        return
      }

      const pos = this.getPos()

      if (pos == null) {
        e.preventDefault()

        return
      }

      const root = this.$el
      const rect = root.getBoundingClientRect()
      const zoom = this.zoom || 1
      const clone = root.cloneNode(true)

      clone.querySelector('[class*="cursor-nwse-resize"]')?.remove()
      clone.style.cssText = `position:fixed;top:-1000px;width:${rect.width / zoom}px;height:${rect.height / zoom}px;display:${root.style.display};vertical-align:${root.style.verticalAlign};zoom:${zoom}`

      document.body.appendChild(clone)

      e.dataTransfer.setDragImage(clone, e.offsetX, e.offsetY)

      requestAnimationFrame(() => clone.remove())

      e.dataTransfer.effectAllowed = 'move'

      this.onAreaDragStart()
    },
    onContextMenu (e) {
      this.selectArea()
      this.onAreaContextMenu(this.area, e)
    },
    onResizeStart (e) {
      if (!this.editable) return

      this.isResizing = true

      this.selectArea()

      const handle = e.target

      handle.setPointerCapture(e.pointerId)

      const startX = e.clientX
      const startY = e.clientY
      const startWidth = this.$el.offsetWidth
      const startHeight = this.$el.offsetHeight

      const onResizeMove = (e) => {
        e.preventDefault()

        this.nodeStyle.width = startWidth + (e.clientX - startX) / this.zoom + 'px'
        this.nodeStyle.height = startHeight + (e.clientY - startY) / this.zoom + 'px'

        this.onAreaResize(this.$el.getBoundingClientRect())
      }

      const onResizeEnd = () => {
        if (!this.isResizing) return

        this.isResizing = false

        handle.removeEventListener('pointermove', onResizeMove)
        handle.removeEventListener('pointerup', onResizeEnd)

        const pos = this.getPos()

        const tr = this.editor.view.state.tr.setNodeMarkup(pos, undefined, {
          ...this.editor.view.state.doc.nodeAt(pos)?.attrs,
          width: this.nodeStyle.width,
          height: this.nodeStyle.height
        })

        this.editor.view.dispatch(tr)
        this.editor.commands.setNodeSelection(pos)
      }

      handle.addEventListener('pointermove', onResizeMove)
      handle.addEventListener('pointerup', onResizeEnd)
    }
  }
}
</script>

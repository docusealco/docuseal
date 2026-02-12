<template>
  <div
    class="relative bg-white select-none mb-4 before:border before:rounded before:top-0 before:bottom-0 before:left-0 before:right-0 before:absolute"
  >
    <div :style="{ zoom: containerWidth / sectionWidthPx }">
      <section
        :id="section.id"
        ref="editorElement"
        :class="section.classList.value"
        :style="section.style.cssText"
      />
    </div>
    <Teleport
      v-if="editor"
      :to="container"
    >
      <div
        v-if="areaToolbarCoords && selectedField && selectedArea && !isAreaDrag"
        class="absolute z-10"
        :style="{ left: areaToolbarCoords.left + 'px', top: areaToolbarCoords.top + 'px' }"
      >
        <AreaTitle
          :area="selectedArea"
          :field="selectedField"
          :editable="editable"
          :template="template"
          :selected-areas-ref="selectedAreasRef"
          :get-field-type-index="getFieldTypeIndex"
          @remove="onRemoveSelectedArea"
          @change="onSelectedAreaChange"
        />
      </div>
      <DynamicMenu
        v-if="editable"
        v-show="!selectedAreasRef.value.length"
        :editor="editor"
        :coords="dynamicMenuCoords"
        @add-variable="dynamicMenuCoords = null"
        @add-condition="dynamicMenuCoords = null"
      />
      <FieldContextMenu
        v-if="contextMenu && contextMenuField"
        :context-menu="contextMenu"
        :field="contextMenuField"
        :with-copy-to-all-pages="false"
        @close="closeContextMenu"
        @delete="onContextMenuDelete"
        @save="save"
      />
    </Teleport>
  </div>
</template>

<script>
import { shallowRef } from 'vue'
import { v4 } from 'uuid'
import FieldContextMenu from './field_context_menu.vue'
import AreaTitle from './area_title.vue'
import DynamicMenu from './dynamic_menu.vue'
import { buildEditor } from './dynamic_editor.js'

export default {
  name: 'DynamicSection',
  components: {
    DynamicMenu,
    FieldContextMenu,
    AreaTitle
  },
  inject: ['template', 'save', 't', 'fieldsDragFieldRef', 'customDragFieldRef', 'selectedAreasRef', 'getFieldTypeIndex', 'fieldTypes', 'withPhone', 'withPayment', 'withVerification', 'withKba', 'backgroundColor'],
  props: {
    section: {
      type: Object,
      required: true
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    },
    container: {
      type: Object,
      required: true
    },
    containerWidth: {
      type: Number,
      required: true
    },
    attachmentsIndex: {
      type: Object,
      required: false,
      default: () => ({})
    },
    selectedSubmitter: {
      type: Object,
      required: false,
      default: null
    },
    dragField: {
      type: Object,
      required: false,
      default: null
    },
    attachmentUuid: {
      type: String,
      required: false,
      default: null
    }
  },
  emits: ['update'],
  data () {
    return {
      isAreaDrag: false,
      areaToolbarCoords: null,
      dynamicMenuCoords: null,
      contextMenu: null
    }
  },
  computed: {
    defaultHeight () {
      return CSS.supports('height', '1lh') ? '1lh' : '1em'
    },
    fieldAreaIndex () {
      return (this.template.fields || []).reduce((acc, field) => {
        field.areas?.forEach((area) => {
          acc[area.uuid] = { area, field }
        })

        return acc
      }, {})
    },
    defaultSizes () {
      return {
        checkbox: { width: '18px', height: '18px' },
        radio: { width: '18px', height: '18px' },
        multiple: { width: '18px', height: '18px' },
        signature: { width: '140px', height: '50px' },
        initials: { width: '40px', height: '32px' },
        stamp: { width: '150px', height: '80px' },
        kba: { width: '150px', height: '80px' },
        verification: { width: '150px', height: '80px' },
        image: { width: '200px', height: '100px' },
        date: { width: '100px', height: this.defaultHeight },
        text: { width: '120px', height: this.defaultHeight },
        cells: { width: '120px', height: this.defaultHeight },
        file: { width: '120px', height: this.defaultHeight },
        payment: { width: '120px', height: this.defaultHeight },
        number: { width: '80px', height: this.defaultHeight },
        select: { width: '120px', height: this.defaultHeight },
        phone: { width: '120px', height: this.defaultHeight }
      }
    },
    editorRef: () => shallowRef(),
    editor () {
      return this.editorRef.value
    },
    sectionWidthPx () {
      const pt = parseFloat(this.section.style.width)

      return pt * (96 / 72)
    },
    zoom () {
      return this.containerWidth / this.sectionWidthPx
    },
    isDraggingField () {
      return !!(this.fieldsDragFieldRef?.value || this.customDragFieldRef?.value || this.dragField)
    },
    selectedArea () {
      return this.selectedAreasRef.value[0]
    },
    selectedField () {
      if (this.selectedArea) {
        return this.fieldAreaIndex[this.selectedArea.uuid]?.field
      } else {
        return null
      }
    },
    contextMenuField () {
      if (this.contextMenu?.areaUuid) {
        return this.fieldAreaIndex[this.contextMenu.areaUuid].field
      } else {
        return null
      }
    }
  },
  watch: {
    containerWidth () {
      this.closeContextMenu()

      if (this.dynamicMenuCoords && this.editor && !this.editor.state.selection.empty) {
        this.$nextTick(() => this.setDynamicMenuCoords(this.editor))
      }
    }
  },
  mounted () {
    this.initEditor()
  },
  beforeUnmount () {
    if (this.editor) {
      this.editor.destroy()
    }
  },
  methods: {
    async initEditor () {
      this.editorRef.value = buildEditor({
        dynamicAreaProps: {
          template: this.template,
          t: this.t,
          selectedAreasRef: this.selectedAreasRef,
          getFieldTypeIndex: this.getFieldTypeIndex,
          findFieldArea: (areaUuid) => this.fieldAreaIndex[areaUuid],
          getZoom: () => this.zoom,
          onAreaContextMenu: this.onAreaContextMenu,
          onAreaResize: this.onAreaResize,
          onAreaDragStart: this.onAreaDragStart
        },
        attachmentsIndex: this.attachmentsIndex,
        onFieldDrop: this.onFieldDrop,
        onFieldDestroy: this.onFieldDestroy,
        editorOptions: {
          element: this.$refs.editorElement,
          editable: this.editable,
          content: this.section.innerHTML,
          onUpdate: (event) => this.$emit('update', event),
          onSelectionUpdate: this.onSelectionUpdate,
          onBlur: () => { this.dynamicMenuCoords = null }
        }
      })
    },
    findAreaNodePos (areaUuid) {
      const el = this.editor.view.dom.querySelector(`[data-area-uuid="${areaUuid}"]`)

      return this.editor.view.posAtDOM(el, 0)
    },
    removeArea (area) {
      const { field } = this.fieldAreaIndex[area.uuid]
      const areaIndex = field.areas.indexOf(area)

      if (areaIndex !== -1) {
        field.areas.splice(areaIndex, 1)
      }

      if (field.areas.length === 0) {
        this.template.fields.splice(this.template.fields.indexOf(field), 1)
      }

      const pos = this.findAreaNodePos(area.uuid)

      this.editor.chain().focus().deleteRange({ from: pos, to: pos + 1 }).run()

      this.save()
    },
    onSelectionUpdate ({ editor }) {
      const { selection } = editor.state

      if (selection.node?.type.name === 'fieldNode') {
        const { areaUuid } = selection.node.attrs

        const field = this.fieldAreaIndex[areaUuid]?.field

        if (field) {
          const area = field.areas.find((a) => a.uuid === areaUuid)

          if (area) {
            const dom = editor.view.nodeDOM(selection.from)
            const areaEl = dom.shadowRoot.firstElementChild

            if (areaEl) {
              const rect = areaEl.getBoundingClientRect()
              const containerRect = this.container.getBoundingClientRect()

              this.areaToolbarCoords = {
                left: rect.left - containerRect.left,
                top: rect.top - containerRect.top
              }
            }

            this.selectedAreasRef.value = [area]
          }
        }
      } else {
        this.areaToolbarCoords = null
        this.selectedAreasRef.value = []

        if (editor.state.selection.empty) {
          this.dynamicMenuCoords = null
        } else {
          this.setDynamicMenuCoords(editor)
        }
      }
    },
    setDynamicMenuCoords (editor) {
      const { from, to } = editor.state.selection
      const view = editor.view
      const start = view.coordsAtPos(from)
      const end = view.coordsAtPos(to)
      const containerRect = this.container.getBoundingClientRect()
      const left = (start.left + end.right) / 2 - containerRect.left

      this.dynamicMenuCoords = {
        top: Math.min(start.top, end.top) - containerRect.top,
        left: Math.max(80, Math.min(left, containerRect.width - 80))
      }
    },
    onFieldDestroy (node) {
      this.selectedAreasRef.value = []

      const { areaUuid } = node.attrs

      let nodeExistsInDoc = false

      this.editor.state.doc.descendants((docNode) => {
        if (docNode.attrs.areaUuid === areaUuid) {
          nodeExistsInDoc = true

          return false
        }
      })

      if (nodeExistsInDoc) return

      const fieldArea = this.fieldAreaIndex[areaUuid]

      if (!fieldArea) return

      const field = fieldArea.field

      const areaIndex = field.areas.findIndex((a) => a.uuid === areaUuid)

      if (areaIndex !== -1) {
        field.areas.splice(areaIndex, 1)
      }

      if (!field.areas?.length) {
        this.template.fields.splice(this.template.fields.indexOf(field), 1)
      }

      this.save()
    },
    onAreaResize (rect) {
      const containerRect = this.container.getBoundingClientRect()

      this.areaToolbarCoords = {
        left: rect.left - containerRect.left,
        top: rect.top - containerRect.top
      }
    },
    onAreaDragStart () {
      this.isAreaDrag = true
    },
    onAreaContextMenu (area, e) {
      this.contextMenu = {
        x: e.clientX,
        y: e.clientY,
        areaUuid: area.uuid
      }
    },
    deselectArea () {
      this.areaToolbarCoords = null
      this.selectedAreasRef.value = []
    },
    closeContextMenu () {
      this.contextMenu = null
    },
    onContextMenuDelete () {
      const menu = this.contextMenu
      const fieldArea = this.fieldAreaIndex[menu.areaUuid]

      if (fieldArea) {
        this.removeArea(fieldArea.area)
      }

      this.closeContextMenu()
      this.deselectArea()
    },
    onRemoveSelectedArea () {
      this.removeArea(this.selectedArea)

      this.deselectArea()
      this.save()
    },
    onSelectedAreaChange () {
      this.save()
    },
    onFieldDrop (view, event, _slice, moved) {
      this.isAreaDrag = false

      if (moved) {
        return
      }

      const draggedField = this.fieldsDragFieldRef?.value || this.customDragFieldRef?.value || this.dragField

      if (!draggedField) return false

      event.preventDefault()

      const pos = view.posAtCoords({ left: event.clientX, top: event.clientY })

      if (!pos) return false

      const fieldType = draggedField.type || 'text'
      const dims = this.defaultSizes[fieldType] || this.defaultSizes.text
      const areaUuid = v4()

      const existingField = this.fieldsDragFieldRef?.value

      if (existingField) {
        if (!this.template.fields.includes(existingField)) {
          this.template.fields.push(existingField)
        }

        existingField.areas = existingField.areas || []
        existingField.areas.push({ uuid: areaUuid, attachment_uuid: this.attachmentUuid })

        const nodeType = view.state.schema.nodes.fieldNode
        const fieldNode = nodeType.create({
          uuid: existingField.uuid,
          areaUuid,
          width: dims.width,
          height: dims.height
        })

        const tr = view.state.tr.insert(pos.pos, fieldNode)

        view.dispatch(tr)
      } else {
        const newField = {
          name: draggedField.name || '',
          uuid: v4(),
          required: fieldType !== 'checkbox',
          submitter_uuid: this.selectedSubmitter.uuid,
          type: fieldType,
          areas: [{ uuid: areaUuid, attachment_uuid: this.attachmentUuid }]
        }

        if (['select', 'multiple', 'radio'].includes(fieldType)) {
          if (draggedField.options?.length) {
            newField.options = draggedField.options.map((opt) => ({
              value: typeof opt === 'string' ? opt : opt.value,
              uuid: v4()
            }))
          } else {
            newField.options = [{ value: '', uuid: v4() }, { value: '', uuid: v4() }]
          }
        }

        if (fieldType === 'datenow') {
          newField.type = 'date'
          newField.readonly = true
          newField.default_value = '{{date}}'
        }

        if (['stamp', 'heading', 'strikethrough'].includes(fieldType)) {
          newField.readonly = true

          if (fieldType === 'strikethrough') {
            newField.default_value = true
          }
        }

        this.template.fields.push(newField)

        const nodeType = view.state.schema.nodes.fieldNode
        const fieldNode = nodeType.create({
          uuid: newField.uuid,
          areaUuid,
          width: dims.width,
          height: dims.height
        })

        const tr = view.state.tr.insert(pos.pos, fieldNode)

        view.dispatch(tr)
      }

      this.fieldsDragFieldRef.value = null
      this.customDragFieldRef.value = null

      this.editor.chain().focus().setNodeSelection(pos.pos).run()

      this.save()

      return true
    }
  }
}
</script>

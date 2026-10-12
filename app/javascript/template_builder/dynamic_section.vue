<template>
  <div
    class="relative bg-white select-none mb-4 before:border before:rounded before:top-0 before:bottom-0 before:left-0 before:right-0 before:absolute"
    :class="{ 'cursor-crosshair': isDrawMode && editable }"
    @mousedown="onMarginMouseDown"
  >
    <div
      v-if="isDrawMode && editable && cursorHighlightCoords"
      class="absolute pointer-events-none z-10 bg-black"
      :style="{ width: '1px', height: cursorHighlightCoords.height + 'px', left: cursorHighlightCoords.x + 'px', top: cursorHighlightCoords.y + 'px' }"
    />
    <div
      :style="{ zoom, '--zoom': zoom }"
      :data-zoomed-out="zoom < 0.75 || null"
    >
      <section
        :id="section.id"
        ref="editorElement"
        dir="auto"
        :class="section.classList.value"
        :style="section.style.cssText"
      />
    </div>
    <input
      ref="imageInput"
      type="file"
      accept="image/*"
      class="hidden"
      @change="onImageSelected"
    >
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
          :is-mobile="isMobile"
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
        :coords="isInsertMenuOpen ? null : dynamicMenuCoords"
        @add-variable="dynamicMenuCoords = null"
        @add-condition="dynamicMenuCoords = null"
        @add-list="$emit('add-list')"
      />
      <div
        v-if="editable && insertMenuCoords && !isDrawMode"
        class="absolute z-10 select-none text-sm"
        :style="{ top: insertMenuCoords.top - 12 + 'px', left: insertMenuCoords.left - 12 + 'px' }"
        @mousedown.prevent
      >
        <button
          class="flex items-center justify-center w-6 h-6 rounded-md border border-neutral-200"
          :class="isInsertMenuOpen ? 'bg-neutral-100 text-base-content' : 'bg-white text-base-content/40 hover:bg-neutral-100 hover:text-base-content'"
          :title="t('insert')"
          @click="isInsertMenuOpen = !isInsertMenuOpen"
        >
          <IconX
            v-if="isInsertMenuOpen"
            :width="14"
            :height="14"
          />
          <IconPlus
            v-else
            :width="14"
            :height="14"
          />
        </button>
        <DynamicInsertMenu
          v-if="isInsertMenuOpen"
          :key="insertMenuCoords.top"
          @close="isInsertMenuOpen = false"
          @insert-field="onInsertField"
          @insert-table="onInsertTable"
          @insert-variable="editor.chain().focus().insertContent('[[variable]]').run()"
          @insert-image="$refs.imageInput.click()"
        />
      </div>
      <DynamicBlockMenu
        v-if="editable && blockMenuCoords && !isDrawMode"
        :coords="blockMenuCoords"
        :get-resize-limits="getBlockResizeLimits"
        @command="onBlockCommand"
        @resize="onBlockResize"
      />
      <FieldContextMenu
        v-if="contextMenu && contextMenuField"
        :context-menu="contextMenu"
        :field="contextMenuField"
        :with-copy-to-all-pages="false"
        @close="closeContextMenu"
        @copy="onContextMenuCopy"
        @delete="onContextMenuDelete"
        @add-custom-field="$emit('add-custom-field', $event)"
        @set-draw="$emit('set-draw', $event)"
        @save="save"
      />
    </Teleport>
  </div>
</template>

<script>
import { shallowRef } from 'vue'
import { DOMSerializer, Fragment } from '@tiptap/pm/model'
import { Selection, TextSelection } from '@tiptap/pm/state'
import { findTable, CellSelection } from '@tiptap/pm/tables'
import { v4 } from 'uuid'
import { IconPlus, IconX } from '@tabler/icons-vue'
import FieldContextMenu from './field_context_menu.vue'
import AreaTitle from './area_title.vue'
import DynamicMenu from './dynamic_menu.vue'
import DynamicInsertMenu from './dynamic_insert_menu.vue'
import DynamicBlockMenu from './dynamic_block_menu.vue'
import { buildEditor, isRegularTable, resizeTable, tableRowMinHeights } from './dynamic_editor.js'

export default {
  name: 'DynamicSection',
  components: {
    DynamicMenu,
    DynamicInsertMenu,
    DynamicBlockMenu,
    FieldContextMenu,
    AreaTitle,
    IconPlus,
    IconX
  },
  inject: ['template', 'save', 'pushUndo', 'undo', 'redo', 'baseFetch', 't', 'fieldsDragFieldRef', 'customDragFieldRef', 'selectedAreasRef', 'getFieldTypeIndex', 'fieldTypes', 'withPhone', 'withPayment', 'withVerification', 'withKba', 'backgroundColor', 'isMobile'],
  props: {
    section: {
      type: Object,
      required: true
    },
    sectionRefs: {
      type: Array,
      required: false,
      default: () => []
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
    drawField: {
      type: Object,
      required: false,
      default: null
    },
    drawFieldType: {
      type: String,
      required: false,
      default: ''
    },
    drawCustomField: {
      type: Object,
      required: false,
      default: null
    },
    renderHtmlForSaveRef: {
      type: Object,
      required: false,
      default: null
    },
    drawOption: {
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
  emits: ['update', 'draw', 'set-draw', 'add-custom-field', 'add-attachment', 'add-list'],
  data () {
    return {
      isAreaDrag: false,
      areaToolbarCoords: null,
      dynamicMenuCoords: null,
      insertMenuCoords: null,
      isInsertMenuOpen: false,
      blockMenuCoords: null,
      contextMenu: null,
      cursorHighlightCoords: null
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
        datenow: { width: '100px', height: this.defaultHeight },
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
    sectionKey () {
      return `${this.attachmentUuid}:${this.section.id}`
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
    isDrawMode () {
      return !!(this.drawField || this.drawCustomField || this.drawFieldType)
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

      if (this.insertMenuCoords && this.editor) {
        this.$nextTick(() => this.setInsertMenuCoords(this.editor))
      }

      if (this.blockMenuCoords && this.editor) {
        this.$nextTick(() => this.setBlockMenuCoords(this.editor))
      }
    }
  },
  mounted () {
    this.lastUpdateTime = 0

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
      getAttachmentsIndex: () => this.attachmentsIndex,
      onFieldDrop: this.onFieldDrop,
      onFieldDestroy: this.onFieldDestroy,
      onUndo: this.undo,
      onRedo: this.redo,
      renderHtmlForSaveRef: this.renderHtmlForSaveRef,
      editorOptions: {
        element: this.$refs.editorElement,
        editable: this.editable,
        content: this.section.innerHTML,
        onUpdate: (event) => {
          this.$emit('update', event)

          if (event.transaction.getMeta('addToHistory') !== false) {
            this.pushUndo({ amend: event.transaction.time - this.lastUpdateTime < 500 })

            this.lastUpdateTime = event.transaction.time
          }

          if (this.blockMenuCoords) {
            this.$nextTick(() => this.setBlockMenuCoords(this.editor))
          }
        },
        onSelectionUpdate: this.onSelectionUpdate,
        onFocus: this.onSelectionUpdate,
        onBlur: () => {
          this.dynamicMenuCoords = null
          this.insertMenuCoords = null
          this.blockMenuCoords = null
        }
      }
    })

    this.editor.view.dom.addEventListener('paste', this.onEditorPaste, true)
    this.editor.view.dom.addEventListener('pointerdown', this.onEditorPointerDown, true)
    this.editor.view.dom.addEventListener('mousemove', this.onEditorMouseMove)
    this.editor.view.dom.addEventListener('mouseleave', this.onEditorMouseLeave)
    this.editor.view.dom.addEventListener('keydown', this.onEditorKeyDown)

    this.$nextTick(() => this.pushUndo({ amend: true }))
  },
  beforeUnmount () {
    if (this.editor) {
      this.editor.view.dom.removeEventListener('paste', this.onEditorPaste, true)
      this.editor.view.dom.removeEventListener('pointerdown', this.onEditorPointerDown, true)
      this.editor.view.dom.removeEventListener('mousemove', this.onEditorMouseMove)
      this.editor.view.dom.removeEventListener('mouseleave', this.onEditorMouseLeave)
      this.editor.view.dom.removeEventListener('keydown', this.onEditorKeyDown)
      this.editor.destroy()
    }
  },
  methods: {
    reloadContent () {
      this.editor.commands.setContent(this.section.innerHTML, { emitUpdate: false, parseOptions: this.editor.options.parseOptions })
    },
    restoreDoc (doc) {
      const { state, view } = this.editor
      const { content } = doc.type.schema === state.schema ? doc : state.schema.nodeFromJSON(doc.toJSON())
      const diffEnd = content.findDiffEnd(state.doc.content)

      if (diffEnd) {
        const tr = state.tr.replaceWith(0, state.doc.content.size, content).setMeta('addToHistory', false)

        view.dispatch(tr.setSelection(Selection.near(tr.doc.resolve(diffEnd.a))).scrollIntoView())

        this.lastUpdateTime = 0
      }
    },
    findAreaNodePos (areaUuid) {
      const el = this.editor.view.dom.querySelector(`[data-area-uuid="${areaUuid}"]`)

      return this.editor.view.posAtDOM(el, 0)
    },
    getFieldInsertIndex (pos) {
      const view = this.editor.view
      const fields = this.template.fields || []

      if (!fields.length) {
        return 0
      }

      let previousField = null

      view.state.doc.nodesBetween(0, pos, (node, nodePos) => {
        if (node.type.name !== 'fieldNode') {
          return
        }

        if (nodePos + node.nodeSize <= pos) {
          previousField = this.fieldAreaIndex[node.attrs.areaUuid]?.field || previousField
        }
      })

      if (!previousField) {
        previousField = this.getPreviousSectionField()
      }

      if (!previousField) {
        return 0
      }

      const previousFieldIndex = fields.indexOf(previousField)

      return previousFieldIndex === -1 ? fields.length : previousFieldIndex + 1
    },
    insertFieldInTemplate (field, index) {
      const currentFieldIndex = this.template.fields.indexOf(field)

      if (currentFieldIndex !== -1) {
        return currentFieldIndex
      }

      this.template.fields.splice(index, 0, field)

      return index
    },
    getLastFieldInSection (sectionRef) {
      let lastField = null

      sectionRef.editor.state.doc.descendants((node) => {
        if (node.type.name === 'fieldNode') {
          lastField = this.fieldAreaIndex[node.attrs.areaUuid]?.field || lastField
        }
      })

      return lastField
    },
    getPreviousSectionField () {
      const sectionIndex = this.sectionRefs.indexOf(this)

      for (let index = sectionIndex - 1; index >= 0; index -= 1) {
        const previousField = this.getLastFieldInSection(this.sectionRefs[index])

        if (previousField) {
          return previousField
        }
      }

      return null
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

        this.blockMenuCoords = null
      } else {
        this.areaToolbarCoords = null
        this.selectedAreasRef.value = []

        this.setBlockMenuCoords(editor)

        if (selection.node || selection.empty || !editor.isFocused) {
          this.dynamicMenuCoords = null
        } else {
          this.setDynamicMenuCoords(editor)
        }
      }

      if (selection instanceof CellSelection) {
        this.insertMenuCoords = null
      } else if (editor.isFocused) {
        this.setInsertMenuCoords(editor)
      }
    },
    setInsertMenuCoords (editor) {
      const coords = editor.view.coordsAtPos(editor.state.selection.head)
      const containerRect = this.container.getBoundingClientRect()
      const sectionEl = this.$refs.editorElement
      const sectionRect = sectionEl.getBoundingClientRect()
      const paddingLeft = parseFloat(getComputedStyle(sectionEl).paddingLeft) * this.zoom

      this.insertMenuCoords = {
        top: (coords.top + coords.bottom) / 2 - containerRect.top,
        left: sectionRect.left - containerRect.left + Math.max(paddingLeft / 2, 14)
      }
    },
    setBlockMenuCoords (editor) {
      const { selection } = editor.state
      const isImage = selection.node?.type.name === 'image'
      const table = isImage ? null : findTable(selection.$from)

      if (!isImage && !table) {
        this.blockMenuCoords = null

        return
      }

      const pos = isImage ? selection.from : table.pos
      const dom = editor.view.nodeDOM(pos)
      const rect = dom.getBoundingClientRect()
      const containerRect = this.container.getBoundingClientRect()
      const coords = {
        type: isImage ? 'image' : 'table',
        pos,
        align: 'left',
        top: rect.top - containerRect.top,
        left: rect.left - containerRect.left,
        width: rect.width,
        height: rect.height
      }

      if (isImage) {
        coords.align = getComputedStyle(dom.parentElement).textAlign.replace('start', 'left').replace('end', 'right')
      } else {
        const { marginLeft, marginRight, float } = dom.style

        if (float === 'left' || float === 'right') {
          coords.align = float
        } else if (marginLeft === 'auto') {
          coords.align = marginRight === 'auto' ? 'center' : 'right'
        } else if (dom.getAttribute('align')) {
          coords.align = dom.getAttribute('align')
        }

        coords.isRegular = isRegularTable(table.node)
        coords.canMerge = editor.can().mergeTableCells()
        coords.canSplit = editor.can().splitTableCell()
      }

      this.blockMenuCoords = coords
    },
    getBlockResizeLimits () {
      const dom = this.editor.view.nodeDOM(this.blockMenuCoords.pos)
      const rect = dom.getBoundingClientRect()

      return {
        minHeight: tableRowMinHeights(dom, this.zoom, false).reduce((acc, value) => acc + value, 0),
        maxWidth: Math.max(this.$refs.editorElement.getBoundingClientRect().right - rect.left, rect.width)
      }
    },
    onBlockResize ({ width, height }) {
      resizeTable(this.editor.view, this.blockMenuCoords.pos, { width: width / this.zoom, height: height / this.zoom }, this.zoom)

      this.editor.commands.focus()

      this.$nextTick(() => this.setBlockMenuCoords(this.editor))
    },
    onBlockCommand (command, arg) {
      this.editor.chain().focus()[command](arg).run()

      this.$nextTick(() => this.setBlockMenuCoords(this.editor))
    },
    onInsertField (type) {
      const { from, to } = this.editor.state.selection

      this.insertFieldAtRange({ sourceField: { type }, from, to })
    },
    onInsertTable ({ rows, cols }) {
      const $pos = this.editor.state.tr.deleteSelection().selection.$head
      const cell = '<td style="border: 1px solid #000000; padding: 4pt; vertical-align: top"><p style="margin: 0"></p></td>'
      const html = `<table style="width: 100%; border-collapse: collapse"><tbody>${`<tr>${cell.repeat(cols)}</tr>`.repeat(rows)}</tbody></table>`
      const isEmpty = $pos.parent.isTextblock && !$pos.parent.content.size
      const from = !$pos.parent.isTextblock ? $pos.pos : isEmpty ? $pos.before() : $pos.after()
      const to = isEmpty ? $pos.after() : from

      this.editor.chain().focus()
        .deleteSelection()
        .insertContentAt({ from, to }, html)
        .setTextSelection(from + 4)
        .run()
    },
    async onImageSelected (event) {
      const file = event.target.files[0]

      event.target.value = ''

      if (!file) return

      const image = await this.uploadImage(file)

      if (image) {
        this.editor.chain().focus().insertContent(image).run()
      }
    },
    async insertImageFiles (files, pos) {
      const images = (await Promise.all(files.map(this.uploadImage))).filter(Boolean)

      if (images.length) {
        this.editor.chain().focus().insertContentAt(pos, images).run()
      }
    },
    async uploadImage (file) {
      const formData = new FormData()

      formData.append('file', file)

      const response = await this.baseFetch(`/templates/${this.template.id}/dynamic_documents/${this.attachmentUuid}/attachments`, {
        method: 'POST',
        body: formData
      })

      const data = await response.json()

      if (!response.ok) return alert(data.error)

      this.$emit('add-attachment', data)

      await this.$nextTick()

      return { type: 'image', attrs: { htmlAttrs: { src: `blob:${data.uuid}`, style: 'max-width: 100%' } } }
    },
    setDynamicMenuCoords (editor) {
      const { from, to } = editor.state.selection
      const view = editor.view
      const start = view.coordsAtPos(from)
      const end = view.coordsAtPos(to)
      const containerRect = this.container.getBoundingClientRect()

      this.dynamicMenuCoords = {
        top: Math.max(start.bottom, end.bottom) - containerRect.top + 8,
        left: (start.left + end.right) / 2 - containerRect.left,
        width: containerRect.width
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
    onEditorMouseLeave () {
      this.cursorHighlightCoords = null
    },
    onEditorKeyDown (event) {
      if (event.key === 'Escape') {
        this.editor.chain().setNodeSelection(0).blur().run()
        this.deselectArea()
      } else if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'z') {
        event.stopPropagation()
      }
    },
    onEditorMouseMove (event) {
      if (!this.isDrawMode || !this.editable) {
        this.cursorHighlightCoords = null

        return
      }

      const view = this.editor?.view

      if (!view) return

      const pos = view.posAtCoords({ left: event.clientX, top: event.clientY })

      if (!pos) {
        this.cursorHighlightCoords = null

        return
      }

      const coords = view.coordsAtPos(pos.pos)
      const outerRect = this.$el.getBoundingClientRect()
      const lineHeight = coords.bottom - coords.top

      this.cursorHighlightCoords = {
        x: coords.left - outerRect.left,
        y: coords.top - outerRect.top,
        height: lineHeight
      }
    },
    getFieldNode (areaUuid) {
      const pos = this.findAreaNodePos(areaUuid)

      return this.editor.state.doc.nodeAt(pos)
    },
    serializeFieldNodeHtml (areaUuid) {
      const node = this.getFieldNode(areaUuid)

      if (!node) {
        return null
      }

      const serializer = DOMSerializer.fromSchema(this.editor.state.schema)
      const container = document.createElement('div')

      container.appendChild(serializer.serializeFragment(Fragment.from(node)))

      return container.innerHTML
    },
    async writeHtmlToClipboard ({ html, text }, clipboardData = null) {
      if (clipboardData) {
        clipboardData.setData('text/html', html)
        clipboardData.setData('text/plain', text || html)

        return true
      }

      if (navigator.clipboard?.write && window.ClipboardItem) {
        await navigator.clipboard.write([
          new ClipboardItem({
            'text/html': new Blob([html], { type: 'text/html' }),
            'text/plain': new Blob([text || html], { type: 'text/plain' })
          })
        ])

        return true
      }

      if (navigator.clipboard?.writeText) {
        await navigator.clipboard.writeText(text || html)

        return true
      }

      return false
    },
    async copyFieldAreaToClipboard (areaUuid, clipboardData = null) {
      const html = this.serializeFieldNodeHtml(areaUuid)

      if (!html) {
        return false
      }

      try {
        await this.writeHtmlToClipboard({ html, text: html }, clipboardData)

        return true
      } catch (e) {
        console.error('Failed to copy dynamic field:', e)

        return false
      }
    },
    async onContextMenuCopy () {
      await this.copyFieldAreaToClipboard(this.contextMenu.areaUuid)

      this.closeContextMenu()
    },
    buildCopiedField (payload) {
      const field = JSON.parse(JSON.stringify(payload.field))
      const area = {
        ...JSON.parse(JSON.stringify(payload.area)),
        uuid: v4(),
        attachment_uuid: this.attachmentUuid
      }

      if (payload.templateId !== this.template.id) {
        delete field.conditions

        if (field.preferences) {
          delete field.preferences.formula
        }
      }

      const newField = payload.parentField || {
        ...field,
        uuid: v4(),
        submitter_uuid: this.selectedSubmitter.uuid,
        areas: []
      }

      newField.areas.push(area)

      if (['radio', 'multiple'].includes(field.type) && field.options?.length) {
        const oldOptionIndex = field.options.findIndex((opt) => opt.uuid === area.option_uuid)

        if (!payload.parentField) {
          newField.options = field.options.map((opt) => ({ ...opt, uuid: v4() }))
        }

        area.option_uuid = (newField.options[oldOptionIndex] || newField.options[0]).uuid
      }

      return { field: newField, area }
    },
    onEditorPaste (event) {
      const clipboardData = event.clipboardData

      if (!clipboardData) {
        return
      }

      const html = clipboardData.getData('text/html')
      const text = clipboardData.getData('text/plain')
      const clipboardHtml = html || (text.includes('<dynamic-field') ? text : '')

      if (/class="[^"]*doc-list-/.test(html)) this.$emit('add-list')

      if (!clipboardHtml || !clipboardHtml.includes('data-field=')) {
        return
      }

      const container = new DOMParser().parseFromString(clipboardHtml, 'text/html').body

      const fieldNodes = [...container.querySelectorAll('dynamic-field[data-field][data-area]')]

      if (!fieldNodes.length) {
        return
      }

      event.preventDefault()

      const { selection } = this.editor.state
      const { from, to } = selection
      let insertIndex = this.getFieldInsertIndex(selection.node?.type.name === 'fieldNode' ? to : from)

      let lastArea = null

      const parentFieldsIndex = {}

      fieldNodes.forEach((fieldNode) => {
        const fieldValue = fieldNode.dataset.field
        const areaValue = fieldNode.dataset.area
        const templateId = fieldNode.dataset.templateId
        const sourceFieldUuid = fieldNode.getAttribute('uuid')

        if (!fieldValue || !areaValue) {
          return
        }

        const { field, area } = this.buildCopiedField({
          field: JSON.parse(fieldValue),
          area: JSON.parse(areaValue),
          templateId: Number(templateId),
          parentField: parentFieldsIndex[sourceFieldUuid]
        })

        if (!parentFieldsIndex[sourceFieldUuid]) {
          parentFieldsIndex[sourceFieldUuid] = field

          this.insertFieldInTemplate(field, insertIndex)
          insertIndex += 1
        }

        fieldNode.setAttribute('uuid', field.uuid)
        fieldNode.setAttribute('area-uuid', area.uuid)
        fieldNode.removeAttribute('data-field')
        fieldNode.removeAttribute('data-area')
        fieldNode.removeAttribute('data-template-id')

        lastArea = area
      })

      this.editor.chain().focus().insertContentAt({ from, to }, container.innerHTML).run()

      if (lastArea) {
        this.editor.commands.setNodeSelection(this.findAreaNodePos(lastArea.uuid))
      }

      this.closeContextMenu()
      this.save()
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
    onFieldDrop (view, event, slice, moved) {
      this.isAreaDrag = false

      if (moved) {
        return
      }

      const draggedField = this.fieldsDragFieldRef?.value || this.customDragFieldRef?.value || this.dragField
      const imageFiles = slice.size ? [] : Array.from(event.dataTransfer.files).filter((file) => file.type.startsWith('image/'))

      if (!draggedField && !imageFiles.length) return false

      event.preventDefault()

      const pos = view.posAtCoords({ left: event.clientX, top: event.clientY })

      if (!pos) return false

      if (draggedField) {
        this.insertFieldAtRange({
          sourceField: draggedField,
          existingField: this.fieldsDragFieldRef?.value,
          from: pos.pos
        })

        this.fieldsDragFieldRef.value = null
        this.customDragFieldRef.value = null
      } else {
        this.insertImageFiles(imageFiles, pos.pos)
      }

      return true
    },
    closestPosAtCoords ({ clientX, clientY }) {
      const view = this.editor.view
      const rect = view.dom.getBoundingClientRect()
      const left = Math.min(Math.max(clientX, rect.left + 1), rect.right - 1)
      const top = Math.min(Math.max(clientY, rect.top + 1), rect.bottom - 1)
      const caret = document.caretPositionFromPoint?.(left, top, { shadowRoots: [view.root] })

      if (caret && view.dom.contains(caret.offsetNode)) {
        return view.posAtDOM(caret.offsetNode, caret.offset)
      } else {
        return view.posAtCoords({ left, top }).pos
      }
    },
    onMarginMouseDown (event) {
      const view = this.editor.view

      if (event.button !== 0 || !this.editable || this.isDrawMode || view.dom.contains(event.target)) {
        return
      }

      event.preventDefault()

      const anchor = this.closestPosAtCoords(event)

      const selectTo = (e) => {
        const { doc, tr } = view.state

        view.dispatch(tr.setSelection(TextSelection.between(doc.resolve(anchor), doc.resolve(this.closestPosAtCoords(e)))))
      }

      const onMouseUp = () => {
        window.removeEventListener('mousemove', selectTo)
        window.removeEventListener('mouseup', onMouseUp)
      }

      selectTo(event)

      view.focus()

      window.addEventListener('mousemove', selectTo)
      window.addEventListener('mouseup', onMouseUp)
    },
    onEditorPointerDown (event) {
      if (!this.isDrawMode || !this.editable || this.isDraggingField) {
        return
      }

      if (event.button === 2) {
        return
      }

      const view = this.editor?.view

      if (!view) {
        return
      }

      const selection = view.state.selection
      const isTextRangeSelection = !selection.empty && !selection.node

      let from = selection.from
      let to = selection.to

      if (!isTextRangeSelection) {
        const pos = view.posAtCoords({ left: event.clientX, top: event.clientY })

        if (!pos) {
          return
        }

        from = pos.pos
        to = pos.pos
      }

      const sourceField = this.drawField || this.drawCustomField || { type: this.drawFieldType }

      event.preventDefault()
      event.stopPropagation()

      if (this.drawOption && this.drawField) {
        const areaWithoutOption = this.drawField.areas?.find((a) => !a.option_uuid)

        if (areaWithoutOption && !this.drawField.areas.find((a) => a.option_uuid === this.drawField.options[0].uuid)) {
          areaWithoutOption.option_uuid = this.drawField.options[0].uuid
        }
      }

      const inserted = this.insertFieldAtRange({
        sourceField,
        existingField: this.drawField,
        optionUuid: this.drawOption?.uuid,
        from,
        to
      })

      if (inserted) {
        this.$emit('draw', inserted)
      }
    },
    buildFieldArea ({ optionUuid = null } = {}) {
      const area = {
        uuid: v4(),
        attachment_uuid: this.attachmentUuid
      }

      if (optionUuid) {
        area.option_uuid = optionUuid
      }

      return area
    },
    buildNewField (sourceField, area) {
      const fieldType = sourceField?.type || 'text'
      const newField = {
        name: sourceField?.name || '',
        uuid: v4(),
        required: fieldType !== 'checkbox',
        submitter_uuid: this.selectedSubmitter.uuid,
        type: fieldType,
        areas: [area]
      }

      if (['select', 'multiple', 'radio'].includes(fieldType)) {
        if (sourceField?.options?.length) {
          newField.options = sourceField.options.map((opt) => ({
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

      return newField
    },
    insertFieldAtRange ({ sourceField, existingField = null, optionUuid = null, from, to = from }) {
      if (!sourceField) {
        return null
      }

      const fieldType = sourceField.type || existingField?.type || 'text'
      const dims = this.defaultSizes[fieldType]
      const area = this.buildFieldArea({ optionUuid })
      const insertIndex = this.getFieldInsertIndex(from)

      let field = existingField
      const view = this.editor.view

      if (field) {
        if (!this.template.fields.includes(field)) {
          this.insertFieldInTemplate(field, insertIndex)
        }

        field.areas = field.areas || []
        field.areas.push(area)
      } else {
        field = this.buildNewField(sourceField, area)
        this.insertFieldInTemplate(field, insertIndex)
      }

      const nodeType = view.state.schema.nodes.fieldNode
      const fieldNode = nodeType.create({
        uuid: field.uuid,
        areaUuid: area.uuid,
        width: dims.width,
        height: dims.height
      })

      const tr = from !== to
        ? view.state.tr.replaceWith(from, to, fieldNode)
        : view.state.tr.insert(from, fieldNode)

      view.dispatch(tr)

      this.editor.chain().focus().setNodeSelection(from).run()
      this.save()

      return { area, field, pos: from }
    }
  }
}
</script>

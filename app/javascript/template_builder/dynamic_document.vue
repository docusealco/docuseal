<template>
  <div
    ref="container"
    class="relative"
    style="container-type: inline-size;"
  >
    <div ref="shadow" />
    <template
      v-for="style in styles"
      :key="style.innerText"
    >
      <Teleport
        v-if="shadow"
        :to="style.innerText.includes('@font-face {') ? 'head' : shadow"
      >
        <component :is="'style'">
          {{ style.innerText }}
        </component>
      </Teleport>
    </template>
    <Teleport
      v-if="shadow"
      :to="shadow"
    >
      <component
        :is="'style'"
        v-if="listsStyle"
      >
        {{ listsStyle }}
      </component>
      <DynamicSection
        v-for="section in sections"
        :ref="setSectionRefs"
        :key="section.id"
        :container="$refs.container"
        :editable="editable"
        :section="section"
        :section-refs="sectionRefs"
        :container-width="containerWidth"
        :attachments-index="attachmentsIndex"
        :selected-submitter="selectedSubmitter"
        :drag-field="dragField"
        :draw-field="drawField"
        :draw-field-type="drawFieldType"
        :draw-custom-field="drawCustomField"
        :render-html-for-save-ref="renderHtmlForSaveRef"
        :draw-option="drawOption"
        :attachment-uuid="document.uuid"
        @update="onSectionUpdate(section, $event)"
        @draw="$emit('draw', $event)"
        @add-custom-field="$emit('add-custom-field', $event)"
        @set-draw="$emit('set-draw', $event)"
        @add-attachment="document.attachments.push($event)"
        @add-list="ensureListsStyle"
      />
    </Teleport>
  </div>
</template>

<script>
import { ref, computed } from 'vue'
import DynamicSection from './dynamic_section.vue'
import { dynamicStylesheet, tiptapStylesheet, listsCss } from './dynamic_editor.js'
import { buildVariablesSchema, mergeSchemaProperties } from './dynamic_variables_schema.js'

export default {
  name: 'TemplateDynamicDocument',
  components: {
    DynamicSection
  },
  inject: ['baseFetch', 'template'],
  provide () {
    return {
      documentFonts: computed(() => this.documentFonts)
    }
  },
  props: {
    document: {
      type: Object,
      required: true
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    },
    autosave: {
      type: Boolean,
      required: false,
      default: true
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
    drawOption: {
      type: Object,
      required: false,
      default: null
    }
  },
  emits: ['update', 'draw', 'set-draw', 'add-custom-field'],
  data () {
    return {
      containerWidth: 1040,
      isMounted: false,
      listsStyle: null,
      sectionRefs: []
    }
  },
  computed: {
    renderHtmlForSaveRef: () => ref(false),
    isDynamic () {
      return true
    },
    attachmentsIndex () {
      return (this.document.attachments || []).reduce((acc, att) => {
        acc[att.uuid] = att.url

        return acc
      }, {})
    },
    bodyDom () {
      return new DOMParser().parseFromString(this.document.body, 'text/html')
    },
    headDom () {
      return new DOMParser().parseFromString(this.document.head, 'text/html')
    },
    sections () {
      return this.bodyDom.querySelectorAll('section')
    },
    styles () {
      return this.headDom.querySelectorAll('style')
    },
    documentFonts () {
      const fonts = []
      const firstFamily = (value) => value.split(',')[0].trim().replace(/^["']|["']$/g, '')
      const add = (label, value) => {
        if (label && !fonts.some((font) => font.label === label)) fonts.push({ label, value })
      }

      this.styles.forEach((style) => {
        const css = style.textContent

        for (const type of ['minor', 'major']) {
          for (const [, name, value] of css.matchAll(new RegExp(`(--[\\w-]+-${type}HAnsi-font):\\s*([^;}]+)`, 'g'))) {
            add(firstFamily(value), `var(${name})`)
          }
        }

        for (const [, value] of css.matchAll(/@font-face\s*\{[^}]*?font-family:\s*([^;}]+)/g)) {
          add(firstFamily(value), value.trim())
        }
      })

      const skipFamilies = ['symbol', 'wingdings', 'wingdings 2', 'wingdings 3', 'webdings', 'serif', 'sans-serif', 'monospace', 'inherit', 'initial']
      const addUsed = (value) => {
        if (value && !value.startsWith('var(') && !skipFamilies.includes(firstFamily(value).toLowerCase())) add(firstFamily(value), value.trim())
      }

      this.styles.forEach((style) => {
        for (const [, value] of style.textContent.replace(/@font-face\s*\{[^}]*\}/g, '').matchAll(/font-family:\s*([^;}]+)/g)) addUsed(value)
      })

      this.bodyDom.querySelectorAll('[style*="font-family"]').forEach((el) => addUsed(el.style.fontFamily))

      return fonts
    },
    shadow () {
      if (this.isMounted) {
        return this.$refs.shadow.attachShadow({ mode: 'open' })
      } else {
        return null
      }
    }
  },
  created () {
    this.updatedSectionEditors = new Map()

    this.loadListsStyle()
  },
  mounted () {
    this.isMounted = true

    this.shadow.adoptedStyleSheets.push(dynamicStylesheet, tiptapStylesheet)

    this.updateContainerWidth()

    this.resizeObserver = new ResizeObserver(() => {
      if (this.$refs.container) {
        this.updateContainerWidth()
      }
    })

    this.resizeObserver.observe(this.$refs.container)

    window.addEventListener('beforeunload', this.onBeforeUnload)
  },
  beforeUnmount () {
    window.removeEventListener('beforeunload', this.onBeforeUnload)

    this.resizeObserver.unobserve(this.$refs.container)
  },
  beforeUpdate () {
    this.sectionRefs = []
  },
  methods: {
    mergeSchemaProperties,
    updateContainerWidth () {
      this.containerWidth = this.$refs.container.clientWidth
    },
    removeArea (area) {
      this.sectionRefs.forEach((sectionRef) => {
        const pos = sectionRef.findAreaNodePos(area.uuid)

        if (pos !== -1) {
          sectionRef.editor.chain().focus().deleteRange({ from: pos, to: pos + 1 }).run()
        }
      })
    },
    setSectionRefs (ref) {
      if (ref) {
        this.sectionRefs.push(ref)
      }
    },
    reloadContent () {
      this.loadListsStyle()

      this.sectionRefs.forEach((ref) => ref.reloadContent())
    },
    getSectionDocs () {
      return this.sectionRefs.map((ref) => [ref.sectionKey, ref.editor.state.doc])
    },
    restoreSectionDocs (sectionDocs) {
      this.sectionRefs.forEach((ref) => {
        if (sectionDocs.has(ref.sectionKey)) ref.restoreDoc(sectionDocs.get(ref.sectionKey))
      })
    },
    onBeforeUnload (event) {
      if (this.saveTimer) {
        event.preventDefault()

        event.returnValue = ''

        return ''
      }
    },
    scrollToArea (area) {
      this.sectionRefs.forEach(({ editor }) => editor.commands.setNodeSelection(0))

      this.sectionRefs.forEach(({ editor }) => {
        const el = editor.view.dom.querySelector(`[data-area-uuid="${area.uuid}"]`)

        if (el) {
          editor.commands.setNodeSelection(editor.view.posAtDOM(el, 0))

          el.scrollIntoView({ behavior: 'smooth', block: 'center' })
        }
      })
    },
    onSectionUpdate (section, { editor }) {
      clearTimeout(this.saveTimer)

      this.updatedSectionEditors.set(section.id, editor)

      this.saveTimer = setTimeout(() => this.autosave ? this.updateSectionsAndSave() : this.updateSections(), 1000)
    },
    loadListsStyle () {
      this.listsStyle = this.bodyDom.querySelector('body > style[data-lists]')?.textContent || null
    },
    ensureListsStyle () {
      if (this.listsStyle) return

      const style = this.bodyDom.createElement('style')

      style.dataset.lists = ''
      style.textContent = listsCss

      this.bodyDom.body.append(style)

      this.listsStyle = listsCss
    },
    updateVariablesSchema () {
      this.document.variables_schema = buildVariablesSchema(this.bodyDom.body)
    },
    updateSections () {
      delete this.saveTimer

      this.updatedSectionEditors.forEach((editor, sectionId) => {
        const target = this.bodyDom.getElementById(sectionId)

        if (target) {
          target.innerHTML = this.getHtmlForSave(editor)
        }
      })

      this.updatedSectionEditors.clear()

      this.document.body = this.bodyDom.body.innerHTML

      this.updateVariablesSchema()

      this.$emit('update', this.document)
    },
    updateSectionsAndSave () {
      this.updateSections()

      return this.saveBody()
    },
    updateAndSave () {
      this.update()

      return this.saveBody()
    },
    update () {
      clearTimeout(this.saveTimer)

      delete this.saveTimer

      this.updatedSectionEditors.clear()

      this.sectionRefs.forEach(({ section, editor }) => {
        const target = this.bodyDom.getElementById(section.id)

        target.innerHTML = this.getHtmlForSave(editor)
      })

      this.document.body = this.bodyDom.body.innerHTML

      this.updateVariablesSchema()

      this.$emit('update', this.document)
    },
    getHtmlForSave (editor) {
      this.renderHtmlForSaveRef.value = true

      const result = editor.getHTML()

      this.renderHtmlForSaveRef.value = false

      return result
    },
    saveBody () {
      clearTimeout(this.saveTimer)

      delete this.saveTimer

      return this.baseFetch(`/templates/${this.template.id}/dynamic_documents/${this.document.uuid}`, {
        method: 'PUT',
        body: JSON.stringify({ body: this.bodyDom.body.innerHTML }),
        headers: { 'Content-Type': 'application/json' }
      })
    },
    syncVariablesSchema (existing, parsed, { disable = true } = {}) {
      for (const key of Object.keys(parsed)) {
        if (!existing[key]) {
          existing[key] = parsed[key]
        }
      }

      for (const key of Object.keys(existing)) {
        if (!parsed[key]) {
          if (disable) {
            existing[key].disabled = true
          } else {
            delete existing[key]
          }
        } else {
          delete existing[key].disabled

          if (!existing[key].form_type) {
            existing[key].type = parsed[key].type
          }

          if (parsed[key].items) {
            if (!existing[key].items) {
              existing[key].items = parsed[key].items
            } else if (existing[key].items.properties && parsed[key].items.properties) {
              this.syncVariablesSchema(existing[key].items.properties, parsed[key].items.properties, { disable })
            } else if (!existing[key].items.properties && !parsed[key].items.properties) {
              existing[key].items.type = parsed[key].items.type
            }
          }

          if (existing[key].properties && parsed[key].properties) {
            this.syncVariablesSchema(existing[key].properties, parsed[key].properties, { disable })
          }
        }
      }
    }
  }
}
</script>

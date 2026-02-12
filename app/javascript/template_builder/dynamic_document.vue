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
      <DynamicSection
        v-for="section in sections"
        :ref="setSectionRefs"
        :key="section.id"
        :container="$refs.container"
        :editable="editable"
        :section="section"
        :container-width="containerWidth"
        :attachments-index="attachmentsIndex"
        :selected-submitter="selectedSubmitter"
        :drag-field="dragField"
        :attachment-uuid="document.uuid"
        @update="onSectionUpdate(section, $event)"
      />
    </Teleport>
  </div>
</template>

<script>
import DynamicSection from './dynamic_section.vue'
import { dynamicStylesheet, tiptapStylesheet } from './dynamic_editor.js'
import { buildVariablesSchema, mergeSchemaProperties } from './dynamic_variables_schema.js'

export default {
  name: 'TemplateDynamicDocument',
  components: {
    DynamicSection
  },
  inject: ['baseFetch', 'template'],
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
    selectedSubmitter: {
      type: Object,
      required: false,
      default: null
    },
    dragField: {
      type: Object,
      required: false,
      default: null
    }
  },
  emits: ['update'],
  data () {
    return {
      containerWidth: 1040,
      isMounted: false,
      sectionRefs: []
    }
  },
  computed: {
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
    shadow () {
      if (this.isMounted) {
        return this.$refs.shadow.attachShadow({ mode: 'open' })
      } else {
        return null
      }
    }
  },
  mounted () {
    this.isMounted = true

    this.shadow.adoptedStyleSheets.push(dynamicStylesheet, tiptapStylesheet)

    this.containerWidth = this.$refs.container.clientWidth

    this.resizeObserver = new ResizeObserver(() => {
      if (this.$refs.container) {
        this.containerWidth = this.$refs.container.clientWidth
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
    setSectionRefs (ref) {
      if (ref) {
        this.sectionRefs.push(ref)
      }
    },
    onBeforeUnload (event) {
      if (this.saveTimer) {
        event.preventDefault()

        event.returnValue = ''

        return ''
      }
    },
    scrollToArea (area) {
      this.sectionRefs.forEach(({ editor }) => {
        const el = editor.view.dom.querySelector(`[data-area-uuid="${area.uuid}"]`)

        if (el) {
          editor.chain().focus().setNodeSelection(editor.view.posAtDOM(el, 0)).run()

          el.scrollIntoView({ behavior: 'smooth', block: 'center' })
        }
      })
    },
    onSectionUpdate (section, { editor }) {
      clearTimeout(this.saveTimer)

      this.saveTimer = setTimeout(async () => {
        await this.updateSectionAndSave(section, editor)

        delete this.saveTimer
      }, 1000)
    },
    updateVariablesSchema () {
      this.document.variables_schema = buildVariablesSchema(this.bodyDom.body)
    },
    updateSectionAndSave (section, editor) {
      const target = this.bodyDom.getElementById(section.id)

      if (target) {
        target.innerHTML = editor.getHTML()
      }

      this.document.body = this.bodyDom.body.innerHTML

      this.updateVariablesSchema()

      this.$emit('update', this.document)

      return this.saveBody()
    },
    updateAndSave () {
      this.update()

      return this.saveBody()
    },
    update () {
      clearTimeout(this.saveTimer)

      delete this.saveTimer

      this.sectionRefs.forEach(({ section, editor }) => {
        const target = this.bodyDom.getElementById(section.id)

        target.innerHTML = editor.getHTML()
      })

      this.document.body = this.bodyDom.body.innerHTML

      this.updateVariablesSchema()

      this.$emit('update', this.document)
    },
    saveBody () {
      clearTimeout(this.saveTimer)

      delete this.saveTimer

      return this.baseFetch(`/templates/${this.template.id}/dynamic_documents/${this.document.uuid}`, {
        method: 'PUT',
        body: JSON.stringify({ body: this.bodyDom.body.innerHTML }),
        headers: { 'Content-Type': 'application/json' }
      })
    }
  }
}
</script>

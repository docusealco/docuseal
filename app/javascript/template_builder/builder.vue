<template>
  <div
    style="max-width: 1600px"
    class="mx-auto px-4"
  >
    <div class="flex justify-between py-1.5 items-center">
      <Contenteditable
        :model-value="template.name"
        class="text-3xl focus:text-clip"
        @update:model-value="updateName"
      />
      <div class="space-x-3 flex items-center">
        <a
          :href="`/templates/${template.id}/submissions`"
          class="btn btn-primary"
        >
          <IconUsersPlus
            width="20"
            class="mr-2 inline"
          />
          Recipients
        </a>
        <a
          :href="`/`"
          class="base-button"
          v-bind="isSaving ? { disabled: true } : {}"
          @click.prevent="onSaveClick"
        ><IconDeviceFloppy
          width="20"
          class="mr-2"
        />Save</a>
      </div>
    </div>
    <div
      class="flex"
      style="max-height: calc(100vh - 60px)"
    >
      <div
        ref="previews"
        class="overflow-auto w-52 flex-none pr-4 mt-0.5 pt-0.5"
      >
        <DocumentPreview
          v-for="(item, index) in template.schema"
          :key="index"
          :with-arrows="template.schema.length > 1"
          :item="item"
          :document="sortedDocuments[index]"
          @scroll-to="scrollIntoDocument(item)"
          @remove="onDocumentRemove"
          @up="moveDocument(item, -1)"
          @down="moveDocument(item, 1)"
          @change="save"
        />
        <div class="sticky bottom-0 bg-base-100 py-2">
          <Upload
            :template-id="template.id"
            @success="updateFromUpload"
          />
        </div>
      </div>
      <div class="w-full overflow-y-auto overflow-x-hidden mt-0.5 pt-0.5">
        <div class="px-3">
          <Document
            v-for="document in sortedDocuments"
            :key="document.uuid"
            :ref="setDocumentRefs"
            :areas-index="fieldAreasIndex[document.uuid]"
            :document="document"
            :is-draw="!!drawField"
            :is-drag="!!dragFieldType"
            @draw="onDraw"
            @drop-field="onDropfield"
          />
        </div>
      </div>
      <div
        class="relative w-72 flex-none"
        :class="drawField ? 'overflow-hidden' : 'overflow-auto'"
      >
        <div
          v-if="drawField"
          class="sticky inset-0 bg-white h-full"
        >
          Draw {{ drawField.name }} field on the page
          <button @click="drawField = false">
            Cancel
          </button>
        </div>
        <div>
          FIelds
          <Fields
            ref="fields"
            v-model:fields="template.fields"
            @set-draw="drawField = $event"
            @set-drag="dragFieldType = $event"
            @drag-end="dragFieldType = null"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import Upload from './upload'
import Fields from './fields'
import Document from './document'
import Contenteditable from './contenteditable'
import DocumentPreview from './preview'
import { IconUsersPlus, IconDeviceFloppy } from '@tabler/icons-vue'

export default {
  name: 'TemplateBuilder',
  components: {
    Upload,
    Document,
    Fields,
    DocumentPreview,
    Contenteditable,
    IconUsersPlus,
    IconDeviceFloppy
  },
  props: {
    template: {
      type: Object,
      required: true
    }
  },
  data () {
    return {
      documentRefs: [],
      isSaving: false,
      drawField: null,
      dragFieldType: null
    }
  },
  computed: {
    fieldAreasIndex () {
      const areas = {}

      this.template.fields.forEach((f) => {
        (f.areas || []).forEach((a) => {
          areas[a.attachment_uuid] ||= {}

          const acc = (areas[a.attachment_uuid][a.page] ||= [])

          acc.push({ area: a, field: f })
        })
      })

      return areas
    },
    sortedDocuments () {
      return this.template.schema.map((item) => {
        return this.template.documents.find(doc => doc.uuid === item.attachment_uuid)
      })
    }
  },
  mounted () {
    document.addEventListener('keyup', this.disableDrawOnEsc)
  },
  unmounted () {
    document.removeEventListener('keyup', this.disableDrawOnEsc)
  },
  beforeUpdate () {
    this.documentRefs = []
  },
  methods: {
    setDocumentRefs (el) {
      if (el) {
        this.documentRefs.push(el)
      }
    },
    scrollIntoDocument (item) {
      const ref = this.documentRefs.find((e) => e.document.uuid === item.attachment_uuid)

      ref.$el.scrollIntoView({ behavior: 'smooth', block: 'start' })
    },
    disableDrawOnEsc (e) {
      if (e.code === 'Escape') {
        this.drawField = null
      }
    },
    onDraw (area) {
      this.drawField.areas ||= []
      this.drawField.areas.push(area)

      this.drawField = null
    },
    onDropfield (area) {
      this.$refs.fields.addField(this.dragFieldType, area)
    },
    updateFromUpload ({ schema, documents }) {
      this.template.schema.push(...schema)
      this.template.documents.push(...documents)

      this.$nextTick(() => {
        this.$refs.previews.scrollTop = this.$refs.previews.scrollHeight

        this.scrollIntoDocument(schema[0])
      })

      this.save()
    },
    updateName (value) {
      this.template.name = value

      this.save()
    },
    onDocumentRemove (item) {
      if (window.confirm('Are you sure?')) {
        this.template.schema.splice(this.template.schema.indexOf(item), 1)
      }

      this.save()
    },
    moveDocument (item, direction) {
      const currentIndex = this.template.schema.indexOf(item)

      this.template.schema.splice(currentIndex, 1)

      if (currentIndex + direction > this.template.schema.length) {
        this.template.schema.unshift(item)
      } else if (currentIndex + direction < 0) {
        this.template.schema.push(item)
      } else {
        this.template.schema.splice(currentIndex + direction, 0, item)
      }

      this.save()
    },
    onSaveClick () {
      this.isSaving = true

      this.save().then(() => {
        window.Turbo.visit('/')
      }).finally(() => {
        this.isSaving = false
      })
    },
    save () {
      return fetch(`/api/templates/${this.template.id}`, {
        method: 'PUT',
        body: JSON.stringify({ template: this.template }),
        headers: { 'Content-Type': 'application/json' }
      }).then((resp) => {
        console.log(resp)
      })
    }
  }
}
</script>

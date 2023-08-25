<template>
  <div
    style="max-width: 1600px"
    class="mx-auto pl-4 h-full"
  >
    <div class="flex justify-between py-1.5 items-center pr-4">
      <div class="flex space-x-3">
        <a
          v-if="withLogoLink"
          href="/"
        >
          <Logo />
        </a>
        <Logo v-else />
        <Contenteditable
          :model-value="template.name"
          class="text-3xl font-semibold focus:text-clip"
          :icon-stroke-width="2.3"
          @update:model-value="updateName"
        />
      </div>
      <div class="space-x-3 flex items-center">
        <slot
          v-if="$slots.buttons"
          name="buttons"
        />
        <template v-else>
          <a
            :href="`/templates/${template.id}/submissions/new`"
            data-turbo-frame="modal"
            class="btn btn-primary"
          >
            <IconUsersPlus
              width="20"
              class="inline"
            />
            <span class="hidden md:inline">
              Recipients
            </span>
          </a>
          <button
            class="base-button"
            :class="{ disabled: isSaving }"
            v-bind="isSaving ? { disabled: true } : {}"
            @click.prevent="onSaveClick"
          >
            <IconInnerShadowTop
              v-if="isSaving"
              width="20"
              class="animate-spin"
            />
            <IconDeviceFloppy
              v-else
              width="20"
            />
            <span class="hidden md:inline">
              Save
            </span>
          </button>
        </template>
      </div>
    </div>
    <div
      class="flex"
      style="max-height: calc(100% - 60px)"
    >
      <div
        ref="previews"
        :style="{ 'display': isBreakpointLg ? 'none' : 'initial' }"
        class="overflow-y-auto overflow-x-hidden w-52 flex-none pr-3 mt-0.5 pt-0.5 hidden lg:block"
      >
        <DocumentPreview
          v-for="(item, index) in template.schema"
          :key="index"
          :with-arrows="template.schema.length > 1"
          :item="item"
          :document="sortedDocuments[index]"
          :template="template"
          :is-direct-upload="isDirectUpload"
          @scroll-to="scrollIntoDocument(item)"
          @remove="onDocumentRemove"
          @replace="onDocumentReplace"
          @up="moveDocument(item, -1)"
          @down="moveDocument(item, 1)"
          @change="save"
        />
        <div class="sticky bottom-0 bg-base-100 py-2">
          <Upload
            v-if="sortedDocuments.length"
            :template-id="template.id"
            :is-direct-upload="isDirectUpload"
            @success="updateFromUpload"
          />
        </div>
      </div>
      <div class="w-full overflow-y-auto overflow-x-hidden mt-0.5 pt-0.5">
        <div
          ref="documents"
          class="pr-3.5 pl-0.5"
        >
          <Dropzone
            v-if="!sortedDocuments.length"
            :template-id="template.id"
            :is-direct-upload="isDirectUpload"
            @success="updateFromUpload"
          />
          <template v-else>
            <template
              v-for="document in sortedDocuments"
              :key="document.uuid"
            >
              <Document
                :ref="setDocumentRefs"
                :areas-index="fieldAreasIndex[document.uuid]"
                :selected-submitter="selectedSubmitter"
                :document="document"
                :is-drag="!!dragFieldType"
                :draw-field="drawField"
                @draw="onDraw"
                @drop-field="onDropfield"
                @remove-area="removeArea"
              />
              <DocumentControls
                v-if="isBreakpointLg"
                :with-arrows="template.schema.length > 1"
                :item="template.schema.find((item) => item.attachment_uuid === document.uuid)"
                :document="document"
                :template="template"
                :is-direct-upload="isDirectUpload"
                class="pb-2 mb-2 border-b border-base-300 border-dashed"
                @remove="onDocumentRemove"
                @replace="onDocumentReplace"
                @up="moveDocument(template.schema.find((item) => item.attachment_uuid === document.uuid), -1)"
                @down="moveDocument(template.schema.find((item) => item.attachment_uuid === document.uuid), 1)"
                @change="save"
              />
            </template>
            <div
              v-if="sortedDocuments.length && isBreakpointLg"
              class="pb-4"
            >
              <Upload
                :template-id="template.id"
                :is-direct-upload="isDirectUpload"
                @success="updateFromUpload"
              />
            </div>
          </template>
        </div>
        <div
          v-if="sortedDocuments.length"
          class="sticky md:hidden"
          style="bottom: 100px"
        >
          <div class="px-4 py-3 rounded-2xl bg-base-200 flex items-center justify-between ml-4 mr-6">
            <span class="w-full text-center text-lg">
              You need a larger screen to use builder tools.
            </span>
          </div>
        </div>
      </div>
      <div
        class="relative w-80 flex-none mt-1 pr-4 pl-0.5 hidden md:block"
        :class="drawField ? 'overflow-hidden' : 'overflow-auto'"
      >
        <div
          v-if="drawField"
          class="sticky inset-0 bg-base-100 h-full"
        >
          <div class="bg-base-300 rounded-lg p-5 text-center space-y-4">
            <p>
              Draw {{ drawField.name }} field on the document
            </p>
            <p>
              <button
                class="base-button"
                @click="drawField = null"
              >
                Cancel
              </button>
            </p>
          </div>
        </div>
        <div>
          <Fields
            ref="fields"
            :fields="template.fields"
            :submitters="template.submitters"
            :selected-submitter="selectedSubmitter"
            :with-sticky-submitters="withStickySubmitters"
            @set-draw="drawField = $event"
            @set-drag="dragFieldType = $event"
            @change-submitter="selectedSubmitter = $event"
            @drag-end="dragFieldType = null"
            @scroll-to-area="scrollToArea"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import Upload from './upload'
import Dropzone from './dropzone'
import Fields from './fields'
import Document from './document'
import Logo from './logo'
import Contenteditable from './contenteditable'
import DocumentPreview from './preview'
import DocumentControls from './controls'
import { IconUsersPlus, IconDeviceFloppy, IconInnerShadowTop } from '@tabler/icons-vue'
import { v4 } from 'uuid'
import { ref, computed } from 'vue'

export default {
  name: 'TemplateBuilder',
  components: {
    Upload,
    Document,
    Fields,
    Logo,
    Dropzone,
    DocumentPreview,
    DocumentControls,
    IconInnerShadowTop,
    Contenteditable,
    IconUsersPlus,
    IconDeviceFloppy
  },
  provide () {
    return {
      template: this.template,
      save: this.save,
      baseFetch: this.baseFetch,
      selectedAreaRef: computed(() => this.selectedAreaRef)
    }
  },
  props: {
    template: {
      type: Object,
      required: true
    },
    isDirectUpload: {
      type: Boolean,
      required: false,
      default: false
    },
    baseUrl: {
      type: String,
      required: false,
      default: ''
    },
    withLogoLink: {
      type: Boolean,
      required: false,
      default: true
    },
    withStickySubmitters: {
      type: Boolean,
      required: false,
      default: true
    },
    fetchOptions: {
      type: Object,
      required: false,
      default: () => ({ headers: {} })
    }
  },
  data () {
    return {
      documentRefs: [],
      isBreakpointLg: false,
      isSaving: false,
      selectedSubmitter: null,
      drawField: null,
      dragFieldType: null
    }
  },
  computed: {
    selectedAreaRef: () => ref(),
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
    selectedField () {
      return this.template.fields.find((f) => f.areas?.includes(this.selectedAreaRef.value))
    },
    sortedDocuments () {
      return this.template.schema.map((item) => {
        return this.template.documents.find(doc => doc.uuid === item.attachment_uuid)
      })
    }
  },
  created () {
    this.selectedSubmitter = this.template.submitters[0]
  },
  mounted () {
    this.$nextTick(() => {
      this.onWindowResize()
    })

    document.addEventListener('keyup', this.onKeyUp)

    window.addEventListener('resize', this.onWindowResize)
  },
  unmounted () {
    document.removeEventListener('keyup', this.onKeyUp)

    window.removeEventListener('resize', this.onWindowResize)
  },
  beforeUpdate () {
    this.documentRefs = []
  },
  methods: {
    onWindowResize (e) {
      const breakpointLg = 1024

      this.isBreakpointLg = this.$el.getRootNode().querySelector('div').offsetWidth < breakpointLg
    },
    setDocumentRefs (el) {
      if (el) {
        this.documentRefs.push(el)
      }
    },
    scrollIntoDocument (item) {
      const ref = this.documentRefs.find((e) => e.document.uuid === item.attachment_uuid)

      ref.$el.scrollIntoView({ behavior: 'smooth', block: 'start' })
    },
    onKeyUp (e) {
      if (e.code === 'Escape') {
        this.drawField = null
        this.selectedAreaRef.value = null
      }

      if (['Backspace', 'Delete'].includes(e.key) && this.selectedAreaRef.value && document.activeElement === document.body) {
        this.removeArea(this.selectedAreaRef.value)

        this.selectedAreaRef.value = null
      }
    },
    removeArea (area) {
      const field = this.template.fields.find((f) => f.areas?.includes(area))

      field.areas.splice(field.areas.indexOf(area), 1)

      if (!field.areas.length) {
        this.template.fields.splice(this.template.fields.indexOf(field), 1)
      }

      this.save()
    },
    onDraw (area) {
      if (this.drawField) {
        this.drawField.areas ||= []
        this.drawField.areas.push(area)

        this.drawField = null
      } else {
        const documentRef = this.documentRefs.find((e) => e.document.uuid === area.attachment_uuid)
        const pageMask = documentRef.pageRefs[area.page].$refs.mask

        const type = (pageMask.clientWidth * area.w) < 35 ? 'checkbox' : 'text'

        if (type === 'checkbox') {
          const previousField = [...this.template.fields].reverse().find((f) => f.type === type)
          const previousArea = previousField?.areas?.[previousField.areas.length - 1]

          const areaW = previousArea?.w || (30 / pageMask.clientWidth)
          const areaH = previousArea?.h || (30 / pageMask.clientHeight)

          if ((pageMask.clientWidth * area.w) < 5) {
            area.x = area.x - (areaW / 2)
            area.y = area.y - (areaH / 2)
          }

          area.w = areaW
          area.h = areaH
        }

        const field = {
          name: '',
          uuid: v4(),
          required: type !== 'checkbox',
          type,
          submitter_uuid: this.selectedSubmitter.uuid,
          areas: [area]
        }

        this.template.fields.push(field)
      }

      this.selectedAreaRef.value = area

      this.save()
    },
    onDropfield (area) {
      const field = {
        name: '',
        type: this.dragFieldType,
        uuid: v4(),
        submitter_uuid: this.selectedSubmitter.uuid,
        required: this.dragFieldType !== 'checkbox'
      }

      if (['select', 'multiple', 'radio'].includes(this.dragFieldType)) {
        field.options = ['']
      }

      const fieldArea = {
        x: (area.x - 6) / area.maskW,
        y: area.y / area.maskH,
        page: area.page,
        attachment_uuid: area.attachment_uuid
      }

      const previousField = [...this.template.fields].reverse().find((f) => f.type === field.type)

      let baseArea

      if (this.selectedField?.type === this.dragFieldType) {
        baseArea = this.selectedAreaRef.value
      } else if (previousField?.areas?.length) {
        baseArea = previousField.areas[previousField.areas.length - 1]
      } else {
        if (['checkbox'].includes(this.dragFieldType)) {
          baseArea = {
            w: area.maskW / 30 / area.maskW,
            h: area.maskW / 30 / area.maskW * (area.maskW / area.maskH)
          }
        } else if (this.dragFieldType === 'image') {
          baseArea = {
            w: area.maskW / 5 / area.maskW,
            h: (area.maskW / 5 / area.maskW) * (area.maskW / area.maskH)
          }
        } else if (this.dragFieldType === 'signature') {
          baseArea = {
            w: area.maskW / 5 / area.maskW,
            h: (area.maskW / 5 / area.maskW) * (area.maskW / area.maskH) / 2
          }
        } else {
          baseArea = {
            w: area.maskW / 5 / area.maskW,
            h: area.maskW / 35 / area.maskW
          }
        }
      }

      fieldArea.w = baseArea.w
      fieldArea.h = baseArea.h
      fieldArea.y = fieldArea.y - baseArea.h / 2

      if (this.dragFieldType === 'cells') {
        fieldArea.cell_w = baseArea.cell_w || (baseArea.w / 5)
      }

      field.areas = [fieldArea]

      this.selectedAreaRef.value = fieldArea

      this.template.fields.push(field)

      this.save()
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

      this.template.fields.forEach((field) => {
        [...(field.areas || [])].forEach((area) => {
          if (area.attachment_uuid === item.attachment_uuid) {
            field.areas.splice(field.areas.indexOf(area), 1)
          }
        })
      })

      this.save()
    },
    onDocumentReplace ({ replaceSchemaItem, schema, documents }) {
      this.template.schema.splice(this.template.schema.indexOf(replaceSchemaItem), 1, schema[0])
      this.template.documents.push(...documents)
      this.template.fields.forEach((field) => {
        (field.areas || []).forEach((area) => {
          if (area.attachment_uuid === replaceSchemaItem.attachment_uuid) {
            area.attachment_uuid = schema[0].attachment_uuid
          }
        })
      })

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
        window.Turbo.visit(`/templates/${this.template.id}`)
      }).finally(() => {
        this.isSaving = false
      })
    },
    scrollToArea (area) {
      const documentRef = this.documentRefs.find((a) => a.document.uuid === area.attachment_uuid)

      documentRef.scrollToArea(area)

      this.selectedAreaRef.value = area
    },
    baseFetch (path, options = {}) {
      return fetch(this.baseUrl + path, {
        ...options,
        headers: { ...this.fetchOptions.headers, ...options.headers }
      })
    },
    save () {
      if (this.$el.closest('template-builder')) {
        this.$el.closest('template-builder').dataset.template = JSON.stringify(this.template)
      }

      return this.baseFetch(`/api/templates/${this.template.id}`, {
        method: 'PUT',
        body: JSON.stringify({
          template: {
            name: this.template.name,
            schema: this.template.schema,
            submitters: this.template.submitters,
            fields: this.template.fields
          }
        }),
        headers: { 'Content-Type': 'application/json' }
      })
    }
  }
}
</script>

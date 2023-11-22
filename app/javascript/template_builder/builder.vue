<template>
  <div
    style="max-width: 1600px"
    class="mx-auto pl-3 md:pl-4 h-full"
  >
    <div
      class="flex justify-between py-1.5 items-center pr-4 sticky top-0 z-10"
      :style="{ backgroundColor }"
    >
      <div class="flex space-x-3">
        <a
          v-if="withLogo"
          href="/"
        >
          <Logo />
        </a>
        <Contenteditable
          :model-value="template.name"
          :editable="editable"
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
            class="btn btn-primary text-base"
            @click="maybeShowEmptyTemplateAlert"
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
              width="22"
              class="animate-spin"
            />
            <IconDeviceFloppy
              v-else
              width="22"
            />
            <span class="hidden md:inline">
              Save
            </span>
          </button>
        </template>
      </div>
    </div>
    <div class="flex md:max-h-[calc(100vh-60px)]">
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
          :accept-file-types="acceptFileTypes"
          :editable="editable"
          :template="template"
          :is-direct-upload="isDirectUpload"
          @scroll-to="scrollIntoDocument"
          @add-blank-page="addBlankPage"
          @remove="onDocumentRemove"
          @replace="onDocumentReplace"
          @up="moveDocument(item, -1)"
          @down="moveDocument(item, 1)"
          @change="save"
          @remove-image="removeImage"
        />
        <div
          class="sticky bottom-0 py-2"
          :class="{ 'bg-base-100': withStickySubmitters }"
        >
          <Upload
            v-if="sortedDocuments.length && editable"
            :accept-file-types="acceptFileTypes"
            :template-id="template.id"
            :is-direct-upload="isDirectUpload"
            @success="updateFromUpload"
          />
        </div>
      </div>
      <div class="w-full overflow-y-hidden md:overflow-y-auto overflow-x-hidden mt-0.5 pt-0.5">
        <div
          ref="documents"
          class="pr-3.5 pl-0.5"
        >
          <Dropzone
            v-if="!sortedDocuments.length"
            :template-id="template.id"
            :accept-file-types="acceptFileTypes"
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
                :editable="editable"
                @draw="onDraw"
                @drop-field="onDropfield"
                @remove-area="removeArea"
              />
              <DocumentControls
                v-if="isBreakpointLg && editable"
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
              v-if="sortedDocuments.length && isBreakpointLg && editable"
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
        <MobileDrawField
          v-if="drawField && isBreakpointLg"
          :draw-field="drawField"
          :fields="template.fields"
          :submitters="template.submitters"
          :selected-submitter="selectedSubmitter"
          class="md:hidden"
          :editable="editable"
          @cancel="drawField = null"
          @change-submitter="[selectedSubmitter = $event, drawField.submitter_uuid = $event.uuid]"
        />
        <FieldType
          v-if="sortedDocuments.length && !drawField && editable"
          class="dropdown-top dropdown-end fixed bottom-4 right-4 z-10 md:hidden"
          :model-value="''"
          @update:model-value="startFieldDraw($event)"
        >
          <label
            class="btn btn-neutral text-white btn-circle btn-lg group"
            tabindex="0"
          >
            <IconPlus
              class="group-focus:hidden"
              width="28"
              height="28"
            />
            <IconX
              class="hidden group-focus:inline"
              width="28"
              height="28"
            />
          </label>
        </FieldType>
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
            :editable="editable"
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
import MobileDrawField from './mobile_draw_field'
import Document from './document'
import Logo from './logo'
import Contenteditable from './contenteditable'
import DocumentPreview from './preview'
import DocumentControls from './controls'
import FieldType from './field_type'
import { IconUsersPlus, IconDeviceFloppy, IconInnerShadowTop, IconPlus, IconX } from '@tabler/icons-vue'
import { v4 } from 'uuid'
import { ref, computed } from 'vue'

export default {
  name: 'TemplateBuilder',
  components: {
    Upload,
    Document,
    Fields,
    MobileDrawField,
    IconPlus,
    FieldType,
    IconX,
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
      backgroundColor: this.backgroundColor,
      withPhone: this.withPhone,
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
    backgroundColor: {
      type: String,
      required: false,
      default: ''
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    },
    acceptFileTypes: {
      type: String,
      required: false,
      default: 'image/*, application/pdf'
    },
    baseUrl: {
      type: String,
      required: false,
      default: ''
    },
    withLogo: {
      type: Boolean,
      required: false,
      default: true
    },
    withStickySubmitters: {
      type: Boolean,
      required: false,
      default: true
    },
    withPhone: {
      type: Boolean,
      required: false,
      default: false
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
    fieldIcons: FieldType.computed.fieldIcons,
    fieldNames: FieldType.computed.fieldNames,
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
    this.undoStack = [JSON.stringify(this.template)]
    this.redoStack = []

    this.$nextTick(() => {
      this.onWindowResize()
    })

    document.addEventListener('keyup', this.onKeyUp)
    window.addEventListener('keydown', this.onKeyDown)

    window.addEventListener('resize', this.onWindowResize)
  },
  unmounted () {
    document.removeEventListener('keyup', this.onKeyUp)
    window.removeEventListener('keydown', this.onKeyDown)

    window.removeEventListener('resize', this.onWindowResize)
  },
  beforeUpdate () {
    this.documentRefs = []
  },
  methods: {
    startFieldDraw (type) {
      const field = {
        name: '',
        uuid: v4(),
        required: type !== 'checkbox',
        areas: [],
        submitter_uuid: this.selectedSubmitter.uuid,
        type
      }

      if (['select', 'multiple', 'radio'].includes(type)) {
        field.options = ['']
      }

      this.drawField = field
    },
    undo () {
      if (this.undoStack.length > 1) {
        this.undoStack.pop()
        const stringData = this.undoStack[this.undoStack.length - 1]
        const currentStringData = JSON.stringify(this.template)

        if (stringData && stringData !== currentStringData) {
          this.redoStack.push(currentStringData)

          Object.assign(this.template, JSON.parse(stringData))

          this.save()
        }
      }
    },
    redo () {
      const stringData = this.redoStack.pop()
      this.lastRedoData = stringData
      const currentStringData = JSON.stringify(this.template)

      if (stringData && stringData !== currentStringData) {
        if (this.undoStack[this.undoStack.length - 1] !== currentStringData) {
          this.undoStack.push(currentStringData)
        }

        Object.assign(this.template, JSON.parse(stringData))

        this.save()
      }
    },
    onWindowResize (e) {
      const breakpointLg = 1024

      this.isBreakpointLg = this.$el.getRootNode().querySelector('div[data-v-app]').offsetWidth < breakpointLg
    },
    setDocumentRefs (el) {
      if (el) {
        this.documentRefs.push(el)
      }
    },
    scrollIntoDocument (item, page) {
      const documentRef = this.documentRefs.find((e) => e.document.uuid === item.attachment_uuid)
      documentRef.scrollIntoDocument(page)
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
    onKeyDown (event) {
      if ((event.metaKey && event.shiftKey && event.key === 'z') || (event.ctrlKey && event.key === 'Z')) {
        event.stopImmediatePropagation()
        event.preventDefault()

        this.redo()
      } else if ((event.ctrlKey || event.metaKey) && event.key === 'z') {
        event.stopImmediatePropagation()
        event.preventDefault()

        this.undo()
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
    pushUndo () {
      const stringData = JSON.stringify(this.template)

      if (this.undoStack[this.undoStack.length - 1] !== stringData) {
        this.undoStack.push(stringData)

        if (this.lastRedoData !== stringData) {
          this.redoStack = []
        }
      }
    },
    onDraw (area) {
      if (this.drawField) {
        this.drawField.areas ||= []
        this.drawField.areas.push(area)

        if (this.template.fields.indexOf(this.drawField) === -1) {
          this.template.fields.push(this.drawField)
        }

        this.drawField = null

        this.selectedAreaRef.value = area

        this.save()
      } else {
        const documentRef = this.documentRefs.find((e) => e.document.uuid === area.attachment_uuid)
        const pageMask = documentRef.pageRefs[area.page].$refs.mask

        const type = (pageMask.clientWidth * area.w) < 35 ? 'checkbox' : 'text'

        if (type === 'checkbox') {
          const previousField = [...this.template.fields].reverse().find((f) => f.type === type)
          const previousArea = previousField?.areas?.[previousField.areas.length - 1]

          if (previousArea || area.w) {
            const areaW = previousArea?.w || (30 / pageMask.clientWidth)
            const areaH = previousArea?.h || (30 / pageMask.clientHeight)

            if ((pageMask.clientWidth * area.w) < 5) {
              area.x = area.x - (areaW / 2)
              area.y = area.y - (areaH / 2)
            }

            area.w = areaW
            area.h = areaH
          }
        }

        if (area.w) {
          const field = {
            name: '',
            uuid: v4(),
            required: type !== 'checkbox',
            type,
            submitter_uuid: this.selectedSubmitter.uuid,
            areas: [area]
          }

          this.template.fields.push(field)

          this.selectedAreaRef.value = area

          this.save()
        }
      }
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
        } else if (this.dragFieldType === 'initials') {
          baseArea = {
            w: area.maskW / 10 / area.maskW,
            h: area.maskW / 35 / area.maskW
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
      if (window.confirm('Are you sure you want to delete the document?')) {
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
    maybeShowEmptyTemplateAlert (e) {
      if (!this.template.fields.length) {
        e.preventDefault()

        alert('Please draw fields to prepare the document.')
      }
    },
    onSaveClick () {
      if (this.template.fields.length) {
        this.isSaving = true

        this.save().then(() => {
          window.Turbo.visit(`/templates/${this.template.id}`)
        }).finally(() => {
          this.isSaving = false
        })
      } else {
        alert('Please draw fields to prepare the document.')
      }
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

      this.pushUndo()

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
    },
    removeImage (item, imageId) {
      const document = this.template.documents.find((e) => e.uuid === item.attachment_uuid)
      if (Array.isArray(document.preview_images)) {
        const indexToRemove = document.preview_images.findIndex((previewImage) => previewImage.id === imageId)
        // console.log(indexToRemove)
        if (indexToRemove !== -1) {
          const confirmed = window.confirm('Are you sure you want to delete this image?')
          if (confirmed) {
            const documentId = document.id
            const apiUrl = `/api/templates/${this.template.id}/documents/${documentId}/del_image`
            fetch(apiUrl, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json'
              },
              body: JSON.stringify({
                template: this.template.id,
                attachment_id: imageId,
                documentId
              })
            })
              .then((response) => {
                if (!response.ok) {
                  throw new Error(`HTTP error! Status: ${response.status}`)
                }
                return response.json()
              })
              .then((data) => {
                console.log('Success:', data)
                document.preview_images = data.updated_preview_images
                document.metadata = data.updated_metadata
              })
              .catch((error) => {
                console.error('Error:', error)
              })
          }
        }
      }
    },
    addBlankPage (item) {
      const documentRef = this.documentRefs.find((e) => e.document.uuid === item.attachment_uuid)
      const confirmed = window.confirm('Are you sure you want to create new image?')
      if (confirmed) {
        const documentId = documentRef.document.id
        const apiUrl = `/api/templates/${this.template.id}/documents/${documentId}/add_new_image`
        fetch(apiUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            template_id: this.template.id,
            document: documentRef.document
          })
        })
          .then((response) => {
            if (!response.ok) {
              throw new Error(`HTTP error! Status: ${response.status}`)
            }
            return response.json()
          })
          .then((data) => {
            console.log('Success: ---', data)
            documentRef.document.preview_images = data.updated_preview_images
            documentRef.document.metadata = data.updated_metadata
          })
          .catch((error) => {
            console.error('Error: ---', error)
          })
      }
    }
  }
}
</script>

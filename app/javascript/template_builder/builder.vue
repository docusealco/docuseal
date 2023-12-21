<template>
  <div
    style="max-width: 1600px"
    class="mx-auto pl-3 md:pl-4 h-full"
  >
    <div
      v-if="$slots.buttons || withTitle"
      class="flex justify-between py-1.5 items-center pr-4 sticky top-0 z-10"
      :style="{ backgroundColor }"
    >
      <div class="flex items-center space-x-3">
        <a
          v-if="withLogo"
          href="/"
        >
          <Logo />
        </a>
        <Contenteditable
          v-if="withTitle"
          :model-value="template.name"
          :editable="editable"
          class="text-xl md:text-3xl font-semibold focus:text-clip"
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
            :href="template.submitters.length > 1 ? `/templates/${template.id}/submissions/new?selfsign=true` : `/d/${template.slug}`"
            class="btn btn-primary btn-ghost text-base hidden md:flex"
            :target="template.submitters.length > 1 ? '' : '_blank'"
            :data-turbo-frame="template.submitters.length > 1 ? 'modal' : ''"
            @click="maybeShowEmptyTemplateAlert"
          >
            <IconWritingSign
              width="20"
              class="inline"
            />
            <span class="hidden md:inline">
              Sign Yourself
            </span>
          </a>
          <a
            :href="`/templates/${template.id}/submissions/new`"
            data-turbo-frame="modal"
            class="white-button md:!px-6"
            @click="maybeShowEmptyTemplateAlert"
          >
            <IconUsersPlus
              width="20"
              class="inline"
            />
            <span class="hidden md:inline">
              Send
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
    <div
      class="flex"
      :class="$slots.buttons || withTitle ? 'md:max-h-[calc(100%_-_60px)]' : 'md:max-h-[100%]'"
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
          :accept-file-types="acceptFileTypes"
          :with-replace-button="withUploadButton"
          :editable="editable"
          :template="template"
          :is-direct-upload="isDirectUpload"
          :is-loading="isLoading"
          :is-deleting="isDeleting"
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
          :style="withStickySubmitters ? { backgroundColor } : {}"
        >
          <Upload
            v-if="sortedDocuments.length && editable && withUploadButton"
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
            v-if="!sortedDocuments.length && withUploadButton"
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
                :is-drag="!!dragField"
                :default-fields="defaultFields"
                :draw-field="drawField"
                :editable="editable"
                :base-url="baseUrl"
                @draw="onDraw"
                @drop-field="onDropfield"
                @remove-area="removeArea"
                @update:my-field="updateMyValues"
              />
              <DocumentControls
                v-if="isBreakpointLg && editable"
                :with-arrows="template.schema.length > 1"
                :item="template.schema.find((item) => item.attachment_uuid === document.uuid)"
                :with-replace-button="withUploadButton"
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
                v-if="withUploadButton"
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
          @cancel="[drawField = null, drawOption = null]"
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
          class="sticky inset-0 h-full"
          :style="{ backgroundColor }"
        >
          <div class="bg-base-300 rounded-lg p-5 text-center space-y-4">
            <p>
              Draw {{ drawField.name }} field on the document
            </p>
            <p>
              <button
                class="base-button"
                @click="[drawField = null, drawOption = null]"
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
            :default-submitters="defaultSubmitters"
            :default-fields="defaultFields"
            :with-sticky-submitters="withStickySubmitters"
            :editable="editable"
            @set-draw="[drawField = $event.field, drawOption = $event.option]"
            @set-drag="dragField = $event"
            @change-submitter="selectedSubmitter = $event"
            @drag-end="dragField = null"
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
import { t } from './i18n'
import { IconUsersPlus, IconDeviceFloppy, IconWritingSign, IconInnerShadowTop, IconPlus, IconX } from '@tabler/icons-vue'
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
    IconWritingSign,
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
      templateAttachments: this.templateAttachments,
      isDirectUpload: this.isDirectUpload,
      baseFetch: this.baseFetch,
      backgroundColor: this.backgroundColor,
      withPhone: this.withPhone,
      withPayment: this.withPayment,
      selectedAreaRef: computed(() => this.selectedAreaRef),
      baseUrl: this.baseUrl,
      t: this.t
    }
  },
  props: {
    template: {
      type: Object,
      required: true
    },
    templateAttachments: {
      type: Array,
      required: false,
      default: () => []
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
    defaultFields: {
      type: Array,
      required: false,
      default: () => []
    },
    defaultSubmitters: {
      type: Array,
      required: false,
      default: () => []
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
    onUpload: {
      type: Function,
      required: false,
      default () {
        return () => {}
      }
    },
    withStickySubmitters: {
      type: Boolean,
      required: false,
      default: true
    },
    withUploadButton: {
      type: Boolean,
      required: false,
      default: true
    },
    withTitle: {
      type: Boolean,
      required: false,
      default: true
    },
    withPhone: {
      type: Boolean,
      required: false,
      default: false
    },
    withPayment: {
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
      dragFieldType: null,
      isLoading: false,
      isDeleting: false,
      drawOption: null,
      dragField: null
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
    },
    myAttachmentsIndex () {
      return this.templateAttachments.reduce((acc, a) => {
        acc[a.uuid] = a

        return acc
      }, {})
    }
  },
  created () {
    this.defaultSubmitters.forEach((name, index) => {
      const submitter = (this.template.submitters[index] ||= {})

      submitter.name = name
      submitter.uuid ||= v4()
    })

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

    this.$nextTick(() => {
      if (document.location.search?.includes('stripe_connect_success')) {
        document.querySelector('form[action="/auth/stripe_connect"]')?.closest('.dropdown')?.querySelector('label')?.focus()
      }
    })
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
    t,
    updateMyValues (values) {
      const existingValues = this.template.values || {}
      const updatedValues = { ...existingValues, ...values }
      this.template.values = updatedValues
    },
    startFieldDraw (type) {
      const field = {
        name: '',
        uuid: v4(),
        required: type !== 'checkbox',
        areas: [],
        submitter_uuid: this.selectedSubmitter.uuid,
        type
      }
      if (['redact', 'my_text', 'my_signature', 'my_initials', 'my_date', 'my_check'].includes(type)) {
        field.required = false
      }
      if (['select', 'multiple', 'radio'].includes(type)) {
        field.options = [{ value: '', uuid: v4() }]
      }

      if (type === 'date') {
        field.preferences = {
          format: Intl.DateTimeFormat().resolvedOptions().locale.endsWith('-US') ? 'MM/DD/YYYY' : 'DD/MM/YYYY'
        }
      }

      this.drawField = field
      this.drawOption = null
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
      const documentRef = this.documentRefs.find((e) => e.document?.uuid === item.attachment_uuid)
      documentRef.scrollIntoDocument(page)
    },
    onKeyUp (e) {
      if (e.code === 'Escape') {
        this.drawField = null
        this.drawOption = null
        this.selectedAreaRef.value = null
      }

      if (this.editable && ['Backspace', 'Delete'].includes(e.key) && this.selectedAreaRef.value && document.activeElement === document.body) {
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
      if (['my_text', 'my_signature', 'my_initials', 'my_date'].includes(field.type)) {
        const valuesArray = Object.values(this.template.values)
        const valueIndex = valuesArray.findIndex((value) => value === this.template.values[field.uuid])
        valuesArray.splice(valueIndex, 1)
        const valueKey = Object.keys(this.template.values)[valueIndex]
        if (['my_signature', 'my_initials'].includes(field.type)) {
          const myAttachmentsIndex = this.myAttachmentsIndex[this.template.values[field.uuid]]
          this.templateAttachments.splice(this.templateAttachments.indexOf(myAttachmentsIndex), 1)
        }
        delete this.template.values[valueKey]
      }

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
        if (this.drawOption) {
          const areaWithoutOption = this.drawField.areas?.find((a) => !a.option_uuid)

          if (areaWithoutOption && !this.drawField.areas.find((a) => a.option_uuid === this.drawField.options[0].uuid)) {
            areaWithoutOption.option_uuid = this.drawField.options[0].uuid
          }

          area.option_uuid = this.drawOption.uuid
        }

        this.drawField.areas ||= []
        this.drawField.areas.push(area)

        if (this.template.fields.indexOf(this.drawField) === -1) {
          this.template.fields.push(this.drawField)
        }

        this.drawField = null
        this.drawOption = null

        this.selectedAreaRef.value = area

        this.save()
      } else if (this.selectedSubmitter.name === 'Me') {
        const documentRef = this.documentRefs.find((e) => e.document.uuid === area.attachment_uuid)
        const pageMask = documentRef.pageRefs[area.page].$refs.mask

        const type = (pageMask.clientWidth * area.w) < 35 ? 'my_check' : 'my_text'

        if (area.w) {
          const field = {
            name: '',
            uuid: v4(),
            required: type !== 'checkbox',
            type,
            submitter_uuid: this.selectedSubmitter.uuid,
            areas: [area]
          }
          if (['redact', 'my_text', 'my_signature', 'my_initials', 'my_date', 'my_check'].includes(field.type)) {
            field.required = false
          }
          this.template.fields.push(field)

          this.selectedAreaRef.value = area

          this.save()
        }
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
          if (['redact', 'my_text', 'my_signature', 'my_initials', 'my_date', 'my_check'].includes(field.type)) {
            field.required = false
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
        uuid: v4(),
        submitter_uuid: this.selectedSubmitter.uuid,
        required: this.dragField.type !== 'checkbox',
        ...this.dragField
      }

      if (['redact', 'my_text', 'my_signature', 'my_initials', 'my_date', 'my_check'].includes(field.type)) {
        field.required = false
      }
      if (['select', 'multiple', 'radio'].includes(field.type)) {
        field.options = [{ value: '', uuid: v4() }]
      }

      if (field.type === 'date') {
        field.preferences = {
          format: Intl.DateTimeFormat().resolvedOptions().locale.endsWith('-US') ? 'MM/DD/YYYY' : 'DD/MM/YYYY'
        }
      }

      const fieldArea = {
        x: (area.x - 6) / area.maskW,
        y: area.y / area.maskH,
        page: area.page,
        attachment_uuid: area.attachment_uuid
      }

      const previousField = [...this.template.fields].reverse().find((f) => f.type === field.type)

      let baseArea

      if (this.selectedField?.type === field.type) {
        baseArea = this.selectedAreaRef.value
      } else if (previousField?.areas?.length) {
        baseArea = previousField.areas[previousField.areas.length - 1]
      } else {
        if (['checkbox', 'my_check'].includes(field.type)) {
          baseArea = {
            w: area.maskW / 30 / area.maskW,
            h: area.maskW / 30 / area.maskW * (area.maskW / area.maskH)
          }
        } else if (field.type === 'image') {
          baseArea = {
            w: area.maskW / 5 / area.maskW,
            h: (area.maskW / 5 / area.maskW) * (area.maskW / area.maskH)
          }
        } else if (['signature', 'my_signature'].includes(field.type)) {
          baseArea = {
            w: area.maskW / 5 / area.maskW,
            h: (area.maskW / 5 / area.maskW) * (area.maskW / area.maskH) / 2
          }
        } else if (['initials', 'my_initials'].includes(field.type)) {
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

      if (field.type === 'cells') {
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

      if (this.onUpload) {
        this.onUpload(this.template)
      }

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

      if (this.onUpload) {
        this.onUpload(this.template)
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
            fields: this.template.fields,
            values: this.template.values
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
            this.isDeleting = true
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
                document_id: documentId
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
                const pageNumber = document.preview_images.findIndex(pic => pic.id === imageId)
                this.template.fields.forEach((field) => {
                  [...(field.areas || [])].forEach((area) => {
                    if (area.attachment_uuid === document.uuid && area.page === pageNumber) {
                      field.areas.splice(field.areas.indexOf(area), 1)
                    }
                  })
                })
                document.preview_images = data.updated_preview_images
                document.metadata = data.updated_metadata
              })
              .catch((error) => {
                console.error('Error:', error)
              })
              .finally(() => {
                this.isDeleting = false
              })
          }
        }
      }
    },
    addBlankPage (item) {
      const documentRef = this.documentRefs.find((e) => e.document.uuid === item.attachment_uuid)
      const confirmed = window.confirm('Are you sure you want to create new image?')
      if (confirmed) {
        this.isLoading = true
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
          .finally(() => {
            this.isLoading = false
          })
      }
    }
  }
}
</script>

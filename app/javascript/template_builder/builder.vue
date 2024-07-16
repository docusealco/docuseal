<template>
  <div
    style="max-width: 1600px"
    class="mx-auto pl-3 md:pl-4 h-full"
  >
    <div
      v-if="pendingFieldAttachmentUuids.length"
      class="top-1.5 sticky h-0 z-20 max-w-2xl mx-auto"
    >
      <div class="alert border-base-content/30 py-2 px-2.5">
        <IconInfoCircle
          class="stroke-info shrink-0 w-6 h-6"
        />
        <span>{{ t('uploaded_pdf_contains_form_fields_keep_or_remove_them') }}</span>
        <div>
          <button
            class="btn btn-sm"
            @click.prevent="removePendingFields"
          >
            {{ t('remove') }}
          </button>
          <button
            class="btn btn-sm btn-neutral text-white"
            @click.prevent="save"
          >
            {{ t('keep') }}
          </button>
        </div>
      </div>
    </div>
    <div
      v-if="$slots.buttons || withTitle"
      id="title_container"
      class="flex justify-between py-1.5 items-center pr-4 top-0 z-10"
      :class="{ sticky: withStickySubmitters || isBreakpointLg }"
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
      <div class="space-x-3 flex items-center flex-shrink-0">
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
            @click="maybeShowErrorTemplateAlert"
          >
            <IconWritingSign
              width="22"
              class="inline"
            />
            <span class="hidden md:inline">
              {{ t('sign_yourself') }}
            </span>
          </a>
          <a
            :href="`/templates/${template.id}/submissions/new?with_link=true`"
            data-turbo-frame="modal"
            class="white-button md:!px-6"
            @click="maybeShowErrorTemplateAlert"
          >
            <IconUsersPlus
              width="20"
              class="inline"
            />
            <span class="hidden md:inline">
              {{ t('send') }}
            </span>
          </a>
          <span
            v-if="editable"
            class="flex"
          >
            <button
              class="base-button !rounded-r-none !pr-2"
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
                {{ t('save') }}
              </span>
            </button>
            <div class="dropdown dropdown-end">
              <label
                tabindex="0"
                class="base-button !rounded-l-none !pl-1 !pr-2 !border-l-neutral-500"
              >
                <span class="text-sm align-text-top">
                  <IconChevronDown class="w-5 h-5 flex-shrink-0" />
                </span>
              </label>
              <ul
                tabindex="0"
                class="dropdown-content p-2 mt-2 shadow menu text-base bg-base-100 rounded-box text-right"
              >
                <li>
                  <a
                    :href="`/templates/${template.id}/form`"
                    data-turbo="false"
                    class="flex items-center justify-center space-x-2"
                  >
                    <IconEye class="w-6 h-6 flex-shrink-0" />
                    <span class="whitespace-nowrap">Save and Preview</span>
                  </a>
                </li>
              </ul>
            </div>
          </span>
          <a
            v-else
            :href="`/templates/${template.id}`"
            class="base-button"
          >
            <span class="hidden md:inline">
              {{ t('back') }}
            </span>
          </a>
        </template>
      </div>
    </div>
    <div
      id="main_container"
      class="flex"
      :class="$slots.buttons || withTitle ? 'md:max-h-[calc(100%_-_60px)]' : 'md:max-h-[100%]'"
    >
      <div
        v-if="withDocumentsList"
        id="documents_container"
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
          @scroll-to="scrollIntoDocument(item)"
          @remove="onDocumentRemove"
          @replace="onDocumentReplace"
          @up="moveDocument(item, -1)"
          @down="moveDocument(item, 1)"
          @change="save"
        />
        <div
          class="sticky bottom-0 py-2 space-y-2"
          :style="{ backgroundColor }"
        >
          <Upload
            v-if="sortedDocuments.length && editable && withUploadButton"
            :accept-file-types="acceptFileTypes"
            :template-id="template.id"
            @success="updateFromUpload"
          />
          <button
            v-if="sortedDocuments.length && editable && withAddPageButton"
            id="add_blank_page_button"
            class="btn btn-outline w-full"
            @click.prevent="addBlankPage"
          >
            <IconInnerShadowTop
              v-if="isLoadingBlankPage"
              class="animate-spin w-5 h-5"
            />
            <IconPlus
              v-else
              class="w-5 h-5"
            />
            {{ t('add_blank_page') }}
          </button>
        </div>
      </div>
      <div
        id="pages_container"
        class="w-full overflow-y-hidden md:overflow-y-auto overflow-x-hidden mt-0.5 pt-0.5"
      >
        <div
          ref="documents"
          class="pr-3.5 pl-0.5"
        >
          <template v-if="!sortedDocuments.length && (withUploadButton || withAddPageButton)">
            <Dropzone
              v-if="withUploadButton"
              :template-id="template.id"
              :accept-file-types="acceptFileTypes"
              @success="updateFromUpload"
            />
            <button
              v-if="withAddPageButton"
              id="add_blank_page_button"
              class="btn btn-outline w-full mt-4"
              @click.prevent="addBlankPage"
            >
              <IconInnerShadowTop
                v-if="isLoadingBlankPage"
                class="animate-spin w-5 h-5"
              />
              <IconPlus
                v-else
                class="w-5 h-5"
              />
              {{ t('add_blank_page') }}
            </button>
          </template>
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
                :input-mode="inputMode"
                :default-fields="[...defaultRequiredFields, ...defaultFields]"
                :allow-draw="!onlyDefinedFields"
                :default-submitters="defaultSubmitters"
                :with-field-placeholder="withFieldPlaceholder"
                :draw-field="drawField"
                :draw-field-type="drawFieldType"
                :editable="editable"
                :base-url="baseUrl"
                @draw="[onDraw($event), withSelectedFieldType ? '' : drawFieldType = '', showDrawField = false]"
                @drop-field="onDropfield"
                @remove-area="removeArea"
              />
              <DocumentControls
                v-if="isBreakpointLg && editable"
                :with-arrows="template.schema.length > 1"
                :item="template.schema.find((item) => item.attachment_uuid === document.uuid)"
                :with-replace-button="withUploadButton"
                :accept-file-types="acceptFileTypes"
                :document="document"
                :template="template"
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
              class="pb-4 space-y-2"
            >
              <Upload
                v-if="withUploadButton"
                :template-id="template.id"
                :accept-file-types="acceptFileTypes"
                @success="updateFromUpload"
              />
              <button
                v-if="withAddPageButton"
                id="add_blank_page_button"
                class="btn btn-outline w-full mt-4"
                @click.prevent="addBlankPage"
              >
                <IconInnerShadowTop
                  v-if="isLoadingBlankPage"
                  class="animate-spin w-5 h-5"
                />
                <IconPlus
                  v-else
                  class="w-5 h-5"
                />
                {{ t('add_blank_page') }}
              </button>
            </div>
          </template>
        </div>
      </div>
      <div
        v-if="withFieldsList"
        id="fields_list_container"
        class="relative w-80 flex-none mt-1 pr-4 pl-0.5 hidden md:block"
        :class="drawField ? 'overflow-hidden' : 'overflow-y-auto overflow-x-hidden'"
      >
        <div
          v-if="showDrawField || drawField"
          class="sticky inset-0 h-full z-20"
          :style="{ backgroundColor }"
        >
          <div class="bg-base-200 rounded-lg p-5 text-center space-y-4">
            <p>
              {{ t('draw_field_on_the_document').replace('{field}', drawField?.name || '') }}
            </p>
            <div>
              <button
                class="base-button"
                @click="clearDrawField"
              >
                {{ t('cancel') }}
              </button>
              <a
                v-if="!drawField && !drawOption && !['stamp', 'signature', 'initials', 'heading'].includes(drawField?.type || drawFieldType)"
                href="#"
                class="link block mt-3 text-sm"
                @click.prevent="[addField(drawFieldType), drawField = null, drawOption = null, withSelectedFieldType ? '' : drawFieldType = '', showDrawField = false]"
              >
                {{ t('or_add_field_without_drawing') }}
              </a>
            </div>
          </div>
        </div>
        <div>
          <Fields
            ref="fields"
            :fields="template.fields"
            :submitters="template.submitters"
            :selected-submitter="selectedSubmitter"
            :with-help="withHelp"
            :default-submitters="defaultSubmitters"
            :draw-field-type="drawFieldType"
            :default-fields="[...defaultRequiredFields, ...defaultFields]"
            :default-required-fields="defaultRequiredFields"
            :field-types="fieldTypes"
            :with-sticky-submitters="withStickySubmitters"
            :only-defined-fields="onlyDefinedFields"
            :editable="editable"
            @add-field="addField"
            @set-draw="[drawField = $event.field, drawOption = $event.option]"
            @set-draw-type="[drawFieldType = $event, showDrawField = true]"
            @set-drag="dragField = $event"
            @change-submitter="selectedSubmitter = $event"
            @drag-end="dragField = null"
            @scroll-to-area="scrollToArea"
          />
        </div>
      </div>
    </div>
    <div class="sticky bottom-0">
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
      <MobileFields
        v-if="sortedDocuments.length && !drawField && editable"
        :fields="template.fields"
        :default-fields="[...defaultRequiredFields, ...defaultFields]"
        :default-required-fields="defaultRequiredFields"
        :field-types="fieldTypes"
        :selected-submitter="selectedSubmitter"
        @select="startFieldDraw($event)"
      />
    </div>
    <div id="docuseal_modal_container" />
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
import MobileFields from './mobile_fields'
import { IconPlus, IconUsersPlus, IconDeviceFloppy, IconChevronDown, IconEye, IconWritingSign, IconInnerShadowTop, IconInfoCircle } from '@tabler/icons-vue'
import { v4 } from 'uuid'
import { ref, computed } from 'vue'
import { en as i18nEn } from './i18n'

export default {
  name: 'TemplateBuilder',
  components: {
    Upload,
    Document,
    Fields,
    IconInfoCircle,
    MobileDrawField,
    IconPlus,
    IconWritingSign,
    MobileFields,
    Logo,
    Dropzone,
    DocumentPreview,
    DocumentControls,
    IconInnerShadowTop,
    Contenteditable,
    IconUsersPlus,
    IconChevronDown,
    IconEye,
    IconDeviceFloppy
  },
  provide () {
    return {
      template: this.template,
      save: this.save,
      t: this.t,
      currencies: this.currencies,
      baseFetch: this.baseFetch,
      fieldTypes: this.fieldTypes,
      backgroundColor: this.backgroundColor,
      withPhone: this.withPhone,
      withPayment: this.withPayment,
      isPaymentConnected: this.isPaymentConnected,
      withFormula: this.withFormula,
      withConditions: this.withConditions,
      defaultDrawFieldType: this.defaultDrawFieldType,
      selectedAreaRef: computed(() => this.selectedAreaRef),
      fieldsDragFieldRef: computed(() => this.fieldsDragFieldRef)
    }
  },
  props: {
    template: {
      type: Object,
      required: true
    },
    i18n: {
      type: Object,
      required: false,
      default: () => ({})
    },
    withFieldPlaceholder: {
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
    inputMode: {
      type: Boolean,
      required: false,
      default: false
    },
    withHelp: {
      type: Boolean,
      required: false,
      default: true
    },
    withAddPageButton: {
      type: Boolean,
      required: false,
      default: false
    },
    autosave: {
      type: Boolean,
      required: false,
      default: true
    },
    defaultFields: {
      type: Array,
      required: false,
      default: () => []
    },
    defaultRequiredFields: {
      type: Array,
      required: false,
      default: () => []
    },
    withSelectedFieldType: {
      type: Boolean,
      required: false,
      default: false
    },
    defaultDrawFieldType: {
      type: String,
      required: false,
      default: 'text'
    },
    currencies: {
      type: Array,
      required: false,
      default: () => []
    },
    fieldTypes: {
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
    onSave: {
      type: Function,
      required: false,
      default () {
        return () => {}
      }
    },
    onChange: {
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
    withFieldsList: {
      type: Boolean,
      required: false,
      default: true
    },
    authenticityToken: {
      type: String,
      required: false,
      default: ''
    },
    withDocumentsList: {
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
    isPaymentConnected: {
      type: Boolean,
      required: false,
      default: false
    },
    withFormula: {
      type: Boolean,
      required: false,
      default: false
    },
    withConditions: {
      type: Boolean,
      required: false,
      default: false
    },
    onlyDefinedFields: {
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
      isLoadingBlankPage: false,
      isSaving: false,
      selectedSubmitter: null,
      showDrawField: false,
      pendingFieldAttachmentUuids: [],
      drawField: null,
      copiedArea: null,
      drawFieldType: null,
      drawOption: null,
      dragField: null
    }
  },
  computed: {
    selectedAreaRef: () => ref(),
    fieldsDragFieldRef: () => ref(),
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
    isAllRequiredFieldsAdded () {
      return !this.defaultRequiredFields?.some((f) => {
        return !this.template.fields?.some((field) => field.name === f.name)
      })
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
    if (!this.template.fields?.length && this.template.submitters?.length === 1) {
      if (this.template.submitters[0]?.name === 'First Party') {
        this.template.submitters[0].name = this.t('first_party')
      }
    }

    const existingSubmittersUuids = this.defaultSubmitters.map((name) => {
      return this.template.submitters.find(e => e.name === name)?.uuid
    })

    this.defaultSubmitters.forEach((name, index) => {
      const submitter = (this.template.submitters[index] ||= {})

      submitter.name = name

      if (existingSubmittersUuids.filter(Boolean).length) {
        submitter.uuid = existingSubmittersUuids[index] || submitter.uuid || v4()
      } else {
        submitter.uuid ||= v4()
      }
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

    this.template.schema.forEach((item) => {
      if (item.pending_fields) {
        this.pendingFieldAttachmentUuids.push(item.attachment_uuid)
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
    t (key) {
      return this.i18n[key] || i18nEn[key] || key
    },
    removePendingFields () {
      this.template.fields = this.template.fields.filter((f) => {
        return this.template.schema.find((item) => item.attachment_uuid === f.attachment_uuid && item.pending_fields)
      })

      this.save()
    },
    addField (type, area = null) {
      const field = {
        name: '',
        uuid: v4(),
        required: type !== 'checkbox',
        areas: area ? [area] : [],
        submitter_uuid: this.selectedSubmitter.uuid,
        type
      }

      if (['select', 'multiple', 'radio'].includes(type)) {
        field.options = [{ value: '', uuid: v4() }]
      }

      if (type === 'stamp') {
        field.readonly = true
      }

      if (type === 'date') {
        field.preferences = {
          format: Intl.DateTimeFormat().resolvedOptions().locale.endsWith('-US') || new Intl.DateTimeFormat('en-US', { timeZoneName: 'short' }).format(new Date()).match(/\s(?:CST|CDT|PST|PDT|EST|EDT)$/) ? 'MM/DD/YYYY' : 'DD/MM/YYYY'
        }
      }

      this.template.fields.push(field)

      this.save()
    },
    startFieldDraw ({ name, type }) {
      const existingField = this.template.fields?.find((f) => f.submitter_uuid === this.selectedSubmitter.uuid && name && name === f.name)

      if (existingField) {
        this.drawField = existingField
      } else {
        const field = {
          name: name || '',
          uuid: v4(),
          required: type !== 'checkbox',
          areas: [],
          submitter_uuid: this.selectedSubmitter.uuid,
          type
        }

        if (['select', 'multiple', 'radio'].includes(type)) {
          field.options = [{ value: '', uuid: v4() }]
        }

        if (type === 'stamp') {
          field.readonly = true
        }

        if (type === 'date') {
          field.preferences = {
            format: Intl.DateTimeFormat().resolvedOptions().locale.endsWith('-US') || new Intl.DateTimeFormat('en-US', { timeZoneName: 'short' }).format(new Date()).match(/\s(?:CST|CDT|PST|PDT|EST|EDT)$/) ? 'MM/DD/YYYY' : 'DD/MM/YYYY'
          }
        }

        this.drawField = field
      }

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
    scrollIntoDocument (item) {
      const ref = this.documentRefs.find((e) => e.document.uuid === item.attachment_uuid)

      ref.$el.scrollIntoView({ behavior: 'smooth', block: 'start' })
    },
    clearDrawField () {
      this.drawField = null
      this.drawOption = null
      this.showDrawField = false

      if (!this.withSelectedFieldType) {
        this.drawFieldType = ''
      }
    },
    onKeyUp (e) {
      if (e.code === 'Escape') {
        this.clearDrawField()

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
      } else if ((event.ctrlKey || event.metaKey) && event.key === 'c' && document.activeElement === document.body) {
        event.preventDefault()

        this.copiedArea = this.selectedAreaRef?.value
      } else if ((event.ctrlKey || event.metaKey) && event.key === 'v' && this.copiedArea && document.activeElement === document.body) {
        event.preventDefault()

        this.pasteField()
      } else if (this.selectedAreaRef.value && ['ArrowLeft', 'ArrowUp', 'ArrowRight', 'ArrowDown'].includes(event.key) && document.activeElement === document.body) {
        event.preventDefault()

        this.handleAreaArrows(event)
      }
    },
    handleAreaArrows (event) {
      if (!this.editable) {
        return
      }

      const area = this.selectedAreaRef.value
      const documentRef = this.documentRefs.find((e) => e.document.uuid === area.attachment_uuid)
      const page = documentRef.pageRefs[area.page].$refs.image
      const rect = page.getBoundingClientRect()
      const diff = (event.shiftKey ? 5.0 : 1.0)

      if (event.key === 'ArrowRight' && event.altKey) {
        area.w = Math.min(Math.max(area.w + diff / rect.width, 0), 1 - area.x)
      } else if (event.key === 'ArrowLeft' && event.altKey) {
        area.w = Math.min(Math.max(area.w - diff / rect.width, 0), 1 - area.x)
      } else if (event.key === 'ArrowUp' && event.altKey) {
        area.h = Math.min(Math.max(area.h - diff / rect.height, 0), 1 - area.y)
      } else if (event.key === 'ArrowDown' && event.altKey) {
        area.h = Math.min(Math.max(area.h + diff / rect.height, 0), 1 - area.y)
      } else if (event.key === 'ArrowRight') {
        area.x = Math.min(Math.max(area.x + diff / rect.width, 0), 1 - area.w)
      } else if (event.key === 'ArrowLeft') {
        area.x = Math.min(Math.max(area.x - diff / rect.width, 0), 1 - area.w)
      } else if (event.key === 'ArrowUp') {
        area.y = Math.min(Math.max(area.y - diff / rect.height, 0), 1 - area.h)
      } else if (event.key === 'ArrowDown') {
        area.y = Math.min(Math.max(area.y + diff / rect.height, 0), 1 - area.h)
      }

      this.debouncedSave()
    },
    debouncedSave () {
      clearTimeout(this._saveTimeout)

      this._saveTimeout = setTimeout(() => {
        this.save()
      }, 700)
    },
    removeArea (area) {
      const field = this.template.fields.find((f) => f.areas?.includes(area))

      field.areas.splice(field.areas.indexOf(area), 1)

      if (!field.areas.length) {
        this.template.fields.splice(this.template.fields.indexOf(field), 1)
      }

      this.save()
    },
    pasteField () {
      const field = this.template.fields.find((f) => f.areas?.includes(this.copiedArea))
      const currentArea = this.selectedAreaRef?.value || this.copiedArea

      if (field && currentArea) {
        const area = {
          ...JSON.parse(JSON.stringify(this.copiedArea)),
          attachment_uuid: currentArea.attachment_uuid,
          page: currentArea.page,
          x: currentArea.x,
          y: currentArea.y + currentArea.h * 1.3
        }

        if (['radio', 'multiple'].includes(field.type)) {
          this.copiedArea.option_uuid ||= field.options[0].uuid
          area.option_uuid = v4()

          field.options.push({ uuid: area.option_uuid })

          field.areas.push(area)
        } else {
          this.template.fields.push({
            ...JSON.parse(JSON.stringify(field)),
            uuid: v4(),
            areas: [area]
          })
        }

        this.selectedAreaRef.value = area

        this.save()
      }
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
    setDefaultAreaSize (area, type) {
      const documentRef = this.documentRefs.find((e) => e.document.uuid === area.attachment_uuid)
      const pageMask = documentRef.pageRefs[area.page].$refs.mask

      if (type === 'checkbox') {
        area.w = pageMask.clientWidth / 30 / pageMask.clientWidth
        area.h = (pageMask.clientWidth / 30 / pageMask.clientWidth) * (pageMask.clientWidth / pageMask.clientHeight)
      } else if (type === 'image') {
        area.w = pageMask.clientWidth / 5 / pageMask.clientWidth
        area.h = (pageMask.clientWidth / 5 / pageMask.clientWidth) * (pageMask.clientWidth / pageMask.clientHeight)
      } else if (type === 'signature' || type === 'stamp') {
        area.w = pageMask.clientWidth / 5 / pageMask.clientWidth
        area.h = (pageMask.clientWidth / 5 / pageMask.clientWidth) * (pageMask.clientWidth / pageMask.clientHeight) / 2
      } else if (type === 'initials') {
        area.w = pageMask.clientWidth / 10 / pageMask.clientWidth
        area.h = (pageMask.clientWidth / 35 / pageMask.clientWidth)
      } else {
        area.w = pageMask.clientWidth / 5 / pageMask.clientWidth
        area.h = (pageMask.clientWidth / 35 / pageMask.clientWidth)
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

        if (area.w === 0 || area.h === 0) {
          const previousArea = this.drawField.areas?.[this.drawField.areas.length - 1]

          if (this.selectedField?.type === this.drawField.type) {
            area.w = this.selectedAreaRef.value.w
            area.h = this.selectedAreaRef.value.h
          } else if (previousArea) {
            area.w = previousArea.w
            area.h = previousArea.h
          } else {
            this.setDefaultAreaSize(area, this.drawOption ? 'checkbox' : this.drawField?.type)
          }

          area.x -= area.w / 2
          area.y -= area.h / 2
        }

        this.drawField.areas ||= []

        const insertBeforeAreaIndex = this.drawField.areas.findIndex((a) => {
          return a.attachment_uuid === area.attachment_uuid && a.page > area.page
        })

        if (insertBeforeAreaIndex !== -1) {
          this.drawField.areas.splice(insertBeforeAreaIndex, 0, area)
        } else {
          this.drawField.areas.push(area)
        }

        if (this.template.fields.indexOf(this.drawField) === -1) {
          this.template.fields.push(this.drawField)
        }

        this.drawField = null
        this.drawOption = null

        this.selectedAreaRef.value = area

        this.save()
      } else {
        const documentRef = this.documentRefs.find((e) => e.document.uuid === area.attachment_uuid)
        const pageMask = documentRef.pageRefs[area.page].$refs.mask

        let type = (pageMask.clientWidth * area.w) < 35 ? 'checkbox' : 'text'

        if (this.drawFieldType) {
          type = this.drawFieldType
        } else if (this.defaultDrawFieldType && this.defaultDrawFieldType !== 'text') {
          type = this.defaultDrawFieldType
        } else if (this.fieldTypes.length !== 0 && !this.fieldTypes.includes(type)) {
          type = this.fieldTypes[0]
        }

        if (type === 'checkbox' && !this.drawFieldType && (this.template.fields[this.template.fields.length - 1]?.type === 'checkbox' || area.w)) {
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

        if (this.drawFieldType && (area.w === 0 || area.h === 0)) {
          if (this.selectedField?.type === this.drawFieldType) {
            area.w = this.selectedAreaRef.value.w
            area.h = this.selectedAreaRef.value.h
          } else {
            this.setDefaultAreaSize(area, this.drawFieldType)
          }

          area.x -= area.w / 2
          area.y -= area.h / 2
        }

        if (area.w) {
          this.addField(type, area)

          this.selectedAreaRef.value = area
        }
      }
    },
    onDropfield (area) {
      const field = this.fieldsDragFieldRef.value || {
        name: '',
        uuid: v4(),
        submitter_uuid: this.selectedSubmitter.uuid,
        required: this.dragField.type !== 'checkbox',
        ...this.dragField
      }

      if (!this.fieldsDragFieldRef.value) {
        if (['select', 'multiple', 'radio'].includes(field.type)) {
          field.options = [{ value: '', uuid: v4() }]
        }

        if (['stamp', 'heading'].includes(field.type)) {
          field.readonly = true
        }

        if (field.type === 'date') {
          field.preferences = {
            format: Intl.DateTimeFormat().resolvedOptions().locale.endsWith('-US') || new Intl.DateTimeFormat('en-US', { timeZoneName: 'short' }).format(new Date()).match(/\s(?:CST|CDT|PST|PDT|EST|EDT)$/) ? 'MM/DD/YYYY' : 'DD/MM/YYYY'
          }
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
        if (['checkbox'].includes(field.type)) {
          baseArea = {
            w: area.maskW / 30 / area.maskW,
            h: area.maskW / 30 / area.maskW * (area.maskW / area.maskH)
          }
        } else if (field.type === 'image') {
          baseArea = {
            w: area.maskW / 5 / area.maskW,
            h: (area.maskW / 5 / area.maskW) * (area.maskW / area.maskH)
          }
        } else if (field.type === 'signature' || field.type === 'stamp') {
          baseArea = {
            w: area.maskW / 5 / area.maskW,
            h: (area.maskW / 5 / area.maskW) * (area.maskW / area.maskH) / 2
          }
        } else if (field.type === 'initials') {
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

      field.areas ||= []

      const lastArea = field.areas[field.areas.length - 1]

      if (lastArea) {
        fieldArea.x -= lastArea.w / 2
        fieldArea.w = lastArea.w
        fieldArea.h = lastArea.h
      }

      field.areas.push(fieldArea)

      this.selectedAreaRef.value = fieldArea

      if (this.template.fields.indexOf(field) === -1) {
        this.template.fields.push(field)
      }

      this.save()

      document.activeElement?.blur()

      if (field.type === 'heading') {
        this.$nextTick(() => {
          const documentRef = this.documentRefs.find((e) => e.document.uuid === area.attachment_uuid)
          const areaRef = documentRef.pageRefs[area.page].areaRefs.find((ref) => ref.area === this.selectedAreaRef.value)

          areaRef.focusValueInput()
        })
      }
    },
    addBlankPage () {
      this.isLoadingBlankPage = true

      const canvas = document.createElement('canvas')

      canvas.width = 816
      canvas.height = 1056

      const ctx = canvas.getContext('2d')

      ctx.fillStyle = 'white'
      ctx.fillRect(0, 0, canvas.width, canvas.height)

      canvas.toBlob((blob) => {
        const file = new File([blob], `Page ${this.template.schema.length + 1}.png`, { type: blob.type, lastModified: Date.now() })

        const formData = new FormData()
        formData.append('files[]', file)

        this.baseFetch(`/templates/${this.template.id}/documents`, {
          method: 'POST',
          body: formData
        }).then(async (resp) => {
          this.updateFromUpload(await resp.json())
        }).finally(() => {
          this.isLoadingBlankPage = false
        })
      }, 'image/png')
    },
    updateFromUpload (data) {
      this.template.schema.push(...data.schema)
      this.template.documents.push(...data.documents)

      if (data.fields) {
        this.template.fields = data.fields
      }

      if (data.submitters) {
        this.template.submitters = data.submitters

        if (!this.template.submitters.find((s) => s.uuid === this.selectedSubmitter?.uuid)) {
          this.selectedSubmitter = this.template.submitters[0]
        }
      }

      this.$nextTick(() => {
        this.$refs.previews.scrollTop = this.$refs.previews.scrollHeight

        this.scrollIntoDocument(data.schema[0])
      })

      if (this.template.name === 'New Document') {
        this.template.name = this.template.schema[0].name
      }

      if (this.onUpload) {
        this.onUpload(this.template)
      }

      this.save()

      data.documents.forEach((attachment) => {
        if (attachment.metadata?.pdf?.fields?.length) {
          this.pendingFieldAttachmentUuids.push(attachment.uuid)

          attachment.metadata.pdf.fields.forEach((field) => {
            field.submitter_uuid = this.selectedSubmitter.uuid

            this.template.fields.push(field)
          })
        }
      })
    },
    updateName (value) {
      this.template.name = value

      this.save()
    },
    onDocumentRemove (item) {
      if (window.confirm(this.t('are_you_sure'))) {
        this.template.schema.splice(this.template.schema.indexOf(item), 1)
      }

      const removedFieldUuids = []

      this.template.fields.forEach((field) => {
        [...(field.areas || [])].forEach((area) => {
          if (area.attachment_uuid === item.attachment_uuid) {
            field.areas.splice(field.areas.indexOf(area), 1)

            removedFieldUuids.push(field.uuid)
          }
        })
      })

      this.template.fields =
        this.template.fields.filter((f) => !removedFieldUuids.includes(f.uuid) || f.areas?.length)

      this.save()
    },
    onDocumentReplace (data) {
      const { replaceSchemaItem, schema, documents } = data

      this.template.schema.splice(this.template.schema.indexOf(replaceSchemaItem), 1, schema[0])
      this.template.documents.push(...documents)

      if (data.fields) {
        this.template.fields = data.fields

        const removedFieldUuids = []

        this.template.fields.forEach((field) => {
          [...(field.areas || [])].forEach((area) => {
            if (area.attachment_uuid === replaceSchemaItem.attachment_uuid) {
              field.areas.splice(field.areas.indexOf(area), 1)

              removedFieldUuids.push(field.uuid)
            }
          })
        })

        this.template.fields =
          this.template.fields.filter((f) => !removedFieldUuids.includes(f.uuid) || f.areas?.length)
      }

      if (data.submitters) {
        this.template.submitters = data.submitters

        if (!this.template.submitters.find((s) => s.uuid === this.selectedSubmitter?.uuid)) {
          this.selectedSubmitter = this.template.submitters[0]
        }
      }

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
    maybeShowErrorTemplateAlert (e) {
      if (!this.isAllRequiredFieldsAdded) {
        e.preventDefault()

        const fields = this.defaultRequiredFields?.filter((f) => {
          return !this.template.fields?.some((field) => field.name === f.name)
        })

        if (fields?.length) {
          return alert(this.t('add_all_required_fields_to_continue') + ': ' + fields.map((f) => f.name).join(', '))
        }
      }

      if (!this.template.fields.length) {
        e.preventDefault()

        alert('Please draw fields to prepare the document.')
      } else {
        const submitterWithoutFields =
          this.template.submitters.find((submitter) => !this.template.fields.some((f) => f.submitter_uuid === submitter.uuid))

        if (submitterWithoutFields) {
          e.preventDefault()

          alert(`Please add fields for the ${submitterWithoutFields.name}. Or, remove the ${submitterWithoutFields.name} if not needed.`)
        }
      }
    },
    onSaveClick () {
      if (!this.isAllRequiredFieldsAdded) {
        const fields = this.defaultRequiredFields?.filter((f) => {
          return !this.template.fields?.some((field) => field.name === f.name)
        })

        if (fields?.length) {
          return alert(this.t('add_all_required_fields_to_continue') + ': ' + fields.map((f) => f.name).join(', '))
        }
      }

      if (!this.template.fields.length) {
        alert('Please draw fields to prepare the document.')
      } else {
        const submitterWithoutFields =
          this.template.submitters.find((submitter) => !this.template.fields.some((f) => f.submitter_uuid === submitter.uuid))

        if (submitterWithoutFields) {
          alert(`Please add fields for the ${submitterWithoutFields.name}. Or, remove the ${submitterWithoutFields.name} if not needed.`)
        } else {
          this.isSaving = true

          this.save().then(() => {
            window.Turbo.visit(`/templates/${this.template.id}`)
          }).finally(() => {
            this.isSaving = false
          })
        }
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
        headers: {
          'X-CSRF-Token': this.authenticityToken,
          ...this.fetchOptions.headers,
          ...options.headers
        }
      })
    },
    save ({ force } = { force: false }) {
      this.pendingFieldAttachmentUuids = []

      if (this.onChange) {
        this.onChange(this.template)
      }

      if (!this.autosave && !force) {
        return Promise.resolve({})
      }

      this.$nextTick(() => {
        if (this.$el.closest('template-builder')) {
          this.$el.closest('template-builder').dataset.template = JSON.stringify(this.template)
        }
      })

      this.pushUndo()

      return this.baseFetch(`/templates/${this.template.id}`, {
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
      }).then(() => {
        if (this.onSave) {
          this.onSave(this.template)
        }
      })
    }
  }
}
</script>

<template>
  <FormulaModal
    v-if="modal?.name === 'formula' && field"
    :field="field"
    :editable="editable && !defaultField"
    :default-field="defaultField"
    :build-default-name="buildDefaultName"
    :inline="true"
    @save="onSave"
    @close="close"
  />
  <FontModal
    v-if="modal?.name === 'font' && field"
    :field="field"
    :editable="editable && !defaultField"
    :default-field="defaultField"
    :build-default-name="buildDefaultName"
    :inline="true"
    @save="onSave"
    @close="close"
  />
  <ConditionsModal
    v-if="modal?.name === 'conditions' && item"
    :item="item"
    :default-field="defaultField"
    :build-default-name="buildDefaultName"
    :inline="true"
    @save="onSave"
    @close="close"
  />
  <DescriptionModal
    v-if="modal?.name === 'description' && field"
    :field="field"
    :editable="editable && !defaultField"
    :default-field="defaultField"
    :build-default-name="buildDefaultName"
    :inline="true"
    @save="onSave"
    @close="close"
  />
  <div
    v-if="modal?.name === 'documents'"
    class="h-screen flex flex-col"
  >
    <DocumentsEditorModal
      :template="template"
      :authenticity-token="authenticityToken"
      :accept-file-types="acceptFileTypes"
      :base-url="baseUrl"
      :page-preview-format="pagePreviewFormat"
      :scroll-to-attachment-uuid="modal.uuid"
      :inline="true"
      @saved="onDocumentsSaved"
      @close="close"
    />
  </div>
  <RevisionsModal
    v-if="modal?.name === 'revisions' && revisions"
    :template="template"
    :revisions="revisions"
    :locale="locale"
    :inline="true"
    @close="close"
    @apply="applyRevision"
  />
  <div
    v-else-if="modal?.name === 'revisions'"
    class="flex justify-center py-8"
  >
    <IconInnerShadowTop class="w-6 h-6 animate-spin" />
  </div>
</template>

<script>
import FormulaModal from './formula_modal'
import FontModal from './font_modal'
import ConditionsModal from './conditions_modal'
import DescriptionModal from './description_modal'
import DocumentsEditorModal from './documents_editor_modal'
import RevisionsModal from './revisions_modal'
import Field from './field'
import FieldType from './field_type'
import { IconInnerShadowTop } from '@tabler/icons-vue'

export default {
  name: 'NativeModals',
  components: {
    FormulaModal,
    FontModal,
    ConditionsModal,
    DescriptionModal,
    DocumentsEditorModal,
    RevisionsModal,
    IconInnerShadowTop
  },
  inject: ['t', 'template', 'locale', 'baseFetch', 'getFieldTypeIndex', 'save', 'nativePlatform'],
  props: {
    defaultFields: {
      type: Array,
      required: false,
      default: () => []
    },
    customFields: {
      type: Array,
      required: false,
      default: () => []
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    },
    authenticityToken: {
      type: String,
      required: false,
      default: ''
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
    pagePreviewFormat: {
      type: String,
      required: false,
      default: '.jpg'
    }
  },
  emits: ['documents-modified'],
  data () {
    return {
      modal: null,
      revisions: null
    }
  },
  computed: {
    fieldNames: FieldType.computed.fieldNames,
    fieldLabels: FieldType.computed.fieldLabels,
    field () {
      if (this.modal?.custom_field_uuid) {
        return this.customFields.find((f) => f.uuid === this.modal.custom_field_uuid)
      }

      return this.template.fields.find((f) => f.uuid === this.modal?.uuid)
    },
    item () {
      if (this.modal?.attachment_uuid) {
        return this.template.schema.find((item) => item.attachment_uuid === this.modal.attachment_uuid)
      }

      return this.field
    },
    defaultField () {
      if (this.modal?.custom_field_uuid) return null

      return this.field && this.defaultFields.find((f) => f.name === this.field.name)
    },
    title () {
      if (!this.modal) return ''
      if (this.modal.name === 'documents') return this.t('edit_documents')
      if (this.modal.name === 'revisions') return this.t('revisions')

      const item = this.item
      const itemName = item ? ((this.defaultField ? (this.defaultField.title || item.title || item.name) : item.name) || this.buildDefaultName(item)) : ''

      if (this.modal.name === 'description') return itemName

      const prefix = { formula: this.t('formula'), font: this.t('font'), conditions: this.t('condition') }[this.modal.name]

      return itemName ? `${prefix} - ${itemName}` : prefix
    }
  },
  mounted () {
    document.title = ''
    document.addEventListener('template-builder:open-modal', this.onOpen)
    document.addEventListener('template-builder:close-modal', this.onClose)
  },
  unmounted () {
    document.removeEventListener('template-builder:open-modal', this.onOpen)
    document.removeEventListener('template-builder:close-modal', this.onClose)
  },
  methods: {
    buildDefaultName: Field.methods.buildDefaultName,
    onOpen (e) {
      this.modal = e.detail

      document.title = this.title
      document.body.style.overflow = e.detail.name === 'documents' ? 'hidden' : ''

      if (e.detail.name === 'revisions') {
        this.loadRevisions()
      }
    },
    onClose () {
      this.modal = null
      this.revisions = null

      document.body.style.overflow = ''
    },
    close () {
      if (this.nativePlatform) {
        window.webkit?.messageHandlers?.modal?.postMessage({ action: 'closeSheet' })
      }
    },
    onSave () {
      if (this.modal?.custom_field_uuid) {
        this.saveCustomFields()
      } else {
        this.save()
      }
    },
    saveCustomFields () {
      return this.baseFetch('/account_custom_fields', {
        method: 'POST',
        body: JSON.stringify({ value: this.customFields }),
        headers: { 'Content-Type': 'application/json' }
      }).then(async (resp) => {
        const fields = await resp.json()

        this.customFields.splice(0, this.customFields.length, ...fields)

        if (this.nativePlatform) {
          window.webkit?.messageHandlers?.modal?.postMessage({ action: 'dispatch', name: 'template-builder:sync-custom-fields', detail: JSON.stringify(fields), dismiss: 'false' })
        }
      })
    },
    loadRevisions () {
      this.revisions = null

      this.baseFetch(`/templates/${this.template.id}/versions`).then(async (resp) => {
        this.revisions = await resp.json()
      })
    },
    applyRevision (revision) {
      if (this.nativePlatform) {
        window.webkit?.messageHandlers?.modal?.postMessage({ action: 'dispatch', name: 'template-builder:apply-revision', detail: JSON.stringify(revision), dismiss: 'true' })
      }
    },
    onDocumentsSaved (data) {
      this.$emit('documents-modified', data)
      this.close()
    }
  }
}
</script>

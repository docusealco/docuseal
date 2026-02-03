<template>
  <div
    ref="dragContainer"
    style="max-width: 1600px"
    class="mx-auto pl-3 h-full bg-base-100"
    :class="isMobile ? 'pl-4' : 'md:pl-4'"
    @dragover="onDragover"
    @drop="isDragFile = false"
  >
    <HoverDropzone
      v-if="sortedDocuments.length && withUploadButton && editable"
      :is-dragging="isDragFile"
      :template-id="template.id"
      :accept-file-types="acceptFileTypes"
      :with-replace-and-clone="withReplaceAndCloneUpload"
      @add="[updateFromUpload($event), isDragFile = false]"
      @replace="[onDocumentsReplace($event), isDragFile = false]"
      @replace-and-clone="onDocumentsReplaceAndTemplateClone($event)"
      @error="[onUploadFailed($event), isDragFile = false]"
    />
    <DragPlaceholder
      ref="dragPlaceholder"
      :field="customDragFieldRef.value || fieldsDragFieldRef.value || toRaw(dragField)"
      :is-field="template.fields.includes(fieldsDragFieldRef.value)"
      :is-custom="!!customDragFieldRef.value"
      :is-default="defaultFields.includes(toRaw(dragField))"
      :is-required="defaultRequiredFields.includes(toRaw(dragField))"
    />
    <div
      v-if="pendingFieldAttachmentUuids.length && editable"
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
      class="flex justify-between py-1.5 items-center pr-4 top-0 z-10 bg-base-100 title-container"
      :class="{ sticky: withStickySubmitters || isBreakpointLg }"
      :style="{ backgroundColor: backgroundColor || '' }"
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
          class="text-xl md:text-3xl font-semibold focus:text-clip template-name"
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
          <form
            v-if="withSignYourselfButton && template.submitters.length < 2"
            target="_blank"
            data-turbo="false"
            class="inline"
            method="post"
            :action="`/d/${template.slug}`"
            @submit="maybeShowErrorTemplateAlert"
          >
            <input
              type="hidden"
              name="_method"
              value="put"
              autocomplete="off"
            >
            <input
              type="hidden"
              name="authenticity_token"
              :value="authenticityToken"
              autocomplete="off"
            >
            <input
              type="hidden"
              name="selfsign"
              value="true"
              autocomplete="off"
            >
            <button
              class="btn btn-primary btn-ghost text-base hidden md:flex"
              type="submit"
            >
              <IconWritingSign
                width="22"
                class="inline"
              />
              <span class="hidden md:inline">
                {{ t('sign_yourself') }}
              </span>
            </button>
          </form>
          <a
            v-else-if="withSignYourselfButton"
            id="sign_yourself_button"
            :href="`/templates/${template.id}/submissions/new?selfsign=true`"
            class="btn btn-primary btn-ghost text-base hidden md:flex"
            data-turbo-frame="modal"
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
            v-if="withSendButton"
            id="send_button"
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
            id="save_button_container"
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
            <div
              class="dropdown dropdown-end"
              :class="{ 'dropdown-open': isDownloading }"
            >
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
                    <span class="whitespace-nowrap">{{ t('save_and_preview') }}</span>
                  </a>
                </li>
                <li>
                  <a
                    :href="`/templates/${template.id}/preferences`"
                    data-turbo-frame="modal"
                    class="flex space-x-2"
                    @click="closeDropdown"
                  >
                    <IconAdjustments class="w-6 h-6 flex-shrink-0" />
                    <span class="whitespace-nowrap">{{ t('preferences') }}</span>
                  </a>
                </li>
                <li v-if="withDownload">
                  <button
                    class="flex space-x-2"
                    :disabled="isDownloading"
                    @click.stop.prevent="download"
                  >
                    <IconInnerShadowTop
                      v-if="isDownloading"
                      class="animate-spin w-6 h-6 flex-shrink-0"
                    />
                    <IconDownload
                      v-else
                      class="w-6 h-6 flex-shrink-0"
                    />
                    <span
                      v-if="isDownloading"
                      class="whitespace-nowrap"
                    >{{ t('downloading_') }}</span>
                    <span
                      v-else
                      class="whitespace-nowrap"
                    >{{ t('download') }}</span>
                  </button>
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
      class="flex main-container"
      :class="$slots.buttons || withTitle ? (isMobile ? 'max-h-[calc(100%_-_60px)]' : 'md:max-h-[calc(100%_-_60px)]') : (isMobile ? 'max-h-[100%]' : 'md:max-h-[100%]')"
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
          :data-document-uuid="item.attachment_uuid"
          :accept-file-types="acceptFileTypes"
          :with-replace-button="withUploadButton"
          :editable="editable"
          :template="template"
          @scroll-to="scrollIntoDocument(item)"
          @remove="onDocumentRemove"
          @replace="onDocumentReplace"
          @up="moveDocument(item, -1)"
          @reorder="reorderFields"
          @down="moveDocument(item, 1)"
          @change="save"
        />
        <div
          class="sticky bottom-0 py-2 space-y-2 bg-base-100"
          :style="{ backgroundColor: backgroundColor || '' }"
        >
          <Upload
            v-if="editable && withUploadButton"
            v-show="sortedDocuments.length"
            ref="upload"
            :accept-file-types="acceptFileTypes"
            :authenticity-token="authenticityToken"
            :with-google-drive="withGoogleDrive"
            :template-id="template.id"
            @success="updateFromUpload"
          />
          <button
            v-if="sortedDocuments.length && editable && withAddPageButton"
            id="add_blank_page_button"
            class="btn btn-outline w-full add-blank-page-button"
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
        class="w-full overflow-x-hidden mt-0.5 pt-0.5"
        :class="isMobile ? 'overflow-y-auto' : 'overflow-y-hidden md:overflow-y-auto'"
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
              :with-google-drive="withGoogleDrive"
              @click-google-drive="$refs.upload.openGoogleDriveModal()"
              @success="updateFromUpload"
            />
            <button
              v-if="withAddPageButton"
              id="add_blank_page_button"
              class="btn btn-outline w-full mt-4 add-blank-page-button"
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
                :allow-draw="!onlyDefinedFields || drawField || drawCustomField"
                :with-signature-id="withSignatureId"
                :with-prefillable="withPrefillable"
                :data-document-uuid="document.uuid"
                :default-submitters="defaultSubmitters"
                :drag-field-placeholder="fieldsDragFieldRef.value || dragField"
                :with-field-placeholder="withFieldPlaceholder"
                :draw-field="drawField"
                :draw-field-type="drawFieldType"
                :draw-custom-field="drawCustomField"
                :editable="editable"
                :is-mobile="isMobile"
                :base-url="baseUrl"
                :with-fields-detection="withFieldsDetection"
                @draw="[onDraw($event), withSelectedFieldType ? '' : drawFieldType = '', drawCustomField = null, showDrawField = false]"
                @drop-field="onDropfield"
                @remove-area="removeArea"
                @paste-field="pasteField"
                @copy-field="copyField"
                @add-custom-field="addCustomField"
                @set-draw="[drawField = $event.field, drawOption = $event.option]"
                @copy-selected-areas="copySelectedAreas"
                @delete-selected-areas="deleteSelectedAreas"
                @autodetect-fields="detectFieldsForPage"
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
                :authenticity-token="authenticityToken"
                :with-google-drive="withGoogleDrive"
                @success="updateFromUpload"
              />
              <button
                v-if="withAddPageButton"
                id="add_blank_page_button"
                class="btn btn-outline w-full mt-4 add-blank-page-button"
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
        v-if="withFieldsList && !isMobile"
        id="fields_list_container"
        class="relative w-80 flex-none mt-1 pr-4 pl-0.5 hidden md:block fields-list-container"
        :class="drawField || drawCustomField ? 'overflow-hidden' : 'overflow-y-auto overflow-x-hidden'"
      >
        <div
          v-if="showDrawField || drawField || drawCustomField"
          class="sticky inset-0 h-full z-20 bg-base-100"
          :style="{ backgroundColor: backgroundColor || '' }"
        >
          <div class="bg-base-200 rounded-lg p-5 text-center space-y-4 draw-field-container">
            <p v-if="(drawField?.type || drawFieldType || drawCustomField?.type) === 'strikethrough'">
              {{ t('draw_strikethrough_the_document') }}
            </p>
            <p v-else>
              {{ t('draw_field_on_the_document') }}
            </p>
            <div>
              <button
                class="base-button cancel-draw-button"
                @click="clearDrawField"
              >
                {{ t('cancel') }}
              </button>
              <a
                v-if="!drawField && !drawOption && !['stamp', 'signature', 'initials', 'heading', 'strikethrough'].includes(drawField?.type || drawFieldType || drawCustomField?.type)"
                href="#"
                class="link block mt-3 text-sm"
                @click.prevent="drawCustomField ? addCustomFieldWithoutDraw() : [addField(drawFieldType), drawField = null, drawOption = null, withSelectedFieldType ? '' : drawFieldType = '', showDrawField = false]"
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
            :custom-fields="customFields"
            :with-custom-fields="withCustomFields"
            :with-fields-search="withFieldsSearch"
            :default-fields="[...defaultRequiredFields, ...defaultFields]"
            :template="template"
            :default-required-fields="defaultRequiredFields"
            :field-types="fieldTypes"
            :with-sticky-submitters="withStickySubmitters"
            :with-fields-detection="withFieldsDetection"
            :with-signature-id="withSignatureId"
            :with-prefillable="withPrefillable"
            :only-defined-fields="onlyDefinedFields"
            :editable="editable"
            :show-tour-start-form="showTourStartForm"
            @add-field="addField"
            @set-draw="[drawField = $event.field, drawOption = $event.option]"
            @select-submitter="selectedSubmitter = $event"
            @set-draw-type="[drawFieldType = $event, showDrawField = true]"
            @set-draw-custom-field="[drawCustomField = $event, showDrawField = true]"
            @set-drag="dragField = $event"
            @set-drag-placeholder="$refs.dragPlaceholder.dragPlaceholder = $event"
            @change-submitter="selectedSubmitter = $event"
            @drag-end="[dragField = null, $refs.dragPlaceholder.dragPlaceholder = null]"
            @scroll-to-area="scrollToArea"
          />
        </div>
      </div>
    </div>
    <div class="sticky bottom-0 z-10">
      <MobileDrawField
        v-if="drawField && (isBreakpointLg || isMobile)"
        :draw-field="drawField"
        :fields="template.fields"
        :submitters="template.submitters"
        :selected-submitter="selectedSubmitter"
        :class="{ 'md:hidden': !isMobile }"
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
        :class="{ 'md:hidden': !isMobile }"
        :selected-submitter="selectedSubmitter"
        @select="startFieldDraw($event)"
      />
    </div>
    <Transition
      enter-active-class="transition-all duration-300 ease-out"
      enter-from-class="translate-y-4 opacity-0"
      enter-to-class="translate-y-0 opacity-100"
      leave-active-class="transition-all duration-300 ease-in"
      leave-from-class="translate-y-0 opacity-100"
      leave-to-class="translate-y-4 opacity-0"
    >
      <div
        v-if="isDetectingPageFields || detectingFieldsAddedCount !== null"
        class="sticky bottom-0 z-50"
      >
        <div class="absolute left-0 right-0 h-0 overflow-visible bottom-16 z-50 flex justify-center">
          <div
            class="rounded-full bg-base-content h-12 flex items-center justify-center space-x-1.5 uppercase font-semibold text-white text-sm cursor-default"
            style="min-width: 180px"
          >
            <template v-if="detectingFieldsAddedCount !== null">
              <span>{{ (detectingFieldsAddedCount === 1 ? t('field_added') : t('fields_added')).replace('{count}', detectingFieldsAddedCount) }}</span>
            </template>
            <template v-else>
              <IconInnerShadowTop
                v-if="!detectingAnalyzingProgress"
                width="20"
                class="animate-spin"
              />
              <span v-if="detectingAnalyzingProgress">
                {{ Math.round(detectingAnalyzingProgress * 100) }}% {{ t('analyzing_') }}
              </span>
              <span v-else>
                {{ t('processing_') }}
              </span>
            </template>
          </div>
        </div>
      </div>
    </Transition>
    <div
      id="docuseal_modal_container"
      class="modal-container"
    />
  </div>
</template>

<script>
import Upload from './upload'
import Dropzone from './dropzone'
import HoverDropzone from './hover_dropzone'
import DragPlaceholder from './drag_placeholder'
import Fields from './fields'
import MobileDrawField from './mobile_draw_field'
import Document from './document'
import Logo from './logo'
import Contenteditable from './contenteditable'
import DocumentPreview from './preview'
import DocumentControls from './controls'
import MobileFields from './mobile_fields'
import FieldSubmitter from './field_submitter'
import { IconPlus, IconUsersPlus, IconDeviceFloppy, IconChevronDown, IconEye, IconWritingSign, IconInnerShadowTop, IconInfoCircle, IconAdjustments, IconDownload } from '@tabler/icons-vue'
import { v4 } from 'uuid'
import { ref, computed, toRaw } from 'vue'
import * as i18n from './i18n'

export default {
  name: 'TemplateBuilder',
  components: {
    Upload,
    DragPlaceholder,
    Document,
    Fields,
    IconInfoCircle,
    MobileDrawField,
    IconPlus,
    IconWritingSign,
    MobileFields,
    Logo,
    Dropzone,
    HoverDropzone,
    DocumentPreview,
    DocumentControls,
    IconInnerShadowTop,
    Contenteditable,
    IconUsersPlus,
    IconChevronDown,
    IconDownload,
    IconAdjustments,
    IconEye,
    IconDeviceFloppy
  },
  provide () {
    return {
      template: this.template,
      save: this.save,
      t: this.t,
      assignDropAreaSize: this.assignDropAreaSize,
      currencies: this.currencies,
      locale: this.locale,
      baseFetch: this.baseFetch,
      fieldTypes: this.fieldTypes,
      backgroundColor: this.backgroundColor,
      withPhone: this.withPhone,
      withVerification: this.withVerification,
      withKba: this.withKba,
      withPayment: this.withPayment,
      isPaymentConnected: this.isPaymentConnected,
      withFormula: this.withFormula,
      withConditions: this.withConditions,
      withCustomFields: this.withCustomFields,
      isInlineSize: this.isInlineSize,
      defaultDrawFieldType: this.defaultDrawFieldType,
      selectedAreasRef: computed(() => this.selectedAreasRef),
      fieldsDragFieldRef: computed(() => this.fieldsDragFieldRef),
      customDragFieldRef: computed(() => this.customDragFieldRef),
      isSelectModeRef: computed(() => this.isSelectModeRef),
      isCmdKeyRef: computed(() => this.isCmdKeyRef),
      getFieldTypeIndex: this.getFieldTypeIndex
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
    withSignatureId: {
      type: Boolean,
      required: false,
      default: null
    },
    withDownload: {
      type: Boolean,
      required: false,
      default: false
    },
    backgroundColor: {
      type: String,
      required: false,
      default: ''
    },
    locale: {
      type: String,
      required: false,
      default: ''
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    },
    withSendButton: {
      type: Boolean,
      required: false,
      default: true
    },
    withSignYourselfButton: {
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
    withFieldsDetection: {
      type: Boolean,
      required: false,
      default: false
    },
    withCustomFields: {
      type: Boolean,
      required: false,
      default: false
    },
    customFields: {
      type: Array,
      required: false,
      default: () => []
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
    defineSubmitters: {
      type: Array,
      required: false,
      default: () => []
    },
    acceptFileTypes: {
      type: String,
      required: false,
      default: 'image/*, application/pdf, application/zip'
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
    withFieldsSearch: {
      type: Boolean,
      required: false,
      default: null
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
    withReplaceAndCloneUpload: {
      type: Boolean,
      required: false,
      default: false
    },
    withPhone: {
      type: Boolean,
      required: false,
      default: false
    },
    withVerification: {
      type: Boolean,
      required: false,
      default: null
    },
    withKba: {
      type: Boolean,
      required: false,
      default: null
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
    withGoogleDrive: {
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
    },
    showTourStartForm: {
      type: Boolean,
      required: false,
      default: false
    }
  },
  data () {
    return {
      documentRefs: [],
      isBreakpointLg: false,
      isDownloading: false,
      isLoadingBlankPage: false,
      isSaving: false,
      isDetectingPageFields: false,
      detectingAnalyzingProgress: null,
      detectingFieldsAddedCount: null,
      selectedSubmitter: null,
      showDrawField: false,
      pendingFieldAttachmentUuids: [],
      drawField: null,
      drawFieldType: null,
      drawCustomField: null,
      drawOption: null,
      dragField: null,
      isDragFile: false
    }
  },
  computed: {
    submitterDefaultNames: FieldSubmitter.computed.names,
    isSelectModeRef: () => ref(false),
    isCmdKeyRef: () => ref(false),
    fieldsDragFieldRef: () => ref(),
    customDragFieldRef: () => ref(),
    selectedAreasRef: () => ref([]),
    language () {
      return this.locale.split('-')[0].toLowerCase()
    },
    withPrefillable () {
      if (this.template.fields) {
        return this.template.fields.some((f) => f.prefillable)
      } else {
        return false
      }
    },
    isInlineSize () {
      return CSS.supports('container-type: size')
    },
    lowestSelectedArea () {
      return this.selectedAreasRef.value.reduce((acc, area) => {
        return area.y + area.h < acc.y + acc.h ? acc : area
      }, this.selectedAreasRef.value[0])
    },
    lastSelectedArea () {
      return this.selectedAreasRef.value[this.selectedAreasRef.value.length - 1]
    },
    isMobile () {
      const isMobileSafariIos = 'ontouchstart' in window && navigator.maxTouchPoints > 0 && /AppleWebKit/i.test(navigator.userAgent)

      return isMobileSafariIos || /android|iphone|ipad/i.test(navigator.userAgent)
    },
    defaultDateFormat () {
      const isUsBrowser = Intl.DateTimeFormat().resolvedOptions().locale.endsWith('-US')
      const isUsTimezone = new Intl.DateTimeFormat('en-US', { timeZoneName: 'short' }).format(new Date()).match(/\s(?:CST|CDT|PST|PDT|EST|EDT)$/)

      return this.localeDateFormats[this.locale] || ((isUsBrowser || isUsTimezone) ? 'MM/DD/YYYY' : 'DD/MM/YYYY')
    },
    localeDateFormats () {
      return {
        'de-DE': 'DD.MM.YYYY',
        'fr-FR': 'DD/MM/YYYY',
        'it-IT': 'DD/MM/YYYY',
        'en-GB': 'DD/MM/YYYY',
        'es-ES': 'DD/MM/YYYY'
      }
    },
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
    fieldTypeIndexMap () {
      const map = {}
      const typeCounters = {}

      this.template.fields.forEach((f) => {
        typeCounters[f.type] ||= 0
        map[f.uuid] = typeCounters[f.type]
        typeCounters[f.type]++
      })

      return map
    },
    isAllRequiredFieldsAdded () {
      return !this.defaultRequiredFields?.some((f) => {
        return !this.template.fields?.some((field) => field.name === f.name)
      })
    },
    selectedField () {
      return this.template.fields.find((f) => f.areas?.includes(this.lastSelectedArea))
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

    const defineSubmittersUuids = this.defineSubmitters.map((name) => {
      return this.template.submitters.find(e => e.name === name)?.uuid
    })

    this.defineSubmitters.forEach((name, index) => {
      const submitter = (this.template.submitters[index] ||= {})

      submitter.name = name || this.submitterDefaultNames[index]

      if (defineSubmittersUuids.filter(Boolean).length || existingSubmittersUuids.filter(Boolean).length) {
        submitter.uuid = defineSubmittersUuids[index] || existingSubmittersUuids[index] || submitter.uuid || v4()
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
    window.addEventListener('dragleave', this.onWindowDragLeave)

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
    window.removeEventListener('dragleave', this.onWindowDragLeave)
  },
  beforeUpdate () {
    this.documentRefs = []
  },
  methods: {
    toRaw,
    addCustomField (field) {
      return this.$refs.fields.addCustomField(field)
    },
    getFieldTypeIndex (field) {
      return this.fieldTypeIndexMap[field.uuid]
    },
    addCustomFieldWithoutDraw () {
      const customField = this.drawCustomField

      const field = JSON.parse(JSON.stringify(customField))

      field.uuid = v4()
      field.submitter_uuid = this.selectedSubmitter.uuid
      field.areas = []

      if (field.options?.length) {
        field.options = field.options.map(opt => ({ ...opt, uuid: v4() }))
      }

      delete field.conditions

      this.insertField(field)
      this.save()

      this.drawCustomField = null
      this.showDrawField = false
    },
    toggleSelectMode () {
      this.isSelectModeRef.value = !this.isSelectModeRef.value

      if (!this.isSelectModeRef.value && this.selectedAreasRef.value.length > 1) {
        this.selectedAreasRef.value = []
      }
    },
    deleteSelectedAreas () {
      [...this.selectedAreasRef.value].forEach((area) => {
        this.removeArea(area, false)
      })

      this.save()
    },
    moveSelectedAreas (dx, dy) {
      let clampedDx = dx
      let clampedDy = dy

      const rectIndex = {}

      this.selectedAreasRef.value.map((area) => {
        const key = `${area.attachment_uuid}-${area.page}`

        let rect = rectIndex[key]

        if (!rect) {
          const documentRef = this.documentRefs.find((e) => e.document.uuid === area.attachment_uuid)
          const page = documentRef.pageRefs[area.page].$refs.image
          rect = page.getBoundingClientRect()

          rectIndex[key] = rect
        }

        const normalizedDx = dx / rect.width
        const normalizedDy = dy / rect.height

        const maxDxLeft = -area.x
        const maxDxRight = 1 - area.w - area.x
        const maxDyTop = -area.y
        const maxDyBottom = 1 - area.h - area.y

        if (normalizedDx < maxDxLeft) clampedDx = Math.max(clampedDx, maxDxLeft * rect.width)
        if (normalizedDx > maxDxRight) clampedDx = Math.min(clampedDx, maxDxRight * rect.width)
        if (normalizedDy < maxDyTop) clampedDy = Math.max(clampedDy, maxDyTop * rect.height)
        if (normalizedDy > maxDyBottom) clampedDy = Math.min(clampedDy, maxDyBottom * rect.height)

        return [area, rect]
      }).forEach(([area, rect]) => {
        area.x += clampedDx / rect.width
        area.y += clampedDy / rect.height
      })

      this.debouncedSave()
    },
    download () {
      this.isDownloading = true

      this.baseFetch(`/templates/${this.template.id}/documents`).then(async (response) => {
        if (response.ok) {
          const urls = await response.json()
          const isMobileSafariIos = 'ontouchstart' in window && navigator.maxTouchPoints > 0 && /AppleWebKit/i.test(navigator.userAgent)
          const isSafariIos = isMobileSafariIos || /iPhone|iPad|iPod/i.test(navigator.userAgent)

          if (isSafariIos && urls.length > 1) {
            this.downloadSafariIos(urls)
          } else {
            this.downloadUrls(urls)
          }
        } else {
          alert(this.t('failed_to_download_files'))
        }
      })
    },
    downloadUrls (urls) {
      const fileRequests = urls.map((url) => {
        return () => {
          return fetch(url).then(async (resp) => {
            const blobUrl = URL.createObjectURL(await resp.blob())
            const link = document.createElement('a')

            link.href = blobUrl
            link.setAttribute('download', decodeURI(url.split('/').pop()))

            link.click()

            URL.revokeObjectURL(blobUrl)
          })
        }
      })

      fileRequests.reduce(
        (prevPromise, request) => prevPromise.then(() => request()),
        Promise.resolve()
      ).finally(() => {
        this.isDownloading = false
      })
    },
    downloadSafariIos (urls) {
      const fileRequests = urls.map((url) => {
        return fetch(url).then(async (resp) => {
          const blob = await resp.blob()
          const blobUrl = URL.createObjectURL(blob.slice(0, blob.size, 'application/octet-stream'))
          const link = document.createElement('a')

          link.href = blobUrl
          link.setAttribute('download', decodeURI(url.split('/').pop()))

          return link
        })
      })

      Promise.all(fileRequests).then((links) => {
        links.forEach((link, index) => {
          setTimeout(() => {
            link.click()

            URL.revokeObjectURL(link.href)
          }, index * 50)
        })
      }).finally(() => {
        this.isDownloading = false
      })
    },
    onDragover (e) {
      if (this.$refs.dragPlaceholder?.dragPlaceholder) {
        this.$refs.dragPlaceholder.isMask = e.target.id === 'mask'

        const ref = this.$refs.dragPlaceholder.dragPlaceholder

        ref.x = e.clientX - ref.offsetX
        ref.y = e.clientY - ref.offsetY
      } else if (e.dataTransfer?.types?.includes('Files')) {
        this.isDragFile = true
      }
    },
    onWindowDragLeave (event) {
      if (event.clientX <= 0 || event.clientY <= 0 || event.clientX >= window.innerWidth || event.clientY >= window.innerHeight) {
        this.isDragFile = false
      }
    },
    reorderFields (item) {
      const itemFields = []
      const fields = []
      const fieldAreasIndex = {}

      const attachmentUuids = this.template.schema.map((e) => e.attachment_uuid)

      this.template.fields.forEach((f) => {
        if (f.areas?.length) {
          const firstArea = f.areas.reduce((min, a) => {
            return attachmentUuids.indexOf(a.attachment_uuid) < attachmentUuids.indexOf(min.attachment_uuid) ? a : min
          }, f.areas[0])

          if (firstArea.attachment_uuid === item.attachment_uuid) {
            itemFields.push(f)
          } else {
            fields.push(f)
          }
        } else {
          fields.push(f)
        }
      })

      const sortArea = (aArea, bArea) => {
        if (aArea.attachment_uuid === bArea.attachment_uuid) {
          if (aArea.page === bArea.page) {
            const aY = aArea.y + aArea.h
            const bY = bArea.y + bArea.h

            if (Math.abs(aY - bY) < 0.01 || (aArea.h < bArea.h ? (aArea.y >= bArea.y && aY <= bY) : (bArea.y >= aArea.y && bY <= aY))) {
              if (aArea.x === bArea.x) {
                return 0
              } else {
                return aArea.x - bArea.x
              }
            } else {
              return (aArea.y + aArea.h) - (bArea.y + bArea.h)
            }
          } else {
            return aArea.page - bArea.page
          }
        } else {
          return attachmentUuids.indexOf(aArea.attachment_uuid) - attachmentUuids.indexOf(bArea.attachment_uuid)
        }
      }

      itemFields.sort((aField, bField) => {
        const aArea = (fieldAreasIndex[aField.uuid] ||= [...(aField.areas || [])].sort(sortArea)[0])
        const bArea = (fieldAreasIndex[bField.uuid] ||= [...(bField.areas || [])].sort(sortArea)[0])

        return sortArea(aArea, bArea)
      })

      const insertBeforeAttachmentUuids = attachmentUuids.slice(this.template.schema.indexOf(item) + 1)

      let sortedFields = []

      if (insertBeforeAttachmentUuids.length) {
        const insertAfterField = fields.find((f) => {
          if (f.areas?.length) {
            return f.areas.find((a) => insertBeforeAttachmentUuids.includes(a.attachment_uuid))
          } else {
            return false
          }
        })

        if (insertAfterField) {
          fields.splice(fields.indexOf(insertAfterField), 0, ...itemFields)

          sortedFields = fields
        } else {
          sortedFields = fields.concat(itemFields)
        }
      } else {
        if (fields.length && itemFields.length && this.template.fields.indexOf(fields[0]) > this.template.fields.indexOf(itemFields[0])) {
          sortedFields = itemFields.concat(fields)
        } else {
          sortedFields = fields.concat(itemFields)
        }
      }

      if (this.template.fields.length === sortedFields.length) {
        this.template.fields = sortedFields
        this.save()
      }
    },
    findFieldInsertIndex (field) {
      if (!field.areas?.length) return -1

      const area = field.areas[0]

      const attachmentUuidsIndex = this.template.schema.reduce((acc, e, index) => {
        acc[e.attachment_uuid] = index

        return acc
      }, {})

      const compareAreas = (a, b) => {
        const aAttIdx = attachmentUuidsIndex[a.attachment_uuid]
        const bAttIdx = attachmentUuidsIndex[b.attachment_uuid]

        if (aAttIdx !== bAttIdx) return aAttIdx - bAttIdx
        if (a.page !== b.page) return a.page - b.page

        const aY = a.y + a.h
        const bY = b.y + b.h

        if (Math.abs(aY - bY) < 0.01) return a.x - b.x
        if (a.h < b.h ? a.y >= b.y && aY <= bY : b.y >= a.y && bY <= aY) return a.x - b.x

        return aY - bY
      }

      let closestBeforeIndex = -1
      let closestBeforeArea = null
      let closestAfterIndex = -1
      let closestAfterArea = null

      this.template.fields.forEach((f, index) => {
        if (f.submitter_uuid === field.submitter_uuid) {
          (f.areas || []).forEach((a) => {
            const cmp = compareAreas(a, area)

            if (cmp < 0) {
              if (!closestBeforeArea || (compareAreas(a, closestBeforeArea) > 0 && closestBeforeIndex < index)) {
                closestBeforeIndex = index
                closestBeforeArea = a
              }
            } else {
              if (!closestAfterArea || (compareAreas(a, closestAfterArea) < 0 && closestAfterIndex > index)) {
                closestAfterIndex = index
                closestAfterArea = a
              }
            }
          })
        }
      })

      if (closestBeforeIndex !== -1) return closestBeforeIndex + 1
      if (closestAfterIndex !== -1) return closestAfterIndex

      return -1
    },
    insertField (field) {
      const insertIndex = this.findFieldInsertIndex(field)

      if (insertIndex !== -1) {
        this.template.fields.splice(insertIndex, 0, field)
      } else {
        this.template.fields.push(field)
      }
    },
    closeDropdown () {
      document.activeElement.blur()
    },
    t (key) {
      return this.i18n[key] || i18n[this.language]?.[key] || i18n.en[key] || key
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
        field.options = [{ value: '', uuid: v4() }, { value: '', uuid: v4() }]
      }

      if (type === 'stamp') {
        field.readonly = true
      }

      if (type === 'datenow') {
        field.type = 'date'
        field.readonly = true
        field.default_value = '{{date}}'
      }

      if (type === 'date') {
        field.preferences = {
          format: this.defaultDateFormat
        }
      }

      if (field.type === 'strikethrough') {
        field.readonly = true
        field.default_value = true
      }

      if (type === 'signature' && [true, false].includes(this.withSignatureId)) {
        field.preferences ||= {}
        field.preferences.with_signature_id = this.withSignatureId
      }

      this.insertField(field)

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
          field.options = [{ value: '', uuid: v4() }, { value: '', uuid: v4() }]
        }

        if (type === 'stamp') {
          field.readonly = true
        }

        if (type === 'date') {
          field.preferences = {
            format: this.defaultDateFormat
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
      this.drawCustomField = null
      this.showDrawField = false

      if (!this.withSelectedFieldType) {
        this.drawFieldType = ''
      }
    },
    onKeyUp (e) {
      this.isCmdKeyRef.value = false

      if (e.code === 'Escape') {
        this.selectedAreasRef.value = []
        this.clearDrawField()
      }

      if (this.editable && ['Backspace', 'Delete'].includes(e.key) && document.activeElement === document.body) {
        if (this.selectedAreasRef.value.length > 1) {
          this.deleteSelectedAreas()
        } else if (this.selectedAreasRef.value.length) {
          this.removeArea(this.lastSelectedArea)
        }
      }
    },
    onKeyDown (event) {
      if (event.key === 'Tab' && document.activeElement === document.body) {
        event.stopImmediatePropagation()
        event.preventDefault()

        this.toggleSelectMode()
      } else if ((event.metaKey && event.shiftKey && event.key === 'z') || (event.ctrlKey && event.key === 'Z')) {
        event.stopImmediatePropagation()
        event.preventDefault()

        this.selectedAreasRef.value = []

        this.redo()
      } else if ((event.ctrlKey || event.metaKey) && event.key === 'z') {
        event.stopImmediatePropagation()
        event.preventDefault()

        this.selectedAreasRef.value = []

        this.undo()
      } else if ((event.ctrlKey || event.metaKey) && event.key === 'c' && document.activeElement === document.body) {
        if (this.selectedAreasRef.value.length > 1) {
          event.preventDefault()
          this.copySelectedAreas()
        } else if (this.selectedAreasRef.value.length) {
          event.preventDefault()
          this.copyField()
        }
      } else if ((event.ctrlKey || event.metaKey) && event.key === 'v' && this.hasClipboardData() && document.activeElement === document.body) {
        event.preventDefault()

        this.pasteField()
      } else if (['ArrowLeft', 'ArrowUp', 'ArrowRight', 'ArrowDown'].includes(event.key) && document.activeElement === document.body) {
        if (this.selectedAreasRef.value.length > 1) {
          event.preventDefault()
          this.handleSelectedAreasArrows(event)
        } else if (this.selectedAreasRef.value.length) {
          event.preventDefault()
          this.handleAreaArrows(event)
        }
      } else if (event.metaKey || event.ctrlKey) {
        this.isCmdKeyRef.value = true
      }
    },
    handleSelectedAreasArrows (event) {
      if (!this.editable) {
        return
      }

      const diff = (event.shiftKey ? 5.0 : 1.0)
      let dx = 0
      let dy = 0

      if (event.key === 'ArrowRight') {
        dx = diff
      } else if (event.key === 'ArrowLeft') {
        dx = -diff
      } else if (event.key === 'ArrowUp') {
        dy = -diff
      } else if (event.key === 'ArrowDown') {
        dy = diff
      }

      this.moveSelectedAreas(dx, dy)
    },
    handleAreaArrows (event) {
      if (!this.editable) {
        return
      }

      const area = this.lastSelectedArea
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
    removeArea (area, save = true) {
      const field = this.template.fields.find((f) => f.areas?.includes(area))

      field.areas.splice(field.areas.indexOf(area), 1)

      if (!field.areas.length) {
        this.template.fields.splice(this.template.fields.indexOf(field), 1)

        this.removeFieldConditions(field)
      }

      this.selectedAreasRef.value.splice(this.selectedAreasRef.value.indexOf(area), 1)

      if (save) {
        this.save()
      }
    },
    removeFieldConditions (field) {
      this.template.fields.forEach((f) => {
        if (f.conditions) {
          f.conditions.forEach((c) => {
            if (c.field_uuid === field.uuid) {
              f.conditions.splice(f.conditions.indexOf(c), 1)
            }
          })
        }
      })

      this.template.schema.forEach((item) => {
        if (item.conditions) {
          item.conditions.forEach((c) => {
            if (c.field_uuid === field.uuid) {
              item.conditions.splice(item.conditions.indexOf(c), 1)
            }
          })
        }
      })
    },
    copyField () {
      const area = this.lastSelectedArea

      if (!area) return

      const field = this.template.fields.find((f) => f.areas?.includes(area))

      if (!field) return

      const clipboardData = {
        field: JSON.parse(JSON.stringify(field)),
        area: JSON.parse(JSON.stringify(area)),
        templateId: this.template.id,
        timestamp: Date.now()
      }

      delete clipboardData.field.areas
      delete clipboardData.field.uuid
      delete clipboardData.field.submitter_uuid

      try {
        localStorage.setItem('docuseal_clipboard', JSON.stringify(clipboardData))
      } catch (e) {
        console.error('Failed to save clipboard:', e)
      }
    },
    copySelectedAreas () {
      const items = []

      const areas = this.selectedAreasRef.value

      const minX = Math.min(...areas.map(a => a.x))
      const minY = Math.min(...areas.map(a => a.y))

      areas.forEach((area) => {
        const field = this.template.fields.find((f) => f.areas?.includes(area))

        if (!field) return

        const fieldCopy = JSON.parse(JSON.stringify(field))
        const areaCopy = JSON.parse(JSON.stringify(area))

        delete fieldCopy.areas
        delete fieldCopy.submitter_uuid

        areaCopy.relativeX = area.x - minX
        areaCopy.relativeY = area.y - minY

        items.push({ field: fieldCopy, area: areaCopy })
      })

      const clipboardData = {
        items,
        templateId: this.template.id,
        timestamp: Date.now(),
        isGroup: true
      }

      try {
        localStorage.setItem('docuseal_clipboard', JSON.stringify(clipboardData))
      } catch (e) {
        console.error('Failed to save clipboard:', e)
      }
    },
    pasteField (targetPosition = null) {
      const clipboard = localStorage.getItem('docuseal_clipboard')

      if (!clipboard) return

      const data = JSON.parse(clipboard)

      if (Date.now() - data.timestamp >= 3600000) {
        localStorage.removeItem('docuseal_clipboard')

        return
      }

      if (data.isGroup && data.items?.length) {
        this.pasteFieldGroup(data, targetPosition)

        return
      }

      const field = data.field
      const area = data.area
      const isSameTemplate = data.templateId === this.template.id

      if (!field || !area) return

      if (!isSameTemplate) {
        delete field.conditions
        delete field.preferences?.formula
      }

      const defaultAttachmentUuid = this.template.schema[0]?.attachment_uuid

      if (field && (this.lowestSelectedArea || targetPosition)) {
        const attachmentUuid = targetPosition?.attachment_uuid ||
          (this.template.documents.find((d) => d.uuid === this.lowestSelectedArea.attachment_uuid) ? this.lowestSelectedArea.attachment_uuid : null) ||
          defaultAttachmentUuid

        const newArea = {
          ...JSON.parse(JSON.stringify(area)),
          attachment_uuid: attachmentUuid,
          page: targetPosition?.page ?? (attachmentUuid === this.lowestSelectedArea.attachment_uuid ? this.lowestSelectedArea.page : 0),
          x: targetPosition ? (targetPosition.x - area.w / 2) : Math.min(...this.selectedAreasRef.value.map((area) => area.x)),
          y: targetPosition ? (targetPosition.y - area.h / 2) : (this.lowestSelectedArea.y + this.lowestSelectedArea.h * 1.3)
        }

        const newField = {
          ...JSON.parse(JSON.stringify(field)),
          uuid: v4(),
          submitter_uuid: this.selectedSubmitter.uuid,
          areas: [newArea]
        }

        if (['radio', 'multiple'].includes(field.type) && field.options?.length) {
          const oldOptionUuid = area.option_uuid
          const optionsMap = {}

          newField.options = field.options.map((opt) => {
            const newUuid = v4()
            optionsMap[opt.uuid] = newUuid
            return { ...opt, uuid: newUuid }
          })

          newArea.option_uuid = optionsMap[oldOptionUuid] || newField.options[0].uuid
        }

        this.insertField(newField)

        this.selectedAreasRef.value = [newArea]

        this.save()
      }
    },
    pasteFieldGroup (data, targetPosition) {
      const isSameTemplate = data.templateId === this.template.id
      const defaultAttachmentUuid = this.template.schema[0]?.attachment_uuid

      const attachmentUuid = targetPosition?.attachment_uuid ||
        (this.lowestSelectedArea && this.template.documents.find((d) => d.uuid === this.lowestSelectedArea.attachment_uuid) ? this.lowestSelectedArea.attachment_uuid : null) ||
        defaultAttachmentUuid

      const page = targetPosition?.page ?? (this.lowestSelectedArea && attachmentUuid === this.lowestSelectedArea.attachment_uuid ? this.lowestSelectedArea.page : 0)

      let baseX, baseY

      if (targetPosition) {
        baseX = targetPosition.x
        baseY = targetPosition.y
      } else if (this.lowestSelectedArea) {
        baseX = Math.min(...this.selectedAreasRef.value.map((area) => area.x))
        baseY = this.lowestSelectedArea.y + this.lowestSelectedArea.h * 1.3
      } else {
        baseX = 0.1
        baseY = 0.1
      }

      const newAreas = []

      const fieldUuidIndex = {}
      const fieldOptionsMap = {}

      data.items.forEach((item) => {
        const field = JSON.parse(JSON.stringify(item.field))
        const area = JSON.parse(JSON.stringify(item.area))

        if (!isSameTemplate) {
          delete field.conditions
          delete field.preferences?.formula
        }

        const newArea = {
          ...area,
          attachment_uuid: attachmentUuid,
          page,
          x: baseX + (area.relativeX || 0),
          y: baseY + (area.relativeY || 0)
        }

        delete newArea.relativeX
        delete newArea.relativeY

        const newField = fieldUuidIndex[field.uuid] || {
          ...field,
          uuid: v4(),
          submitter_uuid: this.selectedSubmitter.uuid,
          areas: []
        }

        fieldUuidIndex[field.uuid] = newField

        newField.areas.push(newArea)
        newAreas.push(newArea)

        if (['radio', 'multiple'].includes(field.type) && field.options?.length) {
          const oldOptionUuid = area.option_uuid

          if (!fieldOptionsMap[field.uuid]) {
            fieldOptionsMap[field.uuid] = {}

            newField.options = field.options.map((opt) => {
              const newUuid = v4()

              fieldOptionsMap[field.uuid][opt.uuid] = newUuid

              return { ...opt, uuid: newUuid }
            })
          }

          newArea.option_uuid = fieldOptionsMap[field.uuid][oldOptionUuid] || newField.options[0].uuid
        }
      })

      Object.values(fieldUuidIndex).forEach((field) => {
        this.insertField(field)
      })

      this.selectedAreasRef.value = [...newAreas]

      this.save()
    },
    hasClipboardData () {
      try {
        const clipboard = localStorage.getItem('docuseal_clipboard')

        if (clipboard) {
          const data = JSON.parse(clipboard)

          return Date.now() - data.timestamp < 3600000
        }

        return false
      } catch {
        return false
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

      if (type === 'checkbox' || type === 'radio' || type === 'multiple') {
        area.w = pageMask.clientWidth / 30 / pageMask.clientWidth
        area.h = (pageMask.clientWidth / 30 / pageMask.clientWidth) * (pageMask.clientWidth / pageMask.clientHeight)
      } else if (type === 'image') {
        area.w = pageMask.clientWidth / 5 / pageMask.clientWidth
        area.h = (pageMask.clientWidth / 5 / pageMask.clientWidth) * (pageMask.clientWidth / pageMask.clientHeight)
      } else if (type === 'signature' || type === 'stamp' || type === 'verification' || type === 'kba') {
        area.w = pageMask.clientWidth / 5 / pageMask.clientWidth
        area.h = (pageMask.clientWidth / 5 / pageMask.clientWidth) * (pageMask.clientWidth / pageMask.clientHeight) / 2
      } else if (type === 'initials') {
        area.w = pageMask.clientWidth / 10 / pageMask.clientWidth
        area.h = (pageMask.clientWidth / 35 / pageMask.clientWidth)
      } else if (type === 'strikethrough') {
        area.w = pageMask.clientWidth / 5 / pageMask.clientWidth
        area.h = (pageMask.clientWidth / 70 / pageMask.clientWidth)
      } else {
        area.w = pageMask.clientWidth / 5 / pageMask.clientWidth
        area.h = (pageMask.clientWidth / 35 / pageMask.clientWidth)
      }
    },
    onDraw ({ area, isTooSmall }) {
      if (this.drawCustomField) {
        return this.onDrawCustomField(area)
      }

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
            area.w = this.lastSelectedArea.w
            area.h = this.lastSelectedArea.h
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
          this.insertField(this.drawField)
        }

        this.drawField = null
        this.drawOption = null

        this.selectedAreasRef.value = [area]

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
          const previousField = this.template.fields.findLast
            ? this.template.fields.findLast((f) => f.type === type)
            : [...this.template.fields].reverse().find((f) => f.type === type)
          const previousArea = previousField?.areas?.[previousField.areas.length - 1]

          if (previousArea || area.w) {
            const areaW = previousArea?.w || area.w || (30 / pageMask.clientWidth)
            const areaH = previousArea?.h || area.h || (30 / pageMask.clientHeight)

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
            area.w = this.lastSelectedArea.w
            area.h = this.lastSelectedArea.h
          } else {
            this.setDefaultAreaSize(area, this.drawFieldType)
          }

          area.x -= area.w / 2
          area.y -= area.h / 2
        }

        if (area.w && (type !== 'checkbox' || this.drawFieldType || !isTooSmall)) {
          this.addField(type, area)

          this.selectedAreasRef.value = [area]
        }
      }
    },
    onDropfield (area) {
      if (this.$refs.dragPlaceholder) {
        this.$refs.dragPlaceholder.dragPlaceholder = null
      }

      if (!this.editable) {
        return
      }

      if (this.customDragFieldRef.value) {
        return this.dropCustomField(area)
      }

      const field = this.fieldsDragFieldRef.value || {
        name: '',
        uuid: v4(),
        submitter_uuid: this.selectedSubmitter.uuid,
        required: this.dragField.type !== 'checkbox',
        ...this.dragField
      }

      if (!field.type) {
        field.type = 'text'
      }

      if (!this.fieldsDragFieldRef.value) {
        if (['select', 'multiple', 'radio'].includes(field.type)) {
          if (this.dragField?.options?.length) {
            field.options = this.dragField.options.map(option => ({ value: option, uuid: v4() }))
          } else {
            field.options = [{ value: '', uuid: v4() }, { value: '', uuid: v4() }]
          }
        }

        if (field.type === 'datenow') {
          field.type = 'date'
          field.readonly = true
          field.default_value = '{{date}}'
        }

        if (['stamp', 'heading', 'strikethrough'].includes(field.type)) {
          field.readonly = true

          if (field.type === 'strikethrough') {
            field.default_value = true
          }
        }

        if (field.type === 'date') {
          field.preferences ||= {}
          field.preferences.format ||= this.defaultDateFormat
        }

        if (field.type === 'signature' && [true, false].includes(this.withSignatureId)) {
          field.preferences ||= {}
          field.preferences.with_signature_id = this.withSignatureId
        }
      }

      const fieldArea = {
        x: (area.x - 6) / area.maskW,
        y: area.y / area.maskH,
        page: area.page,
        attachment_uuid: area.attachment_uuid
      }

      this.assignDropAreaSize(fieldArea, field, area)

      if (field.width) {
        delete field.width
      }

      if (field.height) {
        delete field.height
      }

      field.areas ||= []

      field.areas.push(fieldArea)

      if (this.selectedAreasRef.value.length < 2) {
        this.selectedAreasRef.value = [fieldArea]
      } else {
        this.selectedAreasRef.value.push(fieldArea)
      }

      if (this.template.fields.indexOf(field) === -1) {
        this.insertField(field)
      }

      this.save()

      document.activeElement?.blur()

      if (field.type === 'heading') {
        this.$nextTick(() => {
          const documentRef = this.documentRefs.find((e) => e.document.uuid === area.attachment_uuid)
          const areaRef = documentRef.pageRefs[area.page].areaRefs.find((ref) => ref.area === fieldArea)

          areaRef.isHeadingSelected = true

          areaRef.focusValueInput()
        })
      }
    },
    dropCustomField (area) {
      const customField = this.customDragFieldRef.value
      const customAreas = customField.areas || []

      const field = JSON.parse(JSON.stringify(customField))

      field.uuid = v4()
      field.submitter_uuid = this.selectedSubmitter.uuid
      field.areas = []

      if (field.options?.length) {
        field.options = field.options.map(opt => ({ ...opt, uuid: v4() }))
      }

      delete field.conditions

      const dropX = (area.x - 6) / area.maskW
      const dropY = area.y / area.maskH

      if (customAreas.length > 0) {
        const refArea = customAreas[0]

        customAreas.forEach((customArea) => {
          const fieldArea = {
            x: dropX + (customArea.x - refArea.x),
            y: dropY + (customArea.y - refArea.y) - (customArea.h / 2),
            w: customArea.w,
            h: customArea.h,
            page: area.page,
            attachment_uuid: area.attachment_uuid
          }

          if (customArea.cell_w) {
            fieldArea.cell_w = customArea.cell_w
          }

          if (customArea.option_uuid && field.options?.length) {
            const optionIndex = customField.options.findIndex(o => o.uuid === customArea.option_uuid)
            if (optionIndex !== -1) {
              fieldArea.option_uuid = field.options[optionIndex].uuid
            }
          }

          field.areas.push(fieldArea)
        })
      } else {
        const fieldArea = {
          x: dropX,
          y: dropY,
          page: area.page,
          attachment_uuid: area.attachment_uuid
        }

        this.assignDropAreaSize(fieldArea, field, area)

        field.areas.push(fieldArea)
      }

      this.selectedAreasRef.value = [field.areas[0]]

      this.insertField(field)
      this.save()

      document.activeElement?.blur()
    },
    onDrawCustomField (area) {
      const customField = this.drawCustomField
      const customAreas = customField.areas || []

      const field = JSON.parse(JSON.stringify(customField))

      field.uuid = v4()
      field.submitter_uuid = this.selectedSubmitter.uuid
      field.areas = []

      if (field.options?.length) {
        field.options = field.options.map(opt => ({ ...opt, uuid: v4() }))
      }

      delete field.conditions

      const isClick = area.w === 0 || area.h === 0

      const firstArea = {
        x: area.x,
        y: area.y,
        w: area.w || customAreas[0]?.w,
        h: area.h || customAreas[0]?.h,
        page: area.page,
        attachment_uuid: area.attachment_uuid
      }

      if (!firstArea.w || !firstArea.h) {
        if (customAreas[0]) {
          firstArea.w = customAreas[0].w
          firstArea.h = customAreas[0].h
        } else {
          this.setDefaultAreaSize(firstArea, field.type)
        }
      }

      if (isClick) {
        firstArea.x -= firstArea.w / 2
        firstArea.y -= firstArea.h / 2
      }

      if (field.options?.length) {
        firstArea.option_uuid = field.options[0].uuid
      }

      field.areas.push(firstArea)

      this.selectedAreasRef.value = [field.areas[0]]

      this.insertField(field)
      this.save()

      this.drawCustomField = null
      this.showDrawField = false
    },
    assignDropAreaSize (fieldArea, field, area) {
      const fieldType = field.type || 'text'

      const previousField = this.template.fields.findLast
        ? this.template.fields.findLast((f) => f.type === fieldType)
        : [...this.template.fields].reverse().find((f) => f.type === fieldType)

      let baseArea

      if (this.selectedField?.type === fieldType) {
        baseArea = this.lastSelectedArea
      } else if (previousField?.areas?.length) {
        baseArea = previousField.areas[previousField.areas.length - 1]
      } else {
        if (['checkbox', 'radio', 'multiple'].includes(fieldType)) {
          baseArea = {
            w: area.maskW / 30 / area.maskW,
            h: area.maskW / 30 / area.maskW * (area.maskW / area.maskH)
          }
        } else if (fieldType === 'image') {
          baseArea = {
            w: area.maskW / 5 / area.maskW,
            h: (area.maskW / 5 / area.maskW) * (area.maskW / area.maskH)
          }
        } else if (fieldType === 'signature' || fieldType === 'stamp' || fieldType === 'verification' || fieldType === 'kba') {
          baseArea = {
            w: area.maskW / 5 / area.maskW,
            h: (area.maskW / 5 / area.maskW) * (area.maskW / area.maskH) / 2
          }
        } else if (fieldType === 'initials') {
          baseArea = {
            w: area.maskW / 10 / area.maskW,
            h: area.maskW / 35 / area.maskW
          }
        } else if (fieldType === 'strikethrough') {
          baseArea = {
            w: area.maskW / 5 / area.maskW,
            h: area.maskW / 70 / area.maskW
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

      if (fieldType === 'cells') {
        fieldArea.cell_w = baseArea.cell_w || (baseArea.w / 5)
      }

      if (field.areas?.length) {
        const lastArea = field.areas[field.areas.length - 1]

        if (lastArea) {
          fieldArea.w = lastArea.w
          fieldArea.h = lastArea.h
        }
      }

      if (field.width) {
        fieldArea.w = field.width / area.maskW
      }

      if (field.height) {
        fieldArea.h = field.height / area.maskH
      }

      fieldArea.y = fieldArea.y - fieldArea.h / 2
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
    onUploadFailed (error) {
      if (error) alert(error)
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
        if (this.$refs.previews) {
          this.$refs.previews.scrollTop = this.$refs.previews.scrollHeight
        }

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

            this.insertField(field)
          })
        }
      })
    },
    updateName (value) {
      this.template.name = value

      this.save()
    },
    onDocumentRemove (item) {
      if (window.confirm(this.t('are_you_sure_'))) {
        this.template.schema.splice(this.template.schema.indexOf(item), 1)

        const removedFieldUuids = []

        this.template.fields.forEach((field) => {
          [...(field.areas || [])].forEach((area) => {
            if (area.attachment_uuid === item.attachment_uuid) {
              field.areas.splice(field.areas.indexOf(area), 1)

              removedFieldUuids.push(field.uuid)
            }
          })
        })

        this.template.fields = this.template.fields.reduce((acc, f) => {
          if (removedFieldUuids.includes(f.uuid) && !f.areas?.length) {
            this.removeFieldConditions(f)
          } else {
            acc.push(f)
          }

          return acc
        }, [])

        this.save()
      }
    },
    onDocumentReplace (data) {
      const { replaceSchemaItem, schema, documents } = data
      // eslint-disable-next-line camelcase
      const { google_drive_file_id, ...cleanedReplaceSchemaItem } = replaceSchemaItem

      this.template.schema.splice(this.template.schema.indexOf(replaceSchemaItem), 1, { ...cleanedReplaceSchemaItem, ...schema[0] })
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
    onDocumentsReplace (data) {
      data.schema.forEach((schemaItem, index) => {
        const existingSchemaItem = this.template.schema[index]

        if (this.template.schema[index]) {
          this.onDocumentReplace({
            replaceSchemaItem: existingSchemaItem,
            schema: [schemaItem],
            documents: [data.documents.find((doc) => doc.uuid === schemaItem.attachment_uuid)]
          })
        } else {
          this.updateFromUpload({
            schema: [schemaItem],
            documents: [data.documents.find((doc) => doc.uuid === schemaItem.attachment_uuid)],
            fields: data.fields,
            submitters: data.submitters
          })
        }
      })
    },
    onDocumentsReplaceAndTemplateClone (template) {
      window.Turbo.visit(`/templates/${template.id}/edit`)
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

        alert(this.t('please_draw_fields_to_prepare_the_document'))
      } else {
        const submitterWithoutFields =
          this.template.submitters.find((submitter) => !this.template.fields.some((f) => f.submitter_uuid === submitter.uuid))

        if (submitterWithoutFields) {
          e.preventDefault()

          alert(this.t('please_add_fields_for_the_submitter_name_or_remove_the_submitter_name_if_not_needed').replaceAll('{submitter_name}', submitterWithoutFields.name))
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
        alert(this.t('please_draw_fields_to_prepare_the_document'))
      } else {
        const submitterWithoutFields =
          this.template.submitters.find((submitter) => !this.template.fields.some((f) => f.submitter_uuid === submitter.uuid))

        if (submitterWithoutFields) {
          alert(this.t('please_add_fields_for_the_submitter_name_or_remove_the_submitter_name_if_not_needed').replaceAll('{submitter_name}', submitterWithoutFields.name))
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

      this.selectedAreasRef.value = [area]
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
    detectFieldsForPage ({ page, attachmentUuid }) {
      this.isDetectingPageFields = true
      this.detectingAnalyzingProgress = null
      this.detectingFieldsAddedCount = null

      let totalFieldsAdded = 0
      const hadFieldsBeforeDetection = this.template.fields.length > 0

      const calculateIoU = (area1, area2) => {
        const x1 = Math.max(area1.x, area2.x)
        const y1 = Math.max(area1.y, area2.y)
        const x2 = Math.min(area1.x + area1.w, area2.x + area2.w)
        const y2 = Math.min(area1.y + area1.h, area2.y + area2.h)

        const intersectionArea = Math.max(0, x2 - x1) * Math.max(0, y2 - y1)
        const area1Size = area1.w * area1.h
        const area2Size = area2.w * area2.h
        const unionArea = area1Size + area2Size - intersectionArea

        return unionArea > 0 ? intersectionArea / unionArea : 0
      }

      const hasOverlappingField = (newArea) => {
        const pageAreas = this.fieldAreasIndex[newArea.attachment_uuid]?.[newArea.page] || []

        return pageAreas.some(({ area: existingArea }) => {
          return calculateIoU(existingArea, newArea) >= 0.1
        })
      }

      const filterNonOverlappingFields = (detectedFields) => {
        return detectedFields.filter((field) => {
          return (field.areas || []).every((area) => !hasOverlappingField(area))
        })
      }

      this.baseFetch(`/templates/${this.template.id}/detect_fields`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ attachment_uuid: attachmentUuid, page })
      }).then(async (response) => {
        const reader = response.body.getReader()
        const decoder = new TextDecoder('utf-8')
        let buffer = ''
        const fields = []

        while (true) {
          const { value, done } = await reader.read()

          buffer += decoder.decode(value, { stream: true })

          const lines = buffer.split('\n\n')

          buffer = lines.pop()

          for (const line of lines) {
            if (line.startsWith('data: ')) {
              const jsonStr = line.replace(/^data: /, '')
              const data = JSON.parse(jsonStr)

              if (data.error) {
                const errorFields = filterNonOverlappingFields(data.fields || fields)

                if (errorFields.length) {
                  errorFields.forEach((f) => {
                    if (!f.submitter_uuid) {
                      f.submitter_uuid = this.template.submitters[0].uuid
                    }
                    this.insertField(f)
                  })

                  totalFieldsAdded += errorFields.length

                  this.save()
                } else if (!(data.fields || fields).length) {
                  alert(data.error)
                }

                break
              } else if (data.analyzing) {
                this.detectingAnalyzingProgress = data.progress
              } else if (data.completed) {
                if (data.submitters) {
                  if (!hadFieldsBeforeDetection) {
                    this.template.submitters = data.submitters
                    this.selectedSubmitter = this.template.submitters[0]

                    const finalFields = data.fields || fields

                    finalFields.forEach((f) => {
                      if (!f.submitter_uuid) {
                        f.submitter_uuid = this.template.submitters[0].uuid
                      }
                    })

                    const nonOverlappingFields = filterNonOverlappingFields(finalFields)

                    nonOverlappingFields.forEach((f) => this.insertField(f))
                    totalFieldsAdded += nonOverlappingFields.length

                    if (nonOverlappingFields.length) {
                      this.save()
                    }
                  } else {
                    const existingSubmitters = this.template.submitters
                    const submitterUuidMap = {}

                    data.submitters.forEach((newSubmitter) => {
                      const existingMatch = existingSubmitters.find(
                        (s) => s.name.toLowerCase() === newSubmitter.name.toLowerCase()
                      )

                      if (existingMatch) {
                        submitterUuidMap[newSubmitter.uuid] = existingMatch.uuid
                      } else {
                        submitterUuidMap[newSubmitter.uuid] = newSubmitter.uuid

                        if (!existingSubmitters.find((s) => s.uuid === newSubmitter.uuid)) {
                          this.template.submitters.push(newSubmitter)
                        }
                      }
                    })

                    const finalFields = data.fields || fields

                    finalFields.forEach((f) => {
                      if (f.submitter_uuid && submitterUuidMap[f.submitter_uuid]) {
                        f.submitter_uuid = submitterUuidMap[f.submitter_uuid]
                      } else if (!f.submitter_uuid) {
                        f.submitter_uuid = this.template.submitters[0].uuid
                      }
                    })

                    const nonOverlappingFields = filterNonOverlappingFields(finalFields)

                    nonOverlappingFields.forEach((f) => this.insertField(f))
                    totalFieldsAdded += nonOverlappingFields.length

                    if (nonOverlappingFields.length) {
                      this.save()
                    }
                  }
                } else {
                  const finalFields = data.fields || fields

                  finalFields.forEach((f) => {
                    if (!f.submitter_uuid) {
                      f.submitter_uuid = this.template.submitters[0].uuid
                    }
                  })

                  const nonOverlappingFields = filterNonOverlappingFields(finalFields)

                  nonOverlappingFields.forEach((f) => this.insertField(f))
                  totalFieldsAdded += nonOverlappingFields.length

                  if (nonOverlappingFields.length) {
                    this.save()
                  }
                }

                break
              } else if (data.fields) {
                data.fields.forEach((f) => {
                  if (!f.submitter_uuid) {
                    f.submitter_uuid = this.template.submitters[0].uuid
                  }
                })

                fields.push(...data.fields)
              }
            }
          }

          if (done) break
        }
      }).catch(error => {
        console.error('Error in streaming message: ', error)
      }).finally(() => {
        this.isDetectingPageFields = false
        this.detectingAnalyzingProgress = null
        this.detectingFieldsAddedCount = totalFieldsAdded

        setTimeout(() => {
          this.detectingFieldsAddedCount = null
        }, 1000)
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

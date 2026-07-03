<template>
  <div
    class="modal modal-open items-center !animate-none"
    @dragover.prevent="onModalDragover"
    @dragleave="onModalDragleave"
    @drop.prevent="onModalDrop"
  >
    <div
      class="absolute top-0 bottom-0 right-0 left-0"
      @click.prevent="$emit('close')"
    />
    <div
      class="modal-box relative flex flex-col p-0 w-full h-full rounded-2xl"
      style="max-width: 1240px; max-height: 92vh"
    >
      <div class="flex justify-between items-center border-b py-2 px-6 font-medium">
        <span
          class="modal-title"
          style="padding-top: 2px"
        >
          {{ t('edit_documents') }}
        </span>
        <a
          href="#"
          class="text-xl modal-close-button"
          @click.prevent="$emit('close')"
        >&times;</a>
      </div>
      <div class="flex flex-1 min-h-0 relative">
        <CropView
          v-if="cropPageItem"
          class="absolute inset-0 z-10 bg-base-100"
          :template-id="template.id"
          :page="cropPageItem"
          :image-url="thumbUrl(cropPageItem)"
          :metadata="pageMetadata(cropPageItem)"
          @apply="applyCrop"
          @cancel="closeCropView"
        />
        <RedactView
          v-else-if="redactPageItem"
          class="absolute inset-0 z-10 bg-base-100"
          :template-id="template.id"
          :page="redactPageItem"
          :image-url="thumbUrl(redactPageItem)"
          :metadata="pageMetadata(redactPageItem)"
          :image-page="!documentsIndex[redactPageItem.sourceUuid]?.metadata?.pdf"
          :page-objects-cache="pageObjectsCache"
          @apply="applyRedaction"
          @cancel="closeRedactView"
        />
        <div
          class="contents"
          :class="{ invisible: cropPageItem || redactPageItem }"
        >
          <div class="flex-1 overflow-y-auto px-6 py-4 space-y-4">
            <div
              v-for="(doc, docIndex) in layout"
              :key="doc.attachmentUuid"
              :data-uuid="doc.attachmentUuid"
              class="relative"
            >
              <div
                class="flex items-center pb-2"
                @dragover.prevent="onGridDragover(docIndex)"
                @drop.prevent="onPageDrop"
              >
                <button
                  class="flex items-center space-x-1 flex-1 min-w-0 text-left font-normal"
                  :class="{ 'cursor-default': layout.length === 1 }"
                  @click.prevent="layout.length > 1 && (collapsedDocumentsIndex[doc.attachmentUuid] = !collapsedDocumentsIndex[doc.attachmentUuid])"
                >
                  <IconChevronRight
                    v-if="layout.length > 1"
                    class="w-5 h-5 flex-none transition-transform"
                    :class="{ 'rotate-90': !collapsedDocumentsIndex[doc.attachmentUuid] }"
                  />
                  <span
                    class="truncate"
                    :class="{ 'line-through': !doc.pages.length }"
                  >{{ doc.name }}</span>
                </button>
                <span
                  v-if="doc.pages.length"
                  class="dropdown dropdown-end"
                  :class="{ 'dropdown-open': replacingDocIndex === docIndex }"
                >
                  <label
                    tabindex="0"
                    class="btn border-gray-300 bg-white text-base-content btn-xs rounded hover:text-base-100 hover:bg-base-content hover:border-base-content transition-colors px-0"
                    style="width: 24px; height: 24px"
                    @click.stop
                  >
                    <IconDotsVertical
                      :width="16"
                      :height="16"
                      :stroke-width="1.6"
                    />
                  </label>
                  <ul
                    tabindex="0"
                    class="mt-1.5 dropdown-content p-1 shadow-lg rounded-lg border border-neutral-200 z-50 bg-white"
                    style="min-width: 170px"
                    @click="closeDropdown"
                  >
                    <li v-if="docIndex > 0">
                      <button
                        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm whitespace-nowrap"
                        @click.stop="moveDocument(docIndex, -1); closeDropdown()"
                      >
                        <IconArrowUp class="w-4 h-4" />
                        <span>{{ t('move_up') }}</span>
                      </button>
                    </li>
                    <li v-if="docIndex < layout.length - 1">
                      <button
                        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm whitespace-nowrap"
                        @click.stop="moveDocument(docIndex, 1); closeDropdown()"
                      >
                        <IconArrowDown class="w-4 h-4" />
                        <span>{{ t('move_down') }}</span>
                      </button>
                    </li>
                    <li v-if="docIndex > 0">
                      <button
                        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm whitespace-nowrap"
                        @click.stop="mergeDocument(docIndex, -1); closeDropdown()"
                      >
                        <IconCornerRightUp class="w-4 h-4" />
                        <span>{{ t('merge_with_previous') }}</span>
                      </button>
                    </li>
                    <li v-if="docIndex < layout.length - 1">
                      <button
                        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm whitespace-nowrap"
                        @click.stop="mergeDocument(docIndex, 1); closeDropdown()"
                      >
                        <IconCornerRightDown class="w-4 h-4" />
                        <span>{{ t('merge_with_next') }}</span>
                      </button>
                    </li>
                    <li>
                      <button
                        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm whitespace-nowrap"
                        @click.stop="replaceDocument(docIndex)"
                      >
                        <IconInnerShadowTop
                          v-if="replacingDocIndex === docIndex"
                          class="w-4 h-4 animate-spin"
                        />
                        <IconSwipe
                          v-else
                          class="w-4 h-4"
                        />
                        <span>{{ t('replace') }}</span>
                      </button>
                    </li>
                    <hr class="my-1 border-neutral-200">
                    <li>
                      <button
                        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm text-red-600"
                        @click.stop="removeDocument(docIndex); closeDropdown()"
                      >
                        <IconTrashX class="w-4 h-4" />
                        <span>{{ t('remove') }}</span>
                      </button>
                    </li>
                  </ul>
                </span>
              </div>
              <div
                v-if="(!collapsedDocumentsIndex[doc.attachmentUuid] || layout.length === 1) && doc.pages.length"
                class="grid grid-cols-4 gap-3"
                @dragover.prevent="onGridDragover(docIndex, $event)"
                @drop.prevent="onPageDrop"
              >
                <div
                  v-for="(page, pageIndex) in doc.pages"
                  :key="page.id"
                  :data-page-id="page.id"
                  class="relative cursor-pointer group"
                  draggable="true"
                  @click="selectedPageId = page.id"
                  @mousedown="onPageMousedown(page, $event)"
                  @dragstart="onPageDragstart(page, $event)"
                  @dragend="onPageDragend"
                >
                  <PagePreview
                    :page="page"
                    :image-url="thumbUrl(page)"
                    :metadata="pageMetadata(page)"
                    :areas="pageAreas(page)"
                    :selected="selectedPageId === page.id"
                    :page-number="pageIndex + 1"
                    :extra-action="pageExtraAction(page)"
                    with-actions
                    @rotate="selectedPageId = page.id; rotatePageItem(page)"
                    @remove="selectedPageId = page.id; removePageItem(docIndex, pageIndex)"
                    @redact="openRedactViewForPage(page)"
                    @crop="openCropViewForPage(page)"
                  />
                  <div
                    v-if="dropTarget && dropTarget.docIndex === docIndex && dropTarget.insertIndex === pageIndex"
                    class="absolute -left-2 top-0 bottom-6 w-0.5 bg-neutral-600 rounded pointer-events-none"
                  />
                  <div
                    v-if="dropTarget && dropTarget.docIndex === docIndex && dropTarget.insertIndex === pageIndex + 1 && pageIndex === doc.pages.length - 1"
                    class="absolute -right-2 top-0 bottom-6 w-0.5 bg-neutral-600 rounded pointer-events-none"
                  />
                </div>
              </div>
              <div
                v-if="isFileDragover || uploadingDropIndex === docIndex"
                class="absolute -inset-1.5 rounded-lg border-2 border-dashed flex items-center justify-center"
                :class="fileDropDocIndex === docIndex || uploadingDropIndex === docIndex ? 'border-neutral-600 bg-base-100/80' : 'border-neutral-300 bg-base-100/60'"
                @dragover.prevent="fileDropDocIndex = docIndex"
                @dragleave="fileDropDocIndex = fileDropDocIndex === docIndex ? null : fileDropDocIndex"
                @drop.stop.prevent="onDocumentFileDrop($event, docIndex)"
              >
                <IconInnerShadowTop
                  v-if="uploadingDropIndex === docIndex"
                  class="w-6 h-6 animate-spin"
                />
                <span
                  v-else
                  class="font-medium truncate px-4"
                >{{ t('upload_to_document').replace('{document}', doc.name) }}</span>
              </div>
            </div>
            <div
              v-if="isFileDragover || uploadingDropIndex === -1"
              class="border-2 border-dashed rounded-lg py-10 -mx-1.5 flex flex-col items-center justify-center space-y-1"
              :class="fileDropDocIndex === -1 || uploadingDropIndex === -1 ? 'border-neutral-600 bg-base-100/80' : 'border-neutral-300'"
              @dragover.prevent="fileDropDocIndex = -1"
              @dragleave="fileDropDocIndex = fileDropDocIndex === -1 ? null : fileDropDocIndex"
              @drop.stop.prevent="onDocumentFileDrop($event, null)"
            >
              <IconInnerShadowTop
                v-if="uploadingDropIndex === -1"
                class="w-8 h-8 animate-spin"
              />
              <template v-else>
                <IconCloudUpload class="w-8 h-8" />
                <span class="font-medium">{{ t('add_a_new_document') }}</span>
              </template>
            </div>
          </div>
          <div class="w-56 flex-none border-l px-4 py-4 flex flex-col">
            <div class="space-y-2">
              <button
                class="btn btn-sm w-full justify-start normal-case font-normal rounded disabled:bg-base-300"
                :disabled="!selectedPageId"
                @click.prevent="movePage(-1)"
              >
                <IconArrowBackUp class="w-4 h-4" />
                {{ t('move_backward') }}
              </button>
              <button
                class="btn btn-sm w-full justify-start normal-case font-normal rounded disabled:bg-base-300"
                :disabled="!selectedPageId"
                @click.prevent="movePage(1)"
              >
                <IconArrowForwardUp class="w-4 h-4" />
                {{ t('move_forward') }}
              </button>
              <button
                class="btn btn-sm w-full justify-start normal-case font-normal rounded disabled:bg-base-300"
                :disabled="!selectedPageId"
                @click.prevent="rotatePage"
              >
                <IconRotateClockwise class="w-4 h-4" />
                {{ t('rotate') }}
              </button>
              <button
                class="btn btn-sm w-full justify-start normal-case font-normal rounded disabled:bg-base-300"
                :disabled="!selectedPageId || isReplacing"
                @click.prevent="replaceSelected"
              >
                <IconInnerShadowTop
                  v-if="isReplacing"
                  class="w-4 h-4 animate-spin"
                />
                <IconSwipe
                  v-else
                  class="w-4 h-4"
                />
                {{ t('replace') }}
              </button>
              <input
                ref="replaceFileInput"
                type="file"
                class="hidden"
                :accept="acceptFileTypes"
                multiple
                @change="onReplaceFilesPicked"
              >
              <input
                ref="replaceDocFileInput"
                type="file"
                class="hidden"
                :accept="acceptFileTypes"
                multiple
                @change="onReplaceDocFilesPicked"
              >
              <button
                class="btn btn-sm w-full justify-start normal-case font-normal rounded disabled:bg-base-300"
                :disabled="!selectedPageId"
                @click.prevent="openRedactView"
              >
                <IconEraser class="w-4 h-4" />
                {{ t('redact') }}
              </button>
              <button
                v-if="isSelectedPageCroppable"
                class="btn btn-sm w-full justify-start normal-case font-normal rounded disabled:bg-base-300"
                @click.prevent="openCropView"
              >
                <IconCrop
                  width="22"
                  height="22"
                  style="margin-left: -3px"
                  :stroke-width="1.5"
                />
                <span style="margin-left: -3px">
                  {{ t('crop') }}
                </span>
              </button>
              <button
                class="btn btn-sm w-full justify-start normal-case font-normal rounded disabled:bg-base-300 text-red-600"
                :disabled="!selectedPageId"
                @click.prevent="removePage"
              >
                <IconTrashX class="w-4 h-4" />
                {{ t('remove_page') }}
              </button>
            </div>
            <div class="mt-auto space-y-2">
              <Upload
                :template-id="template.id"
                :accept-file-types="acceptFileTypes"
                :authenticity-token="authenticityToken"
                class="w-full"
                @success="onUploaded"
              />
              <button
                class="btn btn-neutral text-white w-full"
                :disabled="isSaving"
                @click.prevent="save"
              >
                <IconInnerShadowTop
                  v-if="isSaving"
                  class="w-4 h-4 animate-spin"
                />
                {{ t('save') }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    <PagePreview
      v-if="dragPreview"
      ref="dragPreviewEl"
      :page="dragPreview.page"
      :image-url="thumbUrl(dragPreview.page)"
      :metadata="pageMetadata(dragPreview.page)"
      :areas="pageAreas(dragPreview.page)"
      :lazy="false"
      :style="{ position: 'fixed', top: '0', left: '-10000px', width: `${dragPreview.width}px` }"
    />
  </div>
</template>

<script>
import Upload, { convertUnsupportedImages } from './upload'
import RedactView from './documents_editor_redact'
import CropView from './documents_editor_crop'
import PagePreview from './documents_editor_page'
import { IconChevronRight, IconArrowBackUp, IconArrowForwardUp, IconTrashX, IconCloudUpload, IconInnerShadowTop, IconDotsVertical, IconArrowUp, IconArrowDown, IconCornerRightUp, IconCornerRightDown, IconRotateClockwise, IconSwipe, IconEraser, IconCrop } from '@tabler/icons-vue'
import { v4 } from 'uuid'

export default {
  name: 'DocumentsEditorModal',
  components: {
    Upload,
    RedactView,
    CropView,
    PagePreview,
    IconChevronRight,
    IconArrowBackUp,
    IconArrowForwardUp,
    IconTrashX,
    IconCloudUpload,
    IconInnerShadowTop,
    IconDotsVertical,
    IconArrowUp,
    IconArrowDown,
    IconCornerRightUp,
    IconCornerRightDown,
    IconRotateClockwise,
    IconSwipe,
    IconEraser,
    IconCrop
  },
  inject: ['t', 'baseFetch'],
  props: {
    template: {
      type: Object,
      required: true
    },
    authenticityToken: {
      type: String,
      required: false,
      default: ''
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
    },
    scrollToAttachmentUuid: {
      type: String,
      required: false,
      default: null
    },
    acceptFileTypes: {
      type: String,
      required: false,
      default: 'image/*, application/pdf'
    }
  },
  emits: ['close', 'saved'],
  data () {
    return {
      layout: [],
      initialPayload: [],
      uploadedDocuments: [],
      undoStack: [],
      redoStack: [],
      selectedPageId: null,
      dragPageId: null,
      dragPreview: null,
      dropTarget: null,
      isFileDragover: false,
      fileDropDocIndex: null,
      uploadingDropIndex: null,
      replaceDocTargetIndex: null,
      replacingDocIndex: null,
      collapsedDocumentsIndex: {},
      isSaving: false,
      isReplacing: false,
      redactView: null,
      cropView: null,
      pageObjectsCache: {}
    }
  },
  computed: {
    documentsIndex () {
      return [...this.template.documents, ...this.uploadedDocuments].reduce((acc, doc) => {
        acc[doc.uuid] = doc

        return acc
      }, {})
    },
    basePreviewUrl () {
      return this.baseUrl ? new URL(this.baseUrl).origin : ''
    },
    hasChanges () {
      return JSON.stringify(this.buildPayload(this.layout)) !== JSON.stringify(this.initialPayload)
    },
    fieldAreasIndex () {
      const index = {}

      this.template.fields.forEach((field) => {
        const submitterIndex = this.template.submitters.findIndex((s) => s.uuid === field.submitter_uuid)

        ;(field.areas || []).forEach((area) => {
          const key = `${area.attachment_uuid}-${area.page}`

          ;(index[key] ||= []).push({ area, submitterIndex })
        })
      })

      return index
    },
    selectedPosition () {
      return this.pagePosition(this.selectedPageId)
    },
    isSelectedPageCroppable () {
      const position = this.selectedPosition

      if (!position) {
        return false
      }

      const page = this.layout[position.docIndex].pages[position.pageIndex]

      return !page.redact.length && !this.documentsIndex[page.sourceUuid]?.metadata?.pdf
    },
    redactPageItem () {
      if (!this.redactView) {
        return null
      }

      const position = this.pagePosition(this.redactView.pageId)

      return position && this.layout[position.docIndex].pages[position.pageIndex]
    },
    cropPageItem () {
      if (!this.cropView) {
        return null
      }

      const position = this.pagePosition(this.cropView.pageId)

      return position && this.layout[position.docIndex].pages[position.pageIndex]
    }
  },
  created () {
    this.layout = this.template.schema.filter((item) => !item.dynamic).map((item) => {
      return this.buildLayoutItem(item, this.template.documents.find((doc) => doc.uuid === item.attachment_uuid))
    })

    this.initialPayload = this.buildPayload(this.layout)
    this.undoStack = [JSON.stringify(this.layout)]
  },
  mounted () {
    window.addEventListener('keydown', this.onKeyDown)

    if (this.scrollToAttachmentUuid) {
      const item = this.layout.find((doc) => doc.attachmentUuid === this.scrollToAttachmentUuid)

      if (item?.pages.length === 1) {
        this.selectedPageId = item.pages[0].id
      }

      if (item !== this.layout[0]) {
        this.$nextTick(() => {
          this.$el.querySelector(`[data-uuid="${this.scrollToAttachmentUuid}"]`)?.scrollIntoView({ block: 'start' })
        })
      }
    }
  },
  beforeUnmount () {
    window.removeEventListener('keydown', this.onKeyDown)
  },
  methods: {
    buildLayoutItem (schemaItem, document) {
      const numberOfPages = document.metadata?.pdf?.number_of_pages || document.preview_images?.length || 1

      return {
        attachmentUuid: schemaItem.attachment_uuid,
        name: schemaItem.name,
        pages: [...Array(numberOfPages).keys()].map((page) => {
          return { id: v4(), sourceUuid: schemaItem.attachment_uuid, sourcePage: page, rotate: 0, redact: [] }
        })
      }
    },
    buildPayload (layout) {
      return layout.map((doc) => {
        return {
          attachment_uuid: doc.attachmentUuid,
          pages: doc.pages.map((page) => {
            return {
              attachment_uuid: page.sourceUuid,
              page: page.sourcePage,
              ...(page.rotate ? { rotate: page.rotate } : {}),
              ...(page.redact?.length ? { redact: page.redact } : {}),
              ...(page.replacedPage ? { replaced_page: page.replacedPage } : {})
            }
          })
        }
      })
    },
    onKeyDown (event) {
      if ((event.metaKey && event.shiftKey && event.key === 'z') || (event.ctrlKey && event.key === 'Z')) {
        event.preventDefault()

        this.redo()
      } else if ((event.ctrlKey || event.metaKey) && event.key === 'z') {
        event.preventDefault()

        this.undo()
      }
    },
    pushUndo () {
      const stringData = JSON.stringify(this.layout)

      if (this.undoStack[this.undoStack.length - 1] !== stringData) {
        this.undoStack.push(stringData)

        this.redoStack = []
      }
    },
    undo () {
      if (this.undoStack.length > 1) {
        this.undoStack.pop()

        const stringData = this.undoStack[this.undoStack.length - 1]
        const currentStringData = JSON.stringify(this.layout)

        if (stringData && stringData !== currentStringData) {
          this.redoStack.push(currentStringData)

          this.selectedPageId = null
          this.layout = JSON.parse(stringData)
        }
      }
    },
    redo () {
      const stringData = this.redoStack.pop()

      if (stringData && stringData !== JSON.stringify(this.layout)) {
        this.undoStack.push(stringData)

        this.selectedPageId = null
        this.layout = JSON.parse(stringData)
      }
    },
    thumbUrl (page) {
      const document = this.documentsIndex[page.sourceUuid]

      const previewImage = document.preview_images.find((image) => parseInt(image.filename) === page.sourcePage)

      if (previewImage) {
        return previewImage.url
      } else {
        return this.basePreviewUrl + `/preview/${document.signed_key || document.signed_uuid || document.uuid}/${page.sourcePage}${this.pagePreviewFormat}`
      }
    },
    pageMetadata (page) {
      const document = this.documentsIndex[page.sourceUuid]

      return document.preview_images.find((image) => parseInt(image.filename) === page.sourcePage)?.metadata ||
        document.preview_images[0]?.metadata || { width: 1400, height: 1812 }
    },
    pagePosition (pageId) {
      for (let docIndex = 0; docIndex < this.layout.length; docIndex++) {
        const pageIndex = this.layout[docIndex].pages.findIndex((page) => page.id === pageId)

        if (pageIndex !== -1) {
          return { docIndex, pageIndex }
        }
      }

      return null
    },
    pageAreas (page) {
      const areas = this.fieldAreasIndex[`${page.sourceUuid}-${page.sourcePage}`] || []
      const replaced = page.replacedPage

      if (!replaced) {
        return areas
      }

      return [...areas, ...(this.fieldAreasIndex[`${replaced.attachment_uuid}-${replaced.page}`] || [])]
    },
    rotatePage () {
      const position = this.selectedPosition

      if (!position) {
        return
      }

      this.rotatePageItem(this.layout[position.docIndex].pages[position.pageIndex])
    },
    rotatePageItem (page) {
      page.rotate = (page.rotate + 90) % 360

      this.pushUndo()
    },
    movePage (direction) {
      const position = this.selectedPosition

      if (!position) {
        return
      }

      const { docIndex, pageIndex } = position
      const targetIndex = pageIndex + direction

      const [page] = this.layout[docIndex].pages.splice(pageIndex, 1)

      if (targetIndex < 0) {
        if (docIndex > 0) {
          this.layout[docIndex - 1].pages.push(page)
        } else {
          this.layout[docIndex].pages.unshift(page)
        }
      } else if (targetIndex > this.layout[docIndex].pages.length) {
        if (docIndex < this.layout.length - 1) {
          this.layout[docIndex + 1].pages.unshift(page)
        } else {
          this.layout[docIndex].pages.push(page)
        }
      } else {
        this.layout[docIndex].pages.splice(targetIndex, 0, page)
      }

      this.pushUndo()
    },
    removePage () {
      const position = this.selectedPosition

      if (!position) {
        return
      }

      this.removePageItem(position.docIndex, position.pageIndex)
    },
    removePageItem (docIndex, pageIndex) {
      const [page] = this.layout[docIndex].pages.splice(pageIndex, 1)

      if (page.id === this.selectedPageId) {
        this.selectedPageId = null
      }

      this.pushUndo()
    },
    moveDocument (docIndex, direction) {
      const [doc] = this.layout.splice(docIndex, 1)

      this.layout.splice(docIndex + direction, 0, doc)

      this.pushUndo()
    },
    mergeDocument (docIndex, direction) {
      const doc = this.layout[docIndex]
      const target = this.layout[docIndex + direction]

      if (!target) {
        return
      }

      if (direction < 0) {
        target.pages.push(...doc.pages.splice(0))
      } else {
        target.pages.unshift(...doc.pages.splice(0))
      }

      this.collapsedDocumentsIndex[target.attachmentUuid] = false

      this.pushUndo()
    },
    removeDocument (docIndex) {
      const doc = this.layout[docIndex]

      if (doc.pages.some((page) => page.id === this.selectedPageId)) {
        this.selectedPageId = null
      }

      doc.pages.splice(0)

      this.pushUndo()
    },
    closeDropdown () {
      this.$el.getRootNode().activeElement.blur()
    },
    onPageMousedown (page, event) {
      this.dragPreview = { page, width: event.currentTarget.getBoundingClientRect().width }
    },
    onPageDragstart (page, event) {
      this.dragPageId = page.id
      this.selectedPageId = page.id

      event.dataTransfer.effectAllowed = 'move'

      const preview = this.$refs.dragPreviewEl?.$el

      if (preview) {
        event.dataTransfer.setDragImage(preview, event.offsetX, event.offsetY)
      }
    },
    onPageDragend () {
      this.dragPageId = null
      this.dropTarget = null
      this.dragPreview = null
    },
    onGridDragover (docIndex, event = null) {
      if (!this.dragPageId) {
        return
      }

      let insertIndex = this.layout[docIndex].pages.length
      let hoveredIndex = null

      if (event) {
        const tiles = Array.from(event.currentTarget.children)

        for (let i = 0; i < tiles.length; i++) {
          const rect = tiles[i].getBoundingClientRect()

          if (event.clientY < rect.top) {
            insertIndex = i

            break
          }

          if (event.clientY <= rect.bottom) {
            if (event.clientX >= rect.left && event.clientX <= rect.right) {
              hoveredIndex = i
            }

            if (event.clientX < rect.left + rect.width / 2) {
              insertIndex = i

              break
            } else {
              insertIndex = i + 1

              if (event.clientX <= rect.right) {
                break
              }
            }
          }
        }
      }

      const dragPosition = this.pagePosition(this.dragPageId)

      if (dragPosition && dragPosition.docIndex === docIndex &&
        hoveredIndex !== null && hoveredIndex !== dragPosition.pageIndex &&
        (insertIndex === dragPosition.pageIndex || insertIndex === dragPosition.pageIndex + 1)) {
        insertIndex = hoveredIndex < dragPosition.pageIndex ? hoveredIndex : hoveredIndex + 1
      }

      this.dropTarget = { docIndex, insertIndex }
    },
    onPageDrop () {
      if (!this.dragPageId || !this.dropTarget) {
        return
      }

      const { docIndex, insertIndex } = this.dropTarget

      for (const doc of this.layout) {
        const pageIndex = doc.pages.findIndex((page) => page.id === this.dragPageId)

        if (pageIndex !== -1) {
          const [page] = doc.pages.splice(pageIndex, 1)

          let targetIndex = insertIndex

          if (doc === this.layout[docIndex] && pageIndex < insertIndex) {
            targetIndex -= 1
          }

          this.layout[docIndex].pages.splice(targetIndex, 0, page)

          break
        }
      }

      this.dragPageId = null
      this.dropTarget = null

      this.pushUndo()
    },
    onModalDragover (event) {
      if (!this.dragPageId && event.dataTransfer?.types?.includes('Files')) {
        this.isFileDragover = true
      }
    },
    onModalDragleave (event) {
      if (!event.relatedTarget || !this.$el.contains(event.relatedTarget)) {
        this.isFileDragover = false
        this.fileDropDocIndex = null
      }
    },
    onModalDrop (event) {
      this.dropTarget = null

      if (!this.isFileDragover) {
        return
      }

      this.isFileDragover = false
      this.fileDropDocIndex = null
      this.uploadingDropIndex = -1

      this.uploadFiles(event.dataTransfer.files)?.finally(() => {
        this.uploadingDropIndex = null
      })
    },
    onDocumentFileDrop (event, docIndex) {
      this.isFileDragover = false
      this.fileDropDocIndex = null
      this.uploadingDropIndex = docIndex ?? -1

      this.uploadFiles(event.dataTransfer.files, { targetDocIndex: docIndex })?.finally(() => {
        this.uploadingDropIndex = null
      })
    },
    pageExtraAction (page) {
      if (this.documentsIndex[page.sourceUuid]?.metadata?.pdf) {
        return 'redact'
      }

      return page.redact?.length ? null : 'crop'
    },
    openRedactViewForPage (page) {
      this.selectedPageId = page.id
      this.redactView = { pageId: page.id }
    },
    openCropViewForPage (page) {
      this.selectedPageId = page.id
      this.cropView = { pageId: page.id }
    },
    openRedactView () {
      const position = this.selectedPosition

      if (!position) {
        return
      }

      this.redactView = { pageId: this.layout[position.docIndex].pages[position.pageIndex].id }
    },
    closeRedactView () {
      this.redactView = null
    },
    applyRedaction (rects) {
      const page = this.redactPageItem

      if (page) {
        page.redact = rects

        this.pushUndo()
      }

      this.closeRedactView()
    },
    openCropView () {
      const position = this.selectedPosition

      if (!position) {
        return
      }

      this.cropView = { pageId: this.layout[position.docIndex].pages[position.pageIndex].id }
    },
    closeCropView () {
      this.cropView = null
    },
    applyCrop (document) {
      const page = this.cropPageItem

      if (page && document) {
        this.uploadedDocuments.push(document)

        page.replacedPage = this.replacedPageRef(page)
        page.sourceUuid = document.uuid
        page.sourcePage = 0
        page.rotate = 0

        this.pushUndo()
      }

      this.closeCropView()
    },
    replaceSelected () {
      if (this.selectedPosition) {
        this.$refs.replaceFileInput.click()
      }
    },
    replacedPageRef (page) {
      return page.replacedPage || { attachment_uuid: page.sourceUuid, page: page.sourcePage }
    },
    replaceDocumentPages (docIndex, items) {
      const target = this.layout[docIndex]

      if (!target) {
        return
      }

      const newPages = items.flatMap((item) => item.pages)

      target.pages.forEach((page, pageIndex) => {
        const dest = newPages[pageIndex]

        if (dest) {
          dest.replacedPage = this.replacedPageRef(page)
        }

        if (page.id === this.selectedPageId) {
          this.selectedPageId = null
        }
      })

      target.pages = newPages
    },
    replaceDocument (docIndex) {
      this.replaceDocTargetIndex = docIndex

      this.$refs.replaceDocFileInput.click()
    },
    onReplaceDocFilesPicked (event) {
      const docIndex = this.replaceDocTargetIndex

      if (docIndex !== null && event.target.files.length) {
        this.replacingDocIndex = docIndex

        this.uploadFiles(event.target.files, { replaceDocIndex: docIndex })?.finally(() => {
          this.replacingDocIndex = null

          this.closeDropdown()
        })
      }

      event.target.value = ''
      this.replaceDocTargetIndex = null
    },
    onReplaceFilesPicked (event) {
      const position = this.selectedPosition

      if (position && event.target.files.length) {
        this.isReplacing = true

        this.uploadFiles(event.target.files, {
          targetDocIndex: position.docIndex,
          insertIndex: position.pageIndex,
          replacePageId: this.selectedPageId
        })?.finally(() => {
          this.isReplacing = false
        })
      }

      event.target.value = ''
    },
    async uploadFiles (files, { targetDocIndex = null, insertIndex = null, replacePageId = null, replaceDocIndex = null } = {}) {
      const formData = new FormData()

      for (const file of await convertUnsupportedImages(files)) {
        if (file.type === 'application/pdf' || file.type.startsWith('image/')) {
          formData.append('files[]', file)
        }
      }

      if (!formData.has('files[]')) {
        return
      }

      return this.baseFetch(`/templates/${this.template.id}/documents`, {
        method: 'POST',
        headers: { Accept: 'application/json' },
        body: formData
      }).then(async (resp) => {
        const data = await resp.json().catch(() => ({}))

        if (resp.ok) {
          this.onUploaded(data, { targetDocIndex, insertIndex, replacePageId, replaceDocIndex })
        } else if (data.error) {
          alert(data.error)
        }
      })
    },
    onUploaded (data, { targetDocIndex = null, insertIndex = null, replacePageId = null, replaceDocIndex = null } = {}) {
      this.uploadedDocuments.push(...data.documents)

      let position = insertIndex
      let carriedSource = null

      if (replacePageId) {
        const replacePosition = this.pagePosition(replacePageId)

        if (replacePosition) {
          const [replaced] = this.layout[replacePosition.docIndex].pages.splice(replacePosition.pageIndex, 1)

          carriedSource = this.replacedPageRef(replaced)

          targetDocIndex = replacePosition.docIndex
          position = replacePosition.pageIndex
        }

        if (this.selectedPageId === replacePageId) {
          this.selectedPageId = null
        }
      }

      let items = data.schema.map((schemaItem) => {
        return this.buildLayoutItem(schemaItem, data.documents.find((doc) => doc.uuid === schemaItem.attachment_uuid))
      })

      if (targetDocIndex === null && items.length > 1 && data.documents.every((doc) => !doc.metadata?.pdf)) {
        items = [{ ...items[0], pages: items.flatMap((item) => item.pages) }]
      }

      if (carriedSource && items[0]?.pages[0]) {
        items[0].pages[0].replacedPage = carriedSource
      }

      if (replaceDocIndex !== null) {
        this.replaceDocumentPages(replaceDocIndex, items)

        this.pushUndo()

        return
      }

      if ((replacePageId || insertIndex !== null) && items[0]?.pages[0]) {
        this.selectedPageId = items[0].pages[0].id
      }

      const firstNewPage = items[0]?.pages[0]

      items.forEach((item) => {
        if (targetDocIndex === null) {
          this.layout.push(item)
        } else if (position === null) {
          this.layout[targetDocIndex].pages.push(...item.pages)
        } else {
          this.layout[targetDocIndex].pages.splice(position, 0, ...item.pages)

          position += item.pages.length
        }
      })

      if (firstNewPage && !replacePageId && insertIndex === null) {
        this.selectedPageId = firstNewPage.id

        if (targetDocIndex !== null) {
          this.collapsedDocumentsIndex[this.layout[targetDocIndex].attachmentUuid] = false
        }

        this.$nextTick(() => {
          this.$el.querySelector(`[data-page-id="${firstNewPage.id}"]`)?.scrollIntoView({
            behavior: 'smooth',
            block: 'center'
          })
        })
      }

      this.pushUndo()
    },
    save () {
      if (!this.hasChanges) {
        return this.$emit('close')
      }

      this.isSaving = true

      this.baseFetch(`/templates/${this.template.id}/documents_modify`, {
        method: 'POST',
        body: JSON.stringify({ documents: this.buildPayload(this.layout) }),
        headers: { 'Content-Type': 'application/json' }
      }).then(async (resp) => {
        if (resp.ok) {
          this.$emit('saved', await resp.json())
        } else {
          const data = await resp.json().catch(() => ({}))

          if (data.error) {
            alert(data.error)
          }
        }
      }).finally(() => {
        this.isSaving = false
      })
    }
  }
}
</script>

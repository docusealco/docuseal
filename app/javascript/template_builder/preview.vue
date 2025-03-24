<template>
  <div>
    <div class="relative">
      <img
        :src="previewImage.url"
        :width="previewImage.metadata.width"
        :height="previewImage.metadata.height"
        class="rounded border"
        loading="lazy"
      >
      <div
        class="group flex justify-end cursor-pointer top-0 bottom-0 left-0 right-0 absolute p-1 hover:bg-black/10 transition-colors"
        @click="$emit('scroll-to', item)"
      >
        <div
          v-if="editable"
          class="flex justify-between w-full"
        >
          <div
            style="width: 26px"
            class="flex flex-col justify-between group-hover:opacity-100"
            :class="{'opacity-0': !item.conditions?.length }"
          >
            <div>
              <button
                class="btn border-base-200 bg-white text-base-content btn-xs rounded hover:text-base-100 hover:bg-base-content hover:border-base-content w-full transition-colors p-0 document-control-button"
                @click.stop="isShowConditionsModal = true"
              >
                <IconRouteAltLeft
                  :width="14"
                  :stroke-width="1.6"
                />
              </button>
            </div>
          </div>
          <div class="">
            <ReplaceButton
              v-if="withReplaceButton"
              :template-id="template.id"
              :accept-file-types="acceptFileTypes"
              class="opacity-0 group-hover:opacity-100"
              @click.stop
              @success="$emit('replace', { replaceSchemaItem: item, ...$event })"
            />
          </div>
          <div
            class="flex flex-col justify-between opacity-0 group-hover:opacity-100"
          >
            <div>
              <button
                class="btn border-base-200 bg-white text-base-content btn-xs rounded hover:text-base-100 hover:bg-base-content hover:border-base-content w-full transition-colors document-control-button"
                style="width: 24px; height: 24px"
                @click.stop="$emit('remove', item)"
              >
                &times;
              </button>
            </div>
            <div
              class="flex flex-col space-y-1"
            >
              <span
                :data-tip="t('reorder_fields')"
                class="tooltip tooltip-left before:text-xs"
              >
                <button
                  class="btn border-base-200 bg-white text-base-content btn-xs rounded hover:text-base-100 hover:bg-base-content hover:border-base-content w-full transition-colors p-0 document-control-button"
                  @click.stop="$emit('reorder', item)"
                >
                  <IconSortDescending2
                    :width="18"
                    :height="18"
                    :stroke-width="1.6"
                  />
                </button>
              </span>
              <template v-if="withArrows">
                <button
                  class="btn border-base-200 bg-white text-base-content btn-xs rounded hover:text-base-100 hover:bg-base-content hover:border-base-content w-full transition-colors document-control-button"
                  style="width: 24px; height: 24px"
                  @click.stop="$emit('up', item)"
                >
                  &uarr;
                </button>
                <button
                  class="btn border-base-200 bg-white text-base-content btn-xs rounded hover:text-base-100 hover:bg-base-content hover:border-base-content w-full transition-colors document-control-button"
                  style="width: 24px; height: 24px"
                  @click.stop="$emit('down', item)"
                >
                  &darr;
                </button>
              </template>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="flex pb-2 pt-1.5 document-preview-name">
      <Contenteditable
        :model-value="item.name"
        :icon-width="16"
        :editable="editable"
        style="max-width: 95%"
        class="mx-auto"
        @update:model-value="onUpdateName"
      />
    </div>
    <Teleport
      v-if="isShowConditionsModal"
      :to="modalContainerEl"
    >
      <ConditionsModal
        :item="item"
        :build-default-name="buildDefaultName"
        @close="isShowConditionsModal = false"
      />
    </Teleport>
  </div>
</template>

<script>
import Contenteditable from './contenteditable'
import Upload from './upload'
import { IconRouteAltLeft, IconSortDescending2 } from '@tabler/icons-vue'
import ConditionsModal from './conditions_modal'
import ReplaceButton from './replace'
import Field from './field'
import FieldType from './field_type'

export default {
  name: 'DocumentPreview',
  components: {
    Contenteditable,
    IconRouteAltLeft,
    ConditionsModal,
    ReplaceButton,
    IconSortDescending2
  },
  inject: ['t'],
  props: {
    item: {
      type: Object,
      required: true
    },
    template: {
      type: Object,
      required: true
    },
    document: {
      type: Object,
      required: true
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
    withReplaceButton: {
      type: Boolean,
      required: true,
      default: true
    },
    withArrows: {
      type: Boolean,
      required: false,
      default: true
    }
  },
  emits: ['scroll-to', 'change', 'remove', 'up', 'down', 'replace', 'reorder'],
  data () {
    return {
      isShowConditionsModal: false
    }
  },
  computed: {
    fieldNames: FieldType.computed.fieldNames,
    fieldLabels: FieldType.computed.fieldLabels,
    previewImage () {
      return [...this.document.preview_images].sort((a, b) => parseInt(a.filename) - parseInt(b.filename))[0]
    },
    modalContainerEl () {
      return this.$el.getRootNode().querySelector('#docuseal_modal_container')
    }
  },
  methods: {
    upload: Upload.methods.upload,
    buildDefaultName: Field.methods.buildDefaultName,
    onUpdateName (value) {
      this.item.name = value

      this.$emit('change')
    }
  }
}
</script>

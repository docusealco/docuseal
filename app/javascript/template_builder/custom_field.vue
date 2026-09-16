<template>
  <div
    class="list-field group"
  >
    <div
      class="border border-dashed border-base-300 hover:border-base-content/20 rounded relative group fields-list-item transition-colors"
      :style="{ backgroundColor: backgroundColor }"
    >
      <div class="flex items-center justify-between relative group/contenteditable-container">
        <div
          v-if="!isNew"
          class="absolute top-0 bottom-0 right-0 left-0 cursor-pointer"
          @click="$emit('click', field)"
        />
        <div
          class="absolute top-0 bottom-0 left-0 flex items-center transition-all cursor-grab group-hover:bg-base-200/50"
          @click="$emit('click', field)"
        >
          <IconDrag style="margin-left: 1px" />
        </div>
        <div class="flex items-center p-1 pl-6 space-x-1">
          <FieldType
            v-model="field.type"
            :editable="false"
            :button-width="20"
            @click="$emit('click', field)"
          />
          <Contenteditable
            ref="name"
            :model-value="field.name"
            :placeholder="'Field Name'"
            :icon-inline="true"
            :icon-width="18"
            :min-width="isNew ? '100px' : '2px'"
            :icon-stroke-width="1.6"
            :editable-on-button="!isNew"
            :with-button="!isNew"
            :class="{ 'cursor-pointer': !isNew }"
            @click-contenteditable="$emit('click', field)"
            @focus="onNameFocus"
            @blur="onNameBlur"
          />
        </div>
        <div
          class="flex items-center space-x-1"
        >
          <PaymentSettings
            v-if="field.type === 'payment' && !isNew"
            :field="field"
            :background-color="dropdownBgColor"
            :with-condition="false"
            :with-force-open="false"
            @click-description="openDescriptionModal"
            @click-formula="openFormulaModal"
          />
          <span
            v-else-if="!isNew"
            class="dropdown dropdown-end field-settings-dropdown"
            @mouseenter="renderDropdown = true"
            @touchstart="renderDropdown = true"
          >
            <label
              tabindex="0"
              :title="t('settings')"
              class="cursor-pointer flex items-center"
              :class="[iconColorClass, { 'pr-1': isMobile }]"
            >
              <IconDotsVertical
                v-if="isMobile"
                :width="18"
                :height="18"
                :stroke-width="1.6"
              />
              <IconSettings
                v-else
                :width="18"
                :stroke-width="1.6"
              />
            </label>
            <ul
              v-if="renderDropdown"
              tabindex="0"
              class="mt-1.5 dropdown-content menu menu-xs p-2 shadow rounded-box w-52 z-10"
              :style="{ backgroundColor: dropdownBgColor }"
              draggable="true"
              @dragstart.prevent.stop
              @click="closeDropdown"
            >
              <FieldSettings
                :field="field"
                :with-signature-id="withSignatureId"
                :with-prefillable="withPrefillable"
                :background-color="dropdownBgColor"
                :with-areas="false"
                :with-copy-to-all-pages="false"
                :with-condition="false"
                @click-formula="openFormulaModal"
                @click-font="openFontModal"
                @click-description="openDescriptionModal"
                @save="$emit('save')"
              />
              <li
                v-if="isMobile"
                class="field-settings-remove"
              >
                <a
                  href="#"
                  class="text-sm py-1 px-2 text-red-600"
                  @click.prevent="$emit('remove', field)"
                >
                  <IconTrashX
                    :width="20"
                    :stroke-width="1.6"
                  />
                  {{ t('remove') }}
                </a>
              </li>
            </ul>
          </span>
          <button
            v-if="isNew && !$refs.name"
            class="relative text-base-content pr-1 field-save-button"
            :title="t('save')"
            @click="field.name ? $emit('save', field) : focusName()"
          >
            <IconCheck
              :width="18"
              :stroke-width="2"
            />
          </button>
          <button
            v-if="isNew || !isMobile || field.type === 'payment'"
            class="relative group-hover:text-base-content pr-1 field-remove-button"
            :class="isNew ? 'text-base-content' : iconColorClass"
            :title="t('remove')"
            @click="onRemoveClick"
          >
            <IconTrashX
              :width="18"
              :stroke-width="1.6"
            />
          </button>
        </div>
      </div>
    </div>
    <Teleport
      v-if="isShowFormulaModal"
      :to="modalContainerEl"
    >
      <FormulaModal
        :field="field"
        :default-field="defaultField"
        :build-default-name="buildDefaultName"
        @save="$emit('save')"
        @close="isShowFormulaModal = false"
      />
    </Teleport>
    <Teleport
      v-if="isShowFontModal"
      :to="modalContainerEl"
    >
      <FontModal
        :field="field"
        :default-field="defaultField"
        :build-default-name="buildDefaultName"
        @save="$emit('save')"
        @close="isShowFontModal = false"
      />
    </Teleport>
    <Teleport
      v-if="isShowDescriptionModal"
      :to="modalContainerEl"
    >
      <DescriptionModal
        :field="field"
        :default-field="defaultField"
        :build-default-name="buildDefaultName"
        @save="$emit('save')"
        @close="isShowDescriptionModal = false"
      />
    </Teleport>
  </div>
</template>

<script>
import Contenteditable from './contenteditable'
import FieldType from './field_type'
import PaymentSettings from './payment_settings'
import FieldSettings from './field_settings'
import FormulaModal from './formula_modal'
import FontModal from './font_modal'
import DescriptionModal from './description_modal'
import { IconTrashX, IconSettings, IconCheck, IconDotsVertical } from '@tabler/icons-vue'
import IconDrag from './icon_drag'

export default {
  name: 'CustomField',
  components: {
    Contenteditable,
    IconSettings,
    IconDotsVertical,
    IconCheck,
    FieldSettings,
    PaymentSettings,
    IconDrag,
    FormulaModal,
    FontModal,
    DescriptionModal,
    IconTrashX,
    FieldType
  },
  inject: ['backgroundColor', 't', 'isMobile'],
  props: {
    field: {
      type: Object,
      required: true
    },
    isNew: {
      type: Boolean,
      required: false,
      default: false
    },
    withSignatureId: {
      type: Boolean,
      required: false,
      default: null
    },
    withPrefillable: {
      type: Boolean,
      required: false,
      default: false
    }
  },
  emits: ['remove', 'save', 'click'],
  data () {
    return {
      isShowFormulaModal: false,
      isShowFontModal: false,
      isShowDescriptionModal: false,
      renderDropdown: false
    }
  },
  computed: {
    dropdownBgColor () {
      return ['', null, 'transparent'].includes(this.backgroundColor) ? 'white' : this.backgroundColor
    },
    iconColorClass () {
      return this.isMobile ? 'text-base-content' : 'text-transparent group-hover:text-base-content'
    },
    modalContainerEl () {
      return this.$el.getRootNode().querySelector('#docuseal_modal_container')
    }
  },
  created () {
    this.field.preferences ||= {}
  },
  mounted () {
    if (this.isNew) {
      this.focusName()
    }
  },
  methods: {
    openFormulaModal () {
      if (window.webkit?.messageHandlers?.modal) {
        window.webkit.messageHandlers.modal.postMessage({ action: 'sheet', name: 'formula', custom_field_uuid: this.field.uuid })
      } else {
        this.isShowFormulaModal = true
      }
    },
    openFontModal () {
      if (window.webkit?.messageHandlers?.modal) {
        window.webkit.messageHandlers.modal.postMessage({ action: 'sheet', name: 'font', detent: 'medium', custom_field_uuid: this.field.uuid })
      } else {
        this.isShowFontModal = true
      }
    },
    openDescriptionModal () {
      if (window.webkit?.messageHandlers?.modal) {
        window.webkit.messageHandlers.modal.postMessage({ action: 'sheet', name: 'description', custom_field_uuid: this.field.uuid })
      } else {
        this.isShowDescriptionModal = true
      }
    },
    buildDefaultName () {
      return this.t('custom')
    },
    focusName () {
      setTimeout(() => {
        this.$refs.name.clickEdit()
      }, 1)
    },
    onNameFocus (e) {
      if (!this.field.name) {
        setTimeout(() => {
          this.$refs.name.$refs.contenteditable.innerText = ' '
        }, 1)
      }
    },
    closeDropdown () {
      this.$el.getRootNode().activeElement.blur()
    },
    onRemoveClick () {
      if (this.isNew || window.confirm(this.t('are_you_sure_'))) {
        this.$emit('remove', this.field)
      }
    },
    onNameBlur (e) {
      const text = this.$refs.name.$refs.contenteditable.innerText.trim()

      if (text) {
        this.field.name = text
      } else {
        this.$refs.name.setText(this.field.name)
      }

      if (this.field.name) {
        this.$emit('save')
      }
    }
  }
}
</script>

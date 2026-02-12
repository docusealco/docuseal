<template>
  <div
    v-if="field?.type && (isSelected || isNameFocus) && !isInMultiSelection"
    class="absolute bg-white rounded-t border overflow-visible whitespace-nowrap flex z-10 field-area-controls"
    style="top: -25px; height: 25px"
    @mousedown.stop
    @pointerdown.stop
  >
    <FieldSubmitter
      v-if="field.type != 'heading' && field.type != 'strikethrough'"
      v-model="field.submitter_uuid"
      class="border-r roles-dropdown"
      :compact="true"
      :editable="editable && (!defaultField || defaultField.role !== submitter?.name)"
      :allow-add-new="!defaultSubmitters.length"
      :menu-classes="'dropdown-content bg-white menu menu-xs p-2 shadow rounded-box w-52 rounded-t-none -left-[1px] mt-[1px]'"
      :submitters="template.submitters"
      @update:model-value="$emit('change')"
      @click="selectedAreasRef.value = [area]"
    />
    <FieldType
      v-model="field.type"
      :button-width="27"
      :editable="editable && !defaultField"
      :button-classes="'px-1'"
      :menu-classes="'bg-white rounded-t-none'"
      @update:model-value="[maybeUpdateOptions(), $emit('change')]"
      @click="selectedAreasRef.value = [area]"
    />
    <span
      v-if="field.type !== 'checkbox' || field.name"
      ref="name"
      :contenteditable="editable && !defaultField && field.type !== 'heading'"
      dir="auto"
      class="pr-1 cursor-text outline-none block"
      style="min-width: 2px"
      @paste.prevent="onPaste"
      @keydown.enter.prevent="onNameEnter"
      @focus="onNameFocus"
      @blur="onNameBlur"
    >{{ optionIndexText }} {{ (defaultField ? (defaultField.title || field.title || field.name) : field.name) || defaultName }}</span>
    <div
      v-if="isSettingsFocus || isSelectInput || (isValueInput && field.type !== 'heading') || (isNameFocus && !['checkbox', 'phone'].includes(field.type))"
      class="flex items-center ml-1.5"
    >
      <input
        v-if="!isValueInput && !isSelectInput"
        :id="`required-checkbox-${field.uuid}`"
        v-model="field.required"
        type="checkbox"
        class="checkbox checkbox-xs no-animation rounded"
        @mousedown.prevent
      >
      <label
        v-if="!isValueInput && !isSelectInput"
        :for="`required-checkbox-${field.uuid}`"
        class="label text-xs"
        @click.prevent="field.required = !field.required"
        @mousedown.prevent
      >{{ t('required') }}</label>
      <input
        v-if="isValueInput || isSelectInput"
        :id="`readonly-checkbox-${field.uuid}`"
        type="checkbox"
        class="checkbox checkbox-xs no-animation rounded"
        :checked="!(field.readonly ?? true)"
        @change="field.readonly = !(field.readonly ?? true)"
        @mousedown.prevent
      >
      <label
        v-if="isValueInput || isSelectInput"
        :for="`readonly-checkbox-${field.uuid}`"
        class="label text-xs"
        @click.prevent="field.readonly = !(field.readonly ?? true)"
        @mousedown.prevent
      >{{ t('editable') }}</label>
      <span
        v-if="field.type !== 'payment' && !isValueInput"
        class="dropdown dropdown-end field-area-settings-dropdown"
        @mouseenter="renderDropdown = true"
        @touchstart="renderDropdown = true"
      >
        <label
          ref="settingsButton"
          tabindex="0"
          :title="t('settings')"
          class="cursor-pointer flex items-center"
          style="height: 25px"
          @focus="isSettingsFocus = true"
          @blur="maybeBlurSettings"
        >
          <IconDotsVertical class="w-5 h-5" />
        </label>
        <ul
          v-if="renderDropdown"
          ref="settingsDropdown"
          tabindex="0"
          class="dropdown-content menu menu-xs px-2 pb-2 pt-1 shadow rounded-box w-52 z-10 rounded-t-none"
          :style="{ backgroundColor: 'white' }"
          @dragstart.prevent.stop
          @click="closeDropdown"
          @focusout="maybeBlurSettings"
        >
          <FieldSettings
            v-if="isMobile"
            :field="field"
            :default-field="defaultField"
            :editable="editable"
            :background-color="'white'"
            :with-required="false"
            :with-areas="false"
            :with-signature-id="withSignatureId"
            :with-prefillable="withPrefillable"
            @click-formula="isShowFormulaModal = true"
            @click-font="isShowFontModal = true"
            @click-description="isShowDescriptionModal = true"
            @add-custom-field="$emit('add-custom-field')"
            @click-condition="isShowConditionsModal = true"
            @save="$emit('change')"
            @scroll-to="[selectedAreasRef.value = [$event], $emit('scroll-to', $event)]"
          />
          <div
            v-else
            class="whitespace-normal"
          >
            The dots menu is retired in favor of the field context menu. Right-click the field to access field settings. Double-click the field to set a default value.
          </div>
        </ul>
      </span>
    </div>
    <button
      v-else-if="editable"
      class="pr-1"
      :title="t('remove')"
      @click.prevent="$emit('remove')"
    >
      <IconX width="14" />
    </button>
    <Teleport
      v-if="isShowFormulaModal"
      :to="modalContainerEl"
    >
      <FormulaModal
        :field="field"
        :editable="editable && !defaultField"
        :default-field="defaultField"
        :build-default-name="buildDefaultName"
        @save="$emit('change')"
        @close="isShowFormulaModal = false"
      />
    </Teleport>
    <Teleport
      v-if="isShowFontModal"
      :to="modalContainerEl"
    >
      <FontModal
        :field="field"
        :editable="editable && !defaultField"
        :default-field="defaultField"
        :build-default-name="buildDefaultName"
        @save="$emit('change')"
        @close="isShowFontModal = false"
      />
    </Teleport>
    <Teleport
      v-if="isShowConditionsModal"
      :to="modalContainerEl"
    >
      <ConditionsModal
        :item="field"
        :build-default-name="buildDefaultName"
        :default-field="defaultField"
        @save="$emit('change')"
        @close="isShowConditionsModal = false"
      />
    </Teleport>
    <Teleport
      v-if="isShowDescriptionModal"
      :to="modalContainerEl"
    >
      <DescriptionModal
        :field="field"
        :editable="editable && !defaultField"
        :default-field="defaultField"
        :build-default-name="buildDefaultName"
        @save="$emit('change')"
        @close="isShowDescriptionModal = false"
      />
    </Teleport>
  </div>
</template>

<script>
import FieldSubmitter from './field_submitter'
import FieldType from './field_type'
import Field from './field'
import FieldSettings from './field_settings'
import FormulaModal from './formula_modal'
import FontModal from './font_modal'
import ConditionsModal from './conditions_modal'
import DescriptionModal from './description_modal'
import { IconX, IconDotsVertical } from '@tabler/icons-vue'
import { v4 } from 'uuid'

export default {
  name: 'AreaTitle',
  components: {
    FieldType,
    FieldSettings,
    FormulaModal,
    FontModal,
    IconDotsVertical,
    DescriptionModal,
    ConditionsModal,
    FieldSubmitter,
    IconX
  },
  inject: ['t'],
  props: {
    template: {
      type: Object,
      required: true
    },
    selectedAreasRef: {
      type: Object,
      required: true
    },
    getFieldTypeIndex: {
      type: Function,
      required: true
    },
    area: {
      type: Object,
      required: true
    },
    field: {
      type: Object,
      required: false,
      default: null
    },
    defaultField: {
      type: Object,
      required: false,
      default: null
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
    },
    defaultSubmitters: {
      type: Array,
      required: false,
      default: () => []
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    },
    isMobile: {
      type: Boolean,
      required: false,
      default: false
    },
    isValueInput: {
      type: Boolean,
      required: false,
      default: false
    },
    isSelectInput: {
      type: Boolean,
      required: false,
      default: false
    }
  },
  emits: ['remove', 'scroll-to', 'add-custom-field', 'change'],
  data () {
    return {
      isShowFormulaModal: false,
      isShowFontModal: false,
      isShowConditionsModal: false,
      isShowDescriptionModal: false,
      isSettingsFocus: false,
      renderDropdown: false,
      isNameFocus: false
    }
  },
  computed: {
    fieldNames: FieldType.computed.fieldNames,
    fieldLabels: FieldType.computed.fieldLabels,
    submitter () {
      return this.template.submitters.find((s) => s.uuid === this.field.submitter_uuid)
    },
    isSelected () {
      return this.selectedAreasRef.value.includes(this.area)
    },
    isInMultiSelection () {
      return this.selectedAreasRef.value.length >= 2 && this.isSelected
    },
    optionIndexText () {
      if (this.area.option_uuid && this.field.options) {
        return `${this.field.options.findIndex((o) => o.uuid === this.area.option_uuid) + 1}.`
      } else {
        return ''
      }
    },
    defaultName () {
      return this.buildDefaultName(this.field)
    },
    modalContainerEl () {
      return this.$el.getRootNode().querySelector('#docuseal_modal_container')
    }
  },
  methods: {
    buildDefaultName: Field.methods.buildDefaultName,
    closeDropdown () {
      this.$el.getRootNode().activeElement.blur()
    },
    maybeBlurSettings (e) {
      if (!e.relatedTarget || !this.$refs.settingsDropdown.contains(e.relatedTarget)) {
        this.isSettingsFocus = false
      }
    },
    onNameFocus (e) {
      this.selectedAreasRef.value = [this.area]

      this.isNameFocus = true
      this.$refs.name.style.minWidth = this.$refs.name.clientWidth + 'px'

      if (!this.field.name) {
        setTimeout(() => {
          this.$refs.name.innerText = ' '
        }, 1)
      }
    },
    onNameBlur (e) {
      if (e.relatedTarget === this.$refs.settingsButton) {
        this.isSettingsFocus = true
      }

      const text = this.$refs.name.innerText.trim()

      this.isNameFocus = false
      this.$refs.name.style.minWidth = ''

      if (text) {
        this.field.name = text
      } else {
        this.field.name = ''
        this.$refs.name.innerText = this.defaultName
      }

      this.$emit('change')
    },
    onNameEnter (e) {
      this.$refs.name.blur()
    },
    onPaste (e) {
      const text = (e.clipboardData || window.clipboardData).getData('text/plain')
      const selection = this.$el.getRootNode().getSelection()

      if (selection.rangeCount) {
        selection.deleteFromDocument()
        selection.getRangeAt(0).insertNode(document.createTextNode(text))
        selection.collapseToEnd()
      }
    },
    maybeUpdateOptions () {
      delete this.field.default_value

      if (!['radio', 'multiple', 'select'].includes(this.field.type)) {
        delete this.field.options
      }

      if (this.field.type === 'heading') {
        this.field.readonly = true
      }

      if (this.field.type === 'strikethrough') {
        this.field.readonly = true
        this.field.default_value = true
      }

      if (['select', 'multiple', 'radio'].includes(this.field.type)) {
        this.field.options ||= [{ value: '', uuid: v4() }]
      }

      (this.field.areas || []).forEach((area) => {
        if (this.field.type === 'cells') {
          area.cell_w = area.w * 2 / Math.floor(area.w / area.h)
        } else {
          delete area.cell_w
        }
      })
    }
  }
}
</script>

<template>
  <div
    class="list-field group mb-2"
  >
    <div
      class="border border-base-300 rounded relative group fields-list-item"
      :style="{ backgroundColor: backgroundColor }"
    >
      <div class="flex items-center justify-between relative group/contenteditable-container">
        <div
          class="absolute top-0 bottom-0 right-0 left-0 cursor-pointer"
          @click="scrollToFirstArea"
        />
        <div class="flex items-center p-1 space-x-1">
          <FieldType
            v-model="field.type"
            :editable="editable && !defaultField"
            :button-width="20"
            :menu-classes="'mt-1.5'"
            :menu-style="{ backgroundColor: dropdownBgColor }"
            @update:model-value="[maybeUpdateOptions(), save()]"
            @click="scrollToFirstArea"
          />
          <Contenteditable
            ref="name"
            :model-value="(defaultField ? (defaultField.title || field.title || field.name) : field.name) || defaultName"
            :editable="editable && !defaultField && field.type != 'heading'"
            :icon-inline="true"
            :icon-width="18"
            :icon-stroke-width="1.6"
            @focus="[onNameFocus(), scrollToFirstArea()]"
            @blur="onNameBlur"
          />
        </div>
        <div
          v-if="isNameFocus"
          class="flex items-center relative"
        >
          <template v-if="field.type != 'phone'">
            <input
              :id="`required-checkbox-${field.uuid}`"
              v-model="field.required"
              type="checkbox"
              class="checkbox checkbox-xs no-animation rounded"
              @mousedown.prevent
            >
            <label
              :for="`required-checkbox-${field.uuid}`"
              class="label text-xs"
              @click.prevent="field.required = !field.required"
              @mousedown.prevent
            >{{ t('required') }}</label>
          </template>
        </div>
        <div
          v-else-if="editable"
          class="flex items-center space-x-1"
        >
          <button
            v-if="field && !field.areas?.length"
            :title="t('draw')"
            class="relative cursor-pointer text-transparent group-hover:text-base-content"
            @click="$emit('set-draw', { field })"
          >
            <IconNewSection
              :width="18"
              :stroke-width="1.6"
            />
          </button>
          <button
            v-if="field.preferences?.formula"
            class="relative cursor-pointer text-transparent group-hover:text-base-content"
            :title="t('formula')"
            @click="isShowFormulaModal = true"
          >
            <IconMathFunction
              :width="18"
              :stroke-width="1.6"
            />
          </button>
          <button
            v-if="field.conditions?.length"
            class="relative cursor-pointer text-transparent group-hover:text-base-content"
            :title="t('condition')"
            @click="isShowConditionsModal = true"
          >
            <IconRouteAltLeft
              :width="18"
              :stroke-width="1.6"
            />
          </button>
          <PaymentSettings
            v-if="field.type === 'payment'"
            :field="field"
            @click-condition="isShowConditionsModal = true"
            @click-description="isShowDescriptionModal = true"
            @click-formula="isShowFormulaModal = true"
          />
          <span
            v-else
            class="dropdown dropdown-end field-settings-dropdown"
            @mouseenter="renderDropdown = true"
            @touchstart="renderDropdown = true"
          >
            <label
              tabindex="0"
              :title="t('settings')"
              class="cursor-pointer text-transparent group-hover:text-base-content"
            >
              <IconSettings
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
                :default-field="defaultField"
                :editable="editable"
                :with-signature-id="withSignatureId"
                :with-prefillable="withPrefillable"
                :background-color="dropdownBgColor"
                @click-formula="isShowFormulaModal = true"
                @click-font="isShowFontModal = true"
                @click-description="isShowDescriptionModal = true"
                @click-condition="isShowConditionsModal = true"
                @set-draw="$emit('set-draw', $event)"
                @remove-area="removeArea"
                @scroll-to="$emit('scroll-to', $event)"
              />
            </ul>
          </span>
          <button
            class="relative text-transparent group-hover:text-base-content pr-1 field-remove-button"
            :title="t('remove')"
            @click="$emit('remove', field)"
          >
            <IconTrashX
              :width="18"
              :stroke-width="1.6"
            />
          </button>
        </div>
      </div>
      <div
        v-if="field.options && withOptions && (isExpandOptions || field.options.length < 5)"
        ref="options"
        class="border-t border-base-300 mx-2 pt-2 space-y-1.5"
        @dragover="onOptionDragover"
        @drop="reorderOptions"
      >
        <div
          v-for="(option, index) in field.options"
          :key="option.uuid"
          class="flex space-x-1.5 items-center"
          :data-option-uuid="option.uuid"
        >
          <span
            class="text-sm w-3.5 cursor-grab select-none"
            :draggable="editable && !defaultField"
            @dragstart.stop="onOptionDragstart($event, option)"
            @dragend.stop="optionDragRef = null"
            @dragover.prevent.stop="onOptionDragover"
          >
            {{ index + 1 }}.
          </span>
          <div
            v-if="editable && ['radio', 'multiple'].includes(field.type) && (index > 0 || field.areas.find((a) => a.option_uuid) || !field.areas.length) && !field.areas.find((a) => a.option_uuid === option.uuid)"
            class="items-center flex w-full"
          >
            <input
              v-model="option.value"
              class="w-full input input-primary input-xs text-sm bg-transparent !pr-7 -mr-6"
              type="text"
              dir="auto"
              required
              :placeholder="`${t('option')} ${index + 1}`"
              @keydown.enter="option.value ? addOptionAt(index + 1) : null"
              @blur="save"
            >
            <button
              :title="t('draw')"
              tabindex="-1"
              @click.prevent="$emit('set-draw', { field, option })"
            >
              <IconNewSection
                :width="18"
                :stroke-width="1.6"
              />
            </button>
          </div>
          <input
            v-else
            v-model="option.value"
            class="w-full input input-primary input-xs text-sm bg-transparent"
            :placeholder="`${t('option')} ${index + 1}`"
            type="text"
            :readonly="!editable || defaultField"
            required
            dir="auto"
            @keydown.enter="option.value ? addOptionAt(index + 1) : null"
            @focus="maybeFocusOnOptionArea(option)"
            @blur="save"
          >
          <button
            v-if="editable && !defaultField"
            class="text-sm w-3.5"
            tabindex="-1"
            @click="removeOption(option)"
          >
            &times;
          </button>
        </div>
        <div
          v-if="field.options && (!editable || defaultField)"
          class="pb-1"
        />
        <button
          v-else-if="field.options && editable && !defaultField"
          class="field-add-option text-center text-sm w-full pb-1"
          @click="addOptionAt(field.options.length)"
        >
          + {{ t('add_option') }}
        </button>
      </div>
      <div
        v-else-if="field.options && withOptions && !isExpandOptions && field.options.length > 4"
        class="border-t border-base-300 mx-2 space-y-1.5"
      >
        <button
          class="field-expand-options text-center text-sm w-full py-1 flex space-x-0.5 justify-center items-center"
          @click="isExpandOptions = true"
        >
          <span class="lowercase">
            {{ field.options.length }} {{ t('options') }}
          </span>
          <IconChevronDown
            class="ml-2 mr-2 mt-0.5"
            width="15"
            height="15"
          />
        </button>
      </div>
    </div>
    <Teleport
      v-if="isShowFormulaModal"
      :to="modalContainerEl"
    >
      <FormulaModal
        :field="field"
        :editable="editable && !defaultField"
        :default-field="defaultField"
        :build-default-name="buildDefaultName"
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
        @close="isShowFontModal = false"
      />
    </Teleport>
    <Teleport
      v-if="isShowConditionsModal"
      :to="modalContainerEl"
    >
      <ConditionsModal
        :item="field"
        :default-field="defaultField"
        :build-default-name="buildDefaultName"
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
import ConditionsModal from './conditions_modal'
import DescriptionModal from './description_modal'
import { IconRouteAltLeft, IconMathFunction, IconNewSection, IconTrashX, IconSettings, IconChevronDown } from '@tabler/icons-vue'
import { v4 } from 'uuid'

export default {
  name: 'TemplateField',
  components: {
    Contenteditable,
    IconSettings,
    FieldSettings,
    PaymentSettings,
    IconChevronDown,
    IconNewSection,
    FormulaModal,
    FontModal,
    DescriptionModal,
    ConditionsModal,
    IconRouteAltLeft,
    IconTrashX,
    IconMathFunction,
    FieldType
  },
  inject: ['template', 'save', 'backgroundColor', 'selectedAreaRef', 't', 'locale'],
  props: {
    field: {
      type: Object,
      required: true
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
    withOptions: {
      type: Boolean,
      required: false,
      default: true
    },
    defaultField: {
      type: Object,
      required: false,
      default: null
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    }
  },
  emits: ['set-draw', 'remove', 'scroll-to'],
  data () {
    return {
      isExpandOptions: false,
      isNameFocus: false,
      showPaymentModal: false,
      isShowFormulaModal: false,
      isShowFontModal: false,
      isShowConditionsModal: false,
      isShowDescriptionModal: false,
      renderDropdown: false,
      optionDragRef: null
    }
  },
  computed: {
    fieldNames: FieldType.computed.fieldNames,
    fieldLabels: FieldType.computed.fieldLabels,
    dropdownBgColor () {
      return ['', null, 'transparent'].includes(this.backgroundColor) ? 'white' : this.backgroundColor
    },
    schemaAttachmentsIndexes () {
      return (this.template.schema || []).reduce((acc, item, index) => {
        acc[item.attachment_uuid] = index

        return acc
      }, {})
    },
    sortedAreas () {
      return (this.field.areas || []).sort((a, b) => {
        return this.schemaAttachmentsIndexes[a.attachment_uuid] - this.schemaAttachmentsIndexes[b.attachment_uuid]
      })
    },
    modalContainerEl () {
      return this.$el.getRootNode().querySelector('#docuseal_modal_container')
    },
    defaultName () {
      return this.buildDefaultName(this.field, this.template.fields)
    },
    areas () {
      return this.field.areas || []
    }
  },
  created () {
    this.field.preferences ||= {}

    if (this.field.type === 'date') {
      this.field.preferences.format ||=
       ({ 'de-DE': 'DD.MM.YYYY' }[this.locale] || ((Intl.DateTimeFormat().resolvedOptions().locale.endsWith('-US') || new Intl.DateTimeFormat('en-US', { timeZoneName: 'short' }).format(new Date()).match(/\s(?:CST|CDT|PST|PDT|EST|EDT)$/)) ? 'MM/DD/YYYY' : 'DD/MM/YYYY'))
    }
  },
  methods: {
    removeArea (area) {
      this.field.areas.splice(this.field.areas.indexOf(area), 1)

      this.save()
    },
    buildDefaultName (field, fields) {
      if (field.type === 'payment' && field.preferences?.price && !field.preferences?.formula) {
        const { price, currency } = field.preferences || {}

        const formattedPrice = new Intl.NumberFormat([], {
          style: 'currency',
          currency
        }).format(price)

        return `${this.fieldNames[field.type]} ${formattedPrice}`
      } else {
        const typeIndex = fields.filter((f) => f.type === field.type).indexOf(field)

        if (field.type === 'heading' || field.type === 'strikethrough') {
          return `${this.fieldNames[field.type]} ${typeIndex + 1}`
        } else {
          return `${this.fieldLabels[field.type]} ${typeIndex + 1}`
        }
      }
    },
    onNameFocus (e) {
      this.isNameFocus = true

      if (!this.field.name) {
        setTimeout(() => {
          this.$refs.name.$refs.contenteditable.innerText = ' '
        }, 1)
      }
    },
    maybeFocusOnOptionArea (option) {
      const area = this.field.areas.find((a) => a.option_uuid === option.uuid)

      if (area) {
        this.selectedAreaRef.value = area
      }
    },
    scrollToFirstArea () {
      return this.sortedAreas[0] && this.$emit('scroll-to', this.sortedAreas[0])
    },
    closeDropdown () {
      this.$el.getRootNode().activeElement.blur()
    },
    addOptionAt (index) {
      this.isExpandOptions = true

      const insertAt = index ?? this.field.options.length

      this.field.options.splice(insertAt, 0, { value: '', uuid: v4() })

      this.$nextTick(() => {
        const inputs = this.$refs.options.querySelectorAll('input')

        inputs[insertAt]?.focus()
      })

      this.save()
    },
    removeOption (option) {
      this.field.options.splice(this.field.options.indexOf(option), 1)

      const optionIndex = this.field.areas.findIndex((a) => a.option_uuid === option.uuid)

      if (optionIndex !== -1) {
        this.field.areas.splice(this.field.areas.findIndex((a) => a.option_uuid === option.uuid), 1)
      }

      this.save()
    },
    maybeUpdateOptions () {
      delete this.field.default_value

      if (!['radio', 'multiple', 'select'].includes(this.field.type)) {
        delete this.field.options
      }

      if (['radio', 'multiple', 'select'].includes(this.field.type)) {
        this.field.options ||= [{ value: '', uuid: v4() }]
      }

      if (this.field.type === 'heading') {
        this.field.readonly = true
      }

      if (this.field.type === 'strikethrough') {
        this.field.readonly = true
        this.field.default_value = true
      }

      (this.field.areas || []).forEach((area) => {
        if (this.field.type === 'cells') {
          area.cell_w = area.w * 2 / Math.floor(area.w / area.h)
        } else {
          delete area.cell_w
        }
      })
    },
    onNameBlur (e) {
      const text = this.$refs.name.$refs.contenteditable.innerText.trim()

      if (text) {
        this.field.name = text
      } else {
        this.field.name = ''
        this.$refs.name.$refs.contenteditable.innerText = this.defaultName
      }

      this.isNameFocus = false

      this.save()
    },
    onOptionDragstart (event, option) {
      this.optionDragRef = option

      const root = this.$el.getRootNode()
      const hiddenEl = document.createElement('div')

      hiddenEl.style.width = '1px'
      hiddenEl.style.height = '1px'
      hiddenEl.style.opacity = '0'
      hiddenEl.style.position = 'fixed'

      root.querySelector('#docuseal_modal_container')?.appendChild(hiddenEl)
      event.dataTransfer?.setDragImage(hiddenEl, 0, 0)

      setTimeout(() => { hiddenEl.remove() }, 1000)

      event.dataTransfer.effectAllowed = 'move'
    },
    onOptionDragover (e) {
      if (!this.optionDragRef) return

      e.preventDefault()
      e.stopPropagation()

      const targetRow = e.target.closest('[data-option-uuid]')

      if (!targetRow) return

      const dragRow = this.$refs.options?.querySelector(`[data-option-uuid="${this.optionDragRef.uuid}"]`)

      if (!dragRow) return
      if (targetRow === dragRow) return

      const rows = Array.from(this.$refs.options.querySelectorAll('[data-option-uuid]'))

      const currentIndex = rows.indexOf(dragRow)
      const targetIndex = rows.indexOf(targetRow)

      if (currentIndex < targetIndex) {
        targetRow.after(dragRow)
      } else {
        targetRow.before(dragRow)
      }
    },
    reorderOptions (e) {
      if (!this.optionDragRef) return

      e.preventDefault()
      e.stopPropagation()

      const rows = Array.from(this.$refs.options.querySelectorAll('[data-option-uuid]'))

      const newOrder = rows
        .map((el) => this.field.options.find((opt) => opt.uuid === el.dataset.optionUuid))
        .filter(Boolean)

      if (newOrder.length === this.field.options.length) {
        this.field.options.splice(0, this.field.options.length, ...newOrder)

        this.save()
      }

      this.optionDragRef = null
    }
  }
}
</script>

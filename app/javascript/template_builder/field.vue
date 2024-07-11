<template>
  <div
    class="list-field group mb-2"
  >
    <div
      class="border border-base-300 rounded rounded-tr-none relative group"
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
            :editable="editable && !defaultField && field.type != 'heading'"
            :button-width="20"
            :menu-classes="'mt-1.5'"
            :menu-style="{ backgroundColor: dropdownBgColor }"
            @update:model-value="[maybeUpdateOptions(), save()]"
            @click="scrollToFirstArea"
          />
          <Contenteditable
            ref="name"
            :model-value="(defaultField ? (field.title || field.name) : field.name) || defaultName"
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
          />
          <span
            v-else-if="field.type !== 'heading'"
            class="dropdown dropdown-end"
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
                :background-color="dropdownBgColor"
                @click-formula="isShowFormulaModal = true"
                @click-description="isShowDescriptionModal = true"
                @click-condition="isShowConditionsModal = true"
                @set-draw="$emit('set-draw', $event)"
                @scroll-to="$emit('scroll-to', $event)"
              />
            </ul>
          </span>
          <button
            class="relative text-transparent group-hover:text-base-content pr-1"
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
        v-if="field.options"
        ref="options"
        class="border-t border-base-300 mx-2 pt-2 space-y-1.5"
        draggable="true"
        @dragstart.prevent.stop
      >
        <div
          v-for="(option, index) in field.options"
          :key="option.uuid"
          class="flex space-x-1.5 items-center"
        >
          <span class="text-sm w-3.5">
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
            :readonly="!editable"
            required
            dir="auto"
            @focus="maybeFocusOnOptionArea(option)"
            @blur="save"
          >
          <button
            v-if="editable"
            class="text-sm w-3.5"
            tabindex="-1"
            @click="removeOption(option)"
          >
            &times;
          </button>
        </div>
        <div
          v-if="field.options && !editable"
          class="pb-1"
        />
        <button
          v-else-if="field.options && editable"
          class="text-center text-sm w-full pb-1"
          @click="addOption"
        >
          + {{ t('add_option') }}
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
        :build-default-name="buildDefaultName"
        @close="isShowFormulaModal = false"
      />
    </Teleport>
    <Teleport
      v-if="isShowConditionsModal"
      :to="modalContainerEl"
    >
      <ConditionsModal
        :field="field"
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
import ConditionsModal from './conditions_modal'
import DescriptionModal from './description_modal'
import { IconRouteAltLeft, IconMathFunction, IconNewSection, IconTrashX, IconSettings } from '@tabler/icons-vue'
import { v4 } from 'uuid'

export default {
  name: 'TemplateField',
  components: {
    Contenteditable,
    IconSettings,
    FieldSettings,
    PaymentSettings,
    IconNewSection,
    FormulaModal,
    DescriptionModal,
    ConditionsModal,
    IconRouteAltLeft,
    IconTrashX,
    IconMathFunction,
    FieldType
  },
  inject: ['template', 'save', 'backgroundColor', 'selectedAreaRef', 't'],
  props: {
    field: {
      type: Object,
      required: true
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
      isNameFocus: false,
      showPaymentModal: false,
      isShowFormulaModal: false,
      isShowConditionsModal: false,
      isShowDescriptionModal: false,
      renderDropdown: false
    }
  },
  computed: {
    fieldNames: FieldType.computed.fieldNames,
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
        (Intl.DateTimeFormat().resolvedOptions().locale.endsWith('-US') || new Intl.DateTimeFormat('en-US', { timeZoneName: 'short' }).format(new Date()).match(/\s(?:CST|CDT|PST|PDT|EST|EDT)$/) ? 'MM/DD/YYYY' : 'DD/MM/YYYY')
    }
  },
  methods: {
    buildDefaultName (field, fields) {
      if (field.type === 'payment' && field.preferences?.price) {
        const { price, currency } = field.preferences || {}

        const formattedPrice = new Intl.NumberFormat([], {
          style: 'currency',
          currency
        }).format(price)

        return `${this.fieldNames[field.type]} ${formattedPrice}`
      } else {
        const typeIndex = fields.filter((f) => f.type === field.type).indexOf(field)

        if (this.field.type === 'heading') {
          return `${this.fieldNames[field.type]} ${typeIndex + 1}`
        } else {
          const suffix = { multiple: this.t('select'), radio: this.t('group') }[field.type] || this.t('field')
          return `${this.fieldNames[field.type]} ${suffix} ${typeIndex + 1}`
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
      document.activeElement.blur()
    },
    addOption () {
      this.field.options.push({ value: '', uuid: v4() })

      this.$nextTick(() => {
        const inputs = this.$refs.options.querySelectorAll('input')

        inputs[inputs.length - 1]?.focus()
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

      if (['heading'].includes(this.field.type)) {
        this.field.readonly = true
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
    }
  }
}
</script>

<template>
  <div>
    <div
      v-if="!isShowFormulaModal && !isShowFontModal && !isShowConditionsModal && !isShowDescriptionModal && !isShowCustomValidationModal && !isShowLengthValidationModal && !isShowNumberRangeModal && !isShowPriceModal && !isShowPaymentLinkModal"
      ref="menu"
      class="fixed z-50 p-1 bg-base-300 shadow-lg rounded-lg border border-neutral-200 cursor-default"
      style="min-width: 170px"
      :style="menuStyle"
      @mousedown.stop
      @pointerdown.stop
    >
      <label
        v-if="showRequired"
        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm cursor-pointer"
        @click.stop
      >
        <input
          :checked="isRequired"
          type="checkbox"
          class="toggle toggle-xs"
          :disabled="!editable || (defaultField && [true, false].includes(defaultField.required))"
          @change="handleToggleRequired($event.target.checked)"
          @click.stop
        >
        <span>{{ t('required') }}</span>
      </label>
      <label
        v-if="showReadOnly"
        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm cursor-pointer"
        @click.stop
      >
        <input
          :checked="isReadOnly"
          type="checkbox"
          class="toggle toggle-xs"
          :disabled="!editable || (defaultField && [true, false].includes(defaultField.readonly))"
          @change="handleToggleReadOnly($event.target.checked)"
          @click.stop
        >
        <span>{{ t('read_only') }}</span>
      </label>
      <label
        v-if="showPrefillable"
        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm cursor-pointer"
        @click.stop
      >
        <input
          :checked="field.prefillable"
          type="checkbox"
          class="toggle toggle-xs"
          :disabled="!editable || (defaultField && [true, false].includes(defaultField.prefillable))"
          @change="handleTogglePrefillable($event.target.checked)"
          @click.stop
        >
        <span>{{ t('prefillable') }}</span>
      </label>
      <label
        v-if="showSetSigningDate"
        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm cursor-pointer"
        @click.stop
      >
        <input
          :checked="field.readonly && field.default_value === '{{date}}'"
          type="checkbox"
          class="toggle toggle-xs"
          @change="handleToggleSetSigningDate($event.target.checked)"
          @click.stop
        >
        <span>{{ t('set_signing_date') }}</span>
      </label>
      <label
        v-if="showWithLogo"
        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm cursor-pointer"
        @click.stop
      >
        <input
          :checked="field.preferences?.with_logo !== false"
          type="checkbox"
          class="toggle toggle-xs"
          @change="handleToggleWithLogo($event.target.checked)"
          @click.stop
        >
        <span>{{ t('with_logo') }}</span>
      </label>
      <label
        v-if="showSignatureId"
        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm cursor-pointer"
        @click.stop
      >
        <input
          :checked="field.preferences?.with_signature_id"
          type="checkbox"
          class="toggle toggle-xs"
          :disabled="!editable || (defaultField && [true, false].includes(defaultField.required))"
          @change="handleToggleSignatureId($event.target.checked)"
          @click.stop
        >
        <span>{{ t('signature_id') }}</span>
      </label>
      <label
        v-if="showChecked"
        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm cursor-pointer"
        @click.stop
      >
        <input
          :checked="field.default_value"
          type="checkbox"
          class="toggle toggle-xs"
          @change="handleToggleChecked($event.target.checked)"
          @click.stop
        >
        <span>{{ t('checked') }}</span>
      </label>
      <ContextSubmenu
        v-if="showVerificationMethod"
        :icon="IconId"
        :label="t('method')"
        :options="methodOptions"
        :model-value="currentVerificationMethod"
        @select="handleSelectVerificationMethod"
      />
      <hr
        v-if="showRequired || showReadOnly || showPrefillable || showSetSigningDate || showWithLogo || showSignatureId"
        class="my-1 border-neutral-200"
      >
      <ContextSubmenu
        v-if="showFormatSubmenu"
        :icon="IconAdjustmentsHorizontal"
        :label="t('format')"
        :options="formatOptions"
        :model-value="currentFormat"
        @select="handleSelectFormat"
      />
      <ContextSubmenu
        v-if="showValidationSubmenu && field.type !== 'number'"
        :icon="IconInputCheck"
        :label="t('validation')"
        :options="validationMenuItems.map(k => ({ value: k, label: t(k) }))"
        :model-value="currentValidationKey"
        @select="handleSelectValidation"
      />
      <button
        v-if="field.type === 'number'"
        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm"
        @click.stop="openNumberRangeModal"
      >
        <IconInputCheck class="w-4 h-4" />
        <span>{{ t('validation') }}</span>
      </button>
      <ContextSubmenu
        v-if="showPaymentSettings"
        :icon="IconCash"
        :label="t('currency')"
        :options="currencyOptions"
        :model-value="currentCurrency"
        @select="handleSelectCurrency"
      />
      <ContextSubmenu
        v-if="showPaymentSettings"
        :icon="IconCoins"
        :label="t('price')"
        :options="priceTypeOptions"
        :model-value="currentPriceType"
        @select="handleSelectPriceType"
      />
      <button
        v-if="showFont"
        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm"
        @click.stop="openFontModal"
      >
        <IconTypography class="w-4 h-4" />
        <span>{{ t('font') }}</span>
      </button>
      <button
        v-if="showDescription"
        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm"
        @click.stop="openDescriptionModal"
      >
        <IconInfoCircle class="w-4 h-4" />
        <span>{{ t('description') }}</span>
      </button>
      <button
        v-if="showCondition"
        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center justify-between text-sm"
        @click.stop="openConditionModal"
      >
        <span class="flex items-center space-x-2">
          <IconRouteAltLeft class="w-4 h-4" />
          <span>{{ t('condition') }}</span>
        </span>
        <span
          v-if="field.conditions?.length"
          class="bg-neutral-200 rounded px-1 leading-3"
          style="font-size: 9px;"
        >{{ field.conditions.length }}</span>
      </button>
      <button
        v-if="showFormula"
        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm"
        @click.stop="openFormulaModal"
      >
        <IconMathFunction class="w-4 h-4" />
        <span>{{ t('formula') }}</span>
      </button>
      <hr
        v-if="(showFont || showDescription || showCondition || showFormula || showPaymentSettings)"
        class="my-1 border-neutral-200"
      >
      <button
        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center justify-between text-sm"
        @click.stop="$emit('copy')"
      >
        <span class="flex items-center space-x-2">
          <IconCopy class="w-4 h-4" />
          <span>{{ t('copy') }}</span>
        </span>
        <span class="text-xs text-base-content/60 ml-4">{{ isMac ? '⌘C' : 'Ctrl+C' }}</span>
      </button>
      <button
        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center justify-between text-sm text-red-600"
        @click.stop="$emit('delete')"
      >
        <span class="flex items-center space-x-2">
          <IconTrashX class="w-4 h-4" />
          <span>{{ t('remove') }}</span>
        </span>
        <span class="text-xs text-base-content/60 ml-4">Del</span>
      </button>
      <ContextSubmenu
        v-if="showMoreSubmenu"
        :icon="IconDots"
        :label="t('more')"
      >
        <button
          v-if="showDrawNewArea"
          class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm cursor-pointer"
          @click="handleMoreSelect('draw_new_area')"
        >
          <IconNewSection class="w-4 h-4" />
          <span class="whitespace-nowrap">{{ t('draw_new_area') }}</span>
        </button>
        <button
          v-if="showCopyToAllPages"
          class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm cursor-pointer"
          @click="handleMoreSelect('copy_to_all_pages')"
        >
          <IconCopy class="w-4 h-4" />
          <span class="whitespace-nowrap">{{ t('copy_to_all_pages') }}</span>
        </button>
        <button
          v-if="showSaveAsCustom"
          class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm cursor-pointer"
          @click="handleMoreSelect('save_as_custom')"
        >
          <IconForms class="w-4 h-4" />
          <span class="whitespace-nowrap">{{ t('save_as_custom_field') }}</span>
        </button>
      </ContextSubmenu>
    </div>
    <Teleport
      v-if="isShowFormulaModal"
      :to="modalContainerEl"
    >
      <FormulaModal
        :field="field"
        :editable="editable"
        :build-default-name="buildDefaultName"
        @save="$emit('save')"
        @close="closeModal"
      />
    </Teleport>
    <Teleport
      v-if="isShowFontModal"
      :to="modalContainerEl"
    >
      <FontModal
        :field="field"
        :area="contextMenu.area"
        :editable="editable"
        :build-default-name="buildDefaultName"
        @save="$emit('save')"
        @close="closeModal"
      />
    </Teleport>
    <Teleport
      v-if="isShowConditionsModal"
      :to="modalContainerEl"
    >
      <ConditionsModal
        :item="field"
        :build-default-name="buildDefaultName"
        @save="$emit('save')"
        @close="closeModal"
      />
    </Teleport>
    <Teleport
      v-if="isShowDescriptionModal"
      :to="modalContainerEl"
    >
      <DescriptionModal
        :field="field"
        :editable="editable"
        :build-default-name="buildDefaultName"
        @save="$emit('save')"
        @close="closeModal"
      />
    </Teleport>
    <ContextModal
      v-if="isShowCustomValidationModal"
      :title="`${t('custom_validation')} - ${modalFieldName}`"
      :modal-container-el="modalContainerEl"
      @close="closeValidationModal"
      @save="saveCustomValidation"
    >
      <div class="space-y-1 mb-1">
        <div>
          <label
            dir="auto"
            class="label text-sm"
            for="custom_validation_pattern"
          >
            {{ t('regexp_validation') }}
          </label>
          <input
            id="custom_validation_pattern"
            v-model="customValidationPattern"
            dir="auto"
            type="text"
            class="base-input !text-base w-full"
            :placeholder="t('regexp_validation')"
          >
        </div>
        <div>
          <label
            dir="auto"
            class="label text-sm"
            for="custom_validation_message"
          >
            {{ t('error_message') }}
          </label>
          <input
            id="custom_validation_message"
            v-model="customValidationMessage"
            dir="auto"
            :placeholder="t('error_message')"
            class="base-input !text-base w-full"
          >
        </div>
      </div>
    </ContextModal>
    <ContextModal
      v-if="isShowLengthValidationModal"
      :title="`${t('length_validation')} - ${modalFieldName}`"
      :modal-container-el="modalContainerEl"
      @close="closeValidationModal"
      @save="saveLengthValidation"
    >
      <div class="flex space-x-3">
        <div class="flex-1">
          <label
            dir="auto"
            class="label text-sm"
            for="length_validation_min"
          >
            {{ t('min') }}
          </label>
          <input
            id="length_validation_min"
            v-model="lengthValidationMin"
            dir="auto"
            type="number"
            min="0"
            class="base-input !text-base w-full"
            :placeholder="t('min')"
          >
        </div>
        <div class="flex-1">
          <label
            dir="auto"
            class="label text-sm"
            for="length_validation_max"
          >
            {{ t('max') }}
          </label>
          <input
            id="length_validation_max"
            v-model="lengthValidationMax"
            dir="auto"
            type="number"
            min="1"
            class="base-input !text-base w-full"
            :placeholder="t('max')"
          >
        </div>
      </div>
    </ContextModal>
    <ContextModal
      v-if="isShowNumberRangeModal"
      :title="`${t('number_range')} - ${modalFieldName}`"
      :modal-container-el="modalContainerEl"
      @close="closeValidationModal"
      @save="saveNumberRange"
    >
      <div class="flex space-x-3">
        <div class="flex-1">
          <label
            dir="auto"
            class="label text-sm"
            for="number_range_min"
          >
            {{ t('min') }}
          </label>
          <input
            id="number_range_min"
            v-model="numberRangeMin"
            dir="auto"
            type="number"
            class="base-input !text-base w-full"
            :placeholder="t('min')"
          >
        </div>
        <div class="flex-1">
          <label
            dir="auto"
            class="label text-sm"
            for="number_range_max"
          >
            {{ t('max') }}
          </label>
          <input
            id="number_range_max"
            v-model="numberRangeMax"
            dir="auto"
            type="number"
            class="base-input !text-base w-full"
            :placeholder="t('max')"
          >
        </div>
      </div>
    </ContextModal>
    <ContextModal
      v-if="isShowPriceModal"
      :title="`${t('price')} - ${modalFieldName}`"
      :modal-container-el="modalContainerEl"
      @close="closeValidationModal"
      @save="savePrice"
    >
      <div>
        <input
          id="price_value"
          v-model="priceValue"
          dir="auto"
          type="number"
          class="base-input !text-base w-full"
          :placeholder="t('price')"
        >
      </div>
    </ContextModal>
    <ContextModal
      v-if="isShowPaymentLinkModal"
      :title="`${t('payment_link')} - ${modalFieldName}`"
      :modal-container-el="modalContainerEl"
      @close="closeValidationModal"
      @save="savePaymentLink"
    >
      <div>
        <input
          id="payment_link_value"
          v-model="paymentLinkValue"
          dir="auto"
          type="text"
          class="base-input !text-base w-full"
          placeholder="plink_XXXXX"
        >
      </div>
    </ContextModal>
  </div>
</template>

<script>
import { IconCopy, IconTrashX, IconTypography, IconInfoCircle, IconRouteAltLeft, IconMathFunction, IconAdjustmentsHorizontal, IconInputCheck, IconDots, IconNewSection, IconForms, IconId, IconCash, IconCoins } from '@tabler/icons-vue'
import FormulaModal from './formula_modal'
import FontModal from './font_modal'
import ConditionsModal from './conditions_modal'
import DescriptionModal from './description_modal'
import Field from './field'
import FieldType from './field_type.vue'
import FieldSettings from './field_settings.vue'
import ContextSubmenu from './field_context_submenu.vue'
import ContextModal from './field_context_modal.vue'

export default {
  name: 'FieldContextMenu',
  components: {
    IconCopy,
    IconTrashX,
    IconTypography,
    IconInfoCircle,
    IconRouteAltLeft,
    IconMathFunction,
    IconInputCheck,
    IconNewSection,
    IconForms,
    FormulaModal,
    FontModal,
    ConditionsModal,
    DescriptionModal,
    ContextSubmenu,
    ContextModal
  },
  inject: ['t', 'getFieldTypeIndex', 'template', 'withCustomFields', 'currencies'],
  props: {
    contextMenu: {
      type: Object,
      required: true
    },
    field: {
      type: Object,
      required: true
    },
    editable: {
      type: Boolean,
      default: true
    },
    withPrefillable: {
      type: Boolean,
      default: false
    },
    withSignatureId: {
      type: Boolean,
      default: null
    },
    withRequired: {
      type: Boolean,
      default: true
    },
    withCondition: {
      type: Boolean,
      default: true
    },
    withCopyToAllPages: {
      type: Boolean,
      default: true
    },
    defaultField: {
      type: Object,
      required: false,
      default: null
    }
  },
  emits: ['copy', 'delete', 'close', 'set-draw', 'add-custom-field', 'scroll-to', 'save'],
  data () {
    return {
      isShowFormulaModal: false,
      isShowFontModal: false,
      isShowConditionsModal: false,
      isShowDescriptionModal: false,
      isShowCustomValidationModal: false,
      isShowLengthValidationModal: false,
      isShowNumberRangeModal: false,
      isShowPriceModal: false,
      isShowPaymentLinkModal: false,
      customValidationPattern: '',
      customValidationMessage: '',
      lengthValidationMin: '',
      lengthValidationMax: '',
      numberRangeMin: '',
      numberRangeMax: '',
      priceValue: '',
      paymentLinkValue: ''
    }
  },
  computed: {
    fieldNames: FieldType.computed.fieldNames,
    fieldLabels: FieldType.computed.fieldLabels,
    validationOptions: FieldSettings.computed.validations,
    dateFormats: FieldSettings.computed.dateFormats,
    numberFormats: FieldSettings.computed.numberFormats,
    prefillableFieldTypes: FieldSettings.computed.prefillableFieldTypes,
    verificationMethods: FieldSettings.computed.verificationMethods,
    modalContainerEl () {
      return this.$el.getRootNode().querySelector('#docuseal_modal_container')
    },
    modalFieldName () {
      return (this.defaultField ? (this.defaultField.title || this.field.title || this.field.name) : this.field.name) || this.buildDefaultName(this.field)
    },
    isMac () {
      return (navigator.userAgentData?.platform || navigator.platform)?.toLowerCase()?.includes('mac')
    },
    menuStyle () {
      return {
        left: this.contextMenu.x + 'px',
        top: this.contextMenu.y + 'px'
      }
    },
    showFont () {
      return ['text', 'number', 'date', 'select', 'heading', 'cells'].includes(this.field.type)
    },
    showDescription () {
      return !['stamp', 'heading', 'strikethrough'].includes(this.field.type)
    },
    showCondition () {
      return this.withCondition && !['stamp', 'heading'].includes(this.field.type)
    },
    showFormula () {
      return this.field.type === 'number' || this.field.type === 'payment'
    },
    showRequired () {
      return this.withRequired && !['phone', 'stamp', 'verification', 'strikethrough', 'heading'].includes(this.field.type)
    },
    showReadOnly () {
      return ['text', 'number', 'radio', 'multiple', 'select'].includes(this.field.type)
    },
    isRequired () {
      return this.field.required || false
    },
    isReadOnly () {
      return this.field.readonly || false
    },
    showFormatSubmenu () {
      return ['date', 'number', 'signature'].includes(this.field.type)
    },
    showValidationSubmenu () {
      return ['text', 'cells', 'number'].includes(this.field.type)
    },
    showPrefillable () {
      return this.withPrefillable && this.prefillableFieldTypes.includes(this.field.type)
    },
    showSetSigningDate () {
      return this.field.type === 'date'
    },
    showWithLogo () {
      return this.field.type === 'stamp'
    },
    showSignatureId () {
      return [true, false].includes(this.withSignatureId) && this.field.type === 'signature'
    },
    showChecked () {
      return this.field.type === 'checkbox'
    },
    showVerificationMethod () {
      return this.field.type === 'verification'
    },
    lengthValidation () {
      return this.parseLengthPattern(this.field.validation?.pattern)
    },
    currentValidationKey () {
      if (!this.field.validation?.pattern) return 'none'

      if (this.lengthValidation) return 'length'

      const matchedKey = Object.keys(this.validationOptions).find(
        key => this.validationOptions[key] !== 'length' && key === this.field.validation.pattern
      )

      if (matchedKey) return this.validationOptions[matchedKey]

      return 'custom'
    },
    validationMenuItems () {
      return ['none', ...Object.values(this.validationOptions), 'custom']
    },
    signatureFormats () {
      return ['any', ...FieldSettings.computed.signatureFormats.call(this)]
    },
    currentDateFormat () {
      return this.field.preferences?.format || 'MM/DD/YYYY'
    },
    currentNumberFormat () {
      return this.field.preferences?.format || 'none'
    },
    currentSignatureFormat () {
      return this.field.preferences?.format || 'any'
    },
    currentVerificationMethod () {
      return this.field.preferences?.method || 'qes'
    },
    methodOptions () {
      return this.verificationMethods.map(m => ({ value: m.toLowerCase(), label: m }))
    },
    formatOptions () {
      switch (this.field.type) {
        case 'date': return this.dateFormats.map(f => ({ value: f, label: this.formatDate(new Date(), f) }))
        case 'number': return this.numberFormats.map(f => ({ value: f, label: this.formatNumber(123456789.567, f) }))
        case 'signature': return this.signatureFormats.map(f => ({ value: f, label: this.t(f) }))
        default: return []
      }
    },
    currentFormat () {
      switch (this.field.type) {
        case 'date': return this.currentDateFormat
        case 'number': return this.currentNumberFormat
        case 'signature': return this.currentSignatureFormat
        default: return null
      }
    },
    showPaymentSettings () {
      return this.field.type === 'payment'
    },
    defaultCurrencies () {
      return ['USD', 'EUR', 'GBP', 'CAD', 'AUD']
    },
    currenciesList () {
      return this.currencies?.length ? this.currencies : this.defaultCurrencies
    },
    currencyOptions () {
      return this.currenciesList.map(c => ({ value: c, label: c }))
    },
    currentCurrency () {
      return this.field.preferences?.currency || 'USD'
    },
    priceTypeOptions () {
      return [
        { value: 'one_off', label: this.t('fixed') },
        { value: 'formula', label: this.t('formula') },
        { value: 'payment_link', label: this.t('payment_link') }
      ]
    },
    currentPriceType () {
      if (this.field.preferences?.formula) {
        return 'formula'
      }

      if ('payment_link_id' in (this.field.preferences || {})) {
        return 'payment_link'
      }

      if (this.field.preferences?.price) {
        return 'one_off'
      }

      return ''
    },
    showDrawNewArea () {
      return !this.field.areas?.length || !['radio', 'multiple'].includes(this.field.type)
    },
    showCopyToAllPages () {
      return this.withCopyToAllPages && this.field.areas?.length === 1 && ['date', 'signature', 'initials', 'text', 'cells', 'stamp'].includes(this.field.type)
    },
    showSaveAsCustom () {
      return this.withCustomFields
    },
    showMoreSubmenu () {
      return this.showDrawNewArea || this.showCopyToAllPages || this.showSaveAsCustom
    }
  },
  mounted () {
    document.addEventListener('keydown', this.onKeyDown)
    document.addEventListener('mousedown', this.handleClickOutside)

    this.$nextTick(() => {
      this.checkMenuPosition()
    })
  },
  beforeUnmount () {
    document.removeEventListener('keydown', this.onKeyDown)
    document.removeEventListener('mousedown', this.handleClickOutside)
  },
  methods: {
    IconAdjustmentsHorizontal,
    IconInputCheck,
    IconDots,
    IconId,
    IconCash,
    IconCoins,
    buildDefaultName: Field.methods.buildDefaultName,
    formatNumber: FieldSettings.methods.formatNumber,
    formatDate: FieldSettings.methods.formatDate,
    parseLengthPattern: FieldSettings.methods.parseLengthPattern,
    checkMenuPosition () {
      if (this.$refs.menu) {
        const rect = this.$refs.menu.getBoundingClientRect()
        const overflow = rect.bottom - window.innerHeight

        if (overflow > 0) {
          this.contextMenu.y = this.contextMenu.y - overflow - 4
        }
      }
    },
    handleToggleRequired (value) {
      this.field.required = value
      this.$emit('save')
    },
    handleToggleReadOnly (value) {
      this.field.readonly = value
      this.$emit('save')
    },
    onKeyDown (event) {
      if (event.key === 'Escape') {
        event.preventDefault()
        event.stopPropagation()

        this.$emit('close')
      }
    },
    handleClickOutside (event) {
      if (this.$refs.menu && !this.$refs.menu.contains(event.target)) {
        this.$emit('close')
      }
    },
    openFontModal () {
      this.isShowFontModal = true
    },
    openDescriptionModal () {
      this.isShowDescriptionModal = true
    },
    openConditionModal () {
      this.isShowConditionsModal = true
    },
    openFormulaModal () {
      this.isShowFormulaModal = true
    },
    closeModal () {
      this.isShowFormulaModal = false
      this.isShowFontModal = false
      this.isShowConditionsModal = false
      this.isShowDescriptionModal = false

      this.$emit('close')
    },
    handleSelectValidation (key) {
      if (key === 'none') {
        delete this.field.validation
      } else if (key === 'custom') {
        this.customValidationPattern = this.field.validation?.pattern || ''
        this.customValidationMessage = this.field.validation?.message || ''
        this.isShowCustomValidationModal = true
        return
      } else if (key === 'length') {
        const existingLength = this.lengthValidation

        this.lengthValidationMin = existingLength?.min || ''
        this.lengthValidationMax = existingLength?.max || ''
        this.isShowLengthValidationModal = true

        return
      } else {
        this.field.validation ||= {}
        this.field.validation.pattern = Object.keys(this.validationOptions).find(k => this.validationOptions[k] === key)

        delete this.field.validation.message
      }

      this.$emit('save')
      this.$emit('close')
    },
    handleSelectFormat (format) {
      this.field.preferences ||= {}
      this.field.preferences.format = format

      this.$emit('save')
      this.$emit('close')
    },
    handleTogglePrefillable (value) {
      this.field.prefillable = value

      this.$emit('save')
    },
    handleToggleSetSigningDate (value) {
      this.field.default_value = value ? '{{date}}' : null
      this.field.readonly = value

      this.$emit('save')
    },
    handleToggleWithLogo (value) {
      this.field.preferences ||= {}
      this.field.preferences.with_logo = value

      this.$emit('save')
    },
    handleToggleSignatureId (value) {
      this.field.preferences ||= {}
      this.field.preferences.with_signature_id = value

      this.$emit('save')
    },
    handleToggleChecked (value) {
      this.field.default_value = value
      this.field.readonly = value

      this.$emit('save')
    },
    handleSelectVerificationMethod (method) {
      this.field.preferences ||= {}
      this.field.preferences.method = method

      this.$emit('save')
      this.$emit('close')
    },
    openNumberRangeModal () {
      this.numberRangeMin = this.field.validation?.min || ''
      this.numberRangeMax = this.field.validation?.max || ''
      this.isShowNumberRangeModal = true
    },
    saveCustomValidation () {
      this.field.validation = {
        pattern: this.customValidationPattern,
        message: this.customValidationMessage
      }

      this.isShowCustomValidationModal = false

      this.$emit('save')
      this.$emit('close')
    },
    saveLengthValidation () {
      const min = this.lengthValidationMin || '0'
      const max = this.lengthValidationMax || ''

      this.field.validation = { pattern: `.{${min},${max}}` }

      this.isShowLengthValidationModal = false

      this.$emit('save')
      this.$emit('close')
    },
    saveNumberRange () {
      this.field.validation ||= {}

      if (this.numberRangeMin) {
        this.field.validation.min = this.numberRangeMin
      } else {
        delete this.field.validation.min
      }

      if (this.numberRangeMax) {
        this.field.validation.max = this.numberRangeMax
      } else {
        delete this.field.validation.max
      }

      this.isShowNumberRangeModal = false

      this.$emit('save')
      this.$emit('close')
    },
    closeValidationModal () {
      this.isShowCustomValidationModal = false
      this.isShowLengthValidationModal = false
      this.isShowNumberRangeModal = false
      this.isShowPriceModal = false
      this.isShowPaymentLinkModal = false
    },
    handleSelectCurrency (currency) {
      this.field.preferences ||= {}
      this.field.preferences.currency = currency

      this.$emit('save')
      this.$emit('close')
    },
    handleSelectPriceType (type) {
      this.field.preferences ||= {}

      if (type === 'one_off') {
        this.priceValue = this.field.preferences.price || ''
        this.isShowPriceModal = true
      } else if (type === 'payment_link') {
        this.paymentLinkValue = this.field.preferences.payment_link_id || ''
        this.isShowPaymentLinkModal = true
      } else if (type === 'formula') {
        this.openFormulaModal()
      }
    },
    savePrice () {
      this.field.preferences ||= {}
      this.field.preferences.price = this.priceValue

      delete this.field.preferences.payment_link_id
      delete this.field.preferences.formula

      this.isShowPriceModal = false

      this.$emit('save')
      this.$emit('close')
    },
    savePaymentLink () {
      this.field.preferences ||= {}
      this.field.preferences.payment_link_id = this.paymentLinkValue

      delete this.field.preferences.price
      delete this.field.preferences.formula

      this.isShowPaymentLinkModal = false

      this.$emit('save')
      this.$emit('close')
    },
    handleMoreSelect (value) {
      if (value === 'draw_new_area') {
        this.$emit('set-draw', { field: this.field })
        this.$emit('close')
      } else if (value === 'save_as_custom') {
        this.$emit('add-custom-field', this.field)
        this.$emit('close')
      } else if (value === 'copy_to_all_pages') {
        this.copyToAllPages(this.field)
        this.$emit('close')
      }
    },
    copyToAllPages: FieldSettings.methods.copyToAllPages
  }
}
</script>

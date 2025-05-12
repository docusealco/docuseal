<template>
  <span
    class="dropdown field-types-dropdown"
    @mouseenter="renderDropdown = true"
    @touchstart="renderDropdown = true"
  >
    <slot>
      <label
        tabindex="0"
        :title="fieldNames[modelValue]"
        class="cursor-pointer"
      >
        <component
          :is="fieldIcons[modelValue]"
          :width="buttonWidth"
          :class="buttonClasses"
          :stroke-width="1.6"
        />
      </label>
    </slot>
    <ul
      v-if="editable && renderDropdown"
      tabindex="0"
      class="dropdown-content menu menu-xs p-2 shadow rounded-box w-52 z-10 mb-3"
      :style="menuStyle"
      :class="menuClasses"
      @click="closeDropdown"
    >
      <template
        v-for="(icon, type) in fieldIconsSorted"
        :key="type"
      >
        <li v-if="fieldTypes.includes(type) || ((withPhone || type != 'phone') && (withPayment || type != 'payment') && (withVerification || type != 'verification'))">
          <a
            href="#"
            class="text-sm py-1 px-2"
            :class="{ 'active': type === modelValue }"
            @click.prevent="$emit('update:model-value', type)"
          >
            <component
              :is="icon"
              :stroke-width="1.6"
              :width="20"
            />
            {{ fieldNames[type] }}
          </a>
        </li>
      </template>
    </ul>
  </span>
</template>

<script>
import { IconTextSize, IconWritingSign, IconCalendarEvent, IconPhoto, IconCheckbox, IconPaperclip, IconSelect, IconCircleDot, IconChecks, IconColumns3, IconPhoneCheck, IconLetterCaseUpper, IconCreditCard, IconRubberStamp, IconSquareNumber1, IconHeading, IconId } from '@tabler/icons-vue'

export default {
  name: 'FiledTypeDropdown',
  inject: ['withPhone', 'withPayment', 'withVerification', 't', 'fieldTypes'],
  props: {
    modelValue: {
      type: String,
      required: true
    },
    menuClasses: {
      type: String,
      required: false,
      default: 'mt-1.5 bg-base-100'
    },
    menuStyle: {
      type: Object,
      required: false,
      default: () => ({})
    },
    buttonClasses: {
      type: String,
      required: false,
      default: ''
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    },
    buttonWidth: {
      type: Number,
      required: false,
      default: 18
    }
  },
  emits: ['update:model-value'],
  data () {
    return {
      renderDropdown: false
    }
  },
  computed: {
    fieldNames () {
      return {
        heading: this.t('heading'),
        text: this.t('text'),
        signature: this.t('signature'),
        initials: this.t('initials'),
        date: this.t('date'),
        number: this.t('number'),
        image: this.t('image'),
        file: this.t('file'),
        select: this.t('select'),
        checkbox: this.t('checkbox'),
        multiple: this.t('multiple'),
        radio: this.t('radio'),
        cells: this.t('cells'),
        stamp: this.t('stamp'),
        payment: this.t('payment'),
        phone: this.t('phone'),
        verification: this.t('verify_id')
      }
    },
    fieldLabels () {
      return {
        text: this.t('text_field'),
        signature: this.t('signature_field'),
        initials: this.t('initials_field'),
        date: this.t('date_field'),
        number: this.t('number_field'),
        image: this.t('image_field'),
        file: this.t('file_field'),
        select: this.t('select_field'),
        checkbox: this.t('checkbox_field'),
        multiple: this.t('multiple_field'),
        radio: this.t('radio_field'),
        cells: this.t('cells_field'),
        stamp: this.t('stamp_field'),
        payment: this.t('payment_field'),
        phone: this.t('phone_field'),
        verification: this.t('verify_id')
      }
    },
    fieldIcons () {
      return {
        heading: IconHeading,
        text: IconTextSize,
        signature: IconWritingSign,
        initials: IconLetterCaseUpper,
        date: IconCalendarEvent,
        number: IconSquareNumber1,
        image: IconPhoto,
        checkbox: IconCheckbox,
        multiple: IconChecks,
        file: IconPaperclip,
        radio: IconCircleDot,
        select: IconSelect,
        cells: IconColumns3,
        stamp: IconRubberStamp,
        payment: IconCreditCard,
        phone: IconPhoneCheck,
        verification: IconId
      }
    },
    fieldIconsSorted () {
      if (this.fieldTypes.length) {
        return this.fieldTypes.reduce((acc, type) => {
          acc[type] = this.fieldIcons[type]

          return acc
        }, {})
      } else {
        return Object.fromEntries(Object.entries(this.fieldIcons).filter(([key]) => key !== 'heading'))
      }
    }
  },
  methods: {
    closeDropdown () {
      this.$el.getRootNode().activeElement.blur()
    }
  }
}
</script>

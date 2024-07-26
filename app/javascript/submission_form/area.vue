<template>
  <div
    class="field-area flex absolute lg:text-base -outline-offset-1"
    dir="auto"
    :style="computedStyle"
    :class="{ 'text-[1.6vw] lg:text-base': !textOverflowChars, 'text-[1.0vw] lg:text-xs': textOverflowChars, 'cursor-default': !submittable, 'border border-red-100 bg-red-100 cursor-pointer': submittable, 'border border-red-100': !isActive && submittable, 'bg-opacity-80': !isActive && !isValueSet && submittable, 'field-area-active outline-red-500 outline-dashed outline-2 z-10': isActive && submittable, 'bg-opacity-40': (isActive || isValueSet) && submittable }"
  >
    <div
      v-if="(!withFieldPlaceholder || !field.name || field.type === 'cells') && !isActive && !isValueSet && field.type !== 'checkbox' && submittable && !area.option_uuid"
      class="absolute top-0 bottom-0 right-0 left-0 items-center justify-center h-full w-full"
    >
      <span
        v-if="field"
        class="flex justify-center items-center h-full opacity-50"
      >
        <component
          :is="fieldIcons[field.type]"
          width="100%"
          height="100%"
          class="max-h-10 text-base-content"
        />
      </span>
    </div>
    <div
      v-if="isActive && withLabel && (!area.option_uuid || !option.value)"
      class="absolute -top-7 rounded bg-base-content text-base-100 px-2 text-sm whitespace-nowrap pointer-events-none"
    >
      <template v-if="area.option_uuid && !option.value">
        {{ optionValue(option) }}
      </template>
      <template v-else>
        {{ field.name || fieldNames[field.type] }}
        <template v-if="field.type === 'checkbox' && !field.name">
          {{ fieldIndex + 1 }}
        </template>
        <template v-else-if="!field.required && field.type !== 'checkbox'">
          (optional)
        </template>
      </template>
    </div>
    <div
      v-if="isActive"
      ref="scrollToElem"
      class="absolute"
      :style="{ top: scrollPadding }"
    />
    <img
      v-if="field.type === 'image' && image"
      class="object-contain mx-auto"
      :src="image.url"
    >
    <img
      v-else-if="field.type === 'stamp' && stamp"
      class="object-contain mx-auto"
      :src="stamp.url"
    >
    <div
      v-else-if="field.type === 'signature' && signature"
      class="flex flex-col justify-between h-full overflow-hidden"
    >
      <div
        class="flex-grow flex overflow-hidden"
        style="min-height: 50%"
      >
        <img
          class="object-contain mx-auto"
          :src="signature.url"
        >
      </div>
      <div
        v-if="withSignatureId"
        class="w-full mt-1 text-[1vw] lg:text-[0.55rem] lg:leading-[0.65rem]"
      >
        <div class="truncate uppercase">
          ID: {{ signature.uuid }}
        </div>
        <div>
          {{ t('reason') }}: {{ t('digitally_signed_by') }} {{ submitter.name }}
          <template v-if="submitter.email">
            &lt;{{ submitter.email }}&gt;
          </template>
        </div>
        <div>
          {{ new Date(signature.created_at).toLocaleString(undefined, { year: 'numeric', month: 'short', day: 'numeric', hour: 'numeric', minute: 'numeric', timeZoneName: 'short' }) }}
        </div>
      </div>
    </div>
    <img
      v-else-if="field.type === 'initials' && initials"
      class="object-contain mx-auto"
      :src="initials.url"
    >
    <div
      v-else-if="(field.type === 'file' || field.type === 'payment') && attachments.length"
      class="px-0.5 flex flex-col justify-center"
    >
      <a
        v-for="(attachment, index) in attachments"
        :key="index"
        target="_blank"
        :href="attachment.url"
      >
        <IconPaperclip
          class="inline w-[1.6vw] h-[1.6vw] lg:w-4 lg:h-4"
        />
        {{ attachment.filename }}
      </a>
    </div>
    <div
      v-else-if="field.type === 'checkbox'"
      class="w-full p-[1px] flex items-center justify-center"
      @click="$event.target.querySelector('input')?.click()"
    >
      <input
        v-if="submittable"
        type="checkbox"
        :value="false"
        class="aspect-square base-checkbox"
        :class="{ '!w-auto !h-full': area.w > area.h, '!w-full !h-auto': area.w <= area.h }"
        :checked="!!modelValue"
        @click="$emit('update:model-value', !modelValue)"
      >
      <IconCheck
        v-else-if="modelValue"
        class="aspect-square"
        :class="{ '!w-auto !h-full': area.w > area.h, '!w-full !h-auto': area.w <= area.h }"
      />
    </div>
    <div
      v-else-if="field.type === 'radio' && area.option_uuid"
      class="w-full p-[1px] flex items-center justify-center"
      @click="$event.target.querySelector('input')?.click()"
    >
      <input
        v-if="submittable"
        type="radio"
        :value="false"
        class="aspect-square checked:checkbox checked:checkbox-xs"
        :class="{ 'base-radio': !modelValue || modelValue !== optionValue(option), '!w-auto !h-full': area.w > area.h, '!w-full !h-auto': area.w <= area.h }"
        :checked="!!modelValue && modelValue === optionValue(option)"
        @click="$emit('update:model-value', optionValue(option))"
      >
      <IconCheck
        v-else-if="!!modelValue && modelValue === optionValue(option)"
        class="aspect-square"
        :class="{ '!w-auto !h-full': area.w > area.h, '!w-full !h-auto': area.w <= area.h }"
      />
    </div>
    <div
      v-else-if="field.type === 'multiple' && area.option_uuid"
      class="w-full p-[1px] flex items-center justify-center"
      @click="$event.target.querySelector('input')?.click()"
    >
      <input
        v-if="submittable"
        type="checkbox"
        :value="false"
        class="aspect-square base-checkbox"
        :class="{ '!w-auto !h-full': area.w > area.h, '!w-full !h-auto': area.w <= area.h }"
        :checked="!!modelValue && modelValue.includes(optionValue(option))"
        @change="updateMultipleSelectValue(optionValue(option))"
      >
      <IconCheck
        v-else-if="!!modelValue && modelValue.includes(optionValue(option))"
        class="aspect-square"
        :class="{ '!w-auto !h-full': area.w > area.h, '!w-full !h-auto': area.w <= area.h }"
      />
    </div>
    <div
      v-else-if="field.type === 'cells'"
      class="w-full flex items-center"
    >
      <div
        v-for="(char, index) in modelValue"
        :key="index"
        class="text-center flex-none"
        :style="{ width: (area.cell_w / area.w * 100) + '%' }"
      >
        {{ char }}
      </div>
    </div>
    <div
      v-else
      ref="textContainer"
      dir="auto"
      class="flex items-center px-0.5 w-full"
      :class="alignClasses[field.preferences?.align]"
    >
      <span
        v-if="field && field.name && withFieldPlaceholder && !modelValue && modelValue !== 0"
        class="whitespace-pre-wrap text-gray-400"
        :class="{ 'w-full': field.preferences?.align }"
      >{{ field.name }}</span>
      <span v-else-if="Array.isArray(modelValue)">
        {{ modelValue.join(', ') }}
      </span>
      <span v-else-if="field.type === 'date'">
        {{ formattedDate }}
      </span>
      <span v-else-if="field.type === 'number'">
        {{ formatNumber(modelValue, field.preferences?.format) }}
      </span>
      <span
        v-else
        class="whitespace-pre-wrap"
        :class="{ 'w-full': field.preferences?.align }"
      >{{ modelValue }}</span>
    </div>
  </div>
</template>

<script>
import { IconTextSize, IconWritingSign, IconCalendarEvent, IconPhoto, IconCheckbox, IconPaperclip, IconSelect, IconCircleDot, IconChecks, IconCheck, IconColumns3, IconPhoneCheck, IconLetterCaseUpper, IconCreditCard, IconRubberStamp, IconSquareNumber1 } from '@tabler/icons-vue'

export default {
  name: 'FieldArea',
  components: {
    IconPaperclip,
    IconCheck
  },
  inject: ['t'],
  props: {
    field: {
      type: Object,
      required: true
    },
    submitter: {
      type: Object,
      required: true
    },
    withSignatureId: {
      type: Boolean,
      required: false,
      default: false
    },
    isValueSet: {
      type: Boolean,
      required: false,
      default: false
    },
    scrollPadding: {
      type: String,
      required: false,
      default: '-80px'
    },
    withFieldPlaceholder: {
      type: Boolean,
      required: false,
      default: false
    },
    submittable: {
      type: Boolean,
      required: false,
      default: false
    },
    modelValue: {
      type: [Array, String, Number, Object, Boolean],
      required: false,
      default: ''
    },
    isActive: {
      type: Boolean,
      required: false,
      default: false
    },
    withLabel: {
      type: Boolean,
      required: false,
      default: true
    },
    fieldIndex: {
      type: Number,
      required: false,
      default: 0
    },
    attachmentsIndex: {
      type: Object,
      required: false,
      default: () => ({})
    },
    area: {
      type: Object,
      required: true
    }
  },
  emits: ['update:model-value'],
  data () {
    return {
      textOverflowChars: 0
    }
  },
  computed: {
    fieldNames () {
      return {
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
        phone: this.t('phone')
      }
    },
    alignClasses () {
      return {
        center: 'text-center',
        left: 'text-left',
        right: 'text-right'
      }
    },
    option () {
      return this.field.options.find((o) => o.uuid === this.area.option_uuid)
    },
    fieldIcons () {
      return {
        text: IconTextSize,
        signature: IconWritingSign,
        date: IconCalendarEvent,
        number: IconSquareNumber1,
        image: IconPhoto,
        initials: IconLetterCaseUpper,
        file: IconPaperclip,
        select: IconSelect,
        checkbox: IconCheckbox,
        radio: IconCircleDot,
        stamp: IconRubberStamp,
        cells: IconColumns3,
        multiple: IconChecks,
        phone: IconPhoneCheck,
        payment: IconCreditCard
      }
    },
    image () {
      if (this.field.type === 'image') {
        return this.attachmentsIndex[this.modelValue]
      } else {
        return null
      }
    },
    stamp () {
      if (this.field.type === 'stamp') {
        return this.attachmentsIndex[this.modelValue]
      } else {
        return null
      }
    },
    signature () {
      if (this.field.type === 'signature') {
        return this.attachmentsIndex[this.modelValue]
      } else {
        return null
      }
    },
    initials () {
      if (this.field.type === 'initials') {
        return this.attachmentsIndex[this.modelValue]
      } else {
        return null
      }
    },
    locale () {
      return Intl.DateTimeFormat().resolvedOptions()?.locale
    },
    formattedDate () {
      if (this.field.type === 'date' && this.modelValue) {
        return this.formatDate(
          this.modelValue === '{{date}}' ? new Date() : new Date(this.modelValue),
          this.field.preferences?.format || (this.locale.endsWith('-US') ? 'MM/DD/YYYY' : 'DD/MM/YYYY')
        )
      } else {
        return ''
      }
    },
    attachments () {
      if (this.field.type === 'file') {
        return (this.modelValue || []).map((uuid) => this.attachmentsIndex[uuid])
      } else if (this.field.type === 'payment') {
        return [this.attachmentsIndex[this.modelValue]].filter(Boolean)
      } else {
        return []
      }
    },
    computedStyle () {
      const { x, y, w, h } = this.area

      const style = {
        top: y * 100 + '%',
        left: x * 100 + '%',
        width: w * 100 + '%',
        height: h * 100 + '%'
      }

      if (this.field.preferences?.font_size) {
        style.fontSize = this.field.preferences.font_size + 'pt'
      }

      return style
    }
  },
  watch: {
    modelValue () {
      this.$nextTick(() => {
        if (['date', 'text', 'number'].includes(this.field.type) && this.$refs.textContainer && (this.textOverflowChars === 0 || (this.textOverflowChars - 4) > `${this.modelValue}`.length)) {
          this.textOverflowChars = this.$refs.textContainer.scrollHeight > this.$refs.textContainer.clientHeight ? `${this.modelValue || (this.withFieldPlaceholder ? this.field.name : '')}`.length : 0
        }
      })
    }
  },
  mounted () {
    this.$nextTick(() => {
      if (['date', 'text', 'number'].includes(this.field.type) && this.$refs.textContainer) {
        this.textOverflowChars = this.$refs.textContainer.scrollHeight > this.$refs.textContainer.clientHeight ? `${this.modelValue || (this.withFieldPlaceholder ? this.field.name : '')}`.length : 0
      }
    })
  },
  methods: {
    optionValue (option) {
      if (option) {
        if (option.value) {
          return option.value
        } else {
          const index = this.field.options.indexOf(option)

          return `${this.t('option')} ${index + 1}`
        }
      }
    },
    formatNumber (number, format) {
      if (format === 'comma') {
        return new Intl.NumberFormat('en-US').format(number)
      } else if (format === 'dot') {
        return new Intl.NumberFormat('de-DE').format(number)
      } else if (format === 'space') {
        return new Intl.NumberFormat('fr-FR').format(number)
      } else {
        return number
      }
    },
    formatDate (date, format) {
      const monthFormats = {
        M: 'numeric',
        MM: '2-digit',
        MMM: 'short',
        MMMM: 'long'
      }

      const dayFormats = {
        D: 'numeric',
        DD: '2-digit'
      }

      const yearFormats = {
        YYYY: 'numeric',
        YYY: 'numeric',
        YY: '2-digit'
      }

      const parts = new Intl.DateTimeFormat([], {
        day: dayFormats[format.match(/D+/)],
        month: monthFormats[format.match(/M+/)],
        year: yearFormats[format.match(/Y+/)],
        timeZone: 'UTC'
      }).formatToParts(date)

      return format
        .replace(/D+/, parts.find((p) => p.type === 'day').value)
        .replace(/M+/, parts.find((p) => p.type === 'month').value)
        .replace(/Y+/, parts.find((p) => p.type === 'year').value)
    },
    updateMultipleSelectValue (value) {
      if (this.modelValue?.includes(value)) {
        const newValue = [...this.modelValue]

        newValue.splice(newValue.indexOf(value), 1)

        this.$emit('update:model-value', newValue)
      } else {
        const newValue = this.modelValue ? [...this.modelValue] : []

        newValue.push(value)

        this.$emit('update:model-value', newValue)
      }
    }
  }
}
</script>

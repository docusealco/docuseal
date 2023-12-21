<template>
  <div
    v-if="field.type === 'redact'"
    class="flex absolute"
    :style="{ ...computedStyle, backgroundColor: 'black' }"
    :class="{ 'cursor-default ': !submittable, 'border ': submittable, 'z-0 ': isActive && submittable, 'bg-opacity-100 ': (isActive || isValueSet) && submittable }"
  >
    <div
      v-if="!isActive && !isValueSet && field.type !== 'checkbox' && submittable"
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
          class="max-h-10 text-base-content text-white"
        />
      </span>
    </div>
  </div>
  <!-- show myText prefill with stored value -->
  <div
    v-else-if="field.type === 'my_text'"
    class="flex absolute"
    :style="{ ...computedStyle, backgroundColor: 'transparent' }"
    :class="{ 'cursor-default ': !submittable, 'z-0 ': isActive && submittable, 'bg-opacity-100 ': (isActive || isValueSet) && submittable }"
  >
    <span
      style="--tw-bg-opacity: 1; --tw-border-opacity: 0.2; font-size: 1.4rem"
      class="!text-2xl w-full h-full"
      v-text="showLocalText"
    />
  </div>

  <!-- show myDate prefill with stored value -->
  <div
    v-else-if="field.type === 'my_date'"
    class="flex absolute"
    :style="{ ...computedStyle, backgroundColor: 'transparent' }"
    :class="{ 'cursor-default ': !submittable, 'z-0 ': isActive && submittable, 'bg-opacity-100 ': (isActive || isValueSet) && submittable }"
  >
    <span
      style="--tw-bg-opacity: 1; --tw-border-opacity: 0.2; font-size: 1.4rem"
      class="flex items-center px-0.5 w-full h-full"
    >
      {{ getFormattedDate }}
    </span>
  </div>

  <!-- show mySignature and myInitial prefill with stored value -->
  <div
    v-else-if="['my_signature', 'my_initials'].includes(field.type)"
    class="flex absolute"
    :style="computedStyle"
    :class="{ 'text-[1.5vw] lg:text-base': !textOverflowChars, 'text-[1.0vw] lg:text-xs': textOverflowChars, 'cursor-default': !submittable, 'bg-red-100 border cursor-pointer ': submittable, 'border-red-100': !isActive && submittable, 'bg-opacity-70': !isActive && !isValueSet && submittable, 'border-red-500 border-dashed z-10': isActive && submittable, 'bg-opacity-30': (isActive || isValueSet) && submittable }"
  >
    <img
      v-if="field.type === 'my_signature' && mySignatureUrl"
      class="mx-auto"
      :src="mySignatureUrl.url"
    >
    <img
      v-else-if="field.type === 'my_initials' && myInitialsUrl"
      class="mx-auto"
      :src="myInitialsUrl.url"
    >
    <img
      v-else
      class="mx-auto"
    >
  </div>

  <!-- show my_check prefill -->
  <div
    v-else-if="field.type === 'my_check'"
    class="flex absolute items-center h-full w-full justify-center"
    :style="{ ...computedStyle, backgroundColor: 'transparent' }"
    :class="{'cursor-default ': !submittable}"
  >
    <span
      style="--tw-bg-opacity: 1; --tw-border-opacity: 0.2; font-size: 1.4rem"
      class="w-full h-full"
    >
      <component
        :is="fieldIcons[field.type]"
        width="100%"
        height="100%"
        class="h-full"
      />
    </span>
  </div>

  <div
    v-else
    class="flex absolute lg:text-base"
    :style="computedStyle"
    :class="{ 'text-[1.5vw] lg:text-base': !textOverflowChars, 'text-[1.0vw] lg:text-xs': textOverflowChars, 'cursor-default': !submittable, 'bg-red-100 border cursor-pointer ': submittable, 'border-red-100': !isActive && submittable, 'bg-opacity-80': !isActive && !isValueSet && submittable, 'border-red-500 border-dashed z-10': isActive && submittable, 'bg-opacity-40': (isActive || isValueSet) && submittable }"
  >
    <div
      v-if="!isActive && !isValueSet && field.type !== 'checkbox' && submittable && !area.option_uuid"
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
      v-if="isActive && withLabel && !area.option_uuid"
      class="absolute -top-7 rounded bg-base-content text-base-100 px-2 text-sm whitespace-nowrap"
    >
      {{ field.name || fieldNames[field.type] }}
      <template v-if="field.type === 'checkbox' && !field.name">
        {{ fieldIndex + 1 }}
      </template>
      <template v-else-if="!field.required && field.type !== 'checkbox'">
        (optional)
      </template>
    </div>
    <div
      v-if="isActive"
      ref="scrollToElem"
      class="absolute -top-20"
    />
    <img
      v-if="field.type === 'image' && image"
      class="object-contain mx-auto"
      :src="image.url"
    >
    <img
      v-else-if="field.type === 'signature' && signature"
      class="object-contain mx-auto"
      :src="signature.url"
    >
    <img
      v-else-if="field.type === 'initials' && initials"
      class="object-contain mx-auto"
      :src="initials.url"
    >
    <div
      v-else-if="field.type === 'file' || field.type === 'payment'"
      class="px-0.5 flex flex-col justify-center"
    >
      <a
        v-for="(attachment, index) in attachments"
        :key="index"
        target="_blank"
        :href="attachment.url"
      >
        <IconPaperclip
          class="inline w-[1.5vw] h-[1.5vw] lg:w-4 lg:h-4"
        />
        {{ attachment.filename }}
      </a>
    </div>
    <div
      v-else-if="field.type === 'checkbox'"
      class="w-full p-[0.2vw] flex items-center justify-center"
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
      class="w-full p-[0.2vw] flex items-center justify-center"
    >
      <input
        v-if="submittable"
        type="radio"
        :value="false"
        class="aspect-square base-radio"
        :class="{ '!w-auto !h-full': area.w > area.h, '!w-full !h-auto': area.w <= area.h }"
        :checked="!!modelValue && modelValue === field.options.find((o) => o.uuid === area.option_uuid)?.value"
        @click="$emit('update:model-value', field.options.find((o) => o.uuid === area.option_uuid)?.value)"
      >
      <IconCheck
        v-else-if="!!modelValue && modelValue === field.options.find((o) => o.uuid === area.option_uuid)?.value"
        class="aspect-square"
        :class="{ '!w-auto !h-full': area.w > area.h, '!w-full !h-auto': area.w <= area.h }"
      />
    </div>
    <div
      v-else-if="field.type === 'multiple' && area.option_uuid"
      class="w-full p-[0.2vw] flex items-center justify-center"
    >
      <input
        v-if="submittable"
        type="checkbox"
        :value="false"
        class="aspect-square base-checkbox"
        :class="{ '!w-auto !h-full': area.w > area.h, '!w-full !h-auto': area.w <= area.h }"
        :checked="!!modelValue && modelValue.includes(field.options.find((o) => o.uuid === area.option_uuid)?.value)"
        @change="updateMultipleSelectValue(field.options.find((o) => o.uuid === area.option_uuid)?.value)"
      >
      <IconCheck
        v-else-if="!!modelValue && modelValue.includes(field.options.find((o) => o.uuid === area.option_uuid)?.value)"
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
      class="flex items-center px-0.5"
    >
      <span v-if="Array.isArray(modelValue)">
        {{ modelValue.join(', ') }}
      </span>
      <span v-else-if="field.type === 'date'">
        {{ formattedDate }}
      </span>
      <span
        v-else
        class="whitespace-pre-wrap"
      >{{ modelValue }}</span>
    </div>
  </div>
</template>

<script>
import { IconTextSize, IconWritingSign, IconCalendarEvent, IconPhoto, IconCheckbox, IconPaperclip, IconSelect, IconCircleDot, IconChecks, IconCheck, IconColumns3, IconPhoneCheck, IconLetterCaseUpper, IconBarrierBlock, IconCreditCard } from '@tabler/icons-vue'

export default {
  name: 'FieldArea',
  components: {
    IconPaperclip,
    IconCheck
  },
  inject: ['templateAttachments'],
  props: {
    field: {
      type: Object,
      required: true
    },
    isValueSet: {
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
    },
    templateValues: {
      type: Object,
      required: false,
      default () {
        return {}
      }
    }
  },
  emits: ['update:model-value'],
  data () {
    return {
      textOverflowChars: 0,
      showLocalText: ''
    }
  },
  computed: {
    fieldNames () {
      return {
        text: 'Text',
        cells: 'Text',
        signature: 'Signature',
        date: 'Date',
        image: 'Image',
        initials: 'Initials',
        file: 'File',
        select: 'Select',
        checkbox: 'Checkbox',
        radio: 'Radio',
        multiple: 'Multiple Select',
        phone: 'Phone',
        redact: 'Redact',
        my_text: 'Text',
        my_signature: 'My Signature',
        my_initials: 'My Initials',
        my_date: 'Date',
        my_check: 'Check',
        payment: 'Payment'
      }
    },
    fieldIcons () {
      return {
        text: IconTextSize,
        signature: IconWritingSign,
        date: IconCalendarEvent,
        image: IconPhoto,
        initials: IconLetterCaseUpper,
        file: IconPaperclip,
        select: IconSelect,
        checkbox: IconCheckbox,
        radio: IconCircleDot,
        cells: IconColumns3,
        multiple: IconChecks,
        phone: IconPhoneCheck,
        redact: IconBarrierBlock,
        my_check: IconCheck,
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
    myAttachmentsIndex () {
      return this.templateAttachments.reduce((acc, a) => {
        acc[a.uuid] = a

        return acc
      }, {})
    },
    mySignatureUrl () {
      if (this.field.type === 'my_signature') {
        return this.myAttachmentsIndex[this.templateValues[this.field.uuid]]
      } else {
        return null
      }
    },
    myInitialsUrl () {
      if (this.field.type === 'my_initials') {
        return this.myAttachmentsIndex[this.templateValues[this.field.uuid]]
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
          new Date(this.modelValue),
          this.field.preferences?.format || (this.locale.endsWith('-US') ? 'MM/DD/YYYY' : 'DD/MM/YYYY')
        )
      } else {
        return ''
      }
    },
    getFormattedDate () {
      if (this.field.type === 'my_date' && this.templateValues[this.field.uuid]) {
        return new Intl.DateTimeFormat([], { year: 'numeric', month: 'long', day: 'numeric', timeZone: 'UTC' }).format(new Date(this.templateValues[this.field.uuid]))
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

      return {
        top: y * 100 + '%',
        left: x * 100 + '%',
        width: w * 100 + '%',
        height: h * 100 + '%'
      }
    }
  },
  watch: {
    modelValue () {
      if (this.field.type === 'text' && this.$refs.textContainer && (this.textOverflowChars === 0 || (this.textOverflowChars - 4) > this.modelValue.length)) {
        this.textOverflowChars = this.$refs.textContainer.scrollHeight > this.$refs.textContainer.clientHeight ? this.modelValue.length : 0
      }
    }
  },
  mounted () {
    if (this.field.type === 'my_text') {
      const fieldUuid = this.field.uuid
      if (this.templateValues && this.templateValues[fieldUuid]) {
        this.showLocalText = this.templateValues[fieldUuid]
      } else {
        this.showLocalText = ''
      }
    }

    if (this.field.type === 'text' && this.$refs.textContainer) {
      this.$nextTick(() => {
        this.textOverflowChars = this.$refs.textContainer.scrollHeight > this.$refs.textContainer.clientHeight ? this.modelValue.length : 0
      })
    }
  },
  methods: {
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

<template>
  <div
    class="flex cursor-pointer bg-red-100 absolute border"
    :style="computedStyle"
    :class="{ 'border-red-100 bg-opacity-70': !isActive, 'border-red-500 border-dashed bg-opacity-30 z-10': isActive }"
  >
    <div
      v-if="!isActive && !modelValue"
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
      v-if="isActive"
      class="absolute -top-7 rounded bg-base-content text-base-100 px-2 text-sm whitespace-nowrap"
    >
      {{ field.name || fieldNames[field.type] }}
    </div>
    <div
      v-if="isActive"
      ref="scrollToElem"
      class="absolute -top-20"
    />
    <img
      v-if="field.type === 'image' && image"
      class="object-contain"
      :src="image.url"
    >
    <img
      v-else-if="field.type === 'signature' && signature"
      class="object-contain"
      :src="signature.url"
    >
    <div v-else-if="field.type === 'attachment'">
      <a
        v-for="(attachment, index) in attachments"
        :key="index"
        :href="attachment.url"
      >
        {{ attachment.filename }}
      </a>
    </div>
    <span v-else>
      {{ modelValue }}
    </span>
  </div>
</template>

<script>
import { IconTextSize, IconWriting, IconCalendarEvent, IconPhoto, IconCheckbox, IconPaperclip, IconSelect, IconCircleDot } from '@tabler/icons-vue'

export default {
  name: 'FieldArea',
  props: {
    field: {
      type: Object,
      required: true
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
  computed: {
    fieldNames () {
      return {
        text: 'Text',
        signature: 'Signature',
        date: 'Date',
        image: 'Image',
        file: 'File',
        select: 'Select',
        checkbox: 'Checkbox',
        radio: 'Radio'
      }
    },
    fieldIcons () {
      return {
        text: IconTextSize,
        signature: IconWriting,
        date: IconCalendarEvent,
        image: IconPhoto,
        file: IconPaperclip,
        select: IconSelect,
        checkbox: IconCheckbox,
        radio: IconCircleDot
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
    attachments () {
      if (this.field.type === 'attachment') {
        return (this.modelValue || []).map((uuid) => this.attachmentsIndex[uuid])
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
  }
}
</script>

<template>
  <span class="dropdown">
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
    <ul
      tabindex="0"
      class="dropdown-content menu menu-xs p-2 shadow rounded-box w-52 z-10"
      :class="menuClasses"
      @click="closeDropdown"
    >
      <li
        v-for="(icon, type) in fieldIcons"
        :key="type"
      >
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
    </ul>
  </span>
</template>

<script>
import { IconTextSize, IconWritingSign, IconCalendarEvent, IconPhoto, IconCheckbox, IconPaperclip, IconSelect, IconCircleDot, IconChecks, IconColumns3 } from '@tabler/icons-vue'

export default {
  name: 'FiledTypeDropdown',
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
    buttonClasses: {
      type: String,
      required: false,
      default: ''
    },
    buttonWidth: {
      type: Number,
      required: false,
      default: 18
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
        multiple: 'Multiple',
        radio: 'Radio',
        cells: 'Cells'
      }
    },
    fieldIcons () {
      return {
        text: IconTextSize,
        signature: IconWritingSign,
        date: IconCalendarEvent,
        image: IconPhoto,
        file: IconPaperclip,
        select: IconSelect,
        checkbox: IconCheckbox,
        cells: IconColumns3,
        multiple: IconChecks,
        radio: IconCircleDot
      }
    }
  },
  methods: {
    closeDropdown () {
      document.activeElement.blur()
    }
  }
}
</script>

<template>
  <div class="mb-1">
    <Field
      v-for="field in fields"
      :key="field.uuid"
      :field="field"
      :type-index="fields.filter((f) => f.type === field.type).indexOf(field)"
      @remove="fields.splice(fields.indexOf($event), 1)"
      @move-up="move(field, -1)"
      @move-down="move(field, 1)"
      @scroll-to="$emit('scroll-to-area', $event)"
      @set-draw="$emit('set-draw', $event)"
    />
  </div>
  <div class="grid grid-cols-3 gap-1">
    <button
      v-for="(icon, type) in fieldIcons"
      :key="type"
      draggable="true"
      class="flex items-center justify-center border border-dashed border-gray-300 bg-base-100 w-full rounded relative"
      @dragstart="onDragstart(type)"
      @dragend="$emit('drag-end')"
      @click="addField(type)"
    >
      <div class="w-0 absolute left-0">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="cursor-grab"
          width="18"
          height="18"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
          fill="none"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path
            stroke="none"
            d="M0 0h24v24H0z"
            fill="none"
          />
          <path d="M9 5m-1 0a1 1 0 1 0 2 0a1 1 0 1 0 -2 0" />
          <path d="M9 12m-1 0a1 1 0 1 0 2 0a1 1 0 1 0 -2 0" />
          <path d="M9 19m-1 0a1 1 0 1 0 2 0a1 1 0 1 0 -2 0" />
          <path d="M15 5m-1 0a1 1 0 1 0 2 0a1 1 0 1 0 -2 0" />
          <path d="M15 12m-1 0a1 1 0 1 0 2 0a1 1 0 1 0 -2 0" />
          <path d="M15 19m-1 0a1 1 0 1 0 2 0a1 1 0 1 0 -2 0" />
        </svg>
      </div>
      <div class="flex items-center flex-col px-2 py-2">
        <component :is="icon" />
        <span class="text-xs mt-1">
          {{ $t(type) }}
        </span>
      </div>
    </button>
  </div>
</template>

<script>
import Field from './field'
import { v4 } from 'uuid'
import FieldType from './field_type'

export default {
  name: 'TemplateFields',
  components: {
    Field
  },
  props: {
    fields: {
      type: Array,
      required: true
    }
  },
  emits: ['set-draw', 'set-drag', 'drag-end', 'scroll-to-area'],
  computed: {
    fieldIcons: FieldType.computed.fieldIcons
  },
  methods: {
    onDragstart (fieldType) {
      this.$emit('set-drag', fieldType)
    },
    move (field, direction) {
      const currentIndex = this.fields.indexOf(field)

      this.fields.splice(currentIndex, 1)

      if (currentIndex + direction > this.fields.length) {
        this.fields.unshift(field)
      } else if (currentIndex + direction < 0) {
        this.fields.push(field)
      } else {
        this.fields.splice(currentIndex + direction, 0, field)
      }
    },
    addField (type, area = null) {
      const field = {
        name: '',
        uuid: v4(),
        required: true,
        type
      }

      if (['select', 'checkbox', 'radio'].includes(type)) {
        field.options = ['']
      }

      this.fields.push(field)
    }
  }
}
</script>

<template>
  <div class="space-y-2">
    <Field
      v-for="field in fields"
      :key="field.uuid"
      class="border"
      :field="field"
      @remove="fields.splice(fields.indexOf($event), 1)"
      @set-draw="$emit('set-draw', $event)"
    />
  </div>
  <button
    v-for="item in fieldTypes"
    :key="item.type"
    draggable="true"
    class="w-full flex items-center justify-center"
    @dragstart="onDragstart(item.value)"
    @dragend="$emit('drag-end')"
    @click="addField(item.value)"
  >
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class="cursor-move"
      width="18"
      height="18"
      viewBox="0 0 24 24"
      stroke-width="2"
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
      <path d="M4 6l16 0" />
      <path d="M4 12l16 0" />
      <path d="M4 18l16 0" />
    </svg>
    Add {{ item.label }}
    &plus;
  </button>
</template>

<script>
import Field from './field'
import { v4 } from 'uuid'

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
  emits: ['set-draw', 'set-drag', 'drag-end'],
  computed: {
    fieldTypes () {
      return [
        { label: 'Text', value: 'text' },
        { label: 'Signature', value: 'signature' },
        { label: 'Date', value: 'date' },
        { label: 'Image', value: 'image' },
        { label: 'Attachment', value: 'attachment' },
        { label: 'Select', value: 'select' },
        { label: 'Checkbox', value: 'checkbox' },
        { label: 'Radio Group', value: 'radio' }
      ]
    }
  },
  methods: {
    onDragstart (fieldType) {
      this.$emit('set-drag', fieldType)
    },
    addField (type, area = null) {
      const field = {
        name: type === 'signature' ? 'Signature' : '',
        uuid: v4(),
        required: true,
        type
      }

      if (['select', 'checkbox', 'radio'].includes(type)) {
        field.options = ['']
      }

      if (area) {
        field.areas = [area]
      }

      this.fields.push(field)
    }
  }
}
</script>

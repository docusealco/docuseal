<template>
  <div class="space-y-2">
    <Field
      v-for="field in fields"
      :key="field.uuid"
      class="border"
      :field="field"
      @set-draw="$emit('set-draw', $event)"
    />
  </div>
  <button
    v-for="item in fieldTypes"
    :key="item.type"
    class="block w-full"
    @click="addField(item.value)"
  >
    Add {{ item.label }}
  </button>
</template>

<script>
import Field from './field'
import { v4 } from 'uuid'

export default {
  name: 'FlowFields',
  components: {
    Field
  },
  props: {
    fields: {
      type: Array,
      required: true
    }
  },
  emits: ['set-draw'],
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
    addField (type) {
      const field = {
        name: type === 'signature' ? 'Signature' : '',
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

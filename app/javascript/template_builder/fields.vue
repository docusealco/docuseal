<template>
  <div class="sticky -top-1 bg-base-100 pt-1 -mt-1 z-10">
    <FieldSubmitter
      :model-value="selectedSubmitter.uuid"
      class="w-full bg-base-100"
      :submitters="submitters"
      @remove="removeSubmitter"
      @update:model-value="$emit('change-submitter', submitters.find((s) => s.uuid === $event))"
    />
  </div>
  <div class="mb-1 mt-2">
    <Field
      v-for="field in submitterFields"
      :key="field.uuid"
      :field="field"
      :type-index="fields.filter((f) => f.type === field.type).indexOf(field)"
      @remove="removeField"
      @move-up="move(field, -1)"
      @move-down="move(field, 1)"
      @scroll-to="$emit('scroll-to-area', $event)"
      @set-draw="$emit('set-draw', $event)"
    />
  </div>
  <div class="grid grid-cols-3 gap-1 pb-2">
    <button
      v-for="(icon, type) in fieldIcons"
      :key="type"
      draggable="true"
      class="flex items-center justify-center border border-dashed border-base-300 bg-base-100 w-full rounded relative"
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
import FieldSubmitter from './field_submitter'

export default {
  name: 'TemplateFields',
  components: {
    Field,
    FieldSubmitter
  },
  props: {
    fields: {
      type: Array,
      required: true
    },
    submitters: {
      type: Array,
      required: true
    },
    selectedSubmitter: {
      type: Object,
      required: true
    }
  },
  emits: ['set-draw', 'set-drag', 'drag-end', 'scroll-to-area', 'change-submitter'],
  computed: {
    fieldIcons: FieldType.computed.fieldIcons,
    submitterFields () {
      return this.fields.filter((f) => f.submitter_uuid === this.selectedSubmitter.uuid)
    }
  },
  methods: {
    onDragstart (fieldType) {
      this.$emit('set-drag', fieldType)
    },
    removeSubmitter (submitter) {
      [...this.fields].forEach((field) => {
        if (field.submitter_uuid === submitter.uuid) {
          this.removeField(field)
        }
      })

      this.submitters.splice(this.submitters.indexOf(submitter), 1)

      if (this.selectedSubmitter === submitter) {
        this.$emit('change-submitter', this.submitters[0])
      }
    },
    move (field, direction) {
      const currentIndex = this.submitterFields.indexOf(field)
      const fieldsIndex = this.fields.indexOf(field)

      this.fields.splice(fieldsIndex, 1)

      if (currentIndex + direction > this.submitterFields.length) {
        const firstIndex = this.fields.indexOf(this.submitterFields[0])

        this.fields.splice(firstIndex, 0, field)
      } else if (currentIndex + direction < 0) {
        const lastIndex = this.fields.indexOf(this.submitterFields[this.submitterFields.length - 1])

        this.fields.splice(lastIndex + 1, 0, field)
      } else {
        this.fields.splice(fieldsIndex + direction, 0, field)
      }
    },
    removeField (field) {
      this.fields.splice(this.fields.indexOf(field), 1)
    },
    addField (type, area = null) {
      const field = {
        name: '',
        uuid: v4(),
        required: true,
        submitter_uuid: this.selectedSubmitter.uuid,
        type
      }

      if (['select', 'multiple', 'radio'].includes(type)) {
        field.options = ['']
      }

      this.fields.push(field)
    }
  }
}
</script>

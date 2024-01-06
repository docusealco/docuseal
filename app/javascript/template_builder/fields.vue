<template>
  <div :class="withStickySubmitters ? 'sticky top-0 z-10' : ''">
    <FieldSubmitter
      :model-value="selectedSubmitter.uuid"
      class="w-full rounded-lg"
      :class="{ 'bg-base-100': withStickySubmitters }"
      :submitters="submitters"
      :editable="editable && !defaultSubmitters.length"
      @new-submitter="save"
      @remove="removeSubmitter"
      @name-change="save"
      @update:model-value="$emit('change-submitter', submitters.find((s) => s.uuid === $event))"
    />
  </div>
  <div
    ref="fields"
    class="mb-1 mt-2"
    @dragover.prevent="onFieldDragover"
    @drop="reorderFields"
  >
    <Field
      v-for="field in submitterFields"
      :key="field.uuid"
      :data-uuid="field.uuid"
      :field="field"
      :type-index="fields.filter((f) => f.type === field.type).indexOf(field)"
      :editable="editable && (!dragField || dragField !== field)"
      :default-field="defaultFields.find((f) => f.name === field.name)"
      :draggable="editable"
      @dragstart="dragField = field"
      @dragend="dragField = null"
      @remove="removeField"
      @scroll-to="$emit('scroll-to-area', $event)"
      @set-draw="$emit('set-draw', $event)"
    />
  </div>
  <div v-if="submitterDefaultFields.length">
    <hr class="mb-2">
    <template
      v-for="field in submitterDefaultFields"
      :key="field.name"
    >
      <div
        :style="{ backgroundColor: backgroundColor }"
        draggable="true"
        class="border border-base-300 rounded rounded-tr-none relative group mb-2"
        @dragstart="onDragstart({ type: 'text', ...field })"
        @dragend="$emit('drag-end')"
      >
        <div class="flex items-center justify-between relative cursor-grab">
          <div class="flex items-center p-1 space-x-1">
            <IconDrag />
            <FieldType
              :model-value="field.type || 'text'"
              :editable="false"
              :button-width="20"
            />
            <span class="block pl-0.5">
              {{ field.name }}
            </span>
          </div>
        </div>
      </div>
    </template>
  </div>
  <div
    v-if="editable && !onlyDefinedFields"
    class="grid grid-cols-3 gap-1 pb-2"
  >
    <template
      v-for="(icon, type) in fieldIcons"
      :key="type"
    >
      <button
        v-if="(withPhone || type != 'phone') && (withPayment || type != 'payment')"
        draggable="true"
        class="group flex items-center justify-center border border-dashed border-base-300 hover:border-base-content/20 w-full rounded relative"
        :style="{ backgroundColor: backgroundColor }"
        @dragstart="onDragstart({ type: type })"
        @dragend="$emit('drag-end')"
        @click="addField(type)"
      >
        <div class="flex items-console group-hover:bg-base-200/50 transition-all cursor-grab h-full absolute left-0">
          <IconDrag class=" my-auto" />
        </div>
        <div class="flex items-center flex-col px-2 py-2">
          <component :is="icon" />
          <span class="text-xs mt-1">
            {{ fieldNames[type] }}
          </span>
        </div>
      </button>
      <div
        v-else-if="type == 'phone'"
        class="tooltip tooltip-bottom flex"
        :class="{'tooltip-bottom-start': !withPayment, 'tooltip-bottom': withPayment }"
        data-tip="Unlock SMS-verified phone number field with paid plan. Use text field for phone numbers without verification."
      >
        <a
          href="https://www.docuseal.co/pricing"
          target="_blank"
          class="opacity-50 flex items-center justify-center border border-dashed border-base-300 w-full rounded relative"
          :style="{ backgroundColor: backgroundColor }"
        >
          <div class="w-0 absolute left-0">
            <IconLock
              width="18"
              height="18"
              stroke-width="1.5"
            />
          </div>
          <div class="flex items-center flex-col px-2 py-2">
            <component :is="icon" />
            <span class="text-xs mt-1">
              {{ fieldNames[type] }}
            </span>
          </div>
        </a>
      </div>
    </template>
  </div>
  <div
    v-if="fields.length < 4 && editable && withHelp"
    class="text-xs p-2 border border-base-200 rounded"
  >
    <ul class="list-disc list-outside ml-3">
      <li>
        Draw a text field on the page with a mouse
      </li>
      <li>
        Drag &amp; drop any other field type on the page
      </li>
      <li>
        Click on the field type above to start drawing it
      </li>
    </ul>
  </div>
</template>

<script>
import Field from './field'
import { v4 } from 'uuid'
import FieldType from './field_type'
import FieldSubmitter from './field_submitter'
import { IconLock } from '@tabler/icons-vue'
import IconDrag from './icon_drag'

export default {
  name: 'TemplateFields',
  components: {
    Field,
    FieldType,
    FieldSubmitter,
    IconDrag,
    IconLock
  },
  inject: ['save', 'backgroundColor', 'withPhone', 'withPayment', 't'],
  props: {
    fields: {
      type: Array,
      required: true
    },
    withHelp: {
      type: Boolean,
      required: false,
      default: true
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    },
    defaultFields: {
      type: Array,
      required: false,
      default: () => []
    },
    onlyDefinedFields: {
      type: Boolean,
      required: false,
      default: true
    },
    defaultSubmitters: {
      type: Array,
      required: false,
      default: () => []
    },
    withStickySubmitters: {
      type: Boolean,
      required: false,
      default: true
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
  data () {
    return {
      dragField: null
    }
  },
  computed: {
    fieldNames: FieldType.computed.fieldNames,
    fieldIcons: FieldType.computed.fieldIcons,
    submitterFields () {
      return this.fields.filter((f) => f.submitter_uuid === this.selectedSubmitter.uuid)
    },
    submitterDefaultFields () {
      return this.defaultFields.filter((f) => {
        return !this.submitterFields.find((field) => field.name === f.name) && (!f.role || f.role === this.selectedSubmitter.name)
      })
    }
  },
  methods: {
    onDragstart (field) {
      this.$emit('set-drag', field)
    },
    onFieldDragover (e) {
      const targetField = e.target.closest('[data-uuid]')
      const dragField = this.$refs.fields.querySelector(`[data-uuid="${this.dragField.uuid}"]`)

      if (dragField && targetField && targetField !== dragField) {
        const fields = Array.from(this.$refs.fields.children)
        const currentIndex = fields.indexOf(dragField)
        const targetIndex = fields.indexOf(targetField)

        if (currentIndex < targetIndex) {
          targetField.after(dragField)
        } else {
          targetField.before(dragField)
        }
      }
    },
    reorderFields () {
      Array.from(this.$refs.fields.children).forEach((el, index) => {
        if (el.dataset.uuid !== this.fields[index].uuid) {
          const field = this.fields.find((f) => f.uuid === el.dataset.uuid)

          this.fields.splice(this.fields.indexOf(field), 1)
          this.fields.splice(index, 0, field)
        }
      })

      this.save()
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

      this.save()
    },
    removeField (field) {
      this.fields.splice(this.fields.indexOf(field), 1)

      this.save()
    },
    addField (type, area = null) {
      const field = {
        name: '',
        uuid: v4(),
        required: type !== 'checkbox',
        areas: [],
        submitter_uuid: this.selectedSubmitter.uuid,
        type
      }

      if (['select', 'multiple', 'radio'].includes(type)) {
        field.options = [{ value: '', uuid: v4() }]
      }

      if (type === 'stamp') {
        field.readonly = true
      }

      if (type === 'date') {
        field.preferences = {
          format: Intl.DateTimeFormat().resolvedOptions().locale.endsWith('-US') ? 'MM/DD/YYYY' : 'DD/MM/YYYY'
        }
      }

      this.fields.push(field)

      if (!['payment', 'file'].includes(type)) {
        this.$emit('set-draw', { field })
      }

      this.save()
    }
  }
}
</script>

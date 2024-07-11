<template>
  <div :class="withStickySubmitters ? 'sticky top-0 z-[1]' : ''">
    <FieldSubmitter
      :model-value="selectedSubmitter.uuid"
      class="roles-dropdown w-full rounded-lg"
      :style="withStickySubmitters ? { backgroundColor } : {}"
      :submitters="submitters"
      :menu-style="{ backgroundColor: ['', null, 'transparent'].includes(backgroundColor) ? 'white' : backgroundColor }"
      :editable="editable && !defaultSubmitters.length"
      @new-submitter="save"
      @remove="removeSubmitter"
      @name-change="save"
      @update:model-value="$emit('change-submitter', submitters.find((s) => s.uuid === $event))"
    />
  </div>
  <div
    ref="fields"
    class="fields mb-1 mt-2"
    @dragover.prevent="onFieldDragover"
    @drop="reorderFields"
  >
    <Field
      v-for="field in submitterFields"
      :key="field.uuid"
      :data-uuid="field.uuid"
      :field="field"
      :type-index="fields.filter((f) => f.type === field.type).indexOf(field)"
      :editable="editable && (!fieldsDragFieldRef.value || fieldsDragFieldRef.value !== field)"
      :default-field="defaultFields.find((f) => f.name === field.name)"
      :draggable="editable"
      @dragstart="fieldsDragFieldRef.value = field"
      @dragend="fieldsDragFieldRef.value = null"
      @remove="removeField"
      @scroll-to="$emit('scroll-to-area', $event)"
      @set-draw="$emit('set-draw', $event)"
    />
  </div>
  <div v-if="submitterDefaultFields.length && editable">
    <hr class="mb-2">
    <template v-if="isShowFieldSearch">
      <input
        v-model="defaultFieldsSearch"
        :placeholder="t('search_field')"
        class="input input-ghost input-xs px-0 text-base mb-2 !outline-0 !rounded bg-transparent w-full"
      >
      <hr class="mb-2">
    </template>
    <div
      class="overflow-auto relative"
      :style="{
        maxHeight: isShowFieldSearch ? '210px' : '',
        minHeight: isShowFieldSearch ? '210px' : ''
      }"
    >
      <div
        v-if="!filteredSubmitterDefaultFields.length && defaultFieldsSearch"
        class="top-0 bottom-0 text-center absolute flex items-center justify-center w-full flex-col"
      >
        <div>
          {{ t('field_not_found') }}
        </div>
        <a
          href="#"
          class="link"
          @click.prevent="defaultFieldsSearch = ''"
        >
          {{ t('clear') }}
        </a>
      </div>
      <template
        v-for="field in filteredSubmitterDefaultFields"
        :key="field.name"
      >
        <div
          :style="{ backgroundColor }"
          draggable="true"
          class="default-field border border-base-300 rounded rounded-tr-none relative group mb-2"
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
                {{ field.title || field.name }}
              </span>
            </div>
            <span
              v-if="defaultRequiredFields.includes(field)"
              :data-tip="t('required')"
              class="text-red-400 text-3xl pr-1.5 tooltip tooltip-left h-8"
            >
              *
            </span>
          </div>
        </div>
      </template>
    </div>
  </div>
  <div
    v-if="editable && !onlyDefinedFields"
    class="grid grid-cols-3 gap-1 pb-2"
  >
    <template
      v-for="(icon, type) in fieldIconsSorted"
      :key="type"
    >
      <button
        v-if="(fieldTypes.length === 0 || fieldTypes.includes(type)) && (withPhone || type != 'phone') && (withPayment || type != 'payment')"
        draggable="true"
        class="field-type-button group flex items-center justify-center border border-dashed w-full rounded relative"
        :style="{ backgroundColor }"
        :class="drawFieldType === type ? 'border-base-content/40' : 'border-base-300 hover:border-base-content/20'"
        @dragstart="onDragstart({ type: type })"
        @dragend="$emit('drag-end')"
        @click="['file', 'payment'].includes(type) ? $emit('add-field', type) : $emit('set-draw-type', type)"
      >
        <div
          class="flex items-console transition-all cursor-grab h-full absolute left-0"
          :class="drawFieldType === type ? 'bg-base-200/50' : 'group-hover:bg-base-200/50'"
        >
          <IconDrag class="my-auto" />
        </div>
        <div class="flex items-center flex-col px-2 py-2">
          <component :is="icon" />
          <span class="text-xs mt-1">
            {{ fieldNames[type] }}
          </span>
        </div>
      </button>
      <div
        v-else-if="type == 'phone' && (fieldTypes.length === 0 || fieldTypes.includes(type))"
        class="tooltip tooltip-bottom flex"
        :class="{'tooltip-bottom-end': withPayment, 'tooltip-bottom': !withPayment }"
        data-tip="Unlock SMS-verified phone number field with paid plan. Use text field for phone numbers without verification."
      >
        <a
          href="https://www.docuseal.co/pricing"
          target="_blank"
          class="opacity-50 flex items-center justify-center border border-dashed border-base-300 w-full rounded relative"
          :style="{ backgroundColor }"
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
import FieldType from './field_type'
import FieldSubmitter from './field_submitter'
import { IconLock, IconCirclePlus } from '@tabler/icons-vue'
import IconDrag from './icon_drag'

export default {
  name: 'TemplateFields',
  components: {
    Field,
    FieldType,
    IconCirclePlus,
    FieldSubmitter,
    IconDrag,
    IconLock
  },
  inject: ['save', 'backgroundColor', 'withPhone', 'withPayment', 't', 'fieldsDragFieldRef'],
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
    defaultRequiredFields: {
      type: Array,
      required: false,
      default: () => []
    },
    onlyDefinedFields: {
      type: Boolean,
      required: false,
      default: true
    },
    drawFieldType: {
      type: String,
      required: false,
      default: ''
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
    fieldTypes: {
      type: Array,
      required: false,
      default: () => []
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
  emits: ['add-field', 'set-draw', 'set-draw-type', 'set-drag', 'drag-end', 'scroll-to-area', 'change-submitter'],
  data () {
    return {
      defaultFieldsSearch: ''
    }
  },
  computed: {
    fieldNames: FieldType.computed.fieldNames,
    fieldIcons: FieldType.computed.fieldIcons,
    isShowFieldSearch () {
      return this.submitterDefaultFields.length > 15
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
    },
    submitterFields () {
      return this.fields.filter((f) => f.submitter_uuid === this.selectedSubmitter.uuid)
    },
    submitterDefaultFields () {
      return this.defaultFields.filter((f) => {
        return !this.submitterFields.find((field) => field.name === f.name) && (!f.role || f.role === this.selectedSubmitter.name)
      })
    },
    filteredSubmitterDefaultFields () {
      if (this.defaultFieldsSearch) {
        return this.submitterDefaultFields.filter((f) => f.name.toLowerCase().includes(this.defaultFieldsSearch.toLowerCase()))
      } else {
        return this.submitterDefaultFields
      }
    }
  },
  methods: {
    onDragstart (field) {
      this.$emit('set-drag', field)
    },
    onFieldDragover (e) {
      const targetField = e.target.closest('[data-uuid]')
      const dragField = this.$refs.fields.querySelector(`[data-uuid="${this.fieldsDragFieldRef.value.uuid}"]`)

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

      this.fields.forEach((f) => {
        (f.conditions || []).forEach((c) => {
          if (c.field_uuid === field.uuid) {
            f.conditions.splice(f.conditions.indexOf(c), 1)
          }
        })
      })

      this.save()
    }
  }
}
</script>

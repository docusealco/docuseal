<template>
  <span
    class="dropdown dropdown-top dropdown-end absolute bottom-4 right-4 z-10 md:hidden"
  >
    <label
      class="btn btn-neutral text-white btn-circle btn-lg group"
      tabindex="0"
    >
      <IconPlus
        class="group-focus:hidden"
        width="28"
        height="28"
      />
      <IconX
        class="hidden group-focus:inline"
        width="28"
        height="28"
      />
    </label>
    <ul
      tabindex="0"
      class="dropdown-content menu menu-xs p-2 shadow rounded-box w-52 z-10 mb-3 mt-1.5 bg-base-100"
      @click="closeDropdown"
    >
      <template v-if="submitterDefaultFields.length">
        <template
          v-for="field in submitterDefaultFields"
          :key="field.name"
        >
          <li>
            <a
              href="#"
              class="text-sm py-1 px-2"
              @click.prevent="$emit('select', { name: field.name || '', type: field.type || 'text' })"
            >
              <component
                :is="fieldIcons[field.type || 'text']"
                :stroke-width="1.6"
                :width="20"
              />
              {{ field.title || field.name }}
              <span
                v-if="defaultRequiredFields.includes(field)"
                :data-tip="t('required')"
                class="text-red-400 text-2xl tooltip tooltip-left h-6"
              >
                *
              </span>
            </a>
          </li>
        </template>
      </template>
      <template v-else>
        <template
          v-for="(icon, type) in fieldIcons"
          :key="type"
        >
          <li v-if="(fieldTypes.length === 0 || fieldTypes.includes(type)) && (withPhone || type != 'phone') && (withPayment || type != 'payment')">
            <a
              href="#"
              class="text-sm py-1 px-2"
              :class="{ 'active': type === modelValue }"
              @click.prevent="$emit('select', { type })"
            >
              <component
                :is="icon"
                :stroke-width="1.6"
                :width="20"
              />
              {{ fieldNames[type] }}
            </a>
          </li>
        </template>
      </template>
    </ul>
  </span>
</template>
<script>
import { IconPlus, IconX } from '@tabler/icons-vue'
import FieldType from './field_type'

export default {
  name: 'MobileFields',
  components: {
    IconPlus,
    IconX
  },
  inject: ['withPhone', 'withPayment', 'backgroundColor', 't'],
  props: {
    modelValue: {
      type: String,
      required: false,
      default: ''
    },
    fields: {
      type: Array,
      required: false,
      default: () => []
    },
    selectedSubmitter: {
      type: Object,
      required: true
    },
    fieldTypes: {
      type: Array,
      required: false,
      default: () => []
    },
    defaultRequiredFields: {
      type: Array,
      required: false,
      default: () => []
    },
    defaultFields: {
      type: Array,
      required: false,
      default: () => []
    }
  },
  emits: ['select'],
  computed: {
    ...FieldType.computed,
    submitterFields () {
      return this.fields.filter((f) => f.submitter_uuid === this.selectedSubmitter.uuid)
    },
    submitterDefaultFields () {
      return this.defaultFields.filter((f) => {
        return (!f.role || f.role === this.selectedSubmitter.name)
      })
    }
  },
  methods: {
    closeDropdown () {
      document.activeElement.blur()
    }
  }
}
</script>

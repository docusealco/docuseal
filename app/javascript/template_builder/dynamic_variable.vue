<template>
  <div class="group">
    <div class="flex items-center justify-between py-1.5 px-0.5">
      <div class="flex items-center space-x-1 min-w-0">
        <FieldType
          :model-value="formType"
          :editable="editable"
          :button-width="18"
          :menu-classes="'mt-1.5'"
          :menu-style="{ backgroundColor: dropdownBgColor }"
          @update:model-value="onTypeChange"
        />
        <span
          class="truncate"
          :title="path"
        >{{ displayName }}</span>
        <span
          v-if="isArray"
          class="text-xs bg-base-200 rounded px-1 flex-shrink-0"
        >{{ t('list') }}</span>
      </div>
      <div
        v-if="editable"
        class="flex items-center flex-shrink-0"
      >
        <span
          class="dropdown dropdown-end"
          @mouseenter="renderDropdown = true"
          @touchstart="renderDropdown = true"
        >
          <label
            tabindex="0"
            :title="t('settings')"
            class="cursor-pointer text-transparent group-hover:text-base-content"
          >
            <IconSettings
              :width="18"
              :stroke-width="1.6"
            />
          </label>
          <ul
            v-if="renderDropdown"
            tabindex="0"
            class="mt-1.5 dropdown-content menu menu-xs p-2 shadow rounded-box w-52 z-10"
            :style="{ backgroundColor: dropdownBgColor }"
            @click="closeDropdown"
          >
            <div
              class="py-1.5 px-1 relative"
              @click.stop
            >
              <select
                class="select select-bordered select-xs font-normal w-full max-w-xs !h-7 !outline-0 bg-transparent"
                @change="onTypeChange($event.target.value)"
              >
                <option
                  v-for="varType in variableTypes"
                  :key="varType"
                  :value="varType"
                  :selected="varType === formType"
                >{{ t(varType) }}</option>
              </select>
              <label
                :style="{ backgroundColor: dropdownBgColor }"
                class="absolute -top-1 left-2.5 px-1 h-4"
                style="font-size: 8px"
              >{{ t('type') }}</label>
            </div>
            <div
              v-if="formType === 'number'"
              class="py-1.5 px-1 relative"
              @click.stop
            >
              <select
                class="select select-bordered select-xs font-normal w-full max-w-xs !h-7 !outline-0 bg-transparent"
                @change="[schema.format = $event.target.value, save()]"
              >
                <option
                  v-for="format in numberFormats"
                  :key="format"
                  :value="format"
                  :selected="format === schema.format || (format === 'none' && !schema.format)"
                >{{ formatNumber(123456789.567, format) }}</option>
              </select>
              <label
                :style="{ backgroundColor: dropdownBgColor }"
                class="absolute -top-1 left-2.5 px-1 h-4"
                style="font-size: 8px"
              >{{ t('format') }}</label>
            </div>
            <div
              v-if="['text', 'number'].includes(formType)"
              class="py-1.5 px-1 relative"
              @click.stop
            >
              <input
                v-model="schema.default_value"
                :type="formType === 'number' ? 'number' : 'text'"
                :placeholder="t('default_value')"
                dir="auto"
                class="input input-bordered input-xs w-full max-w-xs h-7 !outline-0 bg-transparent"
                @blur="save"
              >
              <label
                v-if="schema.default_value"
                :style="{ backgroundColor: dropdownBgColor }"
                class="absolute -top-1 left-2.5 px-1 h-4"
                style="font-size: 8px"
              >{{ t('default_value') }}</label>
            </div>
            <div
              v-if="formType === 'date'"
              class="py-1.5 px-1 relative"
              @click.stop
            >
              <select
                :value="schema.format || 'MM/DD/YYYY'"
                class="select select-bordered select-xs font-normal w-full max-w-xs !h-7 !outline-0 bg-transparent"
                @change="[schema.format = $event.target.value, save()]"
              >
                <option
                  v-for="format in dateFormats"
                  :key="format"
                  :value="format"
                >{{ formatDate(new Date(), format) }}</option>
              </select>
              <label
                :style="{ backgroundColor: dropdownBgColor }"
                class="absolute -top-1 left-2.5 px-1 h-4"
                style="font-size: 8px"
              >{{ t('format') }}</label>
            </div>
            <li
              v-if="formType === 'date'"
              @click.stop
            >
              <label class="cursor-pointer py-1.5">
                <input
                  :checked="schema.default_value === '{{date}}'"
                  type="checkbox"
                  class="toggle toggle-xs"
                  @change="[schema.default_value = $event.target.checked ? '{{date}}' : undefined, save()]"
                >
                <span class="label-text">{{ t('current_date') }}</span>
              </label>
            </li>
            <div
              v-if="['radio', 'select'].includes(formType)"
              class="py-1.5 px-1 relative"
              @click.stop
            >
              <select
                dir="auto"
                class="select select-bordered select-xs w-full max-w-xs h-7 !outline-0 font-normal bg-transparent"
                @change="[schema.default_value = $event.target.value || undefined, save()]"
              >
                <option
                  value=""
                  :selected="!schema.default_value"
                >{{ t('none') }}</option>
                <option
                  v-for="opt in (schema.options || [])"
                  :key="opt"
                  :value="opt"
                  :selected="schema.default_value === opt"
                >{{ opt }}</option>
              </select>
              <label
                :style="{ backgroundColor: dropdownBgColor }"
                class="absolute -top-1 left-2.5 px-1 h-4"
                style="font-size: 8px"
              >{{ t('default_value') }}</label>
            </div>
            <li
              v-if="formType === 'checkbox'"
              @click.stop
            >
              <label class="cursor-pointer py-1.5">
                <input
                  :checked="schema.default_value === true"
                  type="checkbox"
                  class="toggle toggle-xs"
                  @change="[schema.default_value = $event.target.checked || undefined, save()]"
                >
                <span class="label-text">{{ t('checked') }}</span>
              </label>
            </li>
            <li @click.stop>
              <label class="cursor-pointer py-1.5">
                <input
                  :checked="schema.required !== false"
                  type="checkbox"
                  class="toggle toggle-xs"
                  @change="[schema.required = $event.target.checked, save()]"
                >
                <span class="label-text">{{ t('required') }}</span>
              </label>
            </li>
          </ul>
        </span>
      </div>
    </div>
    <div
      v-if="['radio', 'select'].includes(formType) && schema.options"
      ref="options"
      class="pl-2 pr-1 pb-1.5 space-y-1.5"
    >
      <div
        v-for="(option, index) in schema.options"
        :key="index"
        class="flex space-x-1.5 items-center"
      >
        <span class="text-sm w-3.5 select-none">{{ index + 1 }}.</span>
        <input
          :value="option"
          class="w-full input input-primary input-xs text-sm bg-transparent"
          type="text"
          dir="auto"
          :placeholder="`${t('option')} ${index + 1}`"
          @blur="[schema.options.splice(index, 1, $event.target.value), save()]"
          @keydown.enter="$event.target.value ? onOptionEnter(index, $event.target.value) : null"
        >
        <button
          class="text-sm w-3.5"
          tabindex="-1"
          @click="[schema.options.splice(index, 1), save()]"
        >
          &times;
        </button>
      </div>
      <button
        class="text-center text-sm w-full pb-1"
        @click="addOptionAndFocus((schema.options || []).length)"
      >
        + {{ t('add_option') }}
      </button>
    </div>
  </div>
</template>

<script>
import FieldType from './field_type'
import { IconSettings } from '@tabler/icons-vue'

export default {
  name: 'DynamicVariable',
  components: {
    FieldType,
    IconSettings
  },
  inject: ['t', 'save', 'backgroundColor'],
  provide () {
    return {
      fieldTypes: ['text', 'number', 'date', 'checkbox', 'radio', 'select']
    }
  },
  props: {
    path: {
      type: String,
      required: true
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    },
    groupKey: {
      type: String,
      default: ''
    },
    schema: {
      type: Object,
      required: true
    },
    isArray: {
      type: Boolean,
      default: false
    }
  },
  data () {
    return {
      renderDropdown: false
    }
  },
  computed: {
    displayName () {
      if (this.groupKey) {
        const prefix = this.groupKey + (this.path.startsWith(this.groupKey + '[].') ? '[].' : '.')

        return this.path.slice(prefix.length)
      } else {
        return this.path
      }
    },
    dropdownBgColor () {
      return ['', null, 'transparent'].includes(this.backgroundColor) ? 'white' : this.backgroundColor
    },
    schemaTypeToFormType () {
      return { string: 'text', number: 'number', boolean: 'checkbox', date: 'date' }
    },
    formType () {
      return this.schema.form_type || this.schemaTypeToFormType[this.schema.type] || 'text'
    },
    variableTypes () {
      return ['text', 'number', 'date', 'checkbox', 'radio', 'select']
    },
    formTypeToSchemaType () {
      return { text: 'string', number: 'number', date: 'date', checkbox: 'boolean', radio: 'string', select: 'string' }
    },
    numberFormats () {
      return [
        'none',
        'usd',
        'eur',
        'gbp',
        'comma',
        'dot',
        'space'
      ]
    },
    dateFormats () {
      const formats = [
        'MM/DD/YYYY',
        'DD/MM/YYYY',
        'YYYY-MM-DD',
        'DD-MM-YYYY',
        'DD.MM.YYYY',
        'MMM D, YYYY',
        'MMMM D, YYYY',
        'D MMM YYYY',
        'D MMMM YYYY'
      ]

      if (Intl.DateTimeFormat().resolvedOptions().timeZone?.includes('Seoul') || navigator.language?.startsWith('ko')) {
        formats.push('YYYY년 MM월 DD일')
      }

      if (this.schema.format && !formats.includes(this.schema.format)) {
        formats.unshift(this.schema.format)
      }

      return formats
    }
  },
  methods: {
    onTypeChange (newType) {
      this.schema.type = this.formTypeToSchemaType[newType] || 'string'
      this.schema.form_type = newType

      if (['radio', 'select'].includes(newType)) {
        if (!this.schema.options || !this.schema.options.length) {
          this.schema.options = ['', '']
        }
      } else {
        delete this.schema.options
        delete this.schema.default_value
        delete this.schema.format
      }

      this.save()
    },
    onOptionEnter (index, value) {
      this.schema.options.splice(index, 1, value)
      this.schema.options.splice(index + 1, 0, '')

      this.save()

      this.$nextTick(() => {
        this.$refs.options.querySelectorAll('input')[index + 1]?.focus()
      })
    },
    addOptionAndFocus (index) {
      if (!this.schema.options) {
        this.schema.options = []
      }

      this.schema.options.splice(index, 0, '')
      this.save()

      this.$nextTick(() => {
        this.$refs.options.querySelectorAll('input')[index]?.focus()
      })
    },
    formatNumber (number, format) {
      if (format === 'comma') {
        return new Intl.NumberFormat('en-US').format(number)
      } else if (format === 'usd') {
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(number)
      } else if (format === 'gbp') {
        return new Intl.NumberFormat('en-GB', { style: 'currency', currency: 'GBP', minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(number)
      } else if (format === 'eur') {
        return new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'EUR', minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(number)
      } else if (format === 'dot') {
        return new Intl.NumberFormat('de-DE').format(number)
      } else if (format === 'space') {
        return new Intl.NumberFormat('fr-FR').format(number)
      } else {
        return number
      }
    },
    formatDate (date, format) {
      const monthFormats = { M: 'numeric', MM: '2-digit', MMM: 'short', MMMM: 'long' }
      const dayFormats = { D: 'numeric', DD: '2-digit' }
      const yearFormats = { YYYY: 'numeric', YY: '2-digit' }

      const parts = new Intl.DateTimeFormat([], {
        day: dayFormats[format.match(/D+/)],
        month: monthFormats[format.match(/M+/)],
        year: yearFormats[format.match(/Y+/)]
      }).formatToParts(date)

      return format
        .replace(/D+/, parts.find((p) => p.type === 'day').value)
        .replace(/M+/, parts.find((p) => p.type === 'month').value)
        .replace(/Y+/, parts.find((p) => p.type === 'year').value)
    },
    closeDropdown () {
      this.$el.getRootNode().activeElement.blur()
    }
  }
}
</script>

<template>
  <div dir="auto">
    <div
      class="flex justify-between items-end w-full mb-3.5 sm:mb-4"
      :class="{ 'mb-2': !field.description }"
    >
      <label
        v-if="showFieldNames"
        :for="field.uuid"
        class="label text-xl sm:text-2xl py-0 field-name-label"
      >
        <MarkdownContent
          v-if="field.title"
          :string="field.title"
        />
        <template v-else>
          {{ field.name || t('date') }}
        </template>
        <template v-if="!field.required">
          <span
            class="ml-1"
            :class="{ 'hidden sm:inline': (field.title || field.name || t('date') ).length > 10 }"
          >
            ({{ t('optional') }})
          </span>
        </template>
      </label>
      <button
        v-if="withToday"
        class="btn btn-outline btn-sm !normal-case font-normal set-current-date-button"
        @click.prevent="[setCurrentDate(), $emit('focus')]"
      >
        <IconCalendarCheck
          :width="16"
          aria-hidden="true"
        />
        {{ t('set_today') }}
      </button>
    </div>
    <div
      v-if="field.description"
      :id="field.uuid + '-desc'"
      class="mb-3 px-1 field-description-text"
      dir="auto"
    >
      <MarkdownContent :string="field.description" />
    </div>
    <AppearsOn :field="field" />
    <div class="text-center flex">
      <input
        :id="field.uuid"
        ref="input"
        v-model="value"
        :min="validationMin"
        :max="validationMax"
        class="base-input !text-2xl text-center w-full"
        :required="field.required"
        :aria-describedby="field.description ? field.uuid + '-desc' : undefined"
        :type="inputType"
        :name="formatType === 'datetime' ? undefined : `values[${field.uuid}]`"
        @keydown.enter="onEnter"
        @focus="$emit('focus')"
        @paste="onPaste"
      >
      <input
        v-if="formatType === 'datetime'"
        type="hidden"
        :name="`values[${field.uuid}]`"
        :value="modelValue"
      >
    </div>
  </div>
</template>

<script>
import { IconCalendarCheck } from '@tabler/icons-vue'
import AppearsOn from './appears_on'
import MarkdownContent from './markdown_content'

export default {
  name: 'DateStep',
  components: {
    IconCalendarCheck,
    MarkdownContent,
    AppearsOn
  },
  inject: ['t'],
  props: {
    field: {
      type: Object,
      required: true
    },
    showFieldNames: {
      type: Boolean,
      required: false,
      default: true
    },
    modelValue: {
      type: String,
      required: false,
      default: ''
    }
  },
  emits: ['update:model-value', 'focus', 'submit'],
  computed: {
    formatType () {
      const format = this.field.preferences?.format || ''

      if (/[HhAasz]/.test(format)) return 'datetime'
      if (format && !/[Dd]/.test(format)) return 'month'

      return 'date'
    },
    inputType () {
      return { datetime: 'datetime-local', month: 'month', date: 'date' }[this.formatType]
    },
    dateNowString () {
      return this.formatDateValue(new Date())
    },
    validationMin () {
      if (this.field.validation?.min) {
        return ['{{date}}', '{date}'].includes(this.field.validation.min) ? this.dateNowString : this.field.validation.min
      } else {
        return ''
      }
    },
    validationMax () {
      if (this.field.validation?.max) {
        return ['{{date}}', '{date}'].includes(this.field.validation.max) ? this.dateNowString : this.field.validation.max
      } else {
        return ''
      }
    },
    withToday () {
      if (this.formatType === 'datetime') return false

      const todayDate = new Date().setHours(0, 0, 0, 0)

      if (this.validationMin) {
        if (new Date(this.validationMin).setHours(0, 0, 0, 0) <= todayDate) {
          return this.validationMax ? (new Date(this.validationMax).setHours(0, 0, 0, 0) >= todayDate) : true
        } else {
          return false
        }
      } else if (this.validationMax) {
        return new Date(this.validationMax).setHours(0, 0, 0, 0) >= todayDate
      } else {
        return true
      }
    },
    value: {
      set (value) {
        if (this.formatType === 'datetime' && value) {
          const d = new Date(value)

          if (!isNaN(d)) {
            this.$emit('update:model-value', d.toISOString())

            return
          }
        }

        this.$emit('update:model-value', value)
      },
      get () {
        if (this.formatType === 'datetime') {
          const d = new Date(this.modelValue)

          return isNaN(d) ? '' : this.formatDateValue(d)
        }

        return this.modelValue
      }
    }
  },
  methods: {
    onEnter (e) {
      if (this.modelValue) {
        e.preventDefault()

        this.$emit('submit')
      }
    },
    onPaste (e) {
      e.preventDefault()

      let pasteData = e.clipboardData.getData('text').trim()

      if (pasteData.match(/^\d{2}\.\d{2}\.\d{4}$/)) {
        pasteData = pasteData.split('.').reverse().join('-')
      }

      const parsedDate = new Date(pasteData)

      if (isNaN(parsedDate)) return

      this.setInputValue(parsedDate)
    },
    setCurrentDate () {
      this.setInputValue(new Date())
    },
    setInputValue (date) {
      const inputEl = this.$refs.input

      if (this.formatType === 'date') {
        inputEl.valueAsDate = new Date(date.getTime() - date.getTimezoneOffset() * 60000)
      } else {
        inputEl.value = this.formatDateValue(date)
      }

      inputEl.dispatchEvent(new Event('input', { bubbles: true }))
    },
    formatDateValue (date) {
      const pad = (n) => String(n).padStart(2, '0')
      const ymd = `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`

      if (this.formatType === 'month') return ymd.slice(0, 7)
      if (this.formatType === 'datetime') return `${ymd}T${pad(date.getHours())}:${pad(date.getMinutes())}`

      return ymd
    }
  }
}
</script>

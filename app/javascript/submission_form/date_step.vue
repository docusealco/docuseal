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
        class="btn btn-outline btn-sm !normal-case font-normal set-current-date-button"
        @click.prevent="[setCurrentDate(), $emit('focus')]"
      >
        <IconCalendarCheck :width="16" />
        {{ t('set_today') }}
      </button>
    </div>
    <div
      v-if="field.description"
      class="mb-3 px-1 field-description-text"
      dir="auto"
    >
      <MarkdownContent :string="field.description" />
    </div>
    <AppearsOn :field="field" />
    <div class="text-center">
      <input
        :id="field.uuid"
        ref="input"
        v-model="value"
        class="base-input !text-2xl text-center w-full"
        :required="field.required"
        type="date"
        :name="`values[${field.uuid}]`"
        @keydown.enter="onEnter"
        @focus="$emit('focus')"
        @paste="onPaste"
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
    value: {
      set (value) {
        this.$emit('update:model-value', value)
      },
      get () {
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

      if (!isNaN(parsedDate)) {
        const inputEl = this.$refs.input

        inputEl.valueAsDate = new Date(parsedDate.getTime() - parsedDate.getTimezoneOffset() * 60000)

        inputEl.dispatchEvent(new Event('input', { bubbles: true }))
      }
    },
    setCurrentDate () {
      const inputEl = this.$refs.input

      inputEl.valueAsDate = new Date(new Date().getTime() - new Date().getTimezoneOffset() * 60000)

      inputEl.dispatchEvent(new Event('input', { bubbles: true }))
    }
  }
}
</script>

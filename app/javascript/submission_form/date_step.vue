<template>
  <div dir="auto">
    <div class="flex justify-between items-center w-full mb-2">
      <label
        :for="field.uuid"
        class="label text-2xl"
      >{{ field.name || t('date') }}
        <template v-if="!field.required">({{ t('optional') }})</template>
      </label>
      <button
        class="btn btn-outline btn-sm !normal-case font-normal"
        @click.prevent="setCurrentDate"
      >
        <IconCalendarCheck :width="16" />
        {{ t('set_today') }}
      </button>
    </div>
    <AppearsOn :field="field" />
    <div class="text-center">
      <input
        ref="input"
        v-model="value"
        class="base-input !text-2xl text-center w-full"
        :required="field.required"
        type="date"
        :name="`values[${field.uuid}]`"
        @focus="$emit('focus')"
      >
    </div>
  </div>
</template>

<script>
import { IconCalendarCheck } from '@tabler/icons-vue'
import AppearsOn from './appears_on'

export default {
  name: 'DateStep',
  components: {
    IconCalendarCheck,
    AppearsOn
  },
  inject: ['t'],
  props: {
    field: {
      type: Object,
      required: true
    },
    modelValue: {
      type: String,
      required: false,
      default: ''
    }
  },
  emits: ['update:model-value', 'focus'],
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
    setCurrentDate () {
      const inputEl = this.$refs.input

      inputEl.valueAsDate = new Date(new Date().getTime() - new Date().getTimezoneOffset() * 60000)

      inputEl.dispatchEvent(new Event('input', { bubbles: true }))
    }
  }
}
</script>

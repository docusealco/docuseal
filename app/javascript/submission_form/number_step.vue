<template>
  <label
    v-if="showFieldNames && field.name"
    :for="field.uuid"
    dir="auto"
    class="label text-2xl"
    :class="{ 'mb-2': !field.description }"
  ><template v-if="field.title"><span v-html="field.title" /></template>
    <template v-else>{{ field.name }}</template>
    <template v-if="!field.required">({{ t('optional') }})</template>
  </label>
  <div
    v-else
    class="py-1"
  />
  <div
    v-if="field.description"
    class="mb-3 px-1 text-lg"
    v-html="field.description"
  />
  <AppearsOn :field="field" />
  <div class="items-center flex">
    <input
      type="hidden"
      name="cast_number"
      value="true"
    >
    <input
      :id="field.uuid"
      v-model="number"
      type="number"
      class="base-input !text-2xl w-full"
      step="any"
      :required="field.required"
      :placeholder="`${t('type_here_')}${field.required ? '' : ` (${t('optional')})`}`"
      :name="`values[${field.uuid}]`"
      @focus="$emit('focus')"
    >
  </div>
</template>

<script>
import AppearsOn from './appears_on'

export default {
  name: 'TextStep',
  components: {
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
  emits: ['update:model-value', 'focus'],
  computed: {
    number: {
      set (value) {
        this.$emit('update:model-value', value)
      },
      get () {
        return this.modelValue
      }
    }
  }
}
</script>

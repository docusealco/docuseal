<template>
  <label
    v-if="field.name"
    :for="field.uuid"
    class="label text-2xl mb-2"
  >{{ field.name }}</label>
  <div class="flex w-full">
    <input
      v-if="modelValue.length === 0"
      type="text"
      :name="`values[${field.uuid}][]`"
      :value="''"
      class="hidden"
    >
    <div class="space-y-3.5 mx-auto">
      <div
        v-for="(option, index) in field.options"
        :key="option.uuid"
      >
        <label
          :for="option.uuid"
          class="flex items-center space-x-3"
        >
          <input
            :id="option.uuid"
            :ref="setInputRef"
            type="checkbox"
            :name="`values[${field.uuid}][]`"
            :value="optionValue(option, index)"
            class="base-checkbox !h-7 !w-7"
            :checked="(modelValue || []).includes(optionValue(option, index))"
            @change="onChange"
          >
          <span class="text-xl">
            {{ optionValue(option, index) }}
          </span>
        </label>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'MultiSelectStep',
  inject: ['t'],
  props: {
    field: {
      type: Object,
      required: true
    },
    modelValue: {
      type: Array,
      required: false,
      default: () => []
    }
  },
  emits: ['update:model-value'],
  data () {
    return {
      inputRefs: []
    }
  },
  beforeUpdate () {
    this.inputRefs = []
  },
  methods: {
    setInputRef (el) {
      if (el) {
        this.inputRefs.push(el)
      }
    },
    optionValue (option, index) {
      if (option.value) {
        return option.value
      } else {
        return `${this.t('option')} ${index + 1}`
      }
    },
    onChange () {
      this.$emit('update:model-value', this.inputRefs.filter(e => e.checked).map((e, index) => this.optionValue(e, index)))
    }
  }
}
</script>

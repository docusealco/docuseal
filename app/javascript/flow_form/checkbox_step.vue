<template>
  <div
    v-for="(option, index) in field.options"
    :key="index"
  >
    <label :for="field.uuid + option">
      <input
        :id="field.uuid + option"
        :ref="setInputRef"
        type="checkbox"
        :name="`values[${field.uuid}][]`"
        :value="option"
        :checked="modelValue.includes(option)"
        @change="onChange"
      >
      {{ option }}
    </label>
  </div>
</template>
<script>
export default {
  name: 'SheckboxStep',
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
    onChange () {
      this.$emit('update:model-value', this.inputRefs.filter(e => e.checked).map(e => e.value))
    }
  }
}
</script>

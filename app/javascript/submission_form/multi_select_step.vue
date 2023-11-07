<template>
  <label
    v-if="field.name"
    :for="field.uuid"
    class="label text-2xl mb-2"
  >{{ field.name }}</label>
  <div class="flex w-full">
    <div class="space-y-3.5 mx-auto">
      <div
        v-for="(option, index) in field.options"
        :key="index"
      >
        <label
          :for="field.uuid + option"
          class="flex items-center space-x-3"
        >
          <input
            :id="field.uuid + option"
            :ref="setInputRef"
            type="checkbox"
            :name="`values[${field.uuid}][]`"
            :value="option"
            class="base-checkbox !h-7 !w-7"
            :checked="(modelValue || []).includes(option)"
            @change="onChange"
          >
          <span class="text-xl">
            {{ option }}
          </span>
        </label>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'MultiSelectStep',
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

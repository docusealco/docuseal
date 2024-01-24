<template>
  <label
    v-if="showFieldNames && field.name"
    :for="field.uuid"
    dir="auto"
    class="label text-2xl mb-2"
  >{{ field.name }}</label>
  <div class="flex w-full max-h-44 overflow-y-auto">
    <input
      v-if="modelValue.length === 0"
      type="text"
      :name="`values[${field.uuid}][]`"
      :value="''"
      class="hidden"
    >
    <div
      v-if="!showOptions"
      class="text-xl px-1"
    >
      <span @click="scrollIntoField(field)">
        {{ t('complete_hightlighted_checkboxes_and_click') }} <span class="font-semibold">{{ isLastStep ? t('submit') : t('next') }}</span>.
      </span>
    </div>
    <div
      class="space-y-3.5 mx-auto"
      :class="{ hidden: !showOptions }"
    >
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
  inject: ['t', 'scrollIntoField'],
  props: {
    field: {
      type: Object,
      required: true
    },
    isLastStep: {
      type: Boolean,
      required: true,
      default: false
    },
    showFieldNames: {
      type: Boolean,
      required: false,
      default: true
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
  computed: {
    showOptions () {
      return this.showFieldNames && (this.field.options.some((e) => e.value) || this.field.options.length < 5)
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

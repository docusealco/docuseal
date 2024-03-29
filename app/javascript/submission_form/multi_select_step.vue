<template>
  <label
    v-if="showFieldNames && (field.name || field.title)"
    :for="field.uuid"
    dir="auto"
    class="label text-2xl"
    :class="{ 'mb-2': !field.description }"
  ><MarkdownContent
     v-if="field.title"
     :string="field.title"
   />
    <template v-else>{{ field.name }}</template>
  </label>
  <div
    v-if="field.description"
    dir="auto"
    class="mb-3 px-1"
  >
    <MarkdownContent :string="field.description" />
  </div>
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
          @click="scrollIntoField(field)"
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
import MarkdownContent from './markdown_content'

export default {
  name: 'MultiSelectStep',
  components: {
    MarkdownContent
  },
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

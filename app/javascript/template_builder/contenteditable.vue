<template>
  <div
    class="group/contenteditable relative overflow-visible"
    :class="{ 'flex items-center': !iconInline }"
  >
    <span
      ref="contenteditable"
      contenteditable
      style="min-width: 2px"
      :class="iconInline ? 'inline' : 'block'"
      class="peer outline-none focus:block"
      @keydown.enter.prevent="blurContenteditable"
      @focus="$emit('focus', $event)"
      @blur="onBlur"
    >
      {{ value }}
    </span>
    <span
      v-if="withRequired"
      title="Required"
      class="text-red-500 peer-focus:hidden"
      @click="focusContenteditable"
    >
      *
    </span>
    <IconPencil
      class="cursor-pointer flex-none opacity-0 group-hover/contenteditable:opacity-100 align-middle peer-focus:hidden"
      :style="iconInline ? {} : { right: -(1.1 * iconWidth) + 'px' }"
      title="Edit"
      :class="{ 'ml-1': !withRequired, 'absolute': !iconInline, 'inline align-bottom': iconInline }"
      :width="iconWidth"
      :stroke-width="iconStrokeWidth"
      @click="focusContenteditable"
    />
  </div>
</template>

<script>
import { IconPencil } from '@tabler/icons-vue'

export default {
  name: 'ContenteditableField',
  components: {
    IconPencil
  },
  props: {
    modelValue: {
      type: String,
      required: false,
      default: ''
    },
    iconInline: {
      type: Boolean,
      required: false,
      default: false
    },
    iconWidth: {
      type: Number,
      required: false,
      default: 30
    },
    withRequired: {
      type: Boolean,
      required: false,
      default: false
    },
    iconStrokeWidth: {
      type: Number,
      required: false,
      default: 2
    }
  },
  emits: ['update:model-value', 'focus', 'blur'],
  data () {
    return {
      value: ''
    }
  },
  watch: {
    modelValue: {
      handler (value) {
        this.value = value
      },
      immediate: true
    }
  },
  methods: {
    onBlur (e) {
      setTimeout(() => {
        this.value = this.$refs.contenteditable.innerText.trim() || this.modelValue
        this.$emit('update:model-value', this.value)
        this.$emit('blur', e)
      }, 1)
    },
    focusContenteditable () {
      this.$refs.contenteditable.focus()
    },
    blurContenteditable () {
      this.$refs.contenteditable.blur()
    }
  }
}
</script>

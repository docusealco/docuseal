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
      @keydown.enter.prevent="onEnter"
      @focus="$emit('focus', $event)"
      @blur="onBlur"
    >
      {{ value }}
    </span>
    <IconPencil
      contenteditable="false"
      class="cursor-pointer ml-1 flex-none opacity-0 group-hover/contenteditable:opacity-100 align-middle peer-focus:hidden"
      :style="iconInline ? {} : { right: -(1.1 * iconWidth) + 'px' }"
      title="Edit"
      :class="{ 'absolute': !iconInline, 'inline align-bottom': iconInline }"
      :width="iconWidth"
      :stroke-width="iconStrokeWidth"
      @click="onPencilClick"
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
      this.value = this.$refs.contenteditable.innerText.trim() || this.modelValue

      this.$emit('update:model-value', this.value)
      this.$emit('blur', e)
    },
    onPencilClick () {
      this.$refs.contenteditable.focus()
    },
    onEnter () {
      this.$refs.contenteditable.blur()
    }
  }
}
</script>

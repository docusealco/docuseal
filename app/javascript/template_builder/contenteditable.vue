<template>
  <div
    class="group/contenteditable relative overflow-visible"
    :class="{ 'flex items-center': !iconInline }"
  >
    <span
      ref="contenteditable"
      dir="auto"
      :contenteditable="editable"
      style="min-width: 2px"
      :class="iconInline ? 'inline' : 'block'"
      class="peer outline-none focus:block"
      @paste.prevent="onPaste"
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
      class="cursor-pointer flex-none opacity-0 group-hover/contenteditable-container:opacity-100 group-hover/contenteditable:opacity-100 align-middle peer-focus:hidden"
      :style="iconInline ? {} : { right: -(1.1 * iconWidth) + 'px' }"
      :title="t('edit')"
      :class="{ invisible: !editable, 'ml-1': !withRequired, 'absolute': !iconInline, 'inline align-bottom': iconInline }"
      :width="iconWidth"
      :stroke-width="iconStrokeWidth"
      @click="[focusContenteditable(), selectOnEditClick && selectContent()]"
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
  inject: ['t'],
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
    selectOnEditClick: {
      type: Boolean,
      required: false,
      default: false
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
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
    onPaste (e) {
      const text = (e.clipboardData || window.clipboardData).getData('text/plain')

      const selection = this.$el.getRootNode().getSelection()

      if (selection.rangeCount) {
        selection.deleteFromDocument()
        selection.getRangeAt(0).insertNode(document.createTextNode(text))
        selection.collapseToEnd()
      }
    },
    selectContent () {
      const el = this.$refs.contenteditable

      const range = document.createRange()

      range.selectNodeContents(el)

      const sel = window.getSelection()

      sel.removeAllRanges()

      sel.addRange(range)
    },
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

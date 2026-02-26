<template>
  <div
    class="group/contenteditable relative overflow-visible"
    :class="{ 'flex items-center': !iconInline }"
  >
    <span
      ref="contenteditable"
      dir="auto"
      :contenteditable="editable && (!editableOnButton || isEditable)"
      :data-placeholder="placeholder"
      :data-empty="isEmpty"
      :style="{ minWidth }"
      :class="[iconInline ? (isEmpty ? 'inline-block' : 'inline') : 'block', hideIcon ? 'focus:block' : '']"
      class="peer relative inline-block before:pointer-events-none before:absolute before:left-0 before:top-0 before:select-none before:whitespace-pre before:text-neutral-600 before:content-[attr(data-placeholder)] before:opacity-0 data-[empty=true]:before:opacity-100"
      @paste.prevent="onPaste"
      @keydown.enter.prevent="blurContenteditable"
      @input="updateInputValue"
      @cut="updateInputValue"
      @focus="$emit('focus', $event)"
      @blur="onBlur"
      @click="editable && (!editableOnButton || isEditable) ? '' : $emit('click-contenteditable')"
    >
      {{ value }}
    </span>
    <span
      v-if="withButton"
      class="relative inline"
      :class="{ 'peer-focus:hidden': hideIcon, 'peer-focus:invisible': !hideIcon }"
    >
      <IconPencil
        class="cursor-pointer flex-none opacity-0 group-hover/contenteditable-container:opacity-100 group-hover/contenteditable:opacity-100 align-middle pl-1"
        :style="iconInline ? {} : { right: -(1.1 * iconWidth) + 'px' }"
        :title="t('edit')"
        :class="{ invisible: !editable, 'absolute top-1/2 -translate-y-1/2': !iconInline || floatIcon, 'inline align-bottom': iconInline, 'left-0': floatIcon }"
        :width="iconWidth + 4"
        :stroke-width="iconStrokeWidth"
        @click="clickEdit"
      />
    </span>
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
    placeholder: {
      type: String,
      required: false,
      default: ''
    },
    withButton: {
      type: Boolean,
      required: false,
      default: true
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
    hideIcon: {
      type: Boolean,
      required: false,
      default: true
    },
    floatIcon: {
      type: Boolean,
      required: false,
      default: false
    },
    selectOnEditClick: {
      type: Boolean,
      required: false,
      default: false
    },
    editableOnButton: {
      type: Boolean,
      required: false,
      default: false
    },
    minWidth: {
      type: String,
      required: false,
      default: '2px'
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
  emits: ['update:model-value', 'focus', 'blur', 'click-contenteditable'],
  data () {
    return {
      isEditable: false,
      inputValue: '',
      value: ''
    }
  },
  computed: {
    isEmpty () {
      return !this.inputValue.replace(/\u200B/g, '').replace(/\u00A0/g, ' ').trim()
    }
  },
  watch: {
    modelValue: {
      handler (value) {
        this.value = value || ''
      },
      immediate: true
    }
  },
  mounted () {
    this.updateInputValue()
  },
  methods: {
    updateInputValue () {
      this.inputValue = this.$refs.contenteditable?.textContent || ''
    },
    onPaste (e) {
      const text = (e.clipboardData || window.clipboardData).getData('text/plain')

      const selection = this.$el.getRootNode().getSelection()

      if (selection.rangeCount) {
        selection.deleteFromDocument()
        selection.getRangeAt(0).insertNode(document.createTextNode(text))
        selection.collapseToEnd()
      }

      this.updateInputValue()
    },
    clickEdit (e) {
      this.focusContenteditable()

      if (this.selectOnEditClick) {
        this.selectContent()
      }
    },
    setText (text) {
      this.$refs.contenteditable.innerText = text

      this.updateInputValue()
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
        if (this.$refs.contenteditable) {
          this.value = this.$refs.contenteditable.innerText.trim() || this.modelValue
          this.$emit('update:model-value', this.value)
        }

        this.$emit('blur', e)

        this.isEditable = false
      }, 1)
    },
    focusContenteditable () {
      this.isEditable = true

      this.$nextTick(() => {
        this.$refs.contenteditable.focus()

        this.updateInputValue()
      })
    },
    blurContenteditable () {
      this.$refs.contenteditable.blur()
    }
  }
}
</script>

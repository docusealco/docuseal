<template>
  <div
    v-if="visible"
    class="absolute z-10 flex items-center gap-0.5 px-1.5 py-1 bg-white border border-base-300 rounded-lg shadow select-none"
    :style="{ top: (coords.top - 42) + 'px', left: coords.left + 'px', transform: 'translateX(-50%)' }"
    @mousedown.prevent
  >
    <button
      class="inline-flex items-center justify-center w-7 h-7 border-none rounded cursor-pointer text-gray-700"
      :class="isBold ? 'bg-base-200' : 'bg-transparent'"
      title="Bold"
      @click="toggleBold"
    >
      <IconBold
        :width="16"
        :height="16"
      />
    </button>
    <button
      class="inline-flex items-center justify-center w-7 h-7 border-none rounded cursor-pointer text-gray-700"
      :class="isItalic ? 'bg-base-200' : 'bg-transparent'"
      title="Italic"
      @click="toggleItalic"
    >
      <IconItalic
        :width="16"
        :height="16"
      />
    </button>
    <button
      class="inline-flex items-center justify-center w-7 h-7 border-none rounded cursor-pointer text-gray-700"
      :class="isUnderline ? 'bg-base-200' : 'bg-transparent'"
      title="Underline"
      @click="toggleUnderline"
    >
      <IconUnderline
        :width="16"
        :height="16"
      />
    </button>
    <button
      class="inline-flex items-center justify-center w-7 h-7 border-none rounded cursor-pointer text-gray-700"
      :class="isStrike ? 'bg-base-200' : 'bg-transparent'"
      title="Strikethrough"
      @click="toggleStrike"
    >
      <IconStrikethrough
        :width="16"
        :height="16"
      />
    </button>
    <div class="w-px h-5 bg-base-300 mx-1" />
    <button
      class="inline-flex items-center justify-center text-xs h-7 border-none rounded cursor-pointer text-gray-700 bg-transparent"
      title="Wrap in variable"
      @click="wrapVariable"
    >
      <IconBracketsContain
        :width="16"
        :height="16"
        :stroke-width="1.6"
      />
      <span class="px-0.5">
        Variable
      </span>
    </button>
    <div class="w-px h-5 bg-base-300 mx-1" />
    <button
      class="inline-flex items-center justify-center text-xs h-7 border-none rounded cursor-pointer text-gray-700 bg-transparent"
      title="Wrap in condition"
      @click="wrapCondition"
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        width="16"
        height="16"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="1.6"
        stroke-linecap="round"
        stroke-linejoin="round"
        class="tabler-icon tabler-icon-brackets-contain"
      ><path d="M7 4h-4v16h4" /><path d="M17 4h4v16h-4" />
        <text
          x="12"
          y="16.5"
          text-anchor="middle"
          fill="currentColor"
          stroke="none"
          font-size="14"
          font-weight="600"
          font-family="ui-sans-serif, system-ui, sans-serif"
        >if</text>
      </svg>
      <span class="px-0.5">
        Condition
      </span>
    </button>
  </div>
</template>

<script>
import { IconBold, IconItalic, IconUnderline, IconStrikethrough, IconBracketsContain } from '@tabler/icons-vue'

export default {
  name: 'DynamicMenu',
  components: {
    IconBold,
    IconItalic,
    IconUnderline,
    IconStrikethrough,
    IconBracketsContain
  },
  props: {
    editor: {
      type: Object,
      required: true
    },
    coords: {
      type: Object,
      required: false,
      default: null
    }
  },
  emits: ['add-variable', 'add-condition'],
  data () {
    return {
      isMouseDown: false,
      isBold: this.editor.isActive('bold'),
      isItalic: this.editor.isActive('italic'),
      isUnderline: this.editor.isActive('underline'),
      isStrike: this.editor.isActive('strike')
    }
  },
  computed: {
    visible () {
      return !!this.coords && !this.isMouseDown
    }
  },
  mounted () {
    this.editor.view.dom.addEventListener('mousedown', this.onMouseDown)

    document.addEventListener('mouseup', this.onMouseUp)

    this.editor.on('transaction', this.onTransaction)
  },
  beforeUnmount () {
    if (!this.editor.isDestroyed) {
      this.editor.view.dom.removeEventListener('mousedown', this.onMouseDown)
      this.editor.off('transaction', this.onTransaction)
    }

    document.removeEventListener('mouseup', this.onMouseUp)
  },
  methods: {
    toggleBold () {
      this.editor.chain().focus().toggleBold().run()
    },
    toggleItalic () {
      this.editor.chain().focus().toggleItalic().run()
    },
    toggleUnderline () {
      this.editor.chain().focus().toggleUnderline().run()
    },
    toggleStrike () {
      this.editor.chain().focus().toggleStrike().run()
    },
    wrapVariable () {
      const { from, to } = this.editor.state.selection
      const replacement = '[[variable]]'
      const varFrom = from + 2
      const varTo = varFrom + 8

      this.editor.chain().focus()
        .insertContentAt({ from, to }, replacement)
        .setTextSelection({ from: varFrom, to: varTo })
        .run()

      this.$emit('add-variable')
    },
    wrapCondition () {
      const { from, to } = this.editor.state.selection
      const endText = '[[end]]'
      const ifText = '[[if:variable]]'

      this.editor.chain().focus()
        .insertContentAt(to, endText)
        .insertContentAt(from, ifText)
        .setTextSelection({ from: from + 5, to: from + 13 })
        .run()

      this.$emit('add-condition')
    },
    onMouseDown () {
      this.isMouseDown = true
    },
    onMouseUp () {
      setTimeout(() => {
        this.isMouseDown = false
      }, 1)
    },
    onTransaction () {
      this.isBold = this.editor.isActive('bold')
      this.isItalic = this.editor.isActive('italic')
      this.isUnderline = this.editor.isActive('underline')
      this.isStrike = this.editor.isActive('strike')
    }
  }
}
</script>

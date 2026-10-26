<template>
  <div
    v-if="visible"
    ref="menu"
    class="absolute z-10 flex flex-col gap-1 p-1 bg-white border border-neutral-200 rounded-lg shadow-lg select-none text-sm"
    :style="{ top: coords.top + 'px', left: menuLeft + 'px' }"
    @mousedown.prevent
  >
    <div class="flex items-center gap-0.5">
      <div class="relative">
        <button
          class="flex items-center justify-between gap-1 w-24 sm:w-36 h-7 px-2 border border-neutral-200 rounded-md hover:bg-neutral-100"
          :title="t('font')"
          @click="toggleDropdown('font')"
        >
          <span
            class="truncate"
            :style="{ fontFamily }"
          >{{ fontFamily }}</span>
          <IconChevronDown
            :width="14"
            :height="14"
          />
        </button>
        <div
          v-if="dropdown === 'font'"
          ref="dropdown"
          :class="isDropdownAlignedRight ? 'right-0' : 'left-0'"
          class="absolute z-10 top-full mt-1 w-48 p-1 bg-white border border-neutral-200 rounded-lg shadow-lg max-h-64 overflow-y-auto"
        >
          <button
            v-for="font in fonts"
            :key="font.label"
            class="block w-full text-left px-2 py-1 rounded-md truncate"
            :class="font.label === fontFamily ? 'bg-neutral-200' : 'hover:bg-neutral-100'"
            :style="{ fontFamily: font.value }"
            @click="setSpanStyle('font-family', font.value)"
          >
            {{ font.label }}
          </button>
        </div>
      </div>
      <div class="relative">
        <button
          class="flex items-center justify-between gap-1 w-12 sm:w-16 h-7 px-2 border border-neutral-200 rounded-md hover:bg-neutral-100"
          :title="t('font_size')"
          @click="toggleDropdown('size')"
        >
          <span>{{ fontSize }}</span>
          <IconChevronDown
            :width="14"
            :height="14"
          />
        </button>
        <div
          v-if="dropdown === 'size'"
          ref="dropdown"
          :class="isDropdownAlignedRight ? 'right-0' : 'left-0'"
          class="absolute z-10 top-full mt-1 w-16 p-1 bg-white border border-neutral-200 rounded-lg shadow-lg max-h-64 overflow-y-auto"
        >
          <button
            v-for="size in fontSizes"
            :key="size"
            class="block w-full text-left px-2 py-1 rounded-md"
            :class="size === fontSize ? 'bg-neutral-200' : 'hover:bg-neutral-100'"
            @click="setFontSize(size)"
          >
            {{ size }}
          </button>
        </div>
      </div>
      <button
        class="inline-flex items-center justify-center w-7 h-7 rounded-md hover:bg-neutral-100"
        :title="t('increase_font_size')"
        @click="setFontSize(fontSizes.find((size) => size > fontSize) || fontSize)"
      >
        <IconTextIncrease
          :width="16"
          :height="16"
        />
      </button>
      <button
        class="inline-flex items-center justify-center w-7 h-7 rounded-md hover:bg-neutral-100"
        :title="t('decrease_font_size')"
        @click="setFontSize([...fontSizes].reverse().find((size) => size < fontSize) || fontSize)"
      >
        <IconTextDecrease
          :width="16"
          :height="16"
        />
      </button>
      <div class="w-px h-5 bg-neutral-200 mx-1" />
      <div class="relative">
        <button
          class="inline-flex items-center justify-center h-7 px-1 rounded-md hover:bg-neutral-100"
          :title="t('line_spacing')"
          @click="toggleDropdown('lineHeight')"
        >
          <IconLineHeight
            :width="16"
            :height="16"
          />
          <IconChevronDown
            :width="12"
            :height="12"
          />
        </button>
        <div
          v-if="dropdown === 'lineHeight'"
          ref="dropdown"
          :class="isDropdownAlignedRight ? 'right-0' : 'left-0'"
          class="absolute z-10 top-full mt-1 w-20 p-1 bg-white border border-neutral-200 rounded-lg shadow-lg"
        >
          <button
            v-for="value in lineHeights"
            :key="value"
            class="block w-full text-left px-2 py-1 rounded-md"
            :class="value === lineHeight ? 'bg-neutral-200' : 'hover:bg-neutral-100'"
            @click="setBlockStyle('line-height', `calc(${value} * 1.15)`)"
          >
            {{ value }}
          </button>
        </div>
      </div>
      <div class="relative">
        <button
          class="inline-flex items-center justify-center h-7 px-1 rounded-md hover:bg-neutral-100"
          :title="t('align')"
          @click="toggleDropdown('align')"
        >
          <component
            :is="alignIcons[textAlign]"
            :width="16"
            :height="16"
          />
          <IconChevronDown
            :width="12"
            :height="12"
          />
        </button>
        <div
          v-if="dropdown === 'align'"
          ref="dropdown"
          :class="isDropdownAlignedRight ? 'right-0' : 'left-0'"
          class="absolute z-10 top-full mt-1 w-max flex gap-0.5 p-1 bg-white border border-neutral-200 rounded-lg shadow-lg"
        >
          <button
            v-for="(icon, align) in alignIcons"
            :key="align"
            class="inline-flex items-center justify-center w-7 h-7 rounded-md"
            :class="align === textAlign ? 'bg-neutral-200' : 'hover:bg-neutral-100'"
            :title="t(align)"
            @click="setBlockStyle('text-align', align)"
          >
            <component
              :is="icon"
              :width="16"
              :height="16"
            />
          </button>
        </div>
      </div>
      <div class="relative">
        <button
          class="inline-flex items-center justify-center h-7 px-1 rounded-md"
          :class="listStyle ? 'bg-neutral-200' : 'hover:bg-neutral-100'"
          :title="t('bullet_list')"
          @click="toggleDropdown('list')"
        >
          <IconList
            :width="16"
            :height="16"
          />
          <IconChevronDown
            :width="12"
            :height="12"
          />
        </button>
        <div
          v-if="dropdown === 'list'"
          ref="dropdown"
          :class="isDropdownAlignedRight ? 'right-0' : 'left-0'"
          class="absolute z-10 top-full mt-1 w-28 p-1 bg-white border border-neutral-200 rounded-lg shadow-lg"
        >
          <button
            v-for="({ label, marker }, style) in listStyles"
            :key="style"
            class="flex items-center gap-2 w-full px-2 py-1 rounded-md"
            :class="style === listStyle ? 'bg-neutral-200' : 'hover:bg-neutral-100'"
            @click="toggleList(style)"
          >
            <span class="w-4 text-center">{{ marker }}</span>
            {{ label }}
          </button>
        </div>
      </div>
    </div>
    <div class="flex items-center gap-0.5">
      <button
        class="inline-flex items-center justify-center w-7 h-7 rounded-md"
        :class="isBold ? 'bg-neutral-200' : 'hover:bg-neutral-100'"
        :title="t('bold')"
        @click="toggleBold"
      >
        <IconBold
          :width="16"
          :height="16"
        />
      </button>
      <button
        class="inline-flex items-center justify-center w-7 h-7 rounded-md"
        :class="isItalic ? 'bg-neutral-200' : 'hover:bg-neutral-100'"
        :title="t('italic')"
        @click="toggleItalic"
      >
        <IconItalic
          :width="16"
          :height="16"
        />
      </button>
      <button
        class="inline-flex items-center justify-center w-7 h-7 rounded-md"
        :class="isUnderline ? 'bg-neutral-200' : 'hover:bg-neutral-100'"
        :title="t('underline')"
        @click="toggleUnderline"
      >
        <IconUnderline
          :width="16"
          :height="16"
        />
      </button>
      <button
        class="inline-flex items-center justify-center w-7 h-7 rounded-md"
        :class="isStrike ? 'bg-neutral-200' : 'hover:bg-neutral-100'"
        :title="t('strikethrough')"
        @click="toggleStrike"
      >
        <IconStrikethrough
          :width="16"
          :height="16"
        />
      </button>
      <div class="w-px h-5 bg-neutral-200 mx-1" />
      <div
        v-for="colorProperty in ['color', 'background-color']"
        :key="colorProperty"
        class="relative"
      >
        <button
          class="inline-flex items-center justify-center h-7 px-1 rounded-md hover:bg-neutral-100"
          :title="colorProperty === 'color' ? t('text_color') : t('background_color')"
          @click="toggleDropdown(colorProperty)"
        >
          <span class="flex flex-col items-center">
            <component
              :is="colorProperty === 'color' ? 'IconLetterA' : 'IconHighlight'"
              :width="16"
              :height="14"
            />
            <span
              class="w-4 h-1 rounded-sm border border-neutral-200"
              :style="{ backgroundColor: colorProperty === 'color' ? color : backgroundColor }"
            />
          </span>
          <IconChevronDown
            :width="12"
            :height="12"
          />
        </button>
        <div
          v-if="dropdown === colorProperty"
          ref="dropdown"
          :class="isDropdownAlignedRight ? 'right-0' : 'left-0'"
          class="absolute z-10 top-full mt-1 w-max p-2 bg-white border border-neutral-200 rounded-lg shadow-lg"
        >
          <button
            class="flex items-center gap-1 w-full mb-2 px-2 py-1 rounded-md hover:bg-neutral-100"
            @click="setSpanStyle(colorProperty, null)"
          >
            <IconX
              :width="14"
              :height="14"
            />
            {{ colorProperty === 'color' ? t('default') : t('none') }}
          </button>
          <div class="grid grid-cols-10 gap-1">
            <button
              v-for="value in colors"
              :key="value"
              class="w-4 h-4 rounded-sm border border-neutral-200 hover:scale-125 transition-transform"
              :style="{ backgroundColor: value }"
              :title="value"
              @click="setSpanStyle(colorProperty, value)"
            />
          </div>
        </div>
      </div>
      <div class="w-px h-5 bg-neutral-200 mx-1 sm:mx-0.5" />
      <button
        class="inline-flex items-center justify-center text-xs h-7 px-1 rounded-md"
        :class="isCellSelection ? 'opacity-50 cursor-not-allowed' : 'hover:bg-neutral-100'"
        :title="t('create_variable')"
        :disabled="isCellSelection"
        @click="wrapVariable"
      >
        <IconBracketsContain
          :width="16"
          :height="16"
          :stroke-width="1.6"
        />
        <span class="hidden sm:inline px-0.5 font-mono">
          {{ t('variable') }}
        </span>
      </button>
      <div class="w-px h-5 bg-neutral-200 mx-1 sm:mx-0.5" />
      <button
        class="inline-flex items-center justify-center text-xs h-7 px-1 rounded-md"
        :class="isCellSelection ? 'opacity-50 cursor-not-allowed' : 'hover:bg-neutral-100'"
        :title="t('create_condition')"
        :disabled="isCellSelection"
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
        <span class="hidden sm:inline px-0.5 font-mono">
          {{ t('condition') }}
        </span>
      </button>
    </div>
  </div>
</template>

<script>
import { IconBold, IconItalic, IconUnderline, IconStrikethrough, IconBracketsContain, IconChevronDown, IconTextIncrease, IconTextDecrease, IconLineHeight, IconAlignLeft, IconAlignCenter, IconAlignRight, IconAlignJustified, IconLetterA, IconHighlight, IconList, IconX } from '@tabler/icons-vue'
import { CellSelection } from '@tiptap/pm/tables'
import { findNumbering, numberingListStyle } from './dynamic_editor.js'

export default {
  name: 'DynamicMenu',
  components: {
    IconBold,
    IconItalic,
    IconUnderline,
    IconStrikethrough,
    IconBracketsContain,
    IconChevronDown,
    IconTextIncrease,
    IconTextDecrease,
    IconLineHeight,
    IconLetterA,
    IconHighlight,
    IconList,
    IconX
  },
  inject: ['t', 'documentFonts'],
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
  emits: ['add-variable', 'add-condition', 'add-list'],
  data () {
    return {
      isMouseDown: false,
      dropdown: null,
      isDropdownAlignedRight: false,
      menuWidth: 0,
      isBold: false,
      isItalic: false,
      isUnderline: false,
      isStrike: false,
      fontFamily: '',
      fontSize: 12,
      color: '',
      backgroundColor: '',
      lineHeight: '',
      textAlign: 'left',
      listStyle: null,
      isCellSelection: false
    }
  },
  computed: {
    visible () {
      return !!this.coords && !this.isMouseDown
    },
    menuLeft () {
      return Math.max(4, Math.min(this.coords.left - this.menuWidth / 2, this.coords.width - this.menuWidth - 4))
    },
    standardFonts () {
      return [
        { label: 'Arial', value: 'Arial' },
        { label: 'Times New Roman', value: "'Times New Roman'" },
        { label: 'Courier New', value: "'Courier New'" }
      ]
    },
    fonts () {
      return [
        ...this.documentFonts.filter((font) => !this.standardFonts.some((standardFont) => standardFont.label === font.label)),
        ...this.standardFonts
      ]
    },
    fontSizes () {
      return [8, 9, 10, 10.5, 11, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48, 72]
    },
    lineHeights () {
      return ['1', '1.15', '1.5', '2', '2.5', '3']
    },
    alignIcons () {
      return {
        left: IconAlignLeft,
        center: IconAlignCenter,
        right: IconAlignRight,
        justify: IconAlignJustified
      }
    },
    listStyles () {
      return {
        disc: { label: this.t('dots'), marker: '•' },
        dash: { label: this.t('dash'), marker: '–' },
        decimal: { label: this.t('numbers'), marker: '1.' }
      }
    },
    colors () {
      return [
        '#000000', '#434343', '#666666', '#999999', '#b7b7b7', '#cccccc', '#d9d9d9', '#efefef', '#f3f3f3', '#ffffff',
        '#980000', '#ff0000', '#ff9900', '#ffff00', '#00ff00', '#00ffff', '#4a86e8', '#0000ff', '#9900ff', '#ff00ff',
        '#e6b8af', '#f4cccc', '#fce5cd', '#fff2cc', '#d9ead3', '#d0e0e3', '#c9daf8', '#cfe2f3', '#d9d2e9', '#ead1dc',
        '#cc4125', '#e06666', '#f6b26b', '#ffd966', '#93c47d', '#76a5af', '#6d9eeb', '#6fa8dc', '#8e7cc3', '#c27ba0',
        '#85200c', '#990000', '#b45f06', '#bf9000', '#38761d', '#134f5c', '#1155cc', '#0b5394', '#351c75', '#741b47'
      ]
    }
  },
  watch: {
    visible (value) {
      this.dropdown = null

      if (value) {
        this.readState()
        this.$nextTick(this.measure)
      }
    }
  },
  mounted () {
    this.editor.view.dom.parentElement.addEventListener('mousedown', this.onMouseDown)

    document.addEventListener('mouseup', this.onMouseUp)

    this.editor.on('transaction', this.onTransaction)
  },
  beforeUnmount () {
    if (!this.editor.isDestroyed) {
      this.editor.view.dom.parentElement.removeEventListener('mousedown', this.onMouseDown)
      this.editor.off('transaction', this.onTransaction)
    }

    document.removeEventListener('mouseup', this.onMouseUp)
  },
  methods: {
    measure () {
      if (this.$refs.menu) {
        this.menuWidth = this.$refs.menu.offsetWidth
      }
    },
    toggleDropdown (name) {
      this.dropdown = this.dropdown === name ? null : name
      this.isDropdownAlignedRight = false

      this.$nextTick(() => {
        const dropdownEl = [this.$refs.dropdown].flat()[0]

        if (!dropdownEl) return

        const dropdownRect = dropdownEl.getBoundingClientRect()
        const containerRect = this.$el.parentElement.getBoundingClientRect()

        this.isDropdownAlignedRight = dropdownRect.right > containerRect.right
      })
    },
    toggleBold () {
      this.toggleStyledMark('bold', 'font-weight', this.isBold, (style) => parseInt(style.fontWeight) >= 600)
    },
    toggleItalic () {
      this.toggleStyledMark('italic', 'font-style', this.isItalic, (style) => style.fontStyle === 'italic')
    },
    toggleStyledMark (markName, property, isActive, isStyled) {
      const isSegmentStyled = ({ from }) => isStyled(getComputedStyle(this.textElementAt(from)))

      if (isActive) {
        this.editor.chain().focus().unsetMark(markName).setListMarkerStyle(property, null).run()

        if (this.selectedTextSegments().some(isSegmentStyled)) {
          this.editor.chain().setSpanStyle(property, 'normal').run()
        }
      } else {
        this.editor.chain().focus().setSpanStyle(property, null).run()

        const { state, view } = this.editor
        const tr = state.tr

        this.selectedTextSegments().forEach((segment) => {
          if (!isSegmentStyled(segment)) tr.addMark(segment.from, segment.to, state.schema.marks[markName].create())
        })

        if (tr.docChanged) view.dispatch(tr)

        this.editor.commands.setListMarkerStyle(property, markName)
      }
    },
    selectedTextSegments () {
      const { state } = this.editor
      const segments = []

      state.selection.ranges.forEach(({ $from, $to }) => state.doc.nodesBetween($from.pos, $to.pos, (node, pos) => {
        if (node.isText) segments.push({ from: Math.max(pos, $from.pos), to: Math.min(pos + node.nodeSize, $to.pos) })
      }))

      return segments
    },
    textElementAt (pos) {
      const { node, offset } = this.editor.view.domAtPos(pos, 1)

      if (node.nodeType === Node.TEXT_NODE) return node.parentElement

      return node.childNodes[offset]?.nodeType === Node.ELEMENT_NODE ? node.childNodes[offset] : node
    },
    toggleUnderline () {
      this.editor.chain().focus().toggleUnderline().run()
    },
    toggleStrike () {
      this.editor.chain().focus().toggleStrike().run()
    },
    setSpanStyle (property, value) {
      this.dropdown = null

      const chain = this.editor.chain().focus().setSpanStyle(property, value)

      if (property !== 'background-color') chain.setListMarkerStyle(property, value)

      chain.run()
    },
    setFontSize (size) {
      this.setSpanStyle('font-size', `${size}pt`)
    },
    setBlockStyle (property, value) {
      this.dropdown = null

      this.editor.chain().focus().setBlockStyle(property, value).run()
    },
    toggleList (style) {
      this.dropdown = null

      if (style !== this.listStyle) this.$emit('add-list')

      this.editor.chain().focus().toggleList(style).run()
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
      if (this.visible) {
        this.readState()
      }
    },
    readState () {
      const { view, state } = this.editor
      const { ranges } = state.selection
      const selectionFrom = Math.min(...ranges.map((range) => range.$from.pos))
      const selectionTo = Math.max(...ranges.map((range) => range.$to.pos))
      let from = null

      state.doc.nodesBetween(selectionFrom, selectionTo, (node, pos) => {
        if (from === null && node.isText) from = Math.max(pos, selectionFrom)
      })

      if (from === null) from = selectionFrom

      const $from = state.doc.resolve(from)
      const el = this.textElementAt(from)
      const style = getComputedStyle(el)
      const blockDom = $from.parent.isTextblock ? view.nodeDOM($from.before()) : view.dom
      const decorations = []

      this.isCellSelection = state.selection instanceof CellSelection
      this.isBold = parseInt(style.fontWeight) >= 600
      this.isItalic = style.fontStyle === 'italic'

      this.fontFamily = style.fontFamily.split(',')[0].replace(/["']/g, '').trim()
      this.fontSize = Math.round(parseFloat(style.fontSize) * 0.75 * 2) / 2
      this.color = style.color
      this.backgroundColor = 'transparent'

      for (let inlineEl = el; inlineEl && view.dom.contains(inlineEl); inlineEl = inlineEl.parentElement) {
        const { textDecorationLine, backgroundColor } = getComputedStyle(inlineEl)

        decorations.push(textDecorationLine)

        if (inlineEl === blockDom) break

        if (this.backgroundColor === 'transparent' && backgroundColor !== 'rgba(0, 0, 0, 0)' && backgroundColor !== 'transparent') {
          this.backgroundColor = backgroundColor
        }
      }

      this.isUnderline = this.editor.isActive('underline') || decorations.some((line) => line.includes('underline'))
      this.isStrike = this.editor.isActive('strike') || decorations.some((line) => line.includes('line-through'))

      if ($from.parent.isTextblock) {
        const blockStyle = getComputedStyle(blockDom)
        const align = blockStyle.textAlign.replace('start', 'left').replace('end', 'right')

        this.textAlign = this.alignIcons[align] ? align : 'left'
        this.lineHeight = String(Math.round(parseFloat(blockStyle.lineHeight) / parseFloat(blockStyle.fontSize) / 1.15 * 100) / 100)
      }

      this.listStyle = findNumbering($from.parent) ? numberingListStyle(view, $from.before()) : null
    }
  }
}
</script>

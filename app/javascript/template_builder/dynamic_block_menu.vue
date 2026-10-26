<template>
  <div
    class="absolute z-[5] pointer-events-none select-none"
    :style="{ top: coords.top + 'px', left: coords.left + 'px', width: coords.width + 'px', height: coords.height + 'px' }"
  >
    <div
      class="absolute left-0 bottom-0"
      :style="{ top: Math.max(coords.top - toolbarHeight - 2, 0) - coords.top + 'px' }"
    >
      <div
        ref="toolbar"
        class="sticky top-1.5 flex flex-col sm:flex-row gap-0.5 p-1 bg-white border border-neutral-200 rounded-lg shadow-lg pointer-events-auto"
        @mousedown.prevent
      >
        <div
          v-for="(row, rowIndex) in actionRows"
          :key="rowIndex"
          class="flex items-center gap-0.5"
        >
          <template
            v-for="(group, groupIndex) in row"
            :key="groupIndex"
          >
            <div
              v-if="rowIndex > 0 || groupIndex > 0"
              class="w-px h-5 bg-neutral-200 mx-1"
              :class="{ 'hidden sm:block': rowIndex > 0 && groupIndex === 0 }"
            />
            <button
              v-for="action in group"
              :key="action.title"
              class="inline-flex items-center justify-center w-7 h-7 rounded-md"
              :class="{ 'text-red-600': action.danger, 'bg-neutral-200': action.active, 'hover:bg-neutral-100': !action.active && !isDisabled(action), 'opacity-50 cursor-not-allowed': isDisabled(action) }"
              :title="action.structural && !coords.isRegular ? t('irregular_table_structure') : t(action.title)"
              :disabled="isDisabled(action)"
              @click="$emit('command', action.command, action.arg)"
            >
              <component
                :is="action.icon"
                :width="16"
                :height="16"
                :stroke-width="1.6"
              />
            </button>
          </template>
        </div>
      </div>
    </div>
    <div
      v-if="size"
      class="absolute top-0 left-0 border border-dashed border-blue-500"
      :style="{ width: size.width + 'px', height: size.height + 'px' }"
    />
    <div
      v-if="coords.type === 'table'"
      class="absolute w-3 h-3 bg-white border-2 border-blue-500 rounded-sm pointer-events-auto cursor-nwse-resize touch-none before:absolute before:-inset-3"
      :style="{ left: (size?.width ?? coords.width) - 6 + 'px', top: (size?.height ?? coords.height) - 6 + 'px' }"
      :title="t('resize')"
      @pointerdown.prevent.stop="startResize"
    />
  </div>
</template>

<script>
import { h } from 'vue'
import { IconAlignLeft, IconAlignCenter, IconAlignRight, IconRowInsertTop, IconRowInsertBottom, IconColumnInsertLeft, IconColumnInsertRight, IconRowRemove, IconColumnRemove, IconTrash } from '@tabler/icons-vue'

const IconMergeCells = (props) => h('svg', { xmlns: 'http://www.w3.org/2000/svg', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-linecap': 'round', 'stroke-linejoin': 'round', ...props }, [
  h('path', { d: 'M5 4h14a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-12a2 2 0 0 1 2 -2z' }),
  h('path', { d: 'M6 12h4m-2 -2l2 2l-2 2' }),
  h('path', { d: 'M18 12h-4m2 -2l-2 2l2 2' })
])

const IconSplitCell = (props) => h('svg', { xmlns: 'http://www.w3.org/2000/svg', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-linecap': 'round', 'stroke-linejoin': 'round', ...props }, [
  h('path', { d: 'M5 4h14a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-12a2 2 0 0 1 2 -2z' }),
  h('path', { d: 'M12 4v16' }),
  h('path', { d: 'M10 12h-4m2 -2l-2 2l2 2' }),
  h('path', { d: 'M14 12h4m-2 -2l2 2l-2 2' })
])

export default {
  name: 'DynamicBlockMenu',
  inject: ['t'],
  props: {
    coords: {
      type: Object,
      required: true
    },
    getResizeLimits: {
      type: Function,
      required: true
    }
  },
  emits: ['command', 'resize'],
  data () {
    return {
      size: null,
      toolbarHeight: 0
    }
  },
  computed: {
    actionRows () {
      const alignActions = [
        { command: 'setBlockAlign', arg: 'left', icon: IconAlignLeft, title: 'align_left', active: this.coords.align === 'left' },
        { command: 'setBlockAlign', arg: 'center', icon: IconAlignCenter, title: 'align_center', active: this.coords.align === 'center' },
        { command: 'setBlockAlign', arg: 'right', icon: IconAlignRight, title: 'align_right', active: this.coords.align === 'right' }
      ]

      if (this.coords.type !== 'table') {
        return [[alignActions, [{ command: 'deleteSelection', icon: IconTrash, title: 'delete_image', danger: true }]]]
      }

      return [
        [
          alignActions,
          [
            { command: 'addTableRow', arg: false, icon: IconRowInsertTop, title: 'insert_row_above', structural: true },
            { command: 'addTableRow', arg: true, icon: IconRowInsertBottom, title: 'insert_row_below', structural: true },
            { command: 'addTableColumn', arg: false, icon: IconColumnInsertLeft, title: 'insert_column_left', structural: true },
            { command: 'addTableColumn', arg: true, icon: IconColumnInsertRight, title: 'insert_column_right', structural: true }
          ]
        ],
        [
          [
            { command: 'mergeTableCells', icon: IconMergeCells, title: 'merge_cells', structural: true, disabled: !this.coords.canMerge },
            { command: 'splitTableCell', icon: IconSplitCell, title: 'split_cell', structural: true, disabled: !this.coords.canSplit }
          ],
          [
            { command: 'deleteTableRow', icon: IconRowRemove, title: 'delete_row', danger: true, structural: true },
            { command: 'deleteTableColumn', icon: IconColumnRemove, title: 'delete_column', danger: true, structural: true },
            { command: 'deleteTable', icon: IconTrash, title: 'delete_table', danger: true }
          ]
        ]
      ]
    }
  },
  mounted () {
    this.toolbarHeight = this.$refs.toolbar.offsetHeight
  },
  updated () {
    this.toolbarHeight = this.$refs.toolbar.offsetHeight
  },
  beforeUnmount () {
    window.removeEventListener('pointermove', this.onResizeMove)
    window.removeEventListener('pointerup', this.onResizeEnd)
  },
  methods: {
    isDisabled (action) {
      return (action.structural && !this.coords.isRegular) || action.disabled
    },
    startResize (event) {
      this.resizeStart = { x: event.clientX, y: event.clientY, width: this.coords.width, height: this.coords.height, ...this.getResizeLimits() }
      this.size = { width: this.coords.width, height: this.coords.height }

      window.addEventListener('pointermove', this.onResizeMove)
      window.addEventListener('pointerup', this.onResizeEnd)
    },
    onResizeMove (event) {
      const { x, y, width, height, minHeight, maxWidth } = this.resizeStart
      this.size = {
        width: Math.min(Math.max(width + event.clientX - x, 20), maxWidth),
        height: Math.max(height + event.clientY - y, minHeight)
      }
    },
    onResizeEnd () {
      window.removeEventListener('pointermove', this.onResizeMove)
      window.removeEventListener('pointerup', this.onResizeEnd)

      if (this.size.width !== this.coords.width || this.size.height !== this.coords.height) {
        this.$emit('resize', this.size)
      }

      this.size = null
    }
  }
}
</script>

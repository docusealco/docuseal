<template>
  <div
    ref="menu"
    class="fixed z-50 p-1 bg-white shadow-lg rounded-lg border border-base-300 cursor-default"
    style="min-width: 170px"
    :style="menuStyle"
    @mousedown.stop
    @pointerdown.stop
  >
    <button
      class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center justify-between text-sm"
      :class="!hasClipboardData ? 'opacity-50 cursor-not-allowed' : 'hover:bg-neutral-100'"
      :disabled="!hasClipboardData"
      @click.stop="!hasClipboardData ? null : $emit('paste')"
    >
      <span class="flex items-center space-x-2">
        <IconClipboard class="w-4 h-4" />
        <span>{{ t('paste') }}</span>
      </span>
      <span class="text-xs text-base-content/60 ml-4">{{ isMac ? '⌘V' : 'Ctrl+V' }}</span>
    </button>
    <button
      class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center justify-between text-sm"
      @click.stop="handleToggleSelectMode"
    >
      <span class="flex items-center space-x-2">
        <IconClick
          v-if="!isSelectModeRef.value"
          class="w-4 h-4"
        />
        <IconNewSection
          v-else
          class="w-4 h-4"
        />
        <span>{{ isSelectModeRef.value ? t('draw_fields') : t('select_fields') }}</span>
      </span>
      <span class="text-xs text-base-content/60 ml-4">Tab</span>
    </button>
    <hr
      v-if="showAutodetectFields"
      class="my-1 border-base-300"
    >
    <button
      v-if="showAutodetectFields"
      class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm"
      @click.stop="$emit('autodetect-fields')"
    >
      <IconSparkles class="w-4 h-4" />
      <span>{{ t('autodetect_fields') }}</span>
    </button>
  </div>
</template>

<script>
import { IconClipboard, IconClick, IconNewSection, IconSparkles } from '@tabler/icons-vue'

export default {
  name: 'PageContextMenu',
  components: {
    IconClipboard,
    IconClick,
    IconNewSection,
    IconSparkles
  },
  inject: ['t', 'isSelectModeRef'],
  props: {
    contextMenu: {
      type: Object,
      default: null,
      required: true
    },
    editable: {
      type: Boolean,
      default: true
    },
    withFieldsDetection: {
      type: Boolean,
      default: false
    }
  },
  emits: ['paste', 'close', 'autodetect-fields'],
  computed: {
    isMac () {
      return (navigator.userAgentData?.platform || navigator.platform)?.toLowerCase()?.includes('mac')
    },
    hasClipboardData () {
      try {
        const clipboard = localStorage.getItem('docuseal_clipboard')

        if (clipboard) {
          const data = JSON.parse(clipboard)

          return Date.now() - data.timestamp < 3600000
        }

        return false
      } catch {
        return false
      }
    },
    menuStyle () {
      return {
        left: this.contextMenu.x + 'px',
        top: this.contextMenu.y + 'px'
      }
    },
    showAutodetectFields () {
      return this.withFieldsDetection && this.editable
    }
  },
  mounted () {
    document.addEventListener('keydown', this.onKeyDown)
    document.addEventListener('mousedown', this.handleClickOutside)

    this.$nextTick(() => {
      this.checkMenuPosition()
    })
  },
  beforeUnmount () {
    document.removeEventListener('keydown', this.onKeyDown)
    document.removeEventListener('mousedown', this.handleClickOutside)
  },
  methods: {
    checkMenuPosition () {
      if (this.$refs.menu) {
        const rect = this.$refs.menu.getBoundingClientRect()
        const overflow = rect.bottom - window.innerHeight

        if (overflow > 0) {
          this.contextMenu.y = this.contextMenu.y - overflow - 4
        }
      }
    },
    onKeyDown (event) {
      if (event.key === 'Escape') {
        event.preventDefault()
        event.stopPropagation()

        this.$emit('close')
      } else if ((event.ctrlKey || event.metaKey) && event.key === 'v' && this.hasClipboardData) {
        event.preventDefault()
        event.stopPropagation()

        this.$emit('paste')
      }
    },
    handleClickOutside (event) {
      if (this.$refs.menu && !this.$refs.menu.contains(event.target)) {
        this.$emit('close')
      }
    },
    handleToggleSelectMode () {
      this.isSelectModeRef.value = !this.isSelectModeRef.value

      this.$emit('close')
    }
  }
}
</script>

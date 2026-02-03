<template>
  <div
    class="relative"
    @mouseenter="handleMouseEnter"
    @mouseleave="handleMouseLeave"
  >
    <button
      class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center justify-between text-sm"
      @click.stop="isOpen ? close() : open()"
    >
      <span class="flex items-center space-x-2">
        <component
          :is="icon || 'span'"
          class="w-4 h-4"
        />
        <span>{{ label }}</span>
      </span>
      <IconChevronRight class="w-4 h-4" />
    </button>
    <div
      v-if="isOpen"
      ref="submenu"
      class="absolute p-1 z-50 left-full bg-base-300 shadow-lg rounded-lg border border-neutral-200 cursor-default"
      style="min-width: 170px"
      :style="submenuStyle"
      :class="menuClass"
      @click.stop
    >
      <slot>
        <button
          v-for="option in options"
          :key="option.value"
          class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center justify-between space-x-2 text-sm cursor-pointer"
          @click="handleSelect(option.value)"
        >
          <span class="whitespace-nowrap">{{ option.label }}</span>
          <IconCheck
            v-if="modelValue === option.value"
            class="w-4 h-4"
          />
        </button>
      </slot>
    </div>
  </div>
</template>

<script>
import { IconChevronRight, IconCheck } from '@tabler/icons-vue'

export default {
  name: 'ContextSubmenu',
  components: {
    IconChevronRight,
    IconCheck
  },
  props: {
    icon: {
      type: [Function],
      required: false,
      default: null
    },
    label: {
      type: String,
      required: true
    },
    options: {
      type: Array,
      default: () => []
    },
    modelValue: {
      type: [String, Number],
      default: null
    },
    menuClass: {
      type: String,
      default: ''
    }
  },
  emits: ['select', 'update:modelValue'],
  data () {
    return {
      isOpen: false,
      topOffset: 0
    }
  },
  computed: {
    submenuStyle () {
      return {
        top: this.topOffset + 'px'
      }
    }
  },
  beforeUnmount () {
    this.clearTimeout()
  },
  methods: {
    handleMouseEnter () {
      clearTimeout(this.closeTimeout)

      this.openTimeout = setTimeout(() => this.open(), 200)
    },
    handleMouseLeave () {
      clearTimeout(this.openTimeout)

      this.closeTimeout = setTimeout(() => this.close(), 200)
    },
    open () {
      this.clearTimeout()

      this.isOpen = true
      this.topOffset = 0

      this.$nextTick(() => setTimeout(() => this.adjustPosition(), 0))
    },
    clearTimeout () {
      if (this.openTimeout) {
        clearTimeout(this.openTimeout)
      }

      if (this.closeTimeout) {
        clearTimeout(this.closeTimeout)
      }
    },
    close () {
      this.clearTimeout()

      this.isOpen = false
    },
    handleSelect (value) {
      this.$emit('select', value)
      this.$emit('update:modelValue', value)
    },
    adjustPosition () {
      if (!this.$refs.submenu) return

      const rect = this.$refs.submenu.getBoundingClientRect()
      const overflow = rect.bottom - window.innerHeight

      if (overflow > 0) {
        this.topOffset = -overflow - 4
      } else {
        this.topOffset = 0
      }
    }
  }
}
</script>

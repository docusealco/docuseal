<template>
  <div v-if="inline">
    <slot />
  </div>
  <div
    v-else
    class="fixed inset-0 z-40"
    :class="{ 'pointer-events-none': !open }"
  >
    <div
      class="absolute inset-0 bg-black transition-opacity duration-300"
      :class="open ? 'opacity-25' : 'opacity-0'"
      @click="$emit('close')"
      @dragenter="$emit('close')"
      @touchmove.prevent
    />
    <div
      ref="panel"
      class="absolute top-0 bottom-0 bg-base-100 shadow-xl overflow-y-auto overflow-x-hidden overscroll-contain px-4 transition-transform duration-300 ease-out"
      style="width: 82%; max-width: 340px"
      :class="[side === 'left' ? 'left-0' : 'right-0', open ? 'translate-x-0' : (side === 'left' ? '-translate-x-full' : 'translate-x-full')]"
      @touchmove="onPanelTouchmove"
    >
      <slot />
    </div>
  </div>
</template>

<script>
export default {
  name: 'MobileDrawer',
  props: {
    side: {
      type: String,
      required: false,
      default: 'left'
    },
    open: {
      type: Boolean,
      required: false,
      default: false
    },
    inline: {
      type: Boolean,
      required: false,
      default: false
    }
  },
  emits: ['close'],
  watch: {
    open (value) {
      document.body.style.overflow = value ? 'hidden' : ''
    }
  },
  beforeUnmount () {
    if (this.open) {
      document.body.style.overflow = ''
    }
  },
  methods: {
    onPanelTouchmove (e) {
      if (this.$refs.panel.scrollHeight <= this.$refs.panel.clientHeight) {
        e.preventDefault()
      }
    }
  }
}
</script>

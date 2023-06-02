<template>
  <div
    class="absolute overflow-visible group"
    :style="positionStyle"
    @pointerdown.stop
    @mousedown.stop="startDrag"
  >
    <div
      v-if="field"
      class="absolute bg-white rounded-t border overflow-visible whitespace-nowrap hidden group-hover:block group-hover:z-10"
      style="top: -25px; height: 25px"
      @mousedown.stop
      @pointerdown.stop
    >
      <button
        v-for="(component, type, index) in iconComponents"
        :key="type"
        class="px-0.5 hover:text-base-100 hover:bg-base-content transition-colors"
        :class="{ 'bg-base-content text-base-100': field.type === type, 'rounded-tl': index === 0, 'rounded-tr': index === 4 }"
        @click="changeTypeTo(type)"
      >
        <component
          :is="component"
          :width="20"
          stroke-width="1.5"
        />
      </button>
    </div>
    <div
      class="bg-red-100 opacity-70 flex items-center justify-center h-full w-full"
    >
      {{ field?.name || field?.type }}
    </div>
    <span
      class="h-2 w-2 right-0 bottom-0 bg-red-900 absolute cursor-nwse-resize"
      @mousedown.stop="startResize"
    />
  </div>
</template>

<script>
import { IconTextSize, IconWriting, IconCalendarEvent, IconPhoto, IconCheckbox } from '@tabler/icons-vue'

export default {
  name: 'FieldArea',
  props: {
    bounds: {
      type: Object,
      required: false,
      default () {
        return {
          x: 0,
          y: 0,
          w: 0,
          h: 0
        }
      }
    },
    field: {
      type: Object,
      required: false,
      default: null
    }
  },
  emits: ['start-resize', 'stop-resize', 'start-drag', 'stop-drag'],
  data () {
    return {
      isResize: false,
      dragFrom: { x: 0, y: 0 }
    }
  },
  computed: {
    iconComponents () {
      return {
        text: IconTextSize,
        signature: IconWriting,
        date: IconCalendarEvent,
        image: IconPhoto,
        checkbox: IconCheckbox
      }
    },
    positionStyle () {
      const { x, y, w, h } = this.bounds

      return {
        top: y * 100 + '%',
        left: x * 100 + '%',
        width: w * 100 + '%',
        height: h * 100 + '%'
      }
    }
  },
  methods: {
    changeTypeTo (type) {
      this.field.type = type
    },
    resize (e) {
      if (e.toElement.id === 'mask') {
        this.bounds.w = e.layerX / e.toElement.clientWidth - this.bounds.x
        this.bounds.h = e.layerY / e.toElement.clientHeight - this.bounds.y
      }
    },
    drag (e) {
      if (e.toElement.id === 'mask') {
        this.bounds.x = (e.layerX - this.dragFrom.x) / e.toElement.clientWidth
        this.bounds.y = (e.layerY - this.dragFrom.y) / e.toElement.clientHeight
      }
    },
    startDrag (e) {
      const rect = e.target.getBoundingClientRect()

      this.dragFrom = { x: e.clientX - rect.left, y: e.clientY - rect.top }

      document.addEventListener('mousemove', this.drag)
      document.addEventListener('mouseup', this.stopDrag)

      this.$emit('start-drag')
    },
    stopDrag () {
      document.removeEventListener('mousemove', this.drag)
      document.removeEventListener('mouseup', this.stopDrag)

      this.$emit('stop-drag')
    },
    startResize () {
      document.addEventListener('mousemove', this.resize)
      document.addEventListener('mouseup', this.stopResize)

      this.$emit('start-resize')
    },
    stopResize () {
      document.removeEventListener('mousemove', this.resize)
      document.removeEventListener('mouseup', this.stopResize)

      this.$emit('stop-resize')
    }
  }
}
</script>

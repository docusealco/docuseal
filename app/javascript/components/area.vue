<template>
  <div
    class="bg-red-100 absolute opacity-70"
    :style="positionStyle"
    @mousedown="startDrag"
  >
    <div
      v-if="field"
      class="flex items-center justify-center h-full w-full"
    >
      {{ field?.name || field.type }}
    </div>
    <span
      class="h-2 w-2 right-0 bottom-0 bg-red-900 absolute cursor-nwse-resize"
      @mousedown.stop="startResize"
    />
  </div>
</template>

<script>
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
    resize (e) {
      this.bounds.w = e.layerX / e.toElement.clientWidth - this.bounds.x
      this.bounds.h = e.layerY / e.toElement.clientHeight - this.bounds.y
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

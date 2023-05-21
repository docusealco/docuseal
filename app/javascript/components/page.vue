<template>
  <div class="relative">
    <img
      ref="image"
      :src="image.url"
      :width="width"
      :height="height"
      loading="lazy"
    >
    <div
      class="top-0 bottom-0 left-0 right-0 absolute"
    >
      <FieldArea
        v-for="(item, i) in areas"
        :key="i"
        :scale="scale"
        :bounds="item.area"
        :field="item.field"
        @start-resize="showMask = true"
        @stop-resize="showMask = false"
        @start-drag="showMask = true"
        @stop-drag="showMask = false"
      />
      <FieldArea
        v-if="newArea"
        :scale="scale"
        :bounds="newArea"
      />
    </div>
    <div
      v-show="isDraw || showMask"
      id="mask"
      ref="mask"
      class="top-0 bottom-0 left-0 right-0 absolute"
      @pointerdown="onPointerdown"
      @pointermove="onPointermove"
      @pointerup="onPointerup"
    />
  </div>
</template>

<script>
import FieldArea from './area'

export default {
  name: 'FlowPage',
  components: {
    FieldArea
  },
  props: {
    image: {
      type: Object,
      required: true
    },
    areas: {
      type: Array,
      required: false,
      default: () => []
    },
    isDraw: {
      type: Boolean,
      required: false,
      default: false
    },
    number: {
      type: Number,
      required: true
    }
  },
  emits: ['draw'],
  data () {
    return {
      scale: 1,
      showMask: false,
      newArea: null
    }
  },
  computed: {
    width () {
      return this.image.metadata.width
    },
    height () {
      return this.image.metadata.height
    }
  },
  mounted () {
    this.resizeObserver = new ResizeObserver(this.onResize)

    this.resizeObserver.observe(this.$refs.image)
  },
  beforeUnmount () {
    this.resizeObserver.unobserve(this.$refs.image)
  },
  methods: {
    onResize () {
      this.scale = this.$refs.image.clientWidth / this.image.metadata.width
    },
    onPointerdown (e) {
      if (this.isDraw) {
        this.newArea = {
          initialX: e.layerX / this.scale,
          initialY: e.layerY / this.scale,
          x: e.layerX / this.scale,
          y: e.layerY / this.scale,
          w: 0,
          h: 0
        }
      }
    },
    onPointermove (e) {
      if (this.newArea) {
        const dx = e.layerX / this.scale - this.newArea.initialX
        const dy = e.layerY / this.scale - this.newArea.initialY

        if (dx > 0) {
          this.newArea.x = this.newArea.initialX
        } else {
          this.newArea.x = e.layerX / this.scale
        }

        if (dy > 0) {
          this.newArea.y = this.newArea.initialY
        } else {
          this.newArea.y = e.layerY / this.scale
        }

        this.newArea.w = Math.abs(dx)
        this.newArea.h = Math.abs(dy)
      }
    },
    onPointerup (e) {
      if (this.isDraw && this.newArea) {
        this.$emit('draw', {
          x: this.newArea.x,
          y: this.newArea.y,
          w: Math.max(this.newArea.w, 50),
          h: Math.max(this.newArea.h, 40),
          page: this.number
        })
      }

      this.newArea = null
    }
  }
}
</script>

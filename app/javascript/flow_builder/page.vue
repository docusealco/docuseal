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
        :bounds="item.area"
        :field="item.field"
        @start-resize="showMask = true"
        @stop-resize="showMask = false"
        @start-drag="showMask = true"
        @stop-drag="showMask = false"
      />
      <FieldArea
        v-if="newArea"
        :bounds="newArea"
      />
    </div>
    <div
      v-show="isDraw || isDrag || showMask"
      id="mask"
      ref="mask"
      class="top-0 bottom-0 left-0 right-0 absolute"
      @pointerdown="onPointerdown"
      @pointermove="onPointermove"
      @dragover.prevent
      @drop="onDrop"
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
    isDrag: {
      type: Boolean,
      required: false,
      default: false
    },
    number: {
      type: Number,
      required: true
    }
  },
  emits: ['draw', 'drop-field'],
  data () {
    return {
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
  methods: {
    onDrop (e) {
      this.$emit('drop-field', {
        x: e.layerX / this.$refs.mask.clientWidth,
        y: e.layerY / this.$refs.mask.clientHeight - (this.$refs.mask.clientWidth / 30 / this.$refs.mask.clientWidth) / 2,
        w: this.$refs.mask.clientWidth / 5 / this.$refs.mask.clientWidth,
        h: this.$refs.mask.clientWidth / 30 / this.$refs.mask.clientWidth,
        page: this.number
      })
    },
    onPointerdown (e) {
      if (this.isDraw) {
        this.newArea = {
          initialX: e.layerX / this.$refs.mask.clientWidth,
          initialY: e.layerY / this.$refs.mask.clientHeight,
          x: e.layerX / this.$refs.mask.clientWidth,
          y: e.layerY / this.$refs.mask.clientHeight,
          w: 0,
          h: 0
        }
      }
    },
    onPointermove (e) {
      if (this.newArea) {
        const dx = e.layerX / this.$refs.mask.clientWidth - this.newArea.initialX
        const dy = e.layerY / this.$refs.mask.clientHeight - this.newArea.initialY

        if (dx > 0) {
          this.newArea.x = this.newArea.initialX
        } else {
          this.newArea.x = e.layerX / this.$refs.mask.clientWidth
        }

        if (dy > 0) {
          this.newArea.y = this.newArea.initialY
        } else {
          this.newArea.y = e.layerY / this.$refs.mask.clientHeight
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
          w: Math.max(this.newArea.w, this.$refs.mask.clientWidth / 5 / this.$refs.mask.clientWidth),
          h: Math.max(this.newArea.h, this.$refs.mask.clientWidth / 30 / this.$refs.mask.clientWidth),
          page: this.number
        })
      }

      this.newArea = null
    }
  }
}
</script>

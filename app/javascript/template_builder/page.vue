<template>
  <div class="relative cursor-crosshair select-none">
    <img
      ref="image"
      :src="image.url"
      :width="width"
      class="shadow-md mb-4"
      :height="height"
      loading="lazy"
    >
    <div
      class="top-0 bottom-0 left-0 right-0 absolute"
      @pointerdown="onStartDraw"
    >
      <FieldArea
        v-for="(item, i) in areas"
        :key="i"
        :ref="setAreaRefs"
        :area="item.area"
        :field="item.field"
        @start-resize="[showMask = true, isResize = true]"
        @stop-resize="[showMask = false, isResize = false]"
        @start-drag="[showMask = true, isMove = true]"
        @stop-drag="[showMask = false, isMove = false]"
        @remove="$emit('remove-area', item)"
      />
      <FieldArea
        v-if="newArea"
        :field="{ submitter_uuid: selectedSubmitter.uuid }"
        :area="newArea"
      />
    </div>
    <div
      v-show="isDrag || showMask"
      id="mask"
      ref="mask"
      class="top-0 bottom-0 left-0 right-0 absolute z-10"
      :class="{ 'cursor-grab': isDrag || isMove, 'cursor-nwse-resize': isResize || isDraw }"
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
  name: 'TemplatePage',
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
    selectedSubmitter: {
      type: Object,
      required: true
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
  emits: ['draw', 'drop-field', 'remove-area'],
  data () {
    return {
      areaRefs: [],
      showMask: false,
      isMove: false,
      isResize: false,
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
  beforeUpdate () {
    this.areaRefs = []
  },
  methods: {
    setAreaRefs (el) {
      if (el) {
        this.areaRefs.push(el)
      }
    },
    onDrop (e) {
      this.$emit('drop-field', {
        x: e.layerX,
        y: e.layerY,
        maskW: this.$refs.mask.clientWidth,
        maskH: this.$refs.mask.clientHeight,
        page: this.number
      })
    },
    onStartDraw (e) {
      this.showMask = true

      this.$nextTick(() => {
        this.newArea = {
          initialX: e.layerX / this.$refs.mask.clientWidth,
          initialY: e.layerY / this.$refs.mask.clientHeight,
          x: e.layerX / this.$refs.mask.clientWidth,
          y: e.layerY / this.$refs.mask.clientHeight,
          w: 0,
          h: 0
        }
      })
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
      if (this.newArea) {
        this.$emit('draw', {
          x: this.newArea.x,
          y: this.newArea.y,
          w: this.newArea.w,
          h: this.newArea.h,
          page: this.number
        })
      }

      this.showMask = false
      this.newArea = null
    }
  }
}
</script>

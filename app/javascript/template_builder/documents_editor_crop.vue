<template>
  <div class="flex flex-1 min-h-0">
    <div
      class="flex-1 min-h-0 flex items-center justify-center px-6 py-4"
      style="container-type: size"
    >
      <div
        ref="pageEl"
        class="relative select-none"
        :style="pageStyle"
      >
        <img
          :src="imageUrl"
          :width="metadata.width"
          :height="metadata.height"
          class="absolute border rounded pointer-events-none"
          style="left: 50%; top: 50%; width: 100%; height: auto"
          :style="imageStyle"
        >
        <svg
          class="absolute inset-0 w-full h-full pointer-events-none"
          viewBox="0 0 100 100"
          preserveAspectRatio="none"
        >
          <path
            :d="dimPath"
            fill="black"
            fill-opacity="0.4"
            fill-rule="evenodd"
          />
          <polygon
            :points="polygonPoints"
            fill="none"
            stroke="white"
            stroke-width="0.4"
            vector-effect="non-scaling-stroke"
          />
        </svg>
        <div
          v-for="(corner, cornerIndex) in displayCorners"
          :key="cornerIndex"
          class="absolute w-5 h-5 -ml-2.5 -mt-2.5 rounded-full bg-white border-2 border-neutral-600 cursor-move shadow"
          :style="{ left: `${corner.x * 100}%`, top: `${corner.y * 100}%` }"
          @mousedown.prevent="onCornerMousedown(cornerIndex)"
          @touchstart.prevent="onCornerTouchstart(cornerIndex)"
        />
      </div>
    </div>
    <div class="w-56 flex-none border-l px-4 py-4 space-y-2 flex flex-col">
      <button
        class="btn btn-sm w-full justify-start normal-case font-normal rounded disabled:bg-base-300"
        :disabled="!!isProcessing"
        @click.prevent="submit(true)"
      >
        <IconInnerShadowTop
          v-if="isProcessing === 'scan'"
          class="w-4 h-4 animate-spin"
        />
        <IconScan
          v-else
          class="w-4 h-4"
        />
        {{ t('crop_and_scan') }}
      </button>
      <button
        class="btn btn-sm w-full justify-start normal-case font-normal rounded disabled:bg-base-300"
        :disabled="!!isProcessing"
        @click.prevent="submit(false)"
      >
        <IconInnerShadowTop
          v-if="isProcessing === 'crop'"
          class="w-4 h-4 animate-spin"
        />
        <IconCrop
          v-else
          width="22"
          height="22"
          style="margin-left: -3px"
          :stroke-width="1.5"
        />
        <span :style="{ 'margin-left': isProcessing === 'crop' ? '0px' : '-3px' }">
          {{ t('crop') }}
        </span>
      </button>
      <button
        class="btn btn-sm w-full justify-start normal-case font-normal rounded"
        @click.prevent="$emit('cancel')"
      >
        <IconX class="w-4 h-4" />
        {{ t('cancel') }}
      </button>
      <div class="border-t !mt-3 !mb-1" />
      <button
        class="btn btn-sm w-full justify-start normal-case font-normal rounded"
        @click.prevent="rotateCw"
      >
        <IconRotateClockwise class="w-4 h-4" />
        {{ t('rotate') }}
      </button>
      <button
        class="btn btn-sm w-full justify-start normal-case font-normal rounded"
        :class="{ 'btn-active': flipH }"
        @click.prevent="toggleFlip('flipH')"
      >
        <IconFlipVertical class="w-4 h-4" />
        {{ t('flip_horizontal') }}
      </button>
      <button
        class="btn btn-sm w-full justify-start normal-case font-normal rounded"
        :class="{ 'btn-active': flipV }"
        @click.prevent="toggleFlip('flipV')"
      >
        <IconFlipHorizontal class="w-4 h-4" />
        {{ t('flip_vertical') }}
      </button>
    </div>
  </div>
</template>

<script>
import { IconCrop, IconScan, IconInnerShadowTop, IconX, IconRotateClockwise, IconFlipHorizontal, IconFlipVertical } from '@tabler/icons-vue'

export default {
  name: 'DocumentsEditorCrop',
  components: {
    IconCrop,
    IconScan,
    IconInnerShadowTop,
    IconX,
    IconRotateClockwise,
    IconFlipHorizontal,
    IconFlipVertical
  },
  inject: ['t', 'baseFetch', 'isInlineSize'],
  props: {
    templateId: {
      type: [Number, String],
      required: true
    },
    page: {
      type: Object,
      required: true
    },
    imageUrl: {
      type: String,
      required: true
    },
    metadata: {
      type: Object,
      required: true
    }
  },
  emits: ['apply', 'cancel'],
  data () {
    return {
      corners: [
        { x: 0, y: 0 },
        { x: 1, y: 0 },
        { x: 1, y: 1 },
        { x: 0, y: 1 }
      ],
      cornersTouched: false,
      rotate: this.page.rotate || 0,
      flipH: false,
      flipV: false,
      draggingIndex: null,
      isProcessing: null
    }
  },
  computed: {
    displayWidth () {
      return this.rotate % 180 ? this.metadata.height : this.metadata.width
    },
    displayHeight () {
      return this.rotate % 180 ? this.metadata.width : this.metadata.height
    },
    pageStyle () {
      const ratio = this.displayWidth / this.displayHeight

      return {
        aspectRatio: `${this.displayWidth} / ${this.displayHeight}`,
        width: this.isInlineSize ? `min(100cqw, calc(100cqh * ${ratio}))` : `min(100%, calc(78vh * ${ratio}))`
      }
    },
    imageStyle () {
      const scale = this.rotate % 180 ? this.metadata.width / this.metadata.height : 1
      const scaleX = (this.flipH ? -1 : 1) * scale
      const scaleY = (this.flipV ? -1 : 1) * scale

      return {
        transform: `translate(-50%, -50%) rotate(${this.rotate}deg) scale(${scaleX}, ${scaleY})`
      }
    },
    displayCorners () {
      return this.corners.map((corner) => this.transformPoint(corner, this.rotate, this.flipH, this.flipV))
    },
    polygonPoints () {
      return this.displayCorners.map((corner) => `${corner.x * 100},${corner.y * 100}`).join(' ')
    },
    dimPath () {
      const quad = this.displayCorners.map((corner) => `${corner.x * 100} ${corner.y * 100}`)

      return `M 0 0 H 100 V 100 H 0 Z M ${quad.join(' L ')} Z`
    }
  },
  created () {
    const query = new URLSearchParams({ attachment_uuid: this.page.sourceUuid })

    this.baseFetch(`/templates/${this.templateId}/documents_crop?${query}`).then(async (resp) => {
      if (resp.ok) {
        const data = await resp.json()

        if (data.corners?.length === 4 && !this.cornersTouched) {
          this.corners = data.corners.map((corner) => ({ x: corner.x, y: corner.y }))
        }
      }
    })
  },
  beforeUnmount () {
    window.removeEventListener('mousemove', this.onMousemove)
    window.removeEventListener('mouseup', this.onMouseup)
    window.removeEventListener('touchmove', this.onTouchmove)
    window.removeEventListener('touchend', this.onTouchend)
    window.removeEventListener('touchcancel', this.onTouchend)
  },
  methods: {
    transformPoint (point, rotate, flipH, flipV) {
      let { x, y } = point

      if (flipH) {
        x = 1 - x
      }

      if (flipV) {
        y = 1 - y
      }

      if (rotate === 90) {
        return { x: 1 - y, y: x }
      } else if (rotate === 180) {
        return { x: 1 - x, y: 1 - y }
      } else if (rotate === 270) {
        return { x: y, y: 1 - x }
      } else {
        return { x, y }
      }
    },
    inverseTransformPoint (point, rotate, flipH, flipV) {
      let { x, y } = point

      if (rotate === 90) {
        [x, y] = [y, 1 - x]
      } else if (rotate === 180) {
        [x, y] = [1 - x, 1 - y]
      } else if (rotate === 270) {
        [x, y] = [1 - y, x]
      }

      if (flipH) {
        x = 1 - x
      }

      if (flipV) {
        y = 1 - y
      }

      return { x, y }
    },
    rotateCw () {
      this.rotate = (this.rotate + 90) % 360
    },
    toggleFlip (key) {
      this[key] = !this[key]
    },
    pagePoint (event) {
      const rect = this.$refs.pageEl.getBoundingClientRect()

      return {
        x: Math.min(Math.max((event.clientX - rect.left) / rect.width, 0), 1),
        y: Math.min(Math.max((event.clientY - rect.top) / rect.height, 0), 1)
      }
    },
    startCornerDrag (index) {
      this.draggingIndex = index
      this.cornersTouched = true
    },
    dragCorner (point) {
      if (this.draggingIndex === null) {
        return
      }

      this.corners[this.draggingIndex] = this.inverseTransformPoint(this.pagePoint(point), this.rotate, this.flipH, this.flipV)
    },
    onCornerMousedown (index) {
      this.startCornerDrag(index)

      window.addEventListener('mousemove', this.onMousemove)
      window.addEventListener('mouseup', this.onMouseup, { once: true })
    },
    onMousemove (event) {
      this.dragCorner(event)
    },
    onMouseup () {
      window.removeEventListener('mousemove', this.onMousemove)

      this.draggingIndex = null
    },
    onCornerTouchstart (index) {
      this.startCornerDrag(index)

      window.addEventListener('touchmove', this.onTouchmove, { passive: false })
      window.addEventListener('touchend', this.onTouchend)
      window.addEventListener('touchcancel', this.onTouchend)
    },
    onTouchmove (event) {
      this.dragCorner(event.touches[0])
    },
    onTouchend () {
      window.removeEventListener('touchmove', this.onTouchmove)
      window.removeEventListener('touchend', this.onTouchend)
      window.removeEventListener('touchcancel', this.onTouchend)

      this.draggingIndex = null
    },
    submit (scan) {
      this.isProcessing = scan ? 'scan' : 'crop'

      this.baseFetch(`/templates/${this.templateId}/documents_crop`, {
        method: 'POST',
        body: JSON.stringify({
          attachment_uuid: this.page.sourceUuid,
          corners: this.corners,
          rotate: this.rotate || undefined,
          flip_h: this.flipH,
          flip_v: this.flipV,
          scan
        }),
        headers: { 'Content-Type': 'application/json' }
      }).then(async (resp) => {
        const data = await resp.json().catch(() => ({}))

        if (resp.ok) {
          this.$emit('apply', data.document)
        } else if (data.error) {
          alert(data.error)
        }
      }).finally(() => {
        this.isProcessing = null
      })
    }
  }
}
</script>

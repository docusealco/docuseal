<template>
  <div class="flex flex-1 min-h-0">
    <div class="flex-1 overflow-y-auto px-6 py-4">
      <div
        ref="pageEl"
        class="relative mx-auto select-none cursor-crosshair"
        :style="pageStyle"
        @mousedown.prevent="onMousedown"
        @touchstart.prevent="onTouchstart"
      >
        <img
          :src="imageUrl"
          :width="metadata.width"
          :height="metadata.height"
          class="absolute border rounded pointer-events-none"
          style="left: 50%; top: 50%; width: 100%; height: auto"
          :style="imageStyle"
        >
        <div
          class="absolute pointer-events-none"
          :style="overlayStyle"
        >
          <div
            v-for="(rect, rectIndex) in redactRects"
            :key="`rect-${rectIndex}`"
            class="absolute pointer-events-none"
            :class="color === 'white' ? 'bg-white' : 'bg-black'"
            :style="{
              left: `${rect.x * 100}%`,
              top: `${rect.y * 100}%`,
              width: `${rect.w * 100}%`,
              height: `${rect.h * 100}%`
            }"
          />
        </div>
        <div
          v-if="marquee"
          class="absolute border border-neutral-600 bg-neutral-600/10 pointer-events-none"
          :style="marqueeStyle"
        />
        <div
          v-if="!imagePage && textNodes && !textNodes.length && !imageNodes.length"
          class="absolute inset-x-0 top-0 flex justify-center pt-4 pointer-events-none"
        >
          <span class="bg-base-100/90 border border-neutral-200 rounded-lg shadow px-4 py-2 text-sm">
            {{ t('there_is_no_text_to_redact_on_this_page') }}
          </span>
        </div>
      </div>
    </div>
    <div class="w-56 flex-none border-l px-4 py-4 space-y-2">
      <div class="flex items-center justify-between mb-1">
        <span class="text-sm pl-1">{{ t('color') }}</span>
        <div
          class="join rounded"
          style="height: 28px"
        >
          <button
            v-for="option in colors"
            :key="option"
            class="btn btn-sm join-item !h-7 !min-h-0 bg-white input-bordered hover:border-base-content/20 hover:bg-base-100/50 px-2"
            :class="{ '!bg-base-200': color === option }"
            @click.prevent="color = option"
          >
            <span
              class="block w-10 h-4 border border-base-content/30"
              :style="{ backgroundColor: option }"
            />
          </button>
        </div>
      </div>
      <button
        class="btn btn-sm w-full justify-start normal-case font-normal rounded disabled:bg-base-300"
        :disabled="!hasRedactions && !wasReset"
        @click.prevent="apply"
      >
        <IconCheck class="w-4 h-4" />
        {{ t('apply') }}
      </button>
      <div class="border-t !mt-3 !mb-1" />
      <button
        class="btn btn-sm w-full justify-start normal-case font-normal rounded disabled:bg-base-300"
        :disabled="!hasRedactions"
        @click.prevent="reset"
      >
        <IconRotate class="w-4 h-4" />
        {{ t('reset') }}
      </button>
      <button
        class="btn btn-sm w-full justify-start normal-case font-normal rounded"
        @click.prevent="$emit('cancel')"
      >
        <IconX class="w-4 h-4" />
        {{ t('cancel') }}
      </button>
    </div>
  </div>
</template>

<script>
import { IconCheck, IconRotate, IconX } from '@tabler/icons-vue'

export default {
  name: 'DocumentsEditorRedact',
  components: {
    IconCheck,
    IconRotate,
    IconX
  },
  inject: ['t', 'baseFetch'],
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
    },
    imagePage: {
      type: Boolean,
      required: false,
      default: false
    },
    pageObjectsCache: {
      type: Object,
      required: false,
      default: () => ({})
    }
  },
  emits: ['apply', 'cancel'],
  data () {
    return {
      textNodes: null,
      imageNodes: [],
      selectedNodes: {},
      freeRects: [],
      rects: [],
      color: 'black',
      wasReset: false,
      marquee: null
    }
  },
  computed: {
    colors () {
      return ['black', 'white']
    },
    rotate () {
      return this.page.rotate || 0
    },
    displayWidth () {
      return this.rotate % 180 ? this.metadata.height : this.metadata.width
    },
    displayHeight () {
      return this.rotate % 180 ? this.metadata.width : this.metadata.height
    },
    pageStyle () {
      return { aspectRatio: `${this.displayWidth} / ${this.displayHeight}` }
    },
    imageStyle () {
      const scale = this.rotate % 180 ? this.metadata.width / this.metadata.height : 1

      return {
        transform: `translate(-50%, -50%) rotate(${this.rotate}deg) scale(${scale})`
      }
    },
    overlayStyle () {
      if (!this.rotate || !(this.rotate % 180)) {
        return { inset: '0', transform: this.rotate ? `rotate(${this.rotate}deg)` : undefined }
      }

      return {
        left: '50%',
        top: '50%',
        width: '100%',
        aspectRatio: `${this.metadata.width} / ${this.metadata.height}`,
        transform: `translate(-50%, -50%) rotate(${this.rotate}deg) scale(${this.metadata.width / this.metadata.height})`
      }
    },
    hasRedactions () {
      if (this.imagePage) {
        return this.rects.length > 0
      }

      return Object.keys(this.selectedNodes).length > 0 || this.freeRects.length > 0
    },
    redactRects () {
      if (this.imagePage) {
        return this.rects
      }

      return this.textNodes ? [...this.buildRedactRects(), ...this.freeRects] : []
    },
    marqueeStyle () {
      const left = Math.min(this.marquee.x1, this.marquee.x2)
      const top = Math.min(this.marquee.y1, this.marquee.y2)

      return {
        left: `${left * 100}%`,
        top: `${top * 100}%`,
        width: `${Math.abs(this.marquee.x2 - this.marquee.x1) * 100}%`,
        height: `${Math.abs(this.marquee.y2 - this.marquee.y1) * 100}%`
      }
    }
  },
  created () {
    if ((this.page.redact || []).some((rect) => rect.color === 'white')) {
      this.color = 'white'
    }

    if (this.imagePage) {
      this.rects = (this.page.redact || []).map((rect) => ({ ...rect }))

      return
    }

    const cacheKey = `${this.page.sourceUuid}-${this.page.sourcePage}`

    if (this.pageObjectsCache[cacheKey]) {
      this.textNodes = this.pageObjectsCache[cacheKey].text_nodes
      this.imageNodes = this.pageObjectsCache[cacheKey].image_nodes

      this.preselectNodes()

      return
    }

    const query = new URLSearchParams({ attachment_uuid: this.page.sourceUuid, page: this.page.sourcePage })

    this.baseFetch(`/templates/${this.templateId}/documents_page_objects?${query}`).then(async (resp) => {
      if (resp.ok) {
        const data = await resp.json()

        this.pageObjectsCache[cacheKey] = data
        this.textNodes = data.text_nodes
        this.imageNodes = data.image_nodes

        this.preselectNodes()
      } else {
        this.$emit('cancel')
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
    inverseRotatePoint (point, rotate) {
      let { x, y } = point

      if (rotate === 90) {
        [x, y] = [y, 1 - x]
      } else if (rotate === 180) {
        [x, y] = [1 - x, 1 - y]
      } else if (rotate === 270) {
        [x, y] = [1 - y, x]
      }

      return { x, y }
    },
    apply () {
      const rects = this.redactRects.map((rect) => {
        const next = { x: rect.x, y: rect.y, w: rect.w, h: rect.h }

        if (this.color === 'white') {
          next.color = 'white'
        }

        return next
      })

      this.$emit('apply', rects)
    },
    reset () {
      this.wasReset = true

      if (this.imagePage) {
        this.rects = []
      } else {
        this.selectedNodes = {}
        this.freeRects = []
      }
    },
    boxesIntersect (a, b) {
      return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y
    },
    preselectNodes () {
      const nodeRects = []

      ;(this.page.redact || []).forEach((rect) => {
        if (this.imageNodes.some((node) => this.boxesIntersect(node, rect))) {
          this.freeRects.push({ ...rect })
        } else {
          nodeRects.push(rect)
        }
      })

      this.textNodes.forEach((node, index) => {
        const centerX = node.x + (node.w / 2)
        const centerY = node.y + (node.h / 2)

        const isInside = nodeRects.some((rect) => {
          return centerX >= rect.x && centerX <= rect.x + rect.w &&
            centerY >= rect.y && centerY <= rect.y + rect.h
        })

        if (isInside) {
          this.selectedNodes[index] = true
        }
      })
    },
    buildRedactRects () {
      const nodes = this.textNodes.filter((_, index) => this.selectedNodes[index])

      const sorted = nodes.slice().sort((a, b) => {
        const diff = (a.y + (a.h / 2)) - (b.y + (b.h / 2))

        return Math.abs(diff) < Math.min(a.h, b.h) / 2 ? a.x - b.x : diff
      })

      const rects = []

      sorted.forEach((node) => {
        const last = rects[rects.length - 1]

        const sameLine = last &&
          Math.abs((node.y + (node.h / 2)) - (last.y + (last.h / 2))) < Math.max(last.h, node.h) / 2

        if (sameLine && node.x <= last.x + last.w + (node.h * 0.7)) {
          const right = Math.max(last.x + last.w, node.x + node.w)
          const bottom = Math.max(last.y + last.h, node.y + node.h)

          last.x = Math.min(last.x, node.x)
          last.y = Math.min(last.y, node.y)
          last.w = right - last.x
          last.h = bottom - last.y
        } else {
          rects.push({ x: node.x, y: node.y, w: node.w, h: node.h })
        }
      })

      return rects
    },
    pagePoint (event) {
      const rect = this.$refs.pageEl.getBoundingClientRect()

      return {
        x: Math.min(Math.max((event.clientX - rect.left) / rect.width, 0), 1),
        y: Math.min(Math.max((event.clientY - rect.top) / rect.height, 0), 1)
      }
    },
    startMarquee (point) {
      const start = this.pagePoint(point)

      this.marquee = { x1: start.x, y1: start.y, x2: start.x, y2: start.y }
    },
    updateMarquee (point) {
      if (!this.marquee) {
        return
      }

      const next = this.pagePoint(point)

      this.marquee.x2 = next.x
      this.marquee.y2 = next.y
    },
    onMousedown (event) {
      if (event.button !== 0 || (!this.imagePage && !this.textNodes)) {
        return
      }

      this.startMarquee(event)

      window.addEventListener('mousemove', this.onMousemove)
      window.addEventListener('mouseup', this.onMouseup, { once: true })
    },
    onMousemove (event) {
      this.updateMarquee(event)
    },
    onMouseup () {
      window.removeEventListener('mousemove', this.onMousemove)

      this.finishMarquee()
    },
    onTouchstart (event) {
      if (!this.imagePage && !this.textNodes) {
        return
      }

      this.startMarquee(event.touches[0])

      window.addEventListener('touchmove', this.onTouchmove, { passive: false })
      window.addEventListener('touchend', this.onTouchend)
      window.addEventListener('touchcancel', this.onTouchend)
    },
    onTouchmove (event) {
      this.updateMarquee(event.touches[0])
    },
    onTouchend () {
      window.removeEventListener('touchmove', this.onTouchmove)
      window.removeEventListener('touchend', this.onTouchend)
      window.removeEventListener('touchcancel', this.onTouchend)

      this.finishMarquee()
    },
    finishMarquee () {
      if (!this.marquee) {
        return
      }

      const start = this.inverseRotatePoint({ x: this.marquee.x1, y: this.marquee.y1 }, this.rotate)
      const finish = this.inverseRotatePoint({ x: this.marquee.x2, y: this.marquee.y2 }, this.rotate)

      const left = Math.min(start.x, finish.x)
      const right = Math.max(start.x, finish.x)
      const top = Math.min(start.y, finish.y)
      const bottom = Math.max(start.y, finish.y)

      this.marquee = null

      if (right - left < 0.005 && bottom - top < 0.005) {
        if (this.imagePage) {
          const index = this.rects.findIndex((rect) => {
            return left >= rect.x && left <= rect.x + rect.w && top >= rect.y && top <= rect.y + rect.h
          })

          if (index !== -1) {
            this.rects.splice(index, 1)
          }
        } else {
          const rectIndex = this.freeRects.findIndex((rect) => {
            return left >= rect.x && left <= rect.x + rect.w && top >= rect.y && top <= rect.y + rect.h
          })

          if (rectIndex !== -1) {
            this.freeRects.splice(rectIndex, 1)
          } else {
            const index = this.textNodes.findIndex((node) => {
              return left >= node.x && left <= node.x + node.w && top >= node.y && top <= node.y + node.h
            })

            if (index !== -1) {
              if (this.selectedNodes[index]) {
                delete this.selectedNodes[index]
              } else {
                this.selectedNodes[index] = true
              }
            }
          }
        }
      } else if (this.imagePage) {
        this.rects.push({ x: left, y: top, w: right - left, h: bottom - top })
      } else {
        const marqueeBox = { x: left, y: top, w: right - left, h: bottom - top }

        this.textNodes.forEach((node, index) => {
          if (node.x < right && node.x + node.w > left && node.y < bottom && node.y + node.h > top) {
            this.selectedNodes[index] = true
          }
        })

        this.imageNodes.forEach((node) => {
          if (!this.boxesIntersect(node, marqueeBox)) {
            return
          }

          const x = Math.max(node.x, marqueeBox.x)
          const y = Math.max(node.y, marqueeBox.y)
          const w = Math.min(node.x + node.w, marqueeBox.x + marqueeBox.w) - x
          const h = Math.min(node.y + node.h, marqueeBox.y + marqueeBox.h) - y

          this.freeRects.push({ x, y, w, h })
        })
      }
    }
  }
}
</script>

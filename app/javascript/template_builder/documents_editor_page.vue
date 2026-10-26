<template>
  <div class="relative">
    <div
      class="relative"
      :style="boxStyle"
    >
      <img
        :src="imageUrl"
        :width="metadata.width"
        :height="metadata.height"
        class="rounded border pointer-events-none outline outline-1 -outline-offset-1 transition-[outline-color] duration-75"
        :class="[
          page.rotate % 180 ? 'absolute inset-0 m-auto w-full' : 'w-full',
          selected ? 'outline-neutral-400' : 'outline-transparent'
        ]"
        :style="imageStyle"
        :loading="lazy ? 'lazy' : 'eager'"
      >
      <div
        v-if="areas.length || page.redact.length"
        class="absolute pointer-events-none"
        :style="overlayStyle"
      >
        <div
          v-for="(item, areaIndex) in areas"
          :key="areaIndex"
          class="absolute border rounded-sm opacity-70"
          :class="[areaBorderColor(item.submitterIndex), areaBgColor(item.submitterIndex)]"
          :style="{
            left: `${item.area.x * 100}%`,
            top: `${item.area.y * 100}%`,
            width: `${item.area.w * 100}%`,
            height: `${item.area.h * 100}%`
          }"
        />
        <div
          v-for="(rect, rectIndex) in page.redact"
          :key="`redact-${rectIndex}`"
          class="absolute"
          :class="rect.color === 'white' ? 'bg-white' : 'bg-black'"
          :style="{
            left: `${rect.x * 100}%`,
            top: `${rect.y * 100}%`,
            width: `${rect.w * 100}%`,
            height: `${rect.h * 100}%`
          }"
        />
      </div>
      <div
        v-if="withActions"
        class="absolute top-1 right-1 flex space-x-1 group-hover:opacity-100"
        :class="selected ? 'opacity-100' : 'opacity-0'"
      >
        <span
          v-if="extraAction"
          class="tooltip tooltip-bottom"
          :data-tip="t(extraAction)"
        >
          <button
            class="btn border-gray-300 bg-white text-base-content btn-xs rounded hover:text-base-100 hover:bg-base-content hover:border-base-content transition-colors p-0"
            style="width: 22px; height: 22px; min-height: 22px"
            @click.stop.prevent="$emit(extraAction)"
          >
            <IconEraser
              v-if="extraAction === 'redact'"
              :width="14"
              :height="14"
              :stroke-width="1.6"
            />
            <IconCrop
              v-else
              :width="20"
              :height="20"
              :stroke-width="1.2"
            />
          </button>
        </span>
        <span
          class="tooltip tooltip-bottom"
          :data-tip="t('rotate')"
        >
          <button
            class="btn border-gray-300 bg-white text-base-content btn-xs rounded hover:text-base-100 hover:bg-base-content hover:border-base-content transition-colors p-0"
            style="width: 22px; height: 22px; min-height: 22px"
            @click.stop.prevent="$emit('rotate')"
          >
            <IconRotateClockwise
              :width="14"
              :height="14"
              :stroke-width="1.6"
            />
          </button>
        </span>
        <span
          class="tooltip tooltip-bottom"
          :data-tip="t('remove')"
        >
          <button
            class="btn border-gray-300 bg-white text-base-content btn-xs rounded hover:text-base-100 hover:bg-base-content hover:border-base-content transition-colors p-0"
            style="width: 22px; height: 22px; min-height: 22px"
            @click.stop.prevent="$emit('remove')"
          >
            <IconX
              :width="14"
              :height="14"
              :stroke-width="1.6"
            />
          </button>
        </span>
      </div>
    </div>
    <div
      v-if="pageNumber"
      class="text-center text-sm pt-1 pointer-events-none"
    >
      {{ t('page') }} {{ pageNumber }}
    </div>
  </div>
</template>

<script>
import { IconRotateClockwise, IconX, IconEraser, IconCrop } from '@tabler/icons-vue'
import Area from './area.vue'

export default {
  name: 'DocumentsEditorPage',
  components: {
    IconRotateClockwise,
    IconX,
    IconEraser,
    IconCrop
  },
  inject: ['t'],
  props: {
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
    areas: {
      type: Array,
      required: false,
      default: () => []
    },
    selected: {
      type: Boolean,
      required: false,
      default: false
    },
    withActions: {
      type: Boolean,
      required: false,
      default: false
    },
    pageNumber: {
      type: Number,
      required: false,
      default: null
    },
    lazy: {
      type: Boolean,
      required: false,
      default: true
    },
    extraAction: {
      type: String,
      required: false,
      default: null
    }
  },
  emits: ['rotate', 'remove', 'redact', 'crop'],
  computed: {
    borderColors: Area.computed.borderColors,
    bgColors: Area.computed.bgColors,
    boxStyle () {
      if (!this.page.rotate || !(this.page.rotate % 180)) {
        return null
      }

      return { aspectRatio: `${this.metadata.height} / ${this.metadata.width}` }
    },
    imageStyle () {
      if (!this.page.rotate) {
        return null
      }

      let transform = `rotate(${this.page.rotate}deg)`

      if (this.page.rotate % 180) {
        transform += ` scale(${this.metadata.width / this.metadata.height})`
      }

      return { transform }
    },
    overlayStyle () {
      if (!this.page.rotate || !(this.page.rotate % 180)) {
        return { inset: '0', transform: this.page.rotate ? `rotate(${this.page.rotate}deg)` : undefined }
      }

      return {
        left: '50%',
        top: '50%',
        width: '100%',
        aspectRatio: `${this.metadata.width} / ${this.metadata.height}`,
        transform: `translate(-50%, -50%) rotate(${this.page.rotate}deg) scale(${this.metadata.width / this.metadata.height})`
      }
    }
  },
  methods: {
    areaBorderColor (submitterIndex) {
      return this.borderColors[Math.max(submitterIndex, 0) % this.borderColors.length]
    },
    areaBgColor (submitterIndex) {
      return this.bgColors[Math.max(submitterIndex, 0) % this.bgColors.length]
    }
  }
}
</script>

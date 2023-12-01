<template>
  <div
    class="absolute overflow-visible group"
    :style="positionStyle"
    @pointerdown.stop
    @mousedown.stop="startDrag"
    @touchstart="startTouchDrag"
  >
    <div
      v-if="isSelected || isDraw"
      class="top-0 bottom-0 right-0 left-0 absolute border border-1.5 pointer-events-none"
      :class="borderColors[submitterIndex]"
    />
    <div
      v-if="field.type === 'cells' && (isSelected || isDraw)"
      class="top-0 bottom-0 right-0 left-0 absolute"
    >
      <div
        v-for="(cellW, index) in cells"
        :key="index"
        class="absolute top-0 bottom-0 border-r"
        :class="borderColors[submitterIndex]"
        :style="{ left: (cellW / area.w * 100) + '%' }"
      >
        <span
          v-if="index === 0 && editable"
          class="h-2.5 w-2.5 rounded-full -bottom-1 border-gray-400 bg-white shadow-md border absolute cursor-ew-resize z-10"
          style="left: -4px"
          @mousedown.stop="startResizeCell"
        />
      </div>
    </div>
    <div
      v-if="field?.type"
      class="absolute bg-white rounded-t border overflow-visible whitespace-nowrap group-hover:flex group-hover:z-10"
      :class="{ 'flex z-10': isNameFocus || isSelected, invisible: !isNameFocus && !isSelected }"
      style="top: -25px; height: 25px"
      @mousedown.stop
      @pointerdown.stop
    >
      <FieldSubmitter
        v-if="(field.type !== 'my_text')"
        v-model="field.submitter_uuid"
        class="border-r"
        :compact="true"
        :editable="editable"
        :menu-classes="'dropdown-content bg-white menu menu-xs p-2 shadow rounded-box w-52 rounded-t-none -left-[1px]'"
        :submitters="template.submitters"
        @update:model-value="save"
        @click="selectedAreaRef.value = area"
      />
      <FieldType
        v-if="(field.type !== 'my_text')"
        v-model="field.type"
        :button-width="27"
        :editable="editable"
        :button-classes="'px-1'"
        :menu-classes="'bg-white rounded-t-none'"
        @update:model-value="[maybeUpdateOptions(), save()]"
        @click="selectedAreaRef.value = area"
      />
      <span
        v-if="field.type !== 'checkbox' || field.name"
        ref="name"
        :contenteditable="editable"
        class="pr-1 cursor-text outline-none block"
        style="min-width: 2px"
        @keydown.enter.prevent="onNameEnter"
        @focus="onNameFocus"
        @blur="onNameBlur"
      >{{ optionIndexText }} {{ field.name || defaultName }}</span>
      <div
        v-if="isNameFocus && !['checkbox', 'phone', 'redact', 'my_text'].includes(field.type)"
        class="flex items-center ml-1.5"
      >
        <input
          :id="`required-checkbox-${field.uuid}`"
          v-model="field.required"
          type="checkbox"
          class="checkbox checkbox-xs no-animation rounded"
          @mousedown.prevent
        >
        <label
          :for="`required-checkbox-${field.uuid}`"
          class="label text-xs"
          @click.prevent="field.required = !field.required"
          @mousedown.prevent
        >Required</label>
      </div>
      <button
        v-else-if="editable"
        class="pr-1"
        title="Remove"
        @click.prevent="$emit('remove')"
      >
        <IconX width="14" />
      </button>
    </div>
    <div
      v-if="field.type === 'redact'"
      class="opacity-100 flex items-center justify-center h-full w-full bg-redact"
    >
      <span
        v-if="field"
        class="flex justify-center items-center space-x-1 h-full"
      >
        <component
          :is="fieldIcons[field.type]"
          width="100%"
          height="100%"
          class="max-h-10 text-white"
        />
      </span>
    </div>
    <!-- adding editable textarea for prefills -->
    <div
      v-else-if="field.type === 'my_text'"
      class="flex items-center justify-center h-full w-full"
      style="background-color: rgb(185, 185, 185);"
    >
      <textarea
        :id="field.uuid"
        ref="textarea"
        :value="myLocalText"
        style="border-width: 2px; --tw-bg-opacity: 1; --tw-border-opacity: 0.2;"
        class="!text-2xl w-full h-full"
        :placeholder="`type here`"
        :name="`values[${field.uuid}]`"
        @input="makeMyText"
      />
    </div>
    <div
      v-else
      class="flex items-center h-full w-full"
      :class="[bgColors[submitterIndex], field?.default_value ? '' : 'justify-center']"
    >
      <span
        v-if="field"
        class="flex justify-center items-center space-x-1 h-full"
      >
        <div
          v-if="field?.default_value"
          :class="{ 'text-[1.5vw] lg:text-base': !textOverflowChars, 'text-[1.0vw] lg:text-xs': textOverflowChars }"
        >
          <div
            ref="textContainer"
            class="flex items-center px-0.5"
          >
            <span class="whitespace-pre-wrap">{{ field.default_value }}</span>
          </div>
        </div>
        <component
          :is="fieldIcons[field.type]"
          v-else
          width="100%"
          height="100%"
          class="max-h-10 opacity-50"
        />
      </span>
    </div>
    <div
      v-if="field.type !== 'my_text'"
      ref="touchTarget"
      class="absolute top-0 bottom-0 right-0 left-0 cursor-pointer"
    />
    <span
      v-if="field?.type && editable"
      class="h-4 w-4 md:h-2.5 md:w-2.5 -right-1 rounded-full -bottom-1 border-gray-400 bg-white shadow-md border absolute cursor-nwse-resize"
      @mousedown.stop="startResize"
      @touchstart="startTouchResize"
    />
  </div>
</template>

<script>
import FieldSubmitter from './field_submitter'
import FieldType from './field_type'
import Field from './field'
import { IconX, IconWriting } from '@tabler/icons-vue'
import { v4 } from 'uuid'

export default {
  name: 'FieldArea',
  components: {
    FieldType,
    FieldSubmitter,
    IconX,
    IconWriting
  },
  inject: ['template', 'selectedAreaRef', 'save'],
  props: {
    area: {
      type: Object,
      required: true
    },
    isDraw: {
      type: Boolean,
      required: false,
      default: false
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    },
    field: {
      type: Object,
      required: false,
      default: null
    }
  },
  emits: ['start-resize', 'stop-resize', 'start-drag', 'stop-drag', 'remove', 'update:myText'],
  data () {
    return {
      isResize: false,
      isDragged: false,
      isNameFocus: false,
      myLocalText: '',
      textOverflowChars: 0,
      dragFrom: { x: 0, y: 0 }
    }
  },
  computed: {
    defaultName: Field.computed.defaultName,
    fieldNames: FieldType.computed.fieldNames,
    fieldIcons: FieldType.computed.fieldIcons,
    optionIndexText () {
      if (this.area.option_uuid && this.field.options) {
        return `${this.field.options.findIndex((o) => o.uuid === this.area.option_uuid) + 1}.`
      } else {
        return ''
      }
    },
    cells () {
      const cells = []

      let currentWidth = 0

      while (currentWidth + (this.area.cell_w + this.area.cell_w / 4) < this.area.w) {
        currentWidth += this.area.cell_w || 9999999

        cells.push(currentWidth)
      }

      return cells
    },
    submitter () {
      return this.template.submitters.find((s) => s.uuid === this.field.submitter_uuid)
    },
    submitterIndex () {
      return this.template.submitters.indexOf(this.submitter)
    },
    borderColors () {
      return [
        'border-red-500/50',
        'border-sky-500/50',
        'border-emerald-500/50',
        'border-yellow-300/50',
        'border-purple-600/50',
        'border-pink-500/50',
        'border-cyan-500/50',
        'border-orange-500/50',
        'border-lime-500/50',
        'border-indigo-500/50'
      ]
    },
    bgColors () {
      return [
        'bg-red-100/50',
        'bg-sky-100/50',
        'bg-emerald-100/50',
        'bg-yellow-100/50',
        'bg-purple-100/50',
        'bg-pink-100/50',
        'bg-cyan-100/50',
        'bg-orange-100/50',
        'bg-lime-100/50',
        'bg-indigo-100/50'
      ]
    },
    isSelected () {
      return this.selectedAreaRef.value === this.area
    },
    positionStyle () {
      const { x, y, w, h } = this.area

      return {
        top: y * 100 + '%',
        left: x * 100 + '%',
        width: w * 100 + '%',
        height: h * 100 + '%'
      }
    }
  },
  watch: {
    'field.default_value' () {
      if (this.field.type === 'text' && this.field.default_value && this.$refs.textContainer && (this.textOverflowChars === 0 || (this.textOverflowChars - 4) > this.field.default_value.length)) {
        this.textOverflowChars = this.$el.clientHeight < this.$refs.textContainer.clientHeight ? this.field.default_value.length : 0
      }
    }
  },
  mounted () {
    if (this.field.type === 'my_text') {
      const fieldUuid = this.field.uuid
      if (this.template.values && this.template.values[fieldUuid]) {
        this.myLocalText = this.template.values[fieldUuid]
      } else {
        this.myLocalText = ''
      }
    }

    if (this.field.type === 'text' && this.field.default_value && this.$refs.textContainer && (this.textOverflowChars === 0 || (this.textOverflowChars - 4) > this.field.default_value)) {
      this.$nextTick(() => {
        this.textOverflowChars = this.$el.clientHeight < this.$refs.textContainer.clientHeight ? this.field.default_value.length : 0
      })
    }
  },
  methods: {
    makeMyText (e) {
      this.myLocalText = e.target.value ? e.target.value : this.myLocalText
      this.sendSaveText(
        { [this.field.uuid]: e.target.value }
      )
    },
    sendSaveText (event) {
      this.$emit('update:myText', event)
    },
    onNameFocus (e) {
      this.selectedAreaRef.value = this.area

      this.isNameFocus = true
      this.$refs.name.style.minWidth = this.$refs.name.clientWidth + 'px'

      if (!this.field.name) {
        setTimeout(() => {
          this.$refs.name.innerText = ' '
        }, 1)
      }
    },
    startResizeCell (e) {
      this.$el.getRootNode().addEventListener('mousemove', this.onResizeCell)
      this.$el.getRootNode().addEventListener('mouseup', this.stopResizeCell)

      this.$emit('start-resize', 'ew')
    },
    stopResizeCell (e) {
      this.$el.getRootNode().removeEventListener('mousemove', this.onResizeCell)
      this.$el.getRootNode().removeEventListener('mouseup', this.stopResizeCell)

      this.$emit('stop-resize')

      this.save()
    },
    onResizeCell (e) {
      if (e.target.id === 'mask') {
        const positionX = e.layerX / (e.target.clientWidth - 1)

        if (positionX > this.area.x) {
          this.area.cell_w = positionX - this.area.x
        }
      }
    },
    maybeUpdateOptions () {
      delete this.field.default_value

      if (!['radio', 'multiple', 'select'].includes(this.field.type)) {
        delete this.field.options
      }

      if (['select', 'multiple', 'radio'].includes(this.field.type)) {
        this.field.options ||= [{ value: '', uuid: v4() }]
      }

      (this.field.areas || []).forEach((area) => {
        if (this.field.type === 'cells') {
          area.cell_w = area.w * 2 / Math.floor(area.w / area.h)
        } else {
          delete area.cell_w
        }
      })
    },
    onNameBlur (e) {
      const text = this.$refs.name.innerText.trim()

      this.isNameFocus = false
      this.$refs.name.style.minWidth = ''

      if (text) {
        this.field.name = text
      } else {
        this.field.name = ''
        this.$refs.name.innerText = this.defaultName
      }

      this.save()
    },
    onNameEnter (e) {
      this.$refs.name.blur()
    },
    resize (e) {
      if (e.target.id === 'mask') {
        this.area.w = e.layerX / e.target.clientWidth - this.area.x
        this.area.h = e.layerY / e.target.clientHeight - this.area.y
      }
    },
    drag (e) {
      if (e.target.id === 'mask') {
        this.isDragged = true

        this.area.x = (e.layerX - this.dragFrom.x) / e.target.clientWidth
        this.area.y = (e.layerY - this.dragFrom.y) / e.target.clientHeight
      }
    },
    startDrag (e) {
      this.selectedAreaRef.value = this.area

      if (!this.editable) {
        return
      }

      const rect = e.target.getBoundingClientRect()

      this.dragFrom = { x: e.clientX - rect.left, y: e.clientY - rect.top }

      this.$el.getRootNode().addEventListener('mousemove', this.drag)
      this.$el.getRootNode().addEventListener('mouseup', this.stopDrag)

      this.$emit('start-drag')
    },
    startTouchDrag (e) {
      if (e.target !== this.$refs.touchTarget) {
        return
      }

      this.$refs?.name?.blur()

      e.preventDefault()

      this.isDragged = true

      const rect = e.target.getBoundingClientRect()

      this.selectedAreaRef.value = this.area

      this.dragFrom = { x: rect.left - e.touches[0].clientX, y: rect.top - e.touches[0].clientY }

      this.$el.getRootNode().addEventListener('touchmove', this.touchDrag)
      this.$el.getRootNode().addEventListener('touchend', this.stopTouchDrag)

      this.$emit('start-drag')
    },
    touchDrag (e) {
      const page = this.$parent.$refs.mask.previousSibling
      const rect = page.getBoundingClientRect()

      this.area.x = (this.dragFrom.x + e.touches[0].clientX - rect.left) / rect.width
      this.area.y = (this.dragFrom.y + e.touches[0].clientY - rect.top) / rect.height
    },
    stopTouchDrag () {
      this.$el.getRootNode().removeEventListener('touchmove', this.touchDrag)
      this.$el.getRootNode().removeEventListener('touchend', this.stopTouchDrag)

      if (this.isDragged) {
        this.save()
      }

      this.isDragged = false

      this.$emit('stop-drag')
    },
    stopDrag () {
      this.$el.getRootNode().removeEventListener('mousemove', this.drag)
      this.$el.getRootNode().removeEventListener('mouseup', this.stopDrag)

      if (this.isDragged) {
        this.save()
      }

      this.isDragged = false

      this.$emit('stop-drag')
    },
    startResize () {
      this.selectedAreaRef.value = this.area

      this.$el.getRootNode().addEventListener('mousemove', this.resize)
      this.$el.getRootNode().addEventListener('mouseup', this.stopResize)

      this.$emit('start-resize', 'nwse')
    },
    stopResize () {
      this.$el.getRootNode().removeEventListener('mousemove', this.resize)
      this.$el.getRootNode().removeEventListener('mouseup', this.stopResize)

      this.$emit('stop-resize')

      this.save()
    },
    startTouchResize (e) {
      this.selectedAreaRef.value = this.area

      this.$refs?.name?.blur()

      e.preventDefault()

      this.$el.getRootNode().addEventListener('touchmove', this.touchResize)
      this.$el.getRootNode().addEventListener('touchend', this.stopTouchResize)

      this.$emit('start-resize', 'nwse')
    },
    touchResize (e) {
      const page = this.$parent.$refs.mask.previousSibling
      const rect = page.getBoundingClientRect()

      this.area.w = (e.touches[0].clientX - rect.left) / rect.width - this.area.x
      this.area.h = (e.touches[0].clientY - rect.top) / rect.height - this.area.y
    },
    stopTouchResize () {
      this.$el.getRootNode().removeEventListener('touchmove', this.touchResize)
      this.$el.getRootNode().removeEventListener('touchend', this.stopTouchResize)

      this.$emit('stop-resize')

      this.save()
    }
  }
}
</script>

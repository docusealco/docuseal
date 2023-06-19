<template>
  <div
    class="absolute overflow-visible group"
    :style="positionStyle"
    @pointerdown.stop
    @mousedown.stop="startDrag"
  >
    <div
      v-if="isSelected || !field?.type"
      class="top-0 bottom-0 right-0 left-0 absolute border border-1.5 pointer-events-none"
      :class="borderColors[submitterIndex]"
    />
    <div
      v-if="field?.type"
      class="absolute bg-white rounded-t border overflow-visible whitespace-nowrap group-hover:flex group-hover:z-10"
      :class="{ 'flex z-10': isNameFocus || isSelected, hidden: !isNameFocus && !isSelected }"
      style="top: -25px; height: 25px"
      @mousedown.stop
      @pointerdown.stop
    >
      <FieldSubmitter
        v-model="field.submitter_uuid"
        class="border-r"
        :compact="true"
        :menu-classes="'dropdown-content bg-white menu menu-xs p-2 shadow rounded-box w-52 rounded-t-none -left-[1px]'"
        :submitters="template.submitters"
        @click="selectedAreaRef.value = area"
      />
      <FieldType
        v-model="field.type"
        :button-width="27"
        :button-classes="'px-1'"
        :menu-classes="'bg-white rounded-t-none'"
        @update:model-value="maybeUpdateOptions"
        @click="selectedAreaRef.value = area"
      />
      <span
        v-if="field.type !== 'checkbox' || field.name"
        ref="name"
        contenteditable
        class="pr-1 cursor-text outline-none block"
        style="min-width: 2px"
        @keydown.enter.prevent="onNameEnter"
        @focus="onNameFocus"
        @blur="onNameBlur"
      >{{ field.name || defaultName }}</span>
      <div
        v-if="isNameFocus"
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
        v-else
        class="pr-1"
        title="Remove"
        @click.prevent="$emit('remove')"
      >
        <IconX width="14" />
      </button>
    </div>
    <div
      class="opacity-50 flex items-center justify-center h-full w-full"
      :class="bgColors[submitterIndex]"
    >
      <span
        v-if="field"
        class="flex justify-center items-center space-x-1 h-full"
      >
        <component
          :is="fieldIcons[field.type]"
          width="100%"
          height="100%"
          class="max-h-10"
        />
      </span>
    </div>
    <div
      class="absolute top-0 bottom-0 right-0 left-0 cursor-pointer"
    />
    <span
      v-if="field?.type"
      class="h-2.5 w-2.5 -right-1 rounded-full -bottom-1 border-gray-400 bg-white shadow-md border absolute cursor-nwse-resize"
      @mousedown.stop="startResize"
    />
  </div>
</template>

<script>
import FieldSubmitter from './field_submitter'
import FieldType from './field_type'
import Field from './field'
import { IconX } from '@tabler/icons-vue'

export default {
  name: 'FieldArea',
  components: {
    FieldType,
    FieldSubmitter,
    IconX
  },
  inject: ['template', 'selectedAreaRef'],
  props: {
    area: {
      type: Object,
      required: true
    },
    field: {
      type: Object,
      required: false,
      default: null
    }
  },
  emits: ['start-resize', 'stop-resize', 'start-drag', 'stop-drag', 'remove'],
  data () {
    return {
      isResize: false,
      isNameFocus: false,
      dragFrom: { x: 0, y: 0 }
    }
  },
  computed: {
    defaultName: Field.computed.defaultName,
    fieldIcons: FieldType.computed.fieldIcons,
    submitter () {
      return this.template.submitters.find((s) => s.uuid === this.field.submitter_uuid)
    },
    submitterIndex () {
      return this.template.submitters.indexOf(this.submitter)
    },
    borderColors () {
      return [
        'border-red-500',
        'border-sky-500',
        'border-emerald-500',
        'border-yellow-300',
        'border-purple-600'
      ]
    },
    bgColors () {
      return [
        'bg-red-100',
        'bg-sky-100',
        'bg-emerald-100',
        'bg-yellow-100',
        'bg-purple-100'
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
  methods: {
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
    maybeUpdateOptions () {
      if (!['radio', 'multiple', 'select'].includes(this.field.type)) {
        delete this.field.options
      }

      if (['select', 'multiple', 'radio'].includes(this.field.type)) {
        this.field.options ||= ['']
      }
    },
    onNameBlur (e) {
      this.isNameFocus = false
      this.$refs.name.style.minWidth = ''

      if (e.target.innerText.trim()) {
        this.field.name = e.target.innerText.trim()
      } else {
        this.field.name = ''
        this.$refs.name.innerText = this.defaultName
      }
    },
    onNameEnter (e) {
      this.$refs.name.blur()
    },
    resize (e) {
      if (e.toElement.id === 'mask') {
        this.area.w = e.layerX / e.toElement.clientWidth - this.area.x
        this.area.h = e.layerY / e.toElement.clientHeight - this.area.y
      }
    },
    drag (e) {
      if (e.toElement.id === 'mask') {
        this.area.x = (e.layerX - this.dragFrom.x) / e.toElement.clientWidth
        this.area.y = (e.layerY - this.dragFrom.y) / e.toElement.clientHeight
      }
    },
    startDrag (e) {
      this.selectedAreaRef.value = this.area

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
      this.selectedAreaRef.value = this.area

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

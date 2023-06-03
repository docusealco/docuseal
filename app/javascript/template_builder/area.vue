<template>
  <div
    class="absolute overflow-visible group"
    :style="positionStyle"
    @pointerdown.stop
    @mousedown.stop="startDrag"
  >
    <div
      v-if="field"
      class="absolute bg-white rounded-t border overflow-visible whitespace-nowrap group-hover:flex group-hover:z-10"
      :class="{ flex: isNameFocus || isSelected, hidden: !isNameFocus && !isSelected }"
      style="top: -25px; height: 25px"
      @mousedown.stop
      @pointerdown.stop
    >
      <span class="dropdown dropdown-start border-r">
        <label
          tabindex="0"
          title="Submitter"
          class="cursor-pointer text-base-100"
          @click="selectedAreaRef.value = area"
        >
          <button class="mx-1 w-3 h-3 rounded-full bg-yellow-600" />
        </label>
        <ul
          tabindex="0"
          class="dropdown-content bg-white menu menu-xs p-2 shadow rounded-box w-52 rounded-t-none"
          style="left: -1px"
          @click="closeDropdown"
        >
          <li>
            <a
              href="#"
              class="text-sm py-1 px-2"
              @click.prevent
            >
              Submitter 1
            </a>
          </li>
        </ul>
      </span>
      <FieldType
        v-model="field.type"
        :button-width="27"
        :button-classes="'px-1'"
        :menu-classes="'bg-white rounded-t-none'"
        @click="selectedAreaRef.value = area"
      />
      <span
        v-if="withName"
        ref="name"
        contenteditable
        class="pr-1 cursor-text outline-none block"
        style="min-width: 2px"
        @keydown.enter.prevent="onNameEnter"
        @focus="onNameFocus"
        @blur="onNameBlur"
      >{{ field.name || defaultName }}</span>
      <button
        class="pl-0.5 pr-1.5"
        @click.prevent="$emit('remove')"
      >
        <span>&times;</span>
      </button>
    </div>
    <div
      class="bg-red-100 opacity-50 flex items-center justify-center h-full w-full"
    >
      <span
        v-if="field"
        class="flex justify-center items-center space-x-1"
      >
        <component :is="fieldIcons[field.type]" />
      </span>
    </div>
    <div
      class="absolute top-0 bottom-0 right-0 left-0"
    />
    <span
      class="h-2 w-2 -right-1 rounded-full -bottom-1 bg-red-900 absolute cursor-nwse-resize"
      @mousedown.stop="startResize"
    />
  </div>
</template>

<script>
import FieldType from './field_type'
import Field from './field'

export default {
  name: 'FieldArea',
  components: {
    FieldType
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
    withName () {
      return !['checkbox', 'radio'].includes(this.field.type) || this.field.options
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

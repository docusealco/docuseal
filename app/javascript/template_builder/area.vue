<template>
  <div
    class="absolute overflow-visible group"
    :style="positionStyle"
    @pointerdown.stop
    @mousedown="startMouseMove"
    @touchstart="startTouchDrag"
  >
    <div
      v-if="isSelected || isDraw"
      class="top-0 bottom-0 right-0 left-0 absolute border border-1.5 pointer-events-none"
      :class="field.type === 'heading' ? '' : borderColors[submitterIndex]"
    />
    <div
      v-if="field.type === 'cells' && (isSelected || isDraw)"
      class="top-0 bottom-0 right-0 left-0 absolute"
    >
      <div
        v-for="(cellW, index) in cells"
        :key="index"
        class="absolute top-0 bottom-0 border-r"
        :class="field.type === 'heading' ? '' : borderColors[submitterIndex]"
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
      v-if="field?.type && (isSelected || isNameFocus)"
      class="absolute bg-white rounded-t border overflow-visible whitespace-nowrap flex z-10"
      style="top: -25px; height: 25px"
      @mousedown.stop
      @pointerdown.stop
    >
      <FieldSubmitter
        v-if="field.type != 'heading'"
        v-model="field.submitter_uuid"
        class="border-r"
        :compact="true"
        :editable="editable && (!defaultField || defaultField.role !== submitter?.name)"
        :allow-add-new="!defaultSubmitters.length"
        :menu-classes="'dropdown-content bg-white menu menu-xs p-2 shadow rounded-box w-52 rounded-t-none -left-[1px] mt-[1px]'"
        :submitters="template.submitters"
        @update:model-value="save"
        @click="selectedAreaRef.value = area"
      />
      <FieldType
        v-model="field.type"
        :button-width="27"
        :editable="editable && !defaultField"
        :button-classes="'px-1'"
        :menu-classes="'bg-white rounded-t-none'"
        @update:model-value="[maybeUpdateOptions(), save()]"
        @click="selectedAreaRef.value = area"
      />
      <span
        v-if="field.type !== 'checkbox' || field.name"
        ref="name"
        :contenteditable="editable && !defaultField && field.type !== 'heading'"
        dir="auto"
        class="pr-1 cursor-text outline-none block"
        style="min-width: 2px"
        @paste.prevent="onPaste"
        @keydown.enter.prevent="onNameEnter"
        @focus="onNameFocus"
        @blur="onNameBlur"
      >{{ optionIndexText }} {{ (defaultField ? (field.title || field.name) : field.name) || defaultName }}</span>
      <div
        v-if="isSettingsFocus || (isValueInput && field.type !== 'heading') || (isNameFocus && !['checkbox', 'phone'].includes(field.type))"
        class="flex items-center ml-1.5"
      >
        <input
          v-if="!isValueInput"
          :id="`required-checkbox-${field.uuid}`"
          v-model="field.required"
          type="checkbox"
          class="checkbox checkbox-xs no-animation rounded"
          @mousedown.prevent
        >
        <label
          v-if="!isValueInput"
          :for="`required-checkbox-${field.uuid}`"
          class="label text-xs"
          @click.prevent="field.required = !field.required"
          @mousedown.prevent
        >{{ t('required') }}</label>
        <input
          v-if="isValueInput"
          :id="`readonly-checkbox-${field.uuid}`"
          type="checkbox"
          class="checkbox checkbox-xs no-animation rounded"
          :checked="!(field.readonly ?? true)"
          @change="field.readonly = !(field.readonly ?? true)"
          @mousedown.prevent
        >
        <label
          v-if="isValueInput"
          :for="`readonly-checkbox-${field.uuid}`"
          class="label text-xs"
          @click.prevent="field.readonly = !(field.readonly ?? true)"
          @mousedown.prevent
        >{{ t('editable') }}</label>
        <span
          v-if="field.type !== 'payment' && !isValueInput"
          class="dropdown dropdown-end"
          @mouseenter="renderDropdown = true"
          @touchstart="renderDropdown = true"
        >
          <label
            ref="settingsButton"
            tabindex="0"
            :title="t('settings')"
            class="cursor-pointer flex items-center"
            style="height: 25px"
            @focus="isSettingsFocus = true"
            @blur="maybeBlurSettings"
          >
            <IconDotsVertical class="w-5 h-5" />
          </label>
          <ul
            v-if="renderDropdown"
            ref="settingsDropdown"
            tabindex="0"
            class="dropdown-content menu menu-xs px-2 pb-2 pt-1 shadow rounded-box w-52 z-10 rounded-t-none"
            :style="{ backgroundColor: 'white' }"
            @dragstart.prevent.stop
            @click="closeDropdown"
            @focusout="maybeBlurSettings"
          >
            <FieldSettings
              :field="field"
              :default-field="defaultField"
              :editable="editable"
              :background-color="'white'"
              :with-required="false"
              :with-areas="false"
              @click-formula="isShowFormulaModal = true"
              @click-description="isShowDescriptionModal = true"
              @click-condition="isShowConditionsModal = true"
              @scroll-to="[selectedAreaRef.value = $event, $emit('scroll-to', $event)]"
            />
          </ul>
        </span>
      </div>
      <button
        v-else-if="editable"
        class="pr-1"
        :title="t('remove')"
        @click.prevent="$emit('remove')"
      >
        <IconX width="14" />
      </button>
    </div>
    <div
      ref="touchValueTarget"
      class="flex items-center h-full w-full"
      dir="auto"
      :class="[isValueInput ? 'bg-opacity-50' : 'bg-opacity-80', field.type === 'heading' ? 'bg-gray-50' : bgColors[submitterIndex], isDefaultValuePresent || isValueInput || (withFieldPlaceholder && field.areas) ? (alignClasses[field.preferences?.align] || '') : 'justify-center']"
      @click="focusValueInput"
    >
      <span
        v-if="field"
        class="flex justify-center items-center space-x-1"
        :class="{ 'w-full': ['cells', 'checkbox'].includes(field.type), 'h-full': !isValueInput }"
      >
        <div
          v-if="isDefaultValuePresent || isValueInput || (withFieldPlaceholder && field.areas && field.type !== 'checkbox')"
          :class="{ 'w-full h-full': ['cells', 'checkbox'].includes(field.type), 'text-[1.6vw] lg:text-base': !textOverflowChars, 'text-[1.0vw] lg:text-xs': textOverflowChars }"
        >
          <div
            ref="textContainer"
            class="flex items-center px-0.5"
            :class="{ 'w-full h-full': ['cells', 'checkbox'].includes(field.type) }"
          >
            <IconCheck
              v-if="field.type == 'checkbox'"
              class="aspect-square mx-auto"
              :class="{ '!w-auto !h-full': area.w > area.h, '!w-full !h-auto': area.w <= area.h }"
            />
            <span
              v-else-if="field.type === 'number' && !isValueInput && (field.default_value || field.default_value == 0)"
              class="whitespace-pre-wrap"
            >{{ formatNumber(field.default_value, field.preferences?.format) }}</span>
            <span
              v-else-if="field.default_value === '{{date}}'"
            >
              {{ t('signing_date') }}
            </span>
            <div
              v-else-if="field.type === 'cells' && field.default_value"
              class="w-full flex items-center"
            >
              <div
                v-for="(char, index) in field.default_value"
                :key="index"
                class="text-center flex-none"
                :style="{ width: (area.cell_w / area.w * 100) + '%' }"
              >
                {{ char }}
              </div>
            </div>
            <span
              v-else
              ref="defaultValue"
              :contenteditable="isValueInput"
              class="whitespace-pre-wrap outline-none empty:before:content-[attr(placeholder)] before:text-gray-400"
              :class="{ 'cursor-text': isValueInput }"
              :placeholder="withFieldPlaceholder && !isValueInput ? field.name || defaultName : t('type_value')"
              @blur="onDefaultValueBlur"
              @paste.prevent="onPaste"
              @keydown.enter="onDefaultValueEnter"
            >{{ field.default_value }}</span>
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
      v-if="!isValueInput"
      ref="touchTarget"
      class="absolute top-0 bottom-0 right-0 left-0"
      :class="isDragged ? 'cursor-grab' : 'cursor-pointer'"
      @dblclick="maybeToggleDefaultValue"
      @click="maybeToggleCheckboxValue"
    />
    <span
      v-if="field?.type && editable"
      class="h-4 w-4 md:h-2.5 md:w-2.5 -right-1 rounded-full -bottom-1 border-gray-400 bg-white shadow-md border absolute cursor-nwse-resize"
      @mousedown.stop="startResize"
      @touchstart="startTouchResize"
    />
    <Teleport
      v-if="isShowFormulaModal"
      :to="modalContainerEl"
    >
      <FormulaModal
        :field="field"
        :editable="editable && !defaultField"
        :build-default-name="buildDefaultName"
        @close="isShowFormulaModal = false"
      />
    </Teleport>
    <Teleport
      v-if="isShowConditionsModal"
      :to="modalContainerEl"
    >
      <ConditionsModal
        :field="field"
        :build-default-name="buildDefaultName"
        @close="isShowConditionsModal = false"
      />
    </Teleport>
    <Teleport
      v-if="isShowDescriptionModal"
      :to="modalContainerEl"
    >
      <DescriptionModal
        :field="field"
        :editable="editable && !defaultField"
        :build-default-name="buildDefaultName"
        @close="isShowDescriptionModal = false"
      />
    </Teleport>
  </div>
</template>

<script>
import FieldSubmitter from './field_submitter'
import FieldType from './field_type'
import Field from './field'
import FieldSettings from './field_settings'
import FormulaModal from './formula_modal'
import ConditionsModal from './conditions_modal'
import DescriptionModal from './description_modal'
import { IconX, IconCheck, IconDotsVertical } from '@tabler/icons-vue'
import { v4 } from 'uuid'

export default {
  name: 'FieldArea',
  components: {
    FieldType,
    IconCheck,
    FieldSettings,
    FormulaModal,
    IconDotsVertical,
    DescriptionModal,
    ConditionsModal,
    FieldSubmitter,
    IconX
  },
  inject: ['template', 'selectedAreaRef', 'save', 't'],
  props: {
    area: {
      type: Object,
      required: true
    },
    inputMode: {
      type: Boolean,
      required: false,
      default: false
    },
    isDraw: {
      type: Boolean,
      required: false,
      default: false
    },
    defaultField: {
      type: Object,
      required: false,
      default: null
    },
    withFieldPlaceholder: {
      type: Boolean,
      required: false,
      default: false
    },
    defaultSubmitters: {
      type: Array,
      required: false,
      default: () => []
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
  emits: ['start-resize', 'stop-resize', 'start-drag', 'stop-drag', 'remove', 'scroll-to'],
  data () {
    return {
      isShowFormulaModal: false,
      isShowConditionsModal: false,
      isContenteditable: false,
      isSettingsFocus: false,
      isShowDescriptionModal: false,
      isResize: false,
      isDragged: false,
      isMoved: false,
      renderDropdown: false,
      isNameFocus: false,
      textOverflowChars: 0,
      dragFrom: { x: 0, y: 0 }
    }
  },
  computed: {
    fieldNames: FieldType.computed.fieldNames,
    fieldIcons: FieldType.computed.fieldIcons,
    isDefaultValuePresent () {
      if (this.field?.type === 'radio' && this.field?.areas?.length > 1) {
        return false
      } else {
        return this.field?.default_value || this.field?.default_value === 0
      }
    },
    isValueInput () {
      return (this.field.type === 'heading' && this.isSelected) || this.isContenteditable || (this.inputMode && ['text', 'number', 'date'].includes(this.field.type))
    },
    modalContainerEl () {
      return this.$el.getRootNode().querySelector('#docuseal_modal_container')
    },
    defaultName () {
      return this.buildDefaultName(this.field, this.template.fields)
    },
    alignClasses () {
      return {
        center: 'justify-center',
        left: 'justify-start',
        right: 'justify-end'
      }
    },
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
        'border-red-500/80',
        'border-sky-500/80',
        'border-emerald-500/80',
        'border-yellow-300/80',
        'border-purple-600/80',
        'border-pink-500/80',
        'border-cyan-500/80',
        'border-orange-500/80',
        'border-lime-500/80',
        'border-indigo-500/80',
        'border-red-500/80',
        'border-sky-500/80',
        'border-emerald-500/80',
        'border-yellow-300/80',
        'border-purple-600/80',
        'border-pink-500/80',
        'border-cyan-500/80',
        'border-orange-500/80',
        'border-lime-500/80',
        'border-indigo-500/80'
      ]
    },
    bgColors () {
      return [
        'bg-red-100',
        'bg-sky-100',
        'bg-emerald-100',
        'bg-yellow-100',
        'bg-purple-100',
        'bg-pink-100',
        'bg-cyan-100',
        'bg-orange-100',
        'bg-lime-100',
        'bg-indigo-100',
        'bg-red-100',
        'bg-sky-100',
        'bg-emerald-100',
        'bg-yellow-100',
        'bg-purple-100',
        'bg-pink-100',
        'bg-cyan-100',
        'bg-orange-100',
        'bg-lime-100',
        'bg-indigo-100'
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
      this.$nextTick(() => {
        if (['date', 'text', 'number'].includes(this.field.type) && this.field.default_value && this.$refs.textContainer && (this.textOverflowChars === 0 || (this.textOverflowChars - 4) > `${this.field.default_value}`.length)) {
          this.textOverflowChars = this.$el.clientHeight < this.$refs.textContainer.clientHeight ? `${this.field.default_value}`.length : 0
        }
      })
    }
  },
  mounted () {
    this.$nextTick(() => {
      if (['date', 'text', 'number'].includes(this.field.type) && this.field.default_value && this.$refs.textContainer && (this.textOverflowChars === 0 || (this.textOverflowChars - 4) > `${this.field.default_value}`.length)) {
        this.textOverflowChars = this.$el.clientHeight < this.$refs.textContainer.clientHeight ? `${this.field.default_value}`.length : 0
      }
    })
  },
  methods: {
    buildDefaultName: Field.methods.buildDefaultName,
    closeDropdown () {
      document.activeElement.blur()
    },
    maybeToggleDefaultValue () {
      if (['text', 'number'].includes(this.field.type)) {
        this.isContenteditable = true

        this.$nextTick(() => this.focusValueInput())
      } else if (this.field.type === 'checkbox') {
        this.field.readonly = !this.field.readonly
        this.field.default_value === true ? delete this.field.default_value : this.field.default_value = true

        this.save()
      } else if (this.field.type === 'date') {
        this.field.readonly = !this.field.readonly
        this.field.default_value === '{{date}}' ? delete this.field.default_value : this.field.default_value = '{{date}}'

        this.save()
      }
    },
    maybeToggleCheckboxValue () {
      if (this.inputMode && this.field.type === 'checkbox') {
        this.field.readonly = !this.field.readonly
        this.field.default_value === true ? delete this.field.default_value : this.field.default_value = true

        this.save()
      }
    },
    focusValueInput (e) {
      if (this.$refs.defaultValue !== document.activeElement) {
        this.$refs.defaultValue.focus()

        if (this.$refs.defaultValue.innerText.length && this.$refs.defaultValue !== e?.target) {
          window.getSelection().collapse(
            this.$refs.defaultValue.firstChild,
            this.$refs.defaultValue.innerText.length
          )
        }
      }
    },
    formatNumber (number, format) {
      if (format === 'comma') {
        return new Intl.NumberFormat('en-US').format(number)
      } else if (format === 'dot') {
        return new Intl.NumberFormat('de-DE').format(number)
      } else if (format === 'space') {
        return new Intl.NumberFormat('fr-FR').format(number)
      } else {
        return number
      }
    },
    maybeBlurSettings (e) {
      if (!e.relatedTarget || !this.$refs.settingsDropdown.contains(e.relatedTarget)) {
        this.isSettingsFocus = false
      }
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
    onPaste (e) {
      const text = (e.clipboardData || window.clipboardData).getData('text/plain')

      const selection = this.$el.getRootNode().getSelection()

      if (selection.rangeCount) {
        selection.deleteFromDocument()
        selection.getRangeAt(0).insertNode(document.createTextNode(text))
        selection.collapseToEnd()
      }
    },
    onResizeCell (e) {
      if (e.target.id === 'mask') {
        const positionX = e.offsetX / (e.target.clientWidth - 1)

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

      if (['heading'].includes(this.field.type)) {
        this.field.readonly = true
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
      if (e.relatedTarget === this.$refs.settingsButton) {
        this.isSettingsFocus = true
      }

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
    onDefaultValueBlur (e) {
      const text = this.$refs.defaultValue.innerText.trim()

      this.isContenteditable = false

      if (text) {
        if (this.field.type === 'number') {
          const number = parseFloat(text)

          if (number || number === 0) {
            this.field.default_value = parseFloat(text)
          }
        } else {
          this.field.default_value = text
        }

        if (![true, false].includes(this.field.readonly)) {
          this.field.readonly = true
        }

        this.$refs.defaultValue.innerText = text
      } else {
        delete this.field.readonly
        delete this.field.default_value
        this.$refs.defaultValue.innerText = ''
      }

      this.save()
    },
    onDefaultValueEnter (e) {
      if (this.field.type !== 'heading') {
        e.preventDefault()

        this.$refs.defaultValue.blur()
      }
    },
    onNameEnter (e) {
      this.$refs.name.blur()
    },
    resize (e) {
      if (e.target.id === 'mask') {
        this.area.w = e.offsetX / e.target.clientWidth - this.area.x
        this.area.h = e.offsetY / e.target.clientHeight - this.area.y
      }
    },
    drag (e) {
      if (e.target.id === 'mask') {
        this.isDragged = true

        this.area.x = (e.offsetX - this.dragFrom.x) / e.target.clientWidth
        this.area.y = (e.offsetY - this.dragFrom.y) / e.target.clientHeight
      }
    },
    startTouchDrag (e) {
      if (e.target !== this.$refs.touchTarget && e.target !== this.$refs.touchValueTarget) {
        return
      }

      document.activeElement?.blur()

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
      if (!this.editable) {
        return
      }

      const page = this.$parent.$refs.mask.previousSibling
      const rect = page.getBoundingClientRect()

      this.area.x = Math.min(Math.max((this.dragFrom.x + e.touches[0].clientX - rect.left) / rect.width, 0), 1 - this.area.w)
      this.area.y = Math.min(Math.max((this.dragFrom.y + e.touches[0].clientY - rect.top) / rect.height, 0), 1 - this.area.h)
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
    startMouseMove (e) {
      if (e.target !== this.$refs.touchTarget && e.target !== this.$refs.touchValueTarget) {
        return
      }

      if (document.activeElement !== this.$refs.defaultValue) {
        document.activeElement?.blur()
      }

      e.preventDefault()

      this.isDragged = true

      const rect = e.target.getBoundingClientRect()

      this.selectedAreaRef.value = this.area

      if (this.field.type === 'heading') {
        this.$nextTick(() => this.focusValueInput())
      }

      this.dragFrom = { x: rect.left - e.clientX, y: rect.top - e.clientY }

      this.$el.getRootNode().addEventListener('mousemove', this.mouseMove)
      this.$el.getRootNode().addEventListener('mouseup', this.stopMouseMove)

      this.$emit('start-drag')
    },
    mouseMove (e) {
      if (!this.editable) {
        return
      }

      this.isMoved = true

      const page = this.$parent.$refs.mask.previousSibling
      const rect = page.getBoundingClientRect()

      this.area.x = Math.min(Math.max((this.dragFrom.x + e.clientX - rect.left) / rect.width, 0), 1 - this.area.w)
      this.area.y = Math.min(Math.max((this.dragFrom.y + e.clientY - rect.top) / rect.height, 0), 1 - this.area.h)
    },
    stopMouseMove (e) {
      this.$el.getRootNode().removeEventListener('mousemove', this.mouseMove)
      this.$el.getRootNode().removeEventListener('mouseup', this.stopMouseMove)

      if (this.isMoved) {
        this.save()
      }

      this.isDragged = false
      this.isMoved = false

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

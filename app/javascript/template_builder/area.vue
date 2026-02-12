<template>
  <div
    class="absolute overflow-visible group field-area-container"
    :style="positionStyle"
    :class="{ 'z-[1]': isMoved || isDragged }"
    @pointerdown.stop
    @mousedown="startMouseMove"
    @touchstart="startTouchDrag"
  >
    <div
      v-if="isSelected || isDraw || isInMultiSelection"
      class="top-0 bottom-0 right-0 left-0 absolute border border-1.5 pointer-events-none"
      :class="activeBorderClasses"
    />
    <div
      v-if="field.type === 'cells' && (isSelected || isDraw)"
      class="top-0 bottom-0 right-0 left-0 absolute"
    >
      <div
        v-for="(cellW, index) in cells"
        :key="index"
        class="absolute top-0 bottom-0 border-r"
        :class="field.type === 'heading' ? '' : borderColors[submitterIndex % borderColors.length]"
        :style="{ left: (cellW / area.w * 100) + '%' }"
      >
        <span
          v-if="index === 0 && editable && !isInMultiSelection"
          class="h-2.5 w-2.5 rounded-full -bottom-1 border-gray-400 bg-white shadow-md border absolute cursor-ew-resize z-10"
          style="left: -4px"
          @mousedown.stop="startResizeCell"
        />
      </div>
    </div>
    <AreaTitle
      ref="title"
      :area="area"
      :field="field"
      :template="template"
      :selected-areas-ref="selectedAreasRef"
      :get-field-type-index="getFieldTypeIndex"
      :default-field="defaultField"
      :with-signature-id="withSignatureId"
      :with-prefillable="withPrefillable"
      :default-submitters="defaultSubmitters"
      :editable="editable"
      :is-mobile="isMobile"
      :is-value-input="isValueInput"
      :is-select-input="isSelectInput"
      @change="save"
      @remove="$emit('remove')"
      @scroll-to="$emit('scroll-to', $event)"
      @add-custom-field="$emit('add-custom-field')"
    />
    <div
      ref="touchValueTarget"
      class="flex h-full w-full field-area"
      dir="auto"
      :class="[isValueInput ? 'cursor-text' : '', isValueInput || isCheckboxInput || isSelectInput ? 'bg-opacity-50' : 'bg-opacity-80', bgClasses, isDefaultValuePresent || isValueInput || (withFieldPlaceholder && field.areas) ? fontClasses : 'justify-center items-center']"
      @click="focusValueInput"
    >
      <span
        v-if="field"
        class="flex justify-center items-center space-x-1"
        :class="{ 'w-full': isWFullType, 'h-full': !isValueInput && (!isDefaultValuePresent || field.type === 'strikethrough') }"
      >
        <div
          v-if="field.type === 'strikethrough'"
          class="w-full h-full flex items-center justify-center"
        >
          <svg
            v-if="(((basePageWidth / pageWidth) * pageHeight) * area.h) < 41.6"
            xmlns="http://www.w3.org/2000/svg"
            width="100%"
            height="100%"
          >
            <line
              x1="0"
              y1="50%"
              x2="100%"
              y2="50%"
              :stroke="field.preferences?.color || 'red'"
              :stroke-width="strikethroughWidth"
            />
          </svg>
          <svg
            v-else
            xmlns="http://www.w3.org/2000/svg"
            :style="{ overflow: 'visible', width: `calc(100% - ${strikethroughWidth})`, height: `calc(100% - ${strikethroughWidth})` }"
          >
            <line
              x1="0"
              y1="0"
              x2="100%"
              y2="100%"
              :stroke="field.preferences?.color || 'red'"
              :stroke-width="strikethroughWidth"
            />
            <line
              x1="100%"
              y1="0"
              x2="0"
              y2="100%"
              :stroke="field.preferences?.color || 'red'"
              :stroke-width="strikethroughWidth"
            />
          </svg>
        </div>
        <div
          v-else-if="isDefaultValuePresent || isValueInput || isSelectInput || (withFieldPlaceholder && field.areas && field.type !== 'checkbox')"
          :class="{ 'w-full h-full': isWFullType }"
          :style="fontStyle"
        >
          <div
            ref="textContainer"
            class="flex items-center px-0.5"
            :style="{ color: field.preferences?.color }"
            :class="{ 'w-full h-full': isWFullType }"
          >
            <IconCheck
              v-if="field.type == 'checkbox'"
              class="aspect-square mx-auto"
              :class="{ '!w-auto !h-full': area.w > area.h, '!w-full !h-auto': area.w <= area.h }"
            />
            <template
              v-else-if="(field.type === 'radio' || field.type === 'multiple') && field?.areas?.length > 1"
            >
              <IconCheck
                v-if="field.type === 'multiple' ? field.default_value.includes(buildAreaOptionValue(area)) : buildAreaOptionValue(area) === field.default_value"
                class="aspect-square mx-auto"
                :class="{ '!w-auto !h-full': area.w > area.h, '!w-full !h-auto': area.w <= area.h }"
              />
            </template>
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
              class="w-full flex"
              :class="fontClasses"
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
            <select
              v-else-if="isSelectInput"
              ref="defaultValueSelect"
              class="bg-transparent outline-none focus:outline-none w-full"
              @change="[field.default_value = $event.target.value, field.readonly = !!field.default_value?.length, save()]"
              @focus="selectedAreasRef.value = [area]"
              @keydown.enter="onDefaultValueEnter"
            >
              <option
                :disabled="!field.default_value?.length"
                :selected="!field.default_value?.length"
                :value="''"
              >
                {{ t(field.default_value?.length ? 'none' : 'select') }}
              </option>
              <option
                v-for="(option, index) in field.options"
                :key="index"
                :selected="field.default_value === option.value"
                :value="option.value"
              >
                {{ option.value }}
              </option>
            </select>
            <span
              v-else
              ref="defaultValue"
              :contenteditable="isValueInput"
              class="whitespace-pre-wrap outline-none empty:before:content-[attr(placeholder)] before:text-base-content/30"
              :class="{ 'cursor-text': isValueInput }"
              :placeholder="withFieldPlaceholder && !isValueInput ? defaultField?.title || field.title || field.name || defaultName : (field.type === 'date' ? field.preferences?.format || t('type_value') : t('type_value'))"
              @blur="onDefaultValueBlur"
              @focus="selectedAreasRef.value = [area]"
              @paste.prevent="onPaste"
              @keydown.enter="onDefaultValueEnter"
            >{{ field.default_value }}</span>
          </div>
        </div>
        <component
          :is="fieldIcons[field.type]"
          v-else-if="!isCheckboxInput"
          width="100%"
          height="100%"
          class="max-h-10 opacity-50"
        />
      </span>
    </div>
    <div
      v-if="!isValueInput && !isSelectInput"
      ref="touchTarget"
      class="absolute top-0 bottom-0 right-0 left-0"
      :class="isDragged ? 'cursor-grab' : 'cursor-pointer'"
      @dblclick="maybeToggleDefaultValue"
      @click="inputMode && maybeToggleCheckboxValue()"
    />
    <span
      v-if="field?.type && editable"
      class="h-4 w-4 lg:h-2.5 lg:w-2.5 -right-1 rounded-full -bottom-1 border-gray-400 bg-white shadow-md border absolute cursor-nwse-resize"
      :class="{ 'z-30': isInMultiSelection }"
      @mousedown.stop="startResize"
      @touchstart="startTouchResize"
    />
  </div>
</template>

<script>
import FieldType from './field_type'
import Field from './field'
import AreaTitle from './area_title'
import { IconCheck } from '@tabler/icons-vue'

export default {
  name: 'FieldArea',
  components: {
    IconCheck,
    AreaTitle
  },
  inject: ['template', 'save', 't', 'isInlineSize', 'selectedAreasRef', 'isCmdKeyRef', 'getFieldTypeIndex'],
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
    maxPage: {
      type: Number,
      required: false,
      default: null
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
    withSignatureId: {
      type: Boolean,
      required: false,
      default: null
    },
    withPrefillable: {
      type: Boolean,
      required: false,
      default: false
    },
    pageWidth: {
      type: Number,
      required: false,
      default: 0
    },
    pageHeight: {
      type: Number,
      required: false,
      default: 0
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
    },
    isMobile: {
      type: Boolean,
      required: false,
      default: false
    },
    isSelectMode: {
      type: Boolean,
      required: false,
      default: false
    }
  },
  emits: ['start-resize', 'stop-resize', 'start-drag', 'stop-drag', 'remove', 'scroll-to', 'add-custom-field'],
  data () {
    return {
      isContenteditable: false,
      isResize: false,
      isDragged: false,
      isMoved: false,
      isHeadingSelected: false,
      textOverflowChars: 0,
      dragFrom: { x: 0, y: 0 }
    }
  },
  computed: {
    fieldNames: FieldType.computed.fieldNames,
    fieldLabels: FieldType.computed.fieldLabels,
    fieldIcons: FieldType.computed.fieldIcons,
    bgClasses () {
      if (this.field.type === 'heading') {
        return 'bg-gray-50'
      } else if (this.field.type === 'strikethrough') {
        return 'bg-transparent'
      } else {
        return this.bgColors[this.submitterIndex % this.bgColors.length]
      }
    },
    activeBorderClasses () {
      if (this.field.type === 'heading') {
        return ''
      } else if (this.field.type === 'strikethrough') {
        return 'border-dashed border-gray-300'
      } else {
        return this.borderColors[this.submitterIndex % this.borderColors.length]
      }
    },
    isWFullType () {
      return ['cells', 'checkbox', 'radio', 'multiple', 'select', 'strikethrough'].includes(this.field.type)
    },
    strikethroughWidth () {
      if (this.isInlineSize) {
        return '0.6cqmin'
      } else {
        return 'clamp(0px, 0.5vw, 6px)'
      }
    },
    fontStyle () {
      let fontSize = ''

      if (this.isInlineSize) {
        if (this.textOverflowChars) {
          fontSize = `${this.fontSizePx / 1.5 / 10}cqmin`
        } else {
          fontSize = `${this.fontSizePx / 10}cqmin`
        }
      } else {
        if (this.textOverflowChars) {
          fontSize = `clamp(1pt, ${this.fontSizePx / 1.5 / 10}vw, ${this.fontSizePx / 1.5}px)`
        } else {
          fontSize = `clamp(1pt, ${this.fontSizePx / 10}vw, ${this.fontSizePx}px)`
        }
      }

      return { fontSize, lineHeight: `calc(${fontSize} * ${this.lineHeight})` }
    },
    optionsUuidIndex () {
      return this.field.options.reduce((acc, option) => {
        acc[option.uuid] = option

        return acc
      }, {})
    },
    fontSizePx () {
      return parseInt(this.field?.preferences?.font_size || 11) * this.fontScale
    },
    lineHeight () {
      return 1.3
    },
    basePageWidth () {
      return 1040.0
    },
    fontScale () {
      return this.basePageWidth / 612.0
    },
    isDefaultValuePresent () {
      return this.field?.default_value || this.field?.default_value === 0
    },
    isSelectInput () {
      return this.inputMode && (this.field.type === 'select' || (this.field.type === 'radio' && this.field.areas?.length < 2))
    },
    isCheckboxInput () {
      return this.inputMode && (this.field.type === 'checkbox' || (['radio', 'multiple'].includes(this.field.type) && this.area.option_uuid))
    },
    isValueInput () {
      return (this.field.type === 'heading' && this.isHeadingSelected) || this.isContenteditable ||
        (this.inputMode && (['text', 'number'].includes(this.field.type) || (this.field.type === 'date' && this.field.default_value !== '{{date}}')))
    },
    defaultName () {
      return this.buildDefaultName(this.field)
    },
    fontClasses () {
      if (!this.field.preferences) {
        return { 'items-center': true }
      }

      return {
        'items-center': !this.field.preferences.valign || this.field.preferences.valign === 'center',
        'items-start': this.field.preferences.valign === 'top',
        'items-end': this.field.preferences.valign === 'bottom',
        'justify-center': this.field.preferences.align === 'center',
        'justify-start': this.field.preferences.align === 'left',
        'justify-end': this.field.preferences.align === 'right',
        'font-courier': this.field.preferences.font === 'Courier',
        'font-times': this.field.preferences.font === 'Times',
        'font-bold': ['bold_italic', 'bold'].includes(this.field.preferences.font_type),
        italic: ['bold_italic', 'italic'].includes(this.field.preferences.font_type)
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
        'bg-indigo-100'
      ]
    },
    isSelected () {
      return this.selectedAreasRef.value.includes(this.area)
    },
    isInMultiSelection () {
      return this.selectedAreasRef.value.length >= 2 && this.isSelected
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
          this.textOverflowChars = (this.$el.clientHeight + 1) < this.$refs.textContainer.clientHeight ? `${this.field.default_value}`.length : 0
        }
      })
    }
  },
  mounted () {
    this.$nextTick(() => {
      if (['date', 'text', 'number'].includes(this.field.type) && this.field.default_value && this.$refs.textContainer && (this.textOverflowChars === 0 || (this.textOverflowChars - 4) > `${this.field.default_value}`.length)) {
        this.textOverflowChars = (this.$el.clientHeight + 1) < this.$refs.textContainer.clientHeight ? `${this.field.default_value}`.length : 0
      }
    })
  },
  methods: {
    buildDefaultName: Field.methods.buildDefaultName,
    buildAreaOptionValue (area) {
      const option = this.optionsUuidIndex[area.option_uuid]

      return option?.value || `${this.t('option')} ${this.field.options.indexOf(option) + 1}`
    },
    maybeToggleDefaultValue () {
      if (!this.editable || this.isCmdKeyRef.value) {
        return
      }

      if (['text', 'number'].includes(this.field.type)) {
        this.isContenteditable = true

        this.focusValueInput()
      } else if (this.field.type === 'date') {
        this.field.readonly = !this.field.readonly
        this.field.default_value === '{{date}}' ? delete this.field.default_value : this.field.default_value = '{{date}}'

        this.save()
      } else {
        this.maybeToggleCheckboxValue()
      }
    },
    maybeToggleCheckboxValue () {
      if (this.field.type === 'checkbox') {
        this.field.default_value === true ? delete this.field.default_value : this.field.default_value = true
        this.field.readonly = this.field.default_value === true

        this.save()
      } else if (this.field.type === 'radio' && this.area.option_uuid) {
        const value = this.buildAreaOptionValue(this.area)

        this.field.default_value === value ? delete this.field.default_value : this.field.default_value = value

        this.field.readonly = !!this.field.default_value?.length

        this.save()
      } else if (this.field.type === 'multiple' && this.area.option_uuid) {
        const value = this.buildAreaOptionValue(this.area)

        if (this.field.default_value?.includes(value)) {
          this.field.default_value.splice(this.field.default_value.indexOf(value), 1)

          if (!this.field.default_value?.length) delete this.field.default_value
        } else {
          Array.isArray(this.field.default_value) ? this.field.default_value.push(value) : this.field.default_value = [value]
        }

        this.field.readonly = !!this.field.default_value?.length

        this.save()
      }
    },
    focusValueInput (e) {
      this.$nextTick(() => {
        if (this.$refs.defaultValue && this.$refs.defaultValue !== document.activeElement) {
          this.$refs.defaultValue.focus()

          if (this.$refs.defaultValue.innerText.length && this.$refs.defaultValue !== e?.target) {
            window.getSelection().collapse(
              this.$refs.defaultValue.firstChild,
              this.$refs.defaultValue.innerText.length
            )
          }
        }
      })
    },
    formatNumber (number, format) {
      if (format === 'comma') {
        return new Intl.NumberFormat('en-US').format(number)
      } else if (format === 'usd') {
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(number)
      } else if (format === 'gbp') {
        return new Intl.NumberFormat('en-GB', { style: 'currency', currency: 'GBP', minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(number)
      } else if (format === 'eur') {
        return new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'EUR', minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(number)
      } else if (format === 'dot') {
        return new Intl.NumberFormat('de-DE').format(number)
      } else if (format === 'space') {
        return new Intl.NumberFormat('fr-FR').format(number)
      } else {
        return number
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
    onDefaultValueBlur (e) {
      const text = this.$refs.defaultValue.innerText.trim()

      this.isContenteditable = false
      this.isHeadingSelected = false

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
    resize (e) {
      if (e.target.id === 'mask') {
        this.area.w = e.offsetX / e.target.clientWidth - this.area.x
        this.area.h = e.offsetY / e.target.clientHeight - this.area.y

        if (this.isInMultiSelection) {
          this.selectedAreasRef.value.forEach((area) => {
            if (area !== this.area) {
              area.w = this.area.w
              area.h = this.area.h
            }
          })
        }
      }
    },
    drag (e) {
      if (e.target.id === 'mask' && this.editable) {
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

      if (this.editable) {
        this.isDragged = true
      }

      const rect = e.target.getBoundingClientRect()

      this.selectedAreasRef.value = [this.area]

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
      this.area.y = (this.dragFrom.y + e.touches[0].clientY - rect.top) / rect.height

      if ((this.area.page === 0 && this.area.y < 0) || (this.area.page === this.maxPage && this.area.y > 1 - this.area.h)) {
        this.area.y = Math.min(Math.max(this.area.y, 0), 1 - this.area.h)
      }
    },
    stopTouchDrag () {
      this.$el.getRootNode().removeEventListener('touchmove', this.touchDrag)
      this.$el.getRootNode().removeEventListener('touchend', this.stopTouchDrag)

      this.maybeChangeAreaPage(this.area)

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

      if (e.metaKey || e.ctrlKey) {
        if (!this.selectedAreasRef.value.includes(this.area)) {
          this.selectedAreasRef.value.push(this.area)
        } else {
          this.selectedAreasRef.value.splice(this.selectedAreasRef.value.indexOf(this.area), 1)
        }

        return
      }

      if (this.editable) {
        this.isDragged = true
      }

      const rect = e.target.getBoundingClientRect()

      this.selectedAreasRef.value = [this.area]

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
      this.area.y = (this.dragFrom.y + e.clientY - rect.top) / rect.height

      if ((this.area.page === 0 && this.area.y < 0) || (this.area.page === this.maxPage && this.area.y > 1 - this.area.h)) {
        this.area.y = Math.min(Math.max(this.area.y, 0), 1 - this.area.h)
      }
    },
    stopMouseMove (e) {
      this.$el.getRootNode().removeEventListener('mousemove', this.mouseMove)
      this.$el.getRootNode().removeEventListener('mouseup', this.stopMouseMove)

      this.maybeChangeAreaPage(this.area)

      if (this.isMoved) {
        this.save()
      }

      if (this.field.type === 'heading') {
        this.isHeadingSelected = !this.isMoved

        this.focusValueInput()
      }

      this.isDragged = false
      this.isMoved = false

      this.$emit('stop-drag')
    },
    maybeChangeAreaPage (area) {
      if (area.y < -(area.h / 2)) {
        area.page -= 1
        area.y = 1 + area.y + (16.0 / this.$parent.$refs.mask.previousSibling.offsetHeight)
      } else if (area.y > 1 - (area.h / 2)) {
        area.page += 1
        area.y = area.y - 1 - (16.0 / this.$parent.$refs.mask.previousSibling.offsetHeight)
      }
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
      if (!this.selectedAreasRef.value.includes(this.area)) {
        this.selectedAreasRef.value = [this.area]
      }

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
      if (!this.selectedAreasRef.value.includes(this.area)) {
        this.selectedAreasRef.value = [this.area]
      }

      this.$refs?.title?.$refs?.name?.blur()

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

      if (this.isInMultiSelection) {
        this.selectedAreasRef.value.forEach((area) => {
          if (area !== this.area) {
            area.w = this.area.w
            area.h = this.area.h
          }
        })
      }
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

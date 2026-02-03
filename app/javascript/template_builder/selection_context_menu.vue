<template>
  <div>
    <div
      v-if="!isShowFontModal && !isShowConditionsModal"
      ref="menu"
      class="fixed z-50 p-1 bg-base-300 shadow-lg rounded-lg border border-neutral-200 cursor-default"
      style="min-width: 170px"
      :style="menuStyle"
      @mousedown.stop
      @pointerdown.stop
    >
      <ContextSubmenu
        :icon="IconLayoutAlignMiddle"
        :label="t('align')"
      >
        <button
          class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm"
          @click.stop="alignSelectedAreas('left')"
        >
          <IconLayoutAlignLeft class="w-4 h-4" />
          <span>{{ t('align_left') }}</span>
        </button>
        <button
          class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm"
          @click.stop="alignSelectedAreas('right')"
        >
          <IconLayoutAlignRight class="w-4 h-4" />
          <span>{{ t('align_right') }}</span>
        </button>
        <button
          class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm"
          @click.stop="alignSelectedAreas('top')"
        >
          <IconLayoutAlignTop class="w-4 h-4" />
          <span>{{ t('align_top') }}</span>
        </button>
        <button
          class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm"
          @click.stop="alignSelectedAreas('bottom')"
        >
          <IconLayoutAlignBottom class="w-4 h-4" />
          <span>{{ t('align_bottom') }}</span>
        </button>
      </ContextSubmenu>
      <ContextSubmenu
        :icon="IconAspectRatio"
        :label="t('resize')"
      >
        <button
          class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm"
          @click.stop="resizeSelectedAreas('width')"
        >
          <IconArrowsHorizontal class="w-4 h-4" />
          <span>{{ t('width') }}</span>
        </button>
        <button
          class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm"
          @click.stop="resizeSelectedAreas('height')"
        >
          <IconArrowsVertical class="w-4 h-4" />
          <span>{{ t('height') }}</span>
        </button>
      </ContextSubmenu>
      <hr
        v-if="showFont || showCondition"
        class="my-1 border-neutral-200"
      >
      <button
        v-if="showFont"
        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm"
        @click.stop="openFontModal"
      >
        <IconTypography class="w-4 h-4" />
        <span>{{ t('font') }}</span>
      </button>
      <button
        v-if="showCondition"
        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center space-x-2 text-sm"
        @click.stop="openConditionModal"
      >
        <IconRouteAltLeft class="w-4 h-4" />
        <span>{{ t('condition') }}</span>
      </button>
      <hr class="my-1 border-neutral-200">
      <button
        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center justify-between text-sm"
        @click.stop="$emit('copy')"
      >
        <span class="flex items-center space-x-2">
          <IconCopy class="w-4 h-4" />
          <span>{{ t('copy') }}</span>
        </span>
        <span class="text-xs text-base-content/60 ml-4">{{ isMac ? '⌘C' : 'Ctrl+C' }}</span>
      </button>
      <button
        class="w-full px-2 py-1 rounded-md hover:bg-neutral-100 flex items-center justify-between text-sm text-red-600"
        @click.stop="$emit('delete')"
      >
        <span class="flex items-center space-x-2">
          <IconTrashX class="w-4 h-4" />
          <span>{{ t('remove') }}</span>
        </span>
        <span class="text-xs text-base-content/60 ml-4">Del</span>
      </button>
    </div>
    <Teleport
      v-if="isShowFontModal"
      :to="modalContainerEl"
    >
      <FontModal
        :field="multiSelectField"
        :area="contextMenu.area"
        :editable="editable"
        :build-default-name="buildDefaultName"
        @save="handleSaveMultiSelectFontModal"
        @close="closeModal"
      />
    </Teleport>
    <Teleport
      v-if="isShowConditionsModal"
      :to="modalContainerEl"
    >
      <ConditionsModal
        :item="multiSelectField"
        :build-default-name="buildDefaultName"
        :exclude-field-uuids="selectedFields.map(f => f.uuid)"
        @save="handleSaveMultiSelectConditionsModal"
        @close="closeModal"
      />
    </Teleport>
  </div>
</template>

<script>
import { IconCopy, IconTrashX, IconTypography, IconRouteAltLeft, IconLayoutAlignLeft, IconLayoutAlignRight, IconLayoutAlignTop, IconLayoutAlignBottom, IconLayoutAlignMiddle, IconAspectRatio, IconArrowsHorizontal, IconArrowsVertical } from '@tabler/icons-vue'
import FontModal from './font_modal'
import ConditionsModal from './conditions_modal'
import ContextSubmenu from './field_context_submenu'
import Field from './field'
import FieldType from './field_type'

export default {
  name: 'SelectionContextMenu',
  components: {
    IconCopy,
    IconTrashX,
    IconTypography,
    IconRouteAltLeft,
    IconLayoutAlignLeft,
    IconLayoutAlignRight,
    IconLayoutAlignTop,
    IconLayoutAlignBottom,
    FontModal,
    IconArrowsHorizontal,
    IconArrowsVertical,
    ConditionsModal,
    ContextSubmenu
  },
  inject: ['t', 'save', 'selectedAreasRef', 'getFieldTypeIndex'],
  props: {
    contextMenu: {
      type: Object,
      required: true
    },
    editable: {
      type: Boolean,
      default: true
    },
    template: {
      type: Object,
      required: true
    },
    withCondition: {
      type: Boolean,
      default: true
    }
  },
  emits: ['copy', 'delete', 'close'],
  data () {
    return {
      isShowFontModal: false,
      isShowConditionsModal: false,
      multiSelectField: null
    }
  },
  computed: {
    modalContainerEl () {
      return this.$el.getRootNode().querySelector('#docuseal_modal_container')
    },
    selectedFields () {
      return this.selectedAreasRef.value.map((area) => {
        return this.template.fields.find((f) => f.areas?.includes(area))
      }).filter(Boolean)
    },
    isMac () {
      return (navigator.userAgentData?.platform || navigator.platform)?.toLowerCase()?.includes('mac')
    },
    menuStyle () {
      return {
        left: this.contextMenu.x + 'px',
        top: this.contextMenu.y + 'px'
      }
    },
    showFont () {
      return true
    },
    showCondition () {
      return this.withCondition
    },
    fieldNames: FieldType.computed.fieldNames,
    fieldLabels: FieldType.computed.fieldLabels
  },
  mounted () {
    document.addEventListener('keydown', this.onKeyDown)
    document.addEventListener('mousedown', this.handleClickOutside)

    this.$nextTick(() => this.checkMenuPosition())
  },
  beforeUnmount () {
    document.removeEventListener('keydown', this.onKeyDown)
    document.removeEventListener('mousedown', this.handleClickOutside)
  },
  methods: {
    IconLayoutAlignMiddle,
    IconAspectRatio,
    buildDefaultName: Field.methods.buildDefaultName,
    checkMenuPosition () {
      if (this.$refs.menu) {
        const rect = this.$refs.menu.getBoundingClientRect()
        const overflow = rect.bottom - window.innerHeight

        if (overflow > 0) {
          this.contextMenu.y = this.contextMenu.y - overflow - 4
        }
      }
    },
    onKeyDown (event) {
      if (event.key === 'Escape') {
        event.preventDefault()
        event.stopPropagation()

        this.$emit('close')
      }
    },
    handleClickOutside (event) {
      if (this.$refs.menu && !this.$refs.menu.contains(event.target)) {
        this.$emit('close')
      }
    },
    openFontModal () {
      this.multiSelectField = {
        name: this.t('fields_selected').replace('{count}', this.selectedFields.length),
        preferences: {}
      }

      const preferencesStrings = this.selectedFields.map((f) => JSON.stringify(f.preferences || {}))

      if (preferencesStrings.every((s) => s === preferencesStrings[0])) {
        this.multiSelectField.preferences = JSON.parse(preferencesStrings[0])
      }

      this.isShowFontModal = true
    },
    openConditionModal () {
      this.multiSelectField = {
        name: this.t('fields_selected').replace('{count}', this.selectedFields.length),
        conditions: []
      }

      const conditionStrings = this.selectedFields.map((f) => JSON.stringify(f.conditions || []))

      if (conditionStrings.every((s) => s === conditionStrings[0])) {
        this.multiSelectField.conditions = JSON.parse(conditionStrings[0])
      }

      this.isShowConditionsModal = true
    },
    closeModal () {
      this.isShowFontModal = false
      this.isShowConditionsModal = false
      this.multiSelectField = null

      this.$emit('close')
    },
    alignSelectedAreas (direction) {
      const areas = this.selectedAreasRef.value

      let targetValue

      if (direction === 'left') {
        targetValue = Math.min(...areas.map(a => a.x))
        areas.forEach((area) => { area.x = targetValue })
      } else if (direction === 'right') {
        targetValue = Math.max(...areas.map(a => a.x + a.w))
        areas.forEach((area) => { area.x = targetValue - area.w })
      } else if (direction === 'top') {
        targetValue = Math.min(...areas.map(a => a.y))
        areas.forEach((area) => { area.y = targetValue })
      } else if (direction === 'bottom') {
        targetValue = Math.max(...areas.map(a => a.y + a.h))
        areas.forEach((area) => { area.y = targetValue - area.h })
      }

      this.save()

      this.$emit('close')
    },
    resizeSelectedAreas (dimension) {
      const areas = this.selectedAreasRef.value

      const values = areas.map(a => dimension === 'width' ? a.w : a.h).sort((a, b) => a - b)
      const medianValue = values[Math.floor(values.length / 2)]

      if (dimension === 'width') {
        areas.forEach((area) => { area.w = medianValue })
      } else if (dimension === 'height') {
        areas.forEach((area) => {
          const diff = medianValue - area.h
          area.y = area.y - diff
          area.h = medianValue
        })
      }

      this.save()

      this.$emit('close')
    },
    handleSaveMultiSelectFontModal () {
      this.selectedFields.forEach((field) => {
        field.preferences = { ...field.preferences, ...this.multiSelectField.preferences }
      })

      this.save()

      this.closeModal()
    },
    handleSaveMultiSelectConditionsModal () {
      this.selectedFields.forEach((field) => {
        field.conditions = JSON.parse(JSON.stringify(this.multiSelectField.conditions))
      })

      this.save()

      this.closeModal()
    }
  }
}
</script>

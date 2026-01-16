<template>
  <div>
    <div
      v-if="!isShowFormulaModal && !isShowFontModal && !isShowConditionsModal && !isShowDescriptionModal"
      ref="menu"
      class="fixed z-50 p-1 bg-white shadow-lg rounded-lg border border-base-300 min-w-[170px] cursor-default"
      :style="menuStyle"
      @mousedown.stop
      @pointerdown.stop
    >
      <label
        v-if="showRequired"
        class="w-full px-2 py-1 rounded-md hover:bg-base-100 flex items-center space-x-2 text-sm cursor-pointer"
        @click.stop
      >
        <input
          :checked="isRequired"
          type="checkbox"
          class="toggle toggle-xs"
          @change="handleToggleRequired($event.target.checked)"
          @click.stop
        >
        <span>{{ t('required') }}</span>
      </label>
      <label
        v-if="showReadOnly"
        class="w-full px-2 py-1 rounded-md hover:bg-base-100 flex items-center space-x-2 text-sm cursor-pointer"
        @click.stop
      >
        <input
          :checked="isReadOnly"
          type="checkbox"
          class="toggle toggle-xs"
          @change="handleToggleReadOnly($event.target.checked)"
          @click.stop
        >
        <span>{{ t('read_only') }}</span>
      </label>
      <hr
        v-if="(showRequired || showReadOnly) && (showFont || showDescription || showCondition || showFormula)"
        class="my-1 border-base-300"
      >
      <button
        v-if="showFont"
        class="w-full px-2 py-1 rounded-md hover:bg-base-100 flex items-center space-x-2 text-sm"
        @click.stop="openFontModal"
      >
        <IconTypography class="w-4 h-4" />
        <span>{{ t('font') }}</span>
      </button>
      <button
        v-if="showDescription"
        class="w-full px-2 py-1 rounded-md hover:bg-base-100 flex items-center space-x-2 text-sm"
        @click.stop="openDescriptionModal"
      >
        <IconInfoCircle class="w-4 h-4" />
        <span>{{ t('description') }}</span>
      </button>
      <button
        v-if="showCondition"
        class="w-full px-2 py-1 rounded-md hover:bg-base-100 flex items-center space-x-2 text-sm"
        @click.stop="openConditionModal"
      >
        <IconRouteAltLeft class="w-4 h-4" />
        <span>{{ t('condition') }}</span>
      </button>
      <button
        v-if="showFormula"
        class="w-full px-2 py-1 rounded-md hover:bg-base-100 flex items-center space-x-2 text-sm"
        @click.stop="openFormulaModal"
      >
        <IconMathFunction class="w-4 h-4" />
        <span>{{ t('formula') }}</span>
      </button>
      <hr
        v-if="(showFont || showDescription || showCondition || showFormula) && (showCopy || showDelete || showPaste)"
        class="my-1 border-base-300"
      >
      <button
        v-if="showCopy"
        class="w-full px-2 py-1 rounded-md hover:bg-base-100 flex items-center justify-between text-sm"
        @click.stop="$emit('copy')"
      >
        <span class="flex items-center space-x-2">
          <IconCopy class="w-4 h-4" />
          <span>{{ t('copy') }}</span>
        </span>
        <span class="text-xs text-base-content/60 ml-4">{{ isMac ? '⌘C' : 'Ctrl+C' }}</span>
      </button>
      <button
        v-if="showDelete"
        class="w-full px-2 py-1 rounded-md hover:bg-base-100 flex items-center justify-between text-sm text-red-600"
        @click.stop="$emit('delete')"
      >
        <span class="flex items-center space-x-2">
          <IconTrashX class="w-4 h-4" />
          <span>{{ t('remove') }}</span>
        </span>
        <span class="text-xs text-base-content/60 ml-4">Del</span>
      </button>
      <button
        v-if="showPaste"
        class="w-full px-2 py-1 rounded-md hover:bg-base-100 flex items-center justify-between text-sm"
        :class="!hasClipboardData ? 'opacity-50 cursor-not-allowed' : 'hover:bg-base-100'"
        :disabled="!hasClipboardData"
        @click.stop="!hasClipboardData ? null : $emit('paste')"
      >
        <span class="flex items-center space-x-2">
          <IconClipboard class="w-4 h-4" />
          <span>{{ t('paste') }}</span>
        </span>
        <span class="text-xs text-base-content/60 ml-4">{{ isMac ? '⌘V' : 'Ctrl+V' }}</span>
      </button>
    </div>
    <Teleport
      v-if="isShowFormulaModal"
      to="#docuseal_modal_container"
    >
      <FormulaModal
        :field="field"
        :editable="editable"
        :build-default-name="buildDefaultName"
        @close="closeModal"
      />
    </Teleport>
    <Teleport
      v-if="isShowFontModal"
      to="#docuseal_modal_container"
    >
      <FontModal
        :field="field"
        :area="contextMenu.area"
        :editable="editable"
        :build-default-name="buildDefaultName"
        @close="closeModal"
      />
    </Teleport>
    <Teleport
      v-if="isShowConditionsModal"
      to="#docuseal_modal_container"
    >
      <ConditionsModal
        :item="field"
        :build-default-name="buildDefaultName"
        @close="closeModal"
      />
    </Teleport>
    <Teleport
      v-if="isShowDescriptionModal"
      to="#docuseal_modal_container"
    >
      <DescriptionModal
        :field="field"
        :editable="editable"
        :build-default-name="buildDefaultName"
        @close="closeModal"
      />
    </Teleport>
  </div>
</template>

<script>
import { IconCopy, IconClipboard, IconTrashX, IconTypography, IconInfoCircle, IconRouteAltLeft, IconMathFunction } from '@tabler/icons-vue'
import FormulaModal from './formula_modal'
import FontModal from './font_modal'
import ConditionsModal from './conditions_modal'
import DescriptionModal from './description_modal'
import Field from './field'
import FieldType from './field_type.vue'

export default {
  name: 'ContextMenu',
  components: {
    IconCopy,
    IconClipboard,
    IconTrashX,
    IconTypography,
    IconInfoCircle,
    IconRouteAltLeft,
    IconMathFunction,
    FormulaModal,
    FontModal,
    ConditionsModal,
    DescriptionModal
  },
  inject: ['t', 'save'],
  props: {
    contextMenu: {
      type: Object,
      default: null,
      required: true
    },
    field: {
      type: Object,
      default: null
    },
    editable: {
      type: Boolean,
      default: true
    }
  },
  emits: ['copy', 'paste', 'delete', 'close'],
  data () {
    return {
      isShowFormulaModal: false,
      isShowFontModal: false,
      isShowConditionsModal: false,
      isShowDescriptionModal: false
    }
  },
  computed: {
    fieldNames: FieldType.computed.fieldNames,
    fieldLabels: FieldType.computed.fieldLabels,
    isMac () {
      return (navigator.userAgentData?.platform || navigator.platform)?.toLowerCase()?.includes('mac')
    },
    hasClipboardData () {
      try {
        const clipboard = localStorage.getItem('docuseal_clipboard')

        if (clipboard) {
          const data = JSON.parse(clipboard)

          return Date.now() - data.timestamp < 3600000
        }

        return false
      } catch {
        return false
      }
    },
    menuStyle () {
      return {
        left: this.contextMenu.x + 'px',
        top: this.contextMenu.y + 'px'
      }
    },
    showCopy () {
      return !!this.contextMenu.area
    },
    showPaste () {
      return !this.contextMenu.area
    },
    showDelete () {
      return !!this.contextMenu.area
    },
    showFont () {
      if (!this.field) return false
      return ['text', 'number', 'date', 'select', 'heading'].includes(this.field.type)
    },
    showDescription () {
      if (!this.field) return false
      return !['stamp', 'heading', 'strikethrough'].includes(this.field.type)
    },
    showCondition () {
      if (!this.field) return false
      return !['stamp', 'heading'].includes(this.field.type)
    },
    showFormula () {
      if (!this.field) return false
      return this.field.type === 'number'
    },
    showRequired () {
      if (!this.field) return false
      return !['phone', 'stamp', 'verification', 'strikethrough', 'heading'].includes(this.field.type)
    },
    showReadOnly () {
      if (!this.field) return false
      return ['text', 'number'].includes(this.field.type)
    },
    isRequired () {
      return this.field?.required || false
    },
    isReadOnly () {
      return this.field?.readonly || false
    }
  },
  mounted () {
    document.addEventListener('keydown', this.onKeyDown)
    document.addEventListener('mousedown', this.handleClickOutside)

    this.$nextTick(() => {
      this.checkMenuPosition()
    })
  },
  beforeUnmount () {
    document.removeEventListener('keydown', this.onKeyDown)
    document.removeEventListener('mousedown', this.handleClickOutside)
  },
  methods: {
    buildDefaultName: Field.methods.buildDefaultName,
    checkMenuPosition () {
      if (this.$refs.menu) {
        const rect = this.$refs.menu.getBoundingClientRect()

        if (rect.bottom > window.innerHeight) {
          this.contextMenu.y = this.contextMenu.y - rect.height
        }

        if (rect.right > window.innerWidth) {
          this.contextMenu.x = this.contextMenu.x - rect.width
        }
      }
    },
    handleToggleRequired (value) {
      if (this.field) {
        this.field.required = value
        this.save()
      }
    },
    handleToggleReadOnly (value) {
      if (this.field) {
        this.field.readonly = value
        this.save()
      }
    },
    onKeyDown (event) {
      if (event.key === 'Escape') {
        event.preventDefault()
        event.stopPropagation()

        this.$emit('close')
      } else if ((event.ctrlKey || event.metaKey) && event.key === 'v' && this.hasClipboardData) {
        event.preventDefault()
        event.stopPropagation()

        this.$emit('paste')
      }
    },
    handleClickOutside (event) {
      if (this.$refs.menu && !this.$refs.menu.contains(event.target)) {
        this.$emit('close')
      }
    },
    openFontModal () {
      this.isShowFontModal = true
    },
    openDescriptionModal () {
      this.isShowDescriptionModal = true
    },
    openConditionModal () {
      this.isShowConditionsModal = true
    },
    openFormulaModal () {
      this.isShowFormulaModal = true
    },
    closeModal () {
      this.isShowFormulaModal = false
      this.isShowFontModal = false
      this.isShowConditionsModal = false
      this.isShowDescriptionModal = false

      this.$emit('close')
    }
  }
}
</script>

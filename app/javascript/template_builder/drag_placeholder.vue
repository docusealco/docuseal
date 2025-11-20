<template>
  <Field
    v-if="dragPlaceholder && isField && !isMask && field"
    ref="dragPlaceholder"
    :style="dragPlaceholderStyle"
    :field="field"
    :with-options="false"
    class="fixed z-20 pointer-events-none"
    :editable="false"
  />
  <div
    v-else-if="dragPlaceholder && (isDefault || isRequired) && !isMask && field"
    ref="dragPlaceholder"
    :style="[dragPlaceholderStyle, { backgroundColor: backgroundColor }]"
    class="fixed z-20 border border-base-300 rounded group default-field fields-list-item pointer-events-none"
  >
    <div class="flex items-center justify-between relative cursor-grab">
      <div class="flex items-center p-1 space-x-1">
        <IconDrag />
        <component
          :is="fieldIcons[field.type || 'text']"
          :stroke-width="1.6"
          :width="20"
        />
        <span class="block pl-0.5">
          {{ field.title || field.name }}
        </span>
      </div>
      <span
        v-if="isRequired"
        :data-tip="t('required')"
        class="text-red-400 text-3xl pr-1.5 tooltip tooltip-left h-8"
      >
        *
      </span>
    </div>
  </div>
  <button
    v-else-if="dragPlaceholder && !isMask && field"
    ref="dragPlaceholder"
    class="fixed field-type-button z-20 flex items-center justify-center border border-dashed w-full rounded border-base-content/20 opacity-90 pointer-events-none"
    :style="[dragPlaceholderStyle, { backgroundColor }]"
  >
    <div
      class="flex items-console cursor-grab h-full absolute left-0 bg-base-200/50"
    >
      <IconDrag class="my-auto" />
    </div>
    <div class="flex items-center flex-col px-2 py-2">
      <component :is="fieldIcons[field.type || 'text']" />
      <span class="text-xs mt-1">
        {{ fieldNames[field.type || 'text'] }}
      </span>
    </div>
  </button>
</template>

<script>
import Field from './field'
import IconDrag from './icon_drag'
import FieldType from './field_type'

export default {
  name: 'DragPlaceholder',
  components: {
    Field,
    IconDrag
  },
  inject: ['t', 'backgroundColor'],
  props: {
    field: {
      type: Object,
      required: false,
      default: null
    },
    isDefault: {
      type: Boolean,
      required: false,
      default: false
    },
    isRequired: {
      type: Boolean,
      required: false,
      default: false
    },
    isField: {
      type: Boolean,
      required: false,
      default: false
    }
  },
  data () {
    return {
      isMask: false,
      dragPlaceholder: null
    }
  },
  computed: {
    dragPlaceholderStyle () {
      if (this.dragPlaceholder) {
        return {
          left: this.dragPlaceholder.x + 'px',
          top: this.dragPlaceholder.y + 'px',
          width: this.dragPlaceholder.w + 'px',
          height: this.dragPlaceholder.h + 'px'
        }
      } else {
        return {}
      }
    },
    fieldNames: FieldType.computed.fieldNames,
    fieldIcons: FieldType.computed.fieldIcons
  }
}
</script>

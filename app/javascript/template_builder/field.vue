<template>
  <div
    class="group pb-2"
  >
    <div
      class="border border-base-300 rounded rounded-tr-none relative group"
      :style="{ backgroundColor: backgroundColor }"
    >
      <div class="flex items-center justify-between relative group/contenteditable-container">
        <div
          class="absolute top-0 bottom-0 right-0 left-0 cursor-pointer"
          @click="scrollToFirstArea"
        />
        <div class="flex items-center p-1 space-x-1">
          <FieldType
            v-model="field.type"
            :editable="editable"
            :button-width="20"
            @update:model-value="[maybeUpdateOptions(), save()]"
            @click="scrollToFirstArea"
          />
          <Contenteditable
            ref="name"
            :model-value="field.name || defaultName"
            :editable="editable"
            :icon-inline="true"
            :icon-width="18"
            :icon-stroke-width="1.6"
            @focus="[onNameFocus(), scrollToFirstArea()]"
            @blur="onNameBlur"
          />
        </div>
        <div
          v-if="isNameFocus && !['redact', 'my_text', 'my_signature', 'my_initials', 'my_date', 'my_check'].includes(field.type)"
          class="flex items-center relative"
        >
          <template v-if="field.type != 'phone'">
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
          </template>
        </div>
        <div
          v-else-if="editable"
          class="flex items-center space-x-1"
        >
          <button
            v-if="field && !field.areas.length"
            title="Draw"
            class="relative cursor-pointer text-transparent group-hover:text-base-content"
            @click="$emit('set-draw', { field })"
          >
            <IconNewSection
              :width="18"
              :stroke-width="1.6"
            />
          </button>
          <span
            class="dropdown dropdown-end"
          >
            <label
              tabindex="0"
              title="Settings"
              class="cursor-pointer text-transparent group-hover:text-base-content"
            >
              <IconSettings
                :width="18"
                :stroke-width="1.6"
              />
            </label>
            <ul
              tabindex="0"
              class="mt-1.5 dropdown-content menu menu-xs p-2 shadow bg-base-100 rounded-box w-52 z-10"
              draggable="true"
              @dragstart.prevent.stop
              @click="closeDropdown"
            >
              <div
                v-if="field.type === 'text'"
                class="py-1.5 px-1 relative"
                @click.stop
              >
                <input
                  v-model="field.default_value"
                  type="text"
                  placeholder="Default value"
                  class="input input-bordered input-xs w-full max-w-xs h-7 !outline-0"
                  @blur="save"
                >
                <label
                  v-if="field.default_value"
                  :style="{ backgroundColor: backgroundColor }"
                  class="absolute -top-1 left-2.5 px-1 h-4"
                  style="font-size: 8px"
                >
                  Default value
                </label>
              </div>
              <li
                v-if="field.type != 'phone'"
                @click.stop
              >
                <label class="cursor-pointer py-1.5">
                  <input
                    v-model="field.required"
                    type="checkbox"
                    class="toggle toggle-xs"
                    @update:model-value="save"
                  >
                  <span class="label-text">Required</span>
                </label>
              </li>
              <li
                v-if="field.type === 'text'"
                @click.stop
              >
                <label class="cursor-pointer py-1.5">
                  <input
                    v-model="field.readonly"
                    type="checkbox"
                    class="toggle toggle-xs"
                    @update:model-value="save"
                  >
                  <span class="label-text">Read-only</span>
                </label>
              </li>
              <hr class="pb-0.5 mt-0.5">
              <li
                v-for="(area, index) in field.areas || []"
                :key="index"
              >
                <a
                  href="#"
                  class="text-sm py-1 px-2"
                  @click.prevent="$emit('scroll-to', area)"
                >
                  <IconShape
                    :width="20"
                    :stroke-width="1.6"
                  />
                  Page {{ area.page + 1 }}
                </a>
              </li>
              <li v-if="!field.areas?.length || !['radio', 'multiple'].includes(field.type)">
                <a
                  href="#"
                  class="text-sm py-1 px-2"
                  @click.prevent="$emit('set-draw', { field })"
                >
                  <IconNewSection
                    :width="20"
                    :stroke-width="1.6"
                  />
                  Draw New Area
                </a>
              </li>
              <li v-if="field.areas?.length === 1 && ['date', 'signature', 'initials', 'text', 'cells', 'my_text', 'redact', 'my_signature', 'my_initials', 'my_date', 'my_check'].includes(field.type)">
                <a
                  href="#"
                  class="text-sm py-1 px-2"
                  @click.prevent="copyToAllPages(field)"
                >
                  <IconCopy
                    :width="20"
                    :stroke-width="1.6"
                  />
                  Copy to All Pages
                </a>
              </li>
            </ul>
          </span>
          <button
            class="relative text-transparent group-hover:text-base-content pr-1"
            title="Remove"
            @click="$emit('remove', field)"
          >
            <IconTrashX
              :width="18"
              :stroke-width="1.6"
            />
          </button>
        </div>
      </div>
      <div
        v-if="field.options"
        ref="options"
        class="border-t border-base-300 mx-2 pt-2 space-y-1.5"
        draggable="true"
        @dragstart.prevent.stop
      >
        <div
          v-for="(option, index) in field.options"
          :key="option.uuid"
          class="flex space-x-1.5 items-center"
        >
          <span class="text-sm w-3.5">
            {{ index + 1 }}.
          </span>
          <div
            v-if="['radio', 'multiple'].includes(field.type) && (index > 0 || field.areas.find((a) => a.option_uuid) || !field.areas.length) && !field.areas.find((a) => a.option_uuid === option.uuid)"
            class="items-center flex w-full"
          >
            <input
              v-model="option.value"
              class="w-full input input-primary input-xs text-sm bg-transparent !pr-7 -mr-6"
              type="text"
              required
              @blur="save"
            >
            <button
              title="Draw"
              tabindex="-1"
              @click.prevent="$emit('set-draw', { field, option })"
            >
              <IconNewSection
                :width="18"
                :stroke-width="1.6"
              />
            </button>
          </div>
          <input
            v-else
            v-model="option.value"
            class="w-full input input-primary input-xs text-sm bg-transparent"
            type="text"
            required
            @focus="maybeFocusOnOptionArea(option)"
            @blur="save"
          >
          <button
            class="text-sm w-3.5"
            tabindex="-1"
            @click="removeOption(option)"
          >
            &times;
          </button>
        </div>
        <button
          v-if="field.options"
          class="text-center text-sm w-full pb-1"
          @click="addOption"
        >
          + Add option
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import Contenteditable from './contenteditable'
import FieldType from './field_type'
import { IconShape, IconNewSection, IconTrashX, IconCopy, IconSettings } from '@tabler/icons-vue'
import { v4 } from 'uuid'

export default {
  name: 'TemplateField',
  components: {
    Contenteditable,
    IconSettings,
    IconShape,
    IconNewSection,
    IconTrashX,
    IconCopy,
    FieldType
  },
  inject: ['template', 'save', 'backgroundColor', 'selectedAreaRef'],
  props: {
    field: {
      type: Object,
      required: true
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    }
  },
  emits: ['set-draw', 'remove', 'scroll-to'],
  data () {
    return {
      isNameFocus: false
    }
  },
  computed: {
    fieldNames: FieldType.computed.fieldNames,
    defaultName () {
      const typeIndex = this.template.fields.filter((f) => f.type === this.field.type).indexOf(this.field)

      const suffix = { multiple: 'Select', radio: 'Group' }[this.field.type] || 'Field'

      return `${this.fieldNames[this.field.type]} ${suffix} ${typeIndex + 1}`
    },
    areas () {
      return this.field.areas || []
    }
  },
  methods: {
    copyToAllPages (field) {
      const areaString = JSON.stringify(field.areas[0])

      this.template.documents.forEach((attachment) => {
        attachment.preview_images.forEach((page) => {
          if (!field.areas.find((area) => area.attachment_uuid === attachment.uuid && area.page === parseInt(page.filename))) {
            field.areas.push({ ...JSON.parse(areaString), page: parseInt(page.filename) })
          }
        })
      })

      this.$nextTick(() => {
        this.$emit('scroll-to', this.field.areas[this.field.areas.length - 1])
      })

      this.save()
    },
    onNameFocus (e) {
      this.isNameFocus = true

      if (!this.field.name) {
        setTimeout(() => {
          this.$refs.name.$refs.contenteditable.innerText = ' '
        }, 1)
      }
    },
    maybeFocusOnOptionArea (option) {
      const area = this.field.areas.find((a) => a.option_uuid === option.uuid)

      if (area) {
        this.selectedAreaRef.value = area
      }
    },
    scrollToFirstArea () {
      return this.field.areas?.[0] && this.$emit('scroll-to', this.field.areas[0])
    },
    closeDropdown () {
      document.activeElement.blur()
    },
    addOption () {
      this.field.options.push({ value: '', uuid: v4() })

      this.$nextTick(() => {
        const inputs = this.$refs.options.querySelectorAll('input')

        inputs[inputs.length - 1]?.focus()
      })

      this.save()
    },
    removeOption (option) {
      this.field.options.splice(this.field.options.indexOf(option), 1)
      this.field.areas.splice(this.field.areas.findIndex((a) => a.option_uuid === option.uuid), 1)

      this.save()
    },
    maybeUpdateOptions () {
      delete this.field.default_value

      if (!['radio', 'multiple', 'select'].includes(this.field.type)) {
        delete this.field.options
      }

      if (['radio', 'multiple', 'select'].includes(this.field.type)) {
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
      const text = this.$refs.name.$refs.contenteditable.innerText.trim()

      if (text) {
        this.field.name = text
      } else {
        this.field.name = ''
        this.$refs.name.$refs.contenteditable.innerText = this.defaultName
      }

      this.isNameFocus = false

      this.save()
    },
    removeArea (area) {
      this.field.areas.splice(this.field.areas.indexOf(area), 1)

      this.save()
    }
  }
}
</script>

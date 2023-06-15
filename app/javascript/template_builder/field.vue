<template>
  <div
    class="group pb-2"
  >
    <div
      class="border border-base-300 rounded rounded-tr-none relative group"
    >
      <div class="flex items-center justify-between relative">
        <div
          class="absolute top-0 bottom-0 right-0 left-0 cursor-pointer"
          @click="scrollToFirstArea"
        />
        <div class="flex items-center p-1 space-x-1">
          <FieldType
            v-model="field.type"
            :button-width="20"
            @update:model-value="maybeUpdateOptions"
            @click="scrollToFirstArea"
          />
          <Contenteditable
            ref="name"
            :model-value="field.name || defaultName"
            :icon-inline="true"
            :icon-width="18"
            :icon-stroke-width="1.6"
            @focus="[onNameFocus(), scrollToFirstArea()]"
            @blur="onNameBlur"
          />
        </div>
        <div class="flex items-center space-x-1">
          <span
            v-if="field.areas?.length"
            class="dropdown dropdown-end"
          >
            <label
              tabindex="0"
              title="Areas"
              class="cursor-pointer text-base-100 group-hover:text-base-content"
            >
              <IconShape
                :width="18"
                :stroke-width="1.6"
              />
            </label>
            <ul
              tabindex="0"
              class="mt-1.5 dropdown-content menu menu-xs p-2 shadow bg-base-100 rounded-box w-52 z-10"
              @click="closeDropdown"
            >
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
              <li>
                <a
                  href="#"
                  class="text-sm py-1 px-2"
                  @click.prevent="$emit('set-draw', field)"
                >
                  <IconNewSection
                    :width="20"
                    :stroke-width="1.6"
                  />
                  Draw New Area
                </a>
              </li>
            </ul>
          </span>
          <button
            v-else
            title="Areas"
            class="relative cursor-pointer text-base-100 group-hover:text-base-content"
            @click="$emit('set-draw', field)"
          >
            <IconShape
              :width="18"
              :stroke-width="1.6"
            />
          </button>
          <button
            class="relative text-base-100 group-hover:text-base-content"
            title="Remove"
            @click="$emit('remove', field)"
          >
            <IconTrashX
              :width="18"
              :stroke-width="1.6"
            />
          </button>
          <div class="flex flex-col pr-1 text-base-100 group-hover:text-base-content">
            <button
              title="Up"
              class="relative"
              style="font-size: 10px; margin-bottom: -2px"
              @click="$emit('move-up')"
            >
              ▲
            </button>
            <button
              title="Down"
              class="relative"
              style="font-size: 10px; margin-top: -2px"
              @click="$emit('move-down')"
            >
              ▼
            </button>
          </div>
        </div>
      </div>
      <div
        v-if="field.options"
        class="border-t border-base-300 mx-2 pt-2 space-y-1.5"
      >
        <div
          v-for="(option, index) in field.options"
          :key="index"
          class="flex space-x-1.5 items-center"
        >
          <span class="text-sm w-3.5">
            {{ index + 1 }}.
          </span>
          <input
            v-model="field.options[index]"
            class="w-full input input-primary input-xs text-sm"
            type="text"
            required
          >
          <button
            class="text-sm w-3.5"
            @click="field.options.splice(index, 1)"
          >
            &times;
          </button>
        </div>
        <button
          v-if="field.options"
          class="text-center text-sm w-full pb-1"
          @click="field.options.push('')"
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
import { IconShape, IconNewSection, IconTrashX } from '@tabler/icons-vue'

export default {
  name: 'TemplateField',
  components: {
    Contenteditable,
    IconShape,
    IconNewSection,
    IconTrashX,
    FieldType
  },
  inject: ['template'],
  props: {
    field: {
      type: Object,
      required: true
    }
  },
  emits: ['set-draw', 'remove', 'move-up', 'move-down', 'scroll-to'],
  computed: {
    defaultName () {
      const typeIndex = this.template.fields.filter((f) => f.type === this.field.type).indexOf(this.field)

      const suffix = { multiple: 'Select', radio: 'Group' }[this.field.type] || 'Field'

      return `${this.$t(this.field.type)} ${suffix} ${typeIndex + 1}`
    },
    areas () {
      return this.field.areas || []
    }
  },
  methods: {
    onNameFocus (e) {
      if (!this.field.name) {
        setTimeout(() => {
          this.$refs.name.$refs.contenteditable.innerText = ' '
        }, 1)
      }
    },
    scrollToFirstArea () {
      return this.field.areas?.[0] && this.$emit('scroll-to', this.field.areas[0])
    },
    closeDropdown () {
      document.activeElement.blur()
    },
    maybeUpdateOptions () {
      if (!['radio', 'multiple', 'select'].includes(this.field.type)) {
        delete this.field.options
      }

      if (['radio', 'multiple', 'select'].includes(this.field.type)) {
        this.field.options ||= ['']
      }
    },
    onNameBlur (e) {
      if (e.target.innerText.trim()) {
        this.field.name = e.target.innerText.trim()
      } else {
        this.field.name = ''
        this.$refs.name.$refs.contenteditable.innerText = this.defaultName
      }
    },
    removeArea (area) {
      this.field.areas.splice(this.field.areas.indexOf(area), 1)
    }
  }
}
</script>

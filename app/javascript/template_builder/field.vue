<template>
  <div
    class="group pb-2"
    @mouseleave="closeDropdown"
  >
    <div
      class="border border-base-content rounded rounded-tr-none relative group"
    >
      <div class="flex items-center justify-between space-x-1">
        <div class="flex items-center p-1 space-x-1">
          <span class="dropdown">
            <label
              tabindex="0"
              title="Type"
              class="cursor-pointer"
            >
              <component
                :is="fieldIcons[field.type]"
                width="18"
                :stroke-width="1.6"
              />
            </label>
            <ul
              tabindex="0"
              class="mt-1.5 dropdown-content menu menu-xs p-2 shadow bg-base-100 rounded-box w-52"
              @click="closeDropdown"
            >
              <li
                v-for="(name, type) in fieldNames"
                :key="type"
              >
                <a
                  href="#"
                  class="text-sm py-1 px-2"
                  :class="{ 'active': type === field.type }"
                  @click.prevent="field.type = type"
                >
                  <component
                    :is="fieldIcons[type]"
                    :stroke-width="1.6"
                    :width="20"
                  />
                  {{ name }}
                </a>
              </li>
            </ul>
          </span>
          <Contenteditable
            ref="name"
            :model-value="field.name || defaultName"
            :icon-inline="true"
            :icon-width="19"
            @focus="onNameFocus"
            @blur="onNameBlur"
          />
        </div>
        <div class="flex items-center space-x-1 opacity-0 group-hover:opacity-100">
          <span class="dropdown dropdown-end">
            <label
              tabindex="0"
              title="Areas"
              class="cursor-pointer"
            >
              <IconShape
                :width="20"
                :stroke-width="1.6"
              />
            </label>
            <ul
              tabindex="0"
              class="mt-1.5 dropdown-content menu menu-xs p-2 shadow bg-base-100 rounded-box w-52"
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
          <button @click="$emit('remove', field)">
            <IconTrashX
              :width="20"
              :stroke-width="1.6"
            />
          </button>
          <div class="flex flex-col pr-1">
            <button
              title="Up"
              style="font-size: 10px; margin-bottom: -2px"
              @click="$emit('move-up')"
            >
              ▲
            </button>
            <button
              title="Down"
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
          <span class="text-sm">
            {{ index + 1 }}.
          </span>
          <input
            v-model="field.options[index]"
            class="w-full input input-primary input-xs text-sm"
            type="text"
            required
          >
          <button
            class="text-sm"
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
import { IconTextSize, IconWriting, IconCalendarEvent, IconPhoto, IconCheckbox, IconPaperclip, IconSelect, IconCircleDot, IconShape, IconNewSection, IconTrashX } from '@tabler/icons-vue'

export default {
  name: 'TemplateField',
  components: {
    Contenteditable,
    IconShape,
    IconNewSection,
    IconTrashX
  },
  props: {
    field: {
      type: Object,
      required: true
    },
    typeIndex: {
      type: Number,
      required: false,
      default: 0
    }
  },
  emits: ['set-draw', 'remove', 'move-up', 'move-down', 'scroll-to'],
  computed: {
    defaultName () {
      return `${this.fieldNames[this.field.type]} Field ${this.typeIndex + 1}`
    },
    areas () {
      return this.field.areas || []
    },
    fieldNames () {
      return {
        text: 'Text',
        signature: 'Signature',
        date: 'Date',
        image: 'Image',
        attachment: 'File',
        select: 'Select',
        checkbox: 'Checkbox',
        radio: 'Radio'
      }
    },
    fieldIcons () {
      return {
        text: IconTextSize,
        signature: IconWriting,
        date: IconCalendarEvent,
        image: IconPhoto,
        attachment: IconPaperclip,
        select: IconSelect,
        checkbox: IconCheckbox,
        radio: IconCircleDot
      }
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
    closeDropdown () {
      document.activeElement.blur()
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

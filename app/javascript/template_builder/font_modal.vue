<template>
  <div
    class="modal modal-open items-start !animate-none overflow-y-auto"
  >
    <div
      class="absolute top-0 bottom-0 right-0 left-0"
      @click.prevent="$emit('close')"
    />
    <div class="modal-box pt-4 pb-6 px-6 mt-20 max-h-none w-full max-w-xl">
      <div class="flex justify-between items-center border-b pb-2 mb-2 font-medium">
        <span class="modal-title">
          {{ t('font') }} - {{ field.name || buildDefaultName(field, template.fields) }}
        </span>
        <a
          href="#"
          class="text-xl modal-close-button"
          @click.prevent="$emit('close')"
        >&times;</a>
      </div>
      <div class="mt-4">
        <div>
          <div class="flex items-center space-x-1.5">
            <span>
              <div class="dropdown modal-field-font-dropdown">
                <label
                  tabindex="0"
                  class="base-input flex items-center justify-between"
                  style="height: 32px; padding-right: 0; width: 120px"
                  :class="fonts.find((f) => f.value === preferences.font)?.class"
                >
                  <span style="margin-top: 1px">
                    {{ preferences.font || 'Default' }}
                  </span>
                  <IconChevronDown
                    class="ml-2 mr-2 mt-0.5"
                    width="18"
                    height="18"
                  />
                </label>
                <div
                  tabindex="0"
                  class="dropdown-content p-0 mt-1 block z-10 menu shadow bg-white border border-base-300 rounded-md w-52"
                >
                  <div
                    v-for="(font, index) in fonts"
                    :key="index"
                    :value="font.value"
                    :class="{ 'bg-base-300': preferences.font == font.value, [font.class]: true }"
                    class="hover:bg-base-300 px-2 py-1.5 cursor-pointer"
                    @click="[font.value ? preferences.font = font.value : delete preferences.font, closeDropdown()]"
                  >
                    {{ font.label }}
                  </div>
                </div>
              </div>
            </span>
            <span class="relative">
              <select
                class="select input-bordered bg-white select-sm text-center pl-2"
                style="font-size: 16px; line-height: 12px; width: 86px; text-align-last: center;"
                @change="$event.target.value ? preferences.font_size = parseInt($event.target.value) : delete preferences.font_size"
              >
                <option
                  :selected="!preferences.font_size"
                  value=""
                >
                  Auto
                </option>
                <option
                  v-for="size in sizes"
                  :key="size"
                  :value="size"
                  :selected="size === preferences.font_size"
                >
                  {{ size }}
                </option>
              </select>
              <span
                class="border-l pl-1.5 absolute bg-white bottom-0 pointer-events-none text-sm h-5"
                style="right: 13px; top: 6px"
              >
                pt
              </span>
            </span>
            <span class="flex">
              <div
                class="join"
                style="height: 32px"
              >
                <button
                  v-for="(type, index) in types"
                  :key="index"
                  class="btn btn-sm join-item bg-white input-bordered hover:border-base-content/20 hover:bg-base-200/50 px-2"
                  :class="{ '!bg-base-300': preferences.font_type?.includes(type.value) }"
                  @click="setFontType(type.value)"
                >
                  <component :is="type.icon" />
                </button>
              </div>
            </span>
            <span class="flex">
              <div
                class="join"
                style="height: 32px"
              >
                <button
                  v-for="(align, index) in aligns"
                  :key="index"
                  class="btn btn-sm join-item bg-white input-bordered hover:border-base-content/20 hover:bg-base-200/50 px-2"
                  :class="{ '!bg-base-300': preferences.align === align.value }"
                  @click="align.value && preferences.align != align.value ? preferences.align = align.value : delete preferences.align"
                >
                  <component :is="align.icon" />
                </button>
              </div>
            </span>
            <span class="flex">
              <div class="dropdown modal-field-font-dropdown">
                <label
                  tabindex="0"
                  class="cursor-pointer flex bg-white border input-bordered rounded-md h-8 items-center justify-center px-1"
                  style="-webkit-appearance: none; -moz-appearance: none;"
                >
                  <component :is="valigns.find((v) => v.value === (preferences.valign || 'center'))?.icon" />
                </label>
                <div
                  tabindex="0"
                  class="dropdown-content p-0 mt-1 block z-10 menu shadow bg-white border border-base-300 rounded-md"
                >
                  <div
                    v-for="(valign, index) in valigns"
                    :key="index"
                    :value="valign.value"
                    :class="{ 'bg-base-300': preferences.valign == valign.value }"
                    class="hover:bg-base-300 px-2 py-1.5 cursor-pointer"
                    @click="[valign.value ? preferences.valign = valign.value : delete preferences.valign, closeDropdown()]"
                  >
                    <component :is="valign.icon" />
                  </div>
                </div>
              </div>
            </span>
            <span>
              <select
                class="input input-bordered bg-white input-sm text-lg rounded-md"
                style="-webkit-appearance: none; -moz-appearance: none; text-indent: 0px; text-overflow: ''; padding: 0px 6px; height: 32px"
                @change="$event.target.value ? preferences.color = $event.target.value : delete preferences.color"
              >
                <option
                  v-for="(color, index) in colors"
                  :key="index"
                  :value="color.value"
                  :selected="color.value == preferences.color"
                >
                  {{ color.label }}
                </option>
              </select>
            </span>
          </div>
        </div>
        <div class="mt-4">
          <div
            class="flex border border-base-content/20 rounded-xl bg-white px-4 h-16 modal-field-font-preview"
            :style="{
              color: preferences.color || 'black',
              fontSize: (preferences.font_size || 12) + 'pt',
            }"
            :class="textClasses"
          >
            <span
              contenteditable="true"
              class="outline-none whitespace-nowrap truncate"
            >
              {{ field.default_value || field.name || buildDefaultName(field, template.fields) }}
            </span>
          </div>
        </div>
        <div class="mt-4">
          <button
            class="base-button w-full modal-save-button"
            @click.prevent="saveAndClose"
          >
            {{ t('save') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { IconChevronDown, IconBold, IconItalic, IconAlignLeft, IconAlignRight, IconAlignCenter, IconAlignBoxCenterTop, IconAlignBoxCenterBottom, IconAlignBoxCenterMiddle } from '@tabler/icons-vue'

export default {
  name: 'FontModal',
  components: {
    IconChevronDown
  },
  inject: ['t', 'save', 'template'],
  props: {
    field: {
      type: Object,
      required: true
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    },
    buildDefaultName: {
      type: Function,
      required: true
    }
  },
  emits: ['close'],
  data () {
    return {
      preferences: {}
    }
  },
  computed: {
    fonts () {
      return [
        { value: null, label: 'Default' },
        { value: 'Times', label: 'Times', class: 'font-serif' },
        { value: 'Courier', label: 'Courier', class: 'font-mono' }
      ]
    },
    types () {
      return [
        { icon: IconBold, value: 'bold' },
        { icon: IconItalic, value: 'italic' }
      ]
    },
    aligns () {
      return [
        { icon: IconAlignLeft, value: 'left' },
        { icon: IconAlignCenter, value: 'center' },
        { icon: IconAlignRight, value: 'right' }
      ]
    },
    valigns () {
      return [
        { icon: IconAlignBoxCenterTop, value: 'top' },
        { icon: IconAlignBoxCenterMiddle, value: 'center' },
        { icon: IconAlignBoxCenterBottom, value: 'bottom' }
      ]
    },
    sizes () {
      return [...Array(23).keys()].map(i => i + 6)
    },
    colors () {
      return [
        { label: '⬛', value: 'black' },
        { label: '🟦', value: 'blue' },
        { label: '🟥', value: 'red' }
      ]
    },
    textClasses () {
      return {
        'font-mono': this.preferences.font === 'Courier',
        'font-serif': this.preferences.font === 'Times',
        'justify-center': this.preferences.align === 'center',
        'justify-start': this.preferences.align === 'left',
        'justify-end': this.preferences.align === 'right',
        'items-center': !this.preferences.valign || this.preferences.valign === 'center',
        'items-start': this.preferences.valign === 'top',
        'items-end': this.preferences.valign === 'bottom',
        'font-bold': ['bold_italic', 'bold'].includes(this.preferences.font_type),
        italic: ['bold_italic', 'italic'].includes(this.preferences.font_type)
      }
    },
    keys () {
      return ['font_type', 'font_size', 'color', 'align', 'valign', 'font']
    }
  },
  created () {
    this.preferences = this.keys.reduce((acc, key) => {
      acc[key] = this.field.preferences?.[key]

      return acc
    }, {})
  },
  methods: {
    closeDropdown () {
      this.$el.getRootNode().activeElement.blur()
    },
    setFontType (value) {
      if (value === 'bold') {
        if (this.preferences.font_type === 'bold') {
          delete this.preferences.font_type
        } else if (this.preferences.font_type === 'italic') {
          this.preferences.font_type = 'bold_italic'
        } else if (this.preferences.font_type === 'bold_italic') {
          this.preferences.font_type = 'italic'
        } else {
          this.preferences.font_type = value
        }
      }

      if (value === 'italic') {
        if (this.preferences.font_type === 'italic') {
          delete this.preferences.font_type
        } else if (this.preferences.font_type === 'bold') {
          this.preferences.font_type = 'bold_italic'
        } else if (this.preferences.font_type === 'bold_italic') {
          this.preferences.font_type = 'bold'
        } else {
          this.preferences.font_type = value
        }
      }
    },
    saveAndClose () {
      this.field.preferences ||= {}

      this.keys.forEach((key) => delete this.field.preferences[key])

      Object.assign(this.field.preferences, this.preferences)

      this.save()

      this.$emit('close')
    }
  }
}
</script>

<template>
  <label
    v-if="showFieldNames && (field.name || field.title)"
    :for="field.uuid"
    dir="auto"
    class="label text-2xl"
    :class="{ 'mb-2': !field.description }"
  ><MarkdownContent
     v-if="field.title"
     :string="field.title"
   />
    <template v-else>{{ field.name }}</template>
    <template v-if="!field.required">
      ({{ t('optional') }})
    </template>
  </label>
  <div
    v-else
    class="py-1"
  />
  <div
    v-if="field.description"
    dir="auto"
    class="mb-3 px-1"
  >
    <MarkdownContent :string="field.description" />
  </div>
  <AppearsOn :field="field" />
  <div class="items-center flex">
    <input
      v-if="!isTextArea"
      :id="field.uuid"
      v-model="text"
      :maxlength="cellsMaxLegth"
      dir="auto"
      class="base-input !text-2xl w-full"
      :class="{ '!pr-11 -mr-10': !field.validation?.pattern }"
      :required="field.required"
      :pattern="field.validation?.pattern"
      :placeholder="`${t('type_here_')}${field.required ? '' : ` (${t('optional')})`}`"
      type="text"
      :name="`values[${field.uuid}]`"
      @invalid="field.validation?.message ? $event.target.setCustomValidity(field.validation.message) : ''"
      @input="field.validation?.message ? $event.target.setCustomValidity('') : ''"
      @focus="$emit('focus')"
    >
    <textarea
      v-if="isTextArea"
      :id="field.uuid"
      ref="textarea"
      v-model="text"
      dir="auto"
      class="base-textarea !text-2xl w-full"
      :placeholder="`${t('type_here_')}${field.required ? '' : ` (${t('optional')})`}`"
      :required="field.required"
      :name="`values[${field.uuid}]`"
      @input="resizeTextarea"
      @focus="$emit('focus')"
    />
    <div
      v-if="!isTextArea && field.type !== 'cells' && !field.validation?.pattern"
      class="tooltip"
      :data-tip="t('toggle_multiline_text')"
    >
      <a
        href="#"
        class="btn btn-ghost btn-circle btn-sm"
        @click.prevent="toggleTextArea"
      >
        <IconAlignBoxLeftTop />
      </a>
    </div>
  </div>
</template>

<script>
import { IconAlignBoxLeftTop } from '@tabler/icons-vue'
import AppearsOn from './appears_on'
import MarkdownContent from './markdown_content'

export default {
  name: 'TextStep',
  components: {
    IconAlignBoxLeftTop,
    MarkdownContent,
    AppearsOn
  },
  inject: ['t'],
  props: {
    field: {
      type: Object,
      required: true
    },
    showFieldNames: {
      type: Boolean,
      required: false,
      default: true
    },
    modelValue: {
      type: String,
      required: false,
      default: ''
    }
  },
  emits: ['update:model-value', 'focus'],
  data () {
    return {
      isTextArea: false
    }
  },
  computed: {
    cellsMaxLegth () {
      if (this.field.type === 'cells') {
        const area = this.field.areas?.[0]

        if (area) {
          return parseInt(area.w / area.cell_w) + 1
        } else {
          return null
        }
      } else {
        return null
      }
    },
    text: {
      set (value) {
        this.$emit('update:model-value', value)
      },
      get () {
        return this.modelValue
      }
    }
  },
  mounted () {
    if (this.modelValue) {
      this.isTextArea = this.modelValue.toString().includes('\n')

      if (this.isTextArea) {
        this.$nextTick(() => {
          this.resizeTextarea()
        })
      }
    }
  },
  methods: {
    resizeTextarea () {
      const textarea = this.$refs.textarea

      textarea.style.height = 'auto'
      textarea.style.height = textarea.scrollHeight + 'px'
    },
    toggleTextArea () {
      this.isTextArea = true

      this.$nextTick(() => {
        this.$refs.textarea.focus()
        this.$refs.textarea.setSelectionRange(this.$refs.textarea.value.length, this.$refs.textarea.value.length)

        this.resizeTextarea()
      })
    }
  }
}
</script>

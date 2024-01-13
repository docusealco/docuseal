<template>
  <label
    v-if="field.name"
    :for="field.uuid"
    dir="auto"
    class="label text-2xl"
    :class="{ 'mb-2': !field.description }"
  ><template v-if="field.title"><span v-html="field.title" /></template>
    <template v-else>{{ field.name }}</template>
    <template v-if="!field.required">({{ t('optional') }})</template>
  </label>
  <div
    v-else
    class="py-1"
  />
  <div
    v-if="field.description"
    class="mb-3 px-1 text-lg"
    v-html="field.description"
  />
  <AppearsOn :field="field" />
  <div class="items-center flex">
    <input
      v-if="!isTextArea"
      :id="field.uuid"
      v-model="text"
      :maxlength="cellsMaxLegth"
      dir="auto"
      class="base-input !text-2xl w-full !pr-11 -mr-10"
      :required="field.required"
      :pattern="field.validation?.pattern"
      :oninvalid="field.validation?.message ? `this.setCustomValidity(${JSON.stringify(field.validation.message)})` : ''"
      :oninput="field.validation?.message ? `this.setCustomValidity('')` : ''"
      :placeholder="`${t('type_here_')}${field.required ? '' : ` (${t('optional')})`}`"
      type="text"
      :name="`values[${field.uuid}]`"
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
      v-if="!isTextArea && field.type !== 'cells'"
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

export default {
  name: 'TextStep',
  components: {
    IconAlignBoxLeftTop,
    AppearsOn
  },
  inject: ['t'],
  props: {
    field: {
      type: Object,
      required: true
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
    this.isTextArea = this.modelValue?.includes('\n')

    if (this.isTextArea) {
      this.$nextTick(() => {
        this.resizeTextarea()
      })
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

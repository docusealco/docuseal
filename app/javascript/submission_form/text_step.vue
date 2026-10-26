<template>
  <label
    v-if="showFieldNames && (field.name || field.title)"
    :for="field.uuid"
    dir="auto"
    class="label text-xl sm:text-2xl py-0 mb-2 sm:mb-3.5 field-name-label"
    :class="{ 'mb-2': !field.description }"
  >
    <MarkdownContent
      v-if="field.title"
      :string="field.title"
    />
    <template v-else>{{ field.name }}</template>
    <template v-if="!field.required">
      <span :class="{ 'hidden sm:inline': (field.title || field.name).length > 20 }">
        ({{ t('optional') }})
      </span>
    </template>
  </label>
  <div
    v-else
    class="py-1"
  />
  <div
    v-if="field.description"
    :id="field.uuid + '-desc'"
    dir="auto"
    class="mb-3 px-1 field-description-text"
  >
    <MarkdownContent :string="field.description" />
  </div>
  <AppearsOn :field="field" />
  <div class="items-center flex">
    <input
      v-if="!isTextArea"
      :id="field.uuid"
      ref="input"
      v-model="text"
      :maxlength="cellsMaxLegth"
      dir="auto"
      class="base-input !text-2xl w-full"
      :class="{ '!pr-11 -mr-10': !field.validation?.pattern }"
      :required="field.required"
      :pattern="field.validation?.pattern"
      :title="validationMessage"
      :aria-describedby="field.description ? field.uuid + '-desc' : undefined"
      :placeholder="`${t('type_here_')}${field.required ? '' : ` (${t('optional')})`}`"
      type="text"
      :name="`values[${field.uuid}]`"
      @input="validateValue($event.target)"
      @focus="$emit('focus')"
    >
    <textarea
      v-if="isTextArea"
      :id="field.uuid"
      ref="textarea"
      v-model="text"
      dir="auto"
      class="base-textarea !text-2xl w-full"
      :aria-describedby="field.description ? field.uuid + '-desc' : undefined"
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
      <button
        type="button"
        :aria-label="t('toggle_multiline_text')"
        class="btn btn-ghost btn-circle btn-sm toggle-multiline-text-button"
        @click="toggleTextArea"
      >
        <IconAlignBoxLeftTop aria-hidden="true" />
      </button>
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
          const num = area.w / area.cell_w

          return (num % 1) > 0.2 ? parseInt(num) + 1 : parseInt(num)
        } else {
          return null
        }
      } else {
        return null
      }
    },
    lengthValidation () {
      if (this.field.validation?.pattern) {
        return this.field.validation.pattern.match(/^\.{(?<min>\d+),(?<max>\d+)?}$/)?.groups
      } else {
        return null
      }
    },
    isIbanValidation () {
      return this.patternMessageKeys[this.field.validation?.pattern] === 'must_be_valid_iban'
    },
    patternMessageKeys () {
      return {
        '^[0-9]{3}-[0-9]{2}-[0-9]{4}$': 'must_be_valid_ssn',
        '^[0-9]{2}-[0-9]{7}$': 'must_be_valid_ein',
        '^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$': 'must_be_valid_email',
        '^https?://.*': 'must_be_valid_url',
        '^[0-9]{5}(?:-[0-9]{4})?$': 'must_be_valid_zip',
        '^[A-Z]{2}[0-9]{2}(?: ?[A-Z0-9]){11,30}$': 'must_be_valid_iban',
        '^[0-9]+$': 'must_contain_numbers_only',
        '^[a-zA-Z]+$': 'must_contain_letters_only'
      }
    },
    validationMessage () {
      if (this.field.validation?.message) {
        return this.field.validation.message
      } else if (this.lengthValidation) {
        const number =
          [this.lengthValidation.min, this.lengthValidation.max]
            .filter(Boolean)
            .filter((v, i, a) => a.indexOf(v) === i)
            .join('-')

        return this.t('must_be_characters_length').replace('{number}', number)
      } else if (this.field.validation?.pattern) {
        const key = this.patternMessageKeys[this.field.validation.pattern]

        return key ? this.t(key) : ''
      } else {
        return ''
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

    this.validateValue(this.$refs.input)
  },
  methods: {
    validateValue (input) {
      if (this.isIbanValidation) {
        input.setCustomValidity(this.isValidIban(input.value) ? '' : this.t('must_be_valid_iban'))
      }
    },
    isValidIban (value) {
      const iban = value.replace(/\s/g, '')
      const digits = (iban.slice(4) + iban.slice(0, 4)).replace(/[A-Z]/g, (char) => char.charCodeAt(0) - 55)

      return !iban || digits.split('').reduce((remainder, digit) => (remainder * 10 + parseInt(digit)) % 97, 0) === 1
    },
    resizeTextarea () {
      const textarea = this.$refs.textarea

      if (textarea) {
        textarea.style.height = 'auto'
        textarea.style.height = Math.min(250, textarea.scrollHeight) + 'px'
      }
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

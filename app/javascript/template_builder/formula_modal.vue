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
          {{ t('formula') }} - {{ (defaultField ? (defaultField.title || field.title || field.name) : field.name) || buildDefaultName(field) }}
        </span>
        <a
          href="#"
          class="text-xl modal-close-button"
          @click.prevent="$emit('close')"
        >&times;</a>
      </div>
      <div>
        <div
          v-if="!withFormula"
          class="bg-base-300 rounded-xl py-2 px-3 text-center"
        >
          <a
            href="https://www.docuseal.com/pricing"
            target="_blank"
            class="link"
          >{{ t('available_in_pro') }}</a>
        </div>
        <div class="flex flex-wrap mb-2 gap-y-1 pt-1">
          <button
            v-for="f in fields"
            :key="f.uuid"
            class="mr-1 flex btn btn-neutral btn-outline border-base-content/20 btn-sm normal-case font-normal bg-white !rounded-xl"
            @click.prevent="insertTextUnderCursor(`{{${f.name || buildDefaultName(f)}}}`)"
          >
            <IconMathFunction
              v-if="f.preferences?.formula"
              width="17"
              height="17"
              stroke-width="1.5"
            />
            <IconCodePlus
              v-else
              width="20"
              height="20"
              stroke-width="1.5"
            />
            {{ f.name || buildDefaultName(f) }}
          </button>
        </div>
        <div>
          <div class="flex">
            <textarea
              ref="textarea"
              v-model="formula"
              class="base-textarea !rounded-xl !text-base font-mono w-full !outline-0 !ring-0 !px-3"
              :readonly="!editable"
              required="true"
              @input="resizeTextarea"
            />
          </div>
          <div class="mb-3 mt-1">
            <div
              target="blank"
              class="text-sm mb-2 inline space-x-2 font-mono"
            >
              <button
                class="bg-base-200 px-2 rounded-xl"
                @click="insertTextUnderCursor(' + ')"
              >
                +
              </button>
              <button
                class="bg-base-200 px-2 rounded-xl"
                @click="insertTextUnderCursor(' - ')"
              >
                -
              </button>
              <button
                class="bg-base-200 px-2 rounded-xl"
                @click="insertTextUnderCursor(' * ')"
              >
                *
              </button>
              <button
                class="bg-base-200 px-2 rounded-xl"
                @click="insertTextUnderCursor(' / ')"
              >
                /
              </button>
              <button
                class="bg-base-200 px-2 rounded-xl"
                @click="insertTextUnderCursor('^')"
              >
                ^
              </button>
              <button
                class="bg-base-200 px-2 rounded-xl"
                @click="insertTextUnderCursor('round()')"
              >
                round(n, d)
              </button>
              <button
                class="bg-base-200 px-2 rounded-xl"
                @click="insertTextUnderCursor('abs()')"
              >
                abs(n)
              </button>
            </div>
          </div>
        </div>
        <button
          class="base-button w-full modal-save-button"
          @click.prevent="validateSaveAndClose"
        >
          {{ t('save') }}
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { IconCodePlus, IconMathFunction } from '@tabler/icons-vue'

export default {
  name: 'FormulaModal',
  components: {
    IconCodePlus,
    IconMathFunction
  },
  inject: ['t', 'template', 'withFormula'],
  props: {
    field: {
      type: Object,
      required: true
    },
    defaultField: {
      type: Object,
      required: false,
      default: null
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
  emits: ['close', 'save'],
  data () {
    return {
      formula: ''
    }
  },
  computed: {
    fields () {
      return this.template.fields.reduce((acc, f) => {
        if (f !== this.field && this.isNumberField(f) && (!f.preferences?.formula || !f.preferences.formula.includes(this.field.uuid))) {
          acc.push(f)
        }

        return acc
      }, [])
    }
  },
  created () {
    this.field.preferences ||= {}
  },
  mounted () {
    this.formula = this.humanizeFormula(this.field.preferences.formula || '')
  },
  methods: {
    isNumberField (field) {
      return field.type === 'number' || (['radio', 'select'].includes(field.type) && field.options?.every((o) => String(o.value).match(/^[\d.-]+$/)))
    },
    humanizeFormula (text) {
      return text.replace(/{{(.*?)}}/g, (match, uuid) => {
        const foundField = this.template.fields.find((f) => f.uuid === uuid)

        if (foundField) {
          return `{{${foundField.name || this.buildDefaultName(foundField)}}}`
        } else {
          return '{{FIELD NOT FOUND}}'
        }
      })
    },
    normalizeFormula (text) {
      return text.replace(/{{(.*?)}}/g, (match, name) => {
        const foundField = this.template.fields.find((f) => {
          return (f.name || this.buildDefaultName(f)).trim() === name.trim()
        })

        if (foundField) {
          return `{{${foundField.uuid}}}`
        } else {
          return '{{FIELD NOT FOUND}}'
        }
      })
    },
    validateSaveAndClose () {
      if (!this.withFormula) {
        return alert(this.t('available_only_in_pro'))
      }

      const normalizedFormula = this.normalizeFormula(this.formula)

      if (normalizedFormula.includes('FIELD NOT FOUND')) {
        alert(this.t('some_fields_are_missing_in_the_formula'))
      } else {
        this.field.preferences.formula = normalizedFormula

        if (this.field.type === 'payment') {
          delete this.field.preferences.price
          delete this.field.preferences.payment_link_id
        } else {
          this.field.readonly = !!normalizedFormula
        }

        this.$emit('save')

        this.$emit('close')
      }
    },
    insertTextUnderCursor (textToInsert) {
      const textarea = this.$refs.textarea

      const selectionEnd = textarea.selectionEnd
      const cursorPos = selectionEnd

      const newText = textarea.value.substring(0, cursorPos) + textToInsert + textarea.value.substring(cursorPos)

      this.formula = newText

      this.$nextTick(() => {
        textarea.setSelectionRange(cursorPos + textToInsert.length, cursorPos + textToInsert.length)

        textarea.focus()
      })
    },
    resizeTextarea () {
      const textarea = this.$refs.textarea

      textarea.style.height = 'auto'
      textarea.style.height = textarea.scrollHeight + 'px'
    }
  }
}
</script>

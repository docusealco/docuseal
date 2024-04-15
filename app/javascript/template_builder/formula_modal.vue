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
        <span>
          {{ t('formula') }} - {{ field.name || buildDefaultName(field, template.fields) }}
        </span>
        <a
          href="#"
          class="text-xl"
          @click.prevent="$emit('close')"
        >&times;</a>
      </div>
      <div>
        <div
          v-if="!withFormula"
          class="bg-base-300 rounded-xl py-2 px-3 text-center"
        >
          <a
            href="https://www.docuseal.co/pricing"
            target="_blank"
            class="link"
          >Available in Pro</a>
        </div>
        <div class="flex-inline mb-2 gap-2 space-y-1">
          <button
            v-for="f in fields"
            :key="f.uuid"
            class="mr-1 btn btn-neutral btn-outline border-base-content/20 btn-sm normal-case font-normal bg-white !rounded-xl"
            @click.prevent="insertTextUnderCursor(`{{${f.name || buildDefaultName(f, template.fields)}}}`)"
          >
            <IconCodePlus
              width="20"
              height="20"
              stroke-width="1.5"
            />
            {{ f.name || buildDefaultName(f, template.fields) }}
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
              class="text-sm mb-2 inline space-x-2"
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
                @click="insertTextUnderCursor(' % ')"
              >
                %
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
          class="base-button w-full"
          @click.prevent="validateSaveAndClose"
        >
          {{ t('save') }}
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { IconCodePlus } from '@tabler/icons-vue'

export default {
  name: 'FormulaModal',
  components: {
    IconCodePlus
  },
  inject: ['t', 'save', 'template', 'withFormula'],
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
      formula: ''
    }
  },
  computed: {
    fields () {
      return this.template.fields.reduce((acc, f) => {
        if (f !== this.field && f.submitter_uuid === this.field.submitter_uuid && ['number'].includes(f.type) && !f.preferences?.formula) {
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
    humanizeFormula (text) {
      return text.replace(/{{(.*?)}}/g, (match, uuid) => {
        const foundField = this.fields.find((f) => f.uuid === uuid)

        if (foundField) {
          return `{{${foundField.name || this.buildDefaultName(foundField, this.template.fields)}}}`
        } else {
          return '{{FIELD NOT FOUND}}'
        }
      })
    },
    normalizeFormula (text) {
      return text.replace(/{{(.*?)}}/g, (match, name) => {
        const foundField = this.fields.find((f) => {
          return (f.name || this.buildDefaultName(f, this.template.fields)).trim() === name.trim()
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
        return alert('Available only in Pro')
      }

      const normalizedFormula = this.normalizeFormula(this.formula)

      if (normalizedFormula.includes('FIELD NOT FOUND')) {
        alert('Some fields are missing in the formula.')
      } else {
        this.field.preferences.formula = normalizedFormula
        this.field.readonly = !!normalizedFormula

        this.save()

        this.$emit('close')
      }
    },
    insertTextUnderCursor (textToInsert) {
      const textarea = this.$refs.textarea

      const selectionEnd = textarea.selectionEnd
      const cursorPos = selectionEnd

      const newText = textarea.value.substring(0, cursorPos) + textToInsert + textarea.value.substring(cursorPos)

      this.formula = newText

      textarea.setSelectionRange(cursorPos + textToInsert.length, cursorPos + textToInsert.length)

      textarea.focus()
    },
    resizeTextarea () {
      const textarea = this.$refs.textarea

      textarea.style.height = 'auto'
      textarea.style.height = textarea.scrollHeight + 'px'
    }
  }
}
</script>

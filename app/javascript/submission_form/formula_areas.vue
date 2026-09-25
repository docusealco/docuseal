<template>
  <template
    v-for="(field, fieldIndex) in fields"
    :key="field.uuid"
  >
    <template
      v-for="(area, areaIndex) in field.areas"
      :key="areaIndex"
    >
      <Teleport
        v-if="findPageElementForArea(area)"
        :to="findPageElementForArea(area)"
      >
        <FieldArea
          v-if="isMathLoaded || field.type === 'text'"
          :model-value="field.type === 'text' ? evalTextFormula(field) : calculateFormula(field)"
          :is-inline-size="isInlineSize"
          :field="field"
          :area="area"
          :submittable="false"
          :field-index="fieldIndex"
        />
      </Teleport>
    </template>
  </template>
</template>

<script>
import FieldArea from './area'

export default {
  name: 'FormulaFieldAreas',
  components: {
    FieldArea
  },
  props: {
    fields: {
      type: Array,
      required: false,
      default: () => []
    },
    readonlyValues: {
      type: Object,
      required: false,
      default: () => ({})
    },
    values: {
      type: Object,
      required: false,
      default: () => ({})
    },
    fieldsUuidIndex: {
      type: Object,
      required: false,
      default: () => ({})
    }
  },
  data () {
    return {
      isMathLoaded: false
    }
  },
  computed: {
    isInlineSize () {
      return CSS.supports('container-type: size')
    },
    formulaFieldsUuidIndex () {
      return this.fields.reduce((acc, field) => {
        acc[field.uuid] = field

        return acc
      }, {})
    }
  },
  async mounted () {
    const { Calculator } = await import('./calculator')

    this.math = new Calculator()

    this.isMathLoaded = true
  },
  methods: {
    findPageElementForArea (area) {
      return (this.$root.$el?.parentNode?.getRootNode() || document).getElementById(`page-${area.attachment_uuid}-${area.page}`)
    },
    normalizeFormula (formula, depth = 0) {
      if (depth > 10) return formula

      return formula.replace(/{{(.*?)}}/g, (match, uuid) => {
        if (this.formulaFieldsUuidIndex[uuid]) {
          return `(${this.normalizeFormula(this.formulaFieldsUuidIndex[uuid].preferences.formula, depth + 1)})`
        } else {
          return match
        }
      })
    },
    calculateFormula (field) {
      const transformedFormula = this.normalizeFormula(field.preferences.formula).replace(/{{(.*?)}}/g, (match, uuid) => {
        const value = this.readonlyValues[uuid] || this.values[uuid]

        if (this.fieldsUuidIndex[uuid]?.type === 'date') {
          return this.dateFormulaValue(value)
        }

        return value || 0.0
      })

      const value = this.math.evaluate(transformedFormula.toLowerCase())

      if (field.type === 'date') {
        return Number.isFinite(value) ? new Date(Math.floor(value) * 86400000).toISOString().slice(0, 10) : ''
      }

      return value
    },
    dateFormulaValue (value) {
      if (!value) return 'null'
      if (value === '{{date}}') return 'today()'

      const [year, month, day = 1] = value.slice(0, 10).split('-').map(Number)

      return Date.UTC(year, month - 1, day) / 86400000
    },
    evalTextFormula (field, depth = 0) {
      if (depth > 10) return ''

      return field.preferences.formula.replace(/{{(.*?)}}/g, (match, uuid) => {
        const formulaField = this.formulaFieldsUuidIndex[uuid]

        if (formulaField?.preferences?.formula) {
          if (formulaField.type === 'text') {
            return this.evalTextFormula(formulaField, depth + 1)
          } else if (this.isMathLoaded) {
            return this.calculateFormula(formulaField)
          }
        }

        const value = this.readonlyValues[uuid] ?? this.values[uuid]

        return Array.isArray(value) ? value.join(', ') : (value ?? '')
      })
    }
  }
}
</script>

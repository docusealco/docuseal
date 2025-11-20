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
          v-if="isMathLoaded"
          :model-value="calculateFormula(field)"
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
    fieldsUuidIndex () {
      return this.fields.reduce((acc, field) => {
        acc[field.uuid] = field

        return acc
      }, {})
    }
  },
  async mounted () {
    const {
      create,
      evaluateDependencies,
      addDependencies,
      subtractDependencies,
      divideDependencies,
      multiplyDependencies,
      powDependencies,
      roundDependencies,
      absDependencies,
      sinDependencies,
      tanDependencies,
      cosDependencies
    } = await import('mathjs')

    this.math = create({
      evaluateDependencies,
      addDependencies,
      subtractDependencies,
      divideDependencies,
      multiplyDependencies,
      powDependencies,
      roundDependencies,
      absDependencies,
      sinDependencies,
      tanDependencies,
      cosDependencies
    })

    this.isMathLoaded = true
  },
  methods: {
    findPageElementForArea (area) {
      return (this.$root.$el?.parentNode?.getRootNode() || document).getElementById(`page-${area.attachment_uuid}-${area.page}`)
    },
    normalizeFormula (formula, depth = 0) {
      if (depth > 10) return formula

      return formula.replace(/{{(.*?)}}/g, (match, uuid) => {
        if (this.fieldsUuidIndex[uuid]) {
          return `(${this.normalizeFormula(this.fieldsUuidIndex[uuid].preferences.formula, depth + 1)})`
        } else {
          return match
        }
      })
    },
    calculateFormula (field) {
      const transformedFormula = this.normalizeFormula(field.preferences.formula).replace(/{{(.*?)}}/g, (match, uuid) => {
        return this.readonlyValues[uuid] || this.values[uuid] || 0.0
      })

      return this.math.evaluate(transformedFormula.toLowerCase())
    }
  }
}
</script>

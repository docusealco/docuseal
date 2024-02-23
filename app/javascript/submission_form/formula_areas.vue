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
    calculateFormula (field) {
      const transformedFormula = field.preferences.formula.replace(/{{(.*?)}}/g, (match, uuid) => {
        return this.values[uuid] || 0.0
      })

      return this.math.evaluate(transformedFormula.toLowerCase())
    }
  }
}
</script>

<template>
  <template
    v-for="step in steps"
    :key="step[0].uuid"
  >
    <template
      v-for="(field, fieldIndex) in step"
      :key="field.uuid"
    >
      <template
        v-for="(area, areaIndex) in field.areas"
        :key="areaIndex"
      >
        <Teleport :to="`#page-${area.attachment_uuid}-${area.page}`">
          <FieldArea
            :ref="setAreaRef"
            v-model="values[field.uuid]"
            :field="field"
            :values="values"
            :area="area"
            :field-index="fieldIndex"
            :step="step"
            :is-active="currentStep === step"
            :attachments-index="attachmentsIndex"
            @click="$emit('focus-step', step)"
          />
        </Teleport>
      </template>
    </template>
  </template>
</template>

<script>
import FieldArea from './area'

export default {
  name: 'FieldAreas',
  components: {
    FieldArea
  },
  props: {
    steps: {
      type: Array,
      required: false,
      default: () => []
    },
    values: {
      type: Object,
      required: false,
      default: () => ({})
    },
    attachmentsIndex: {
      type: Object,
      required: false,
      default: () => ({})
    },
    currentStep: {
      type: Array,
      required: false,
      default: () => []
    }
  },
  emits: ['focus-step'],
  data () {
    return {
      areaRefs: []
    }
  },
  beforeUpdate () {
    this.areaRefs = []
  },
  methods: {
    scrollIntoField (field) {
      this.areaRefs.find((area) => {
        if (area.field === field) {
          area.$refs.scrollToElem.scrollIntoView({ behavior: 'smooth', block: 'start' })

          return true
        } else {
          return null
        }
      })
    },
    setAreaRef (el) {
      if (el) {
        this.areaRefs.push(el)
      }
    }
  }
}
</script>

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
        <Teleport
          :to="`#page-${area.attachment_uuid}-${area.page}`"
        >
          <FieldArea
            :ref="setAreaRef"
            v-model="values[field.uuid]"
            :field="field"
            :area="area"
            :submittable="true"
            :field-index="fieldIndex"
            :is-active="currentStep === step"
            :with-label="withLabel"
            :is-value-set="step.some((f) => f.uuid in values)"
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
    withLabel: {
      type: Boolean,
      required: false,
      default: true
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
          if (document.body.style.overflow === 'hidden') {
            this.scrollInContainer(area.$el)
          } else {
            area.$refs.scrollToElem.scrollIntoView({ behavior: 'smooth', block: 'start' })
          }

          return true
        } else {
          return null
        }
      })
    },
    scrollInContainer (target) {
      const padding = 64
      const boxRect = window.scrollbox.children[0].getBoundingClientRect()
      const targetRect = target.getBoundingClientRect()

      const targetTopRelativeToBox = targetRect.top - boxRect.top

      window.scrollbox.scrollTop = targetTopRelativeToBox - document.body.offsetHeight + window.form_container.offsetHeight + target.offsetHeight + padding
    },
    setAreaRef (el) {
      if (el) {
        this.areaRefs.push(el)
      }
    }
  }
}
</script>

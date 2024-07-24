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
          v-if="findPageElementForArea(area)"
          :to="findPageElementForArea(area)"
        >
          <FieldArea
            :ref="setAreaRef"
            v-model="values[field.uuid]"
            :field="field"
            :area="area"
            :submittable="true"
            :field-index="fieldIndex"
            :scroll-padding="scrollPadding"
            :submitter="submitter"
            :with-field-placeholder="withFieldPlaceholder"
            :with-signature-id="withSignatureId"
            :is-active="currentStep === step"
            :with-label="withLabel && !withFieldPlaceholder"
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
    withSignatureId: {
      type: Boolean,
      required: false,
      default: false
    },
    submitter: {
      type: Object,
      required: true
    },
    values: {
      type: Object,
      required: false,
      default: () => ({})
    },
    withFieldPlaceholder: {
      type: Boolean,
      required: false,
      default: false
    },
    scrollPadding: {
      type: String,
      required: false,
      default: '-80px'
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
    scrollEl: {
      type: Object,
      required: false,
      default: null
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
    findPageElementForArea (area) {
      return (this.$root.$el?.parentNode?.getRootNode() || document).getElementById(`page-${area.attachment_uuid}-${area.page}`)
    },
    scrollIntoField (field) {
      if (field?.areas) {
        this.scrollIntoArea(field.areas[0])
      }
    },
    scrollIntoArea (area) {
      const areaRef = this.areaRefs.find((a) => a.area === area)

      if (areaRef) {
        const root = this.$root.$el.parentNode.getRootNode()
        const container = root.body || root.querySelector('div')

        if (container.style.overflow === 'hidden') {
          this.scrollInContainer(areaRef.$el)
        } else {
          const targetRect = areaRef.$refs.scrollToElem.getBoundingClientRect()
          const root = this.$root.$el?.parentNode?.classList?.contains('ds') ? this.$root.$el : document.body
          const rootRect = root.getBoundingClientRect()
          const scrollEl = this.scrollEl || window

          scrollEl.scrollTo({ top: targetRect.top - rootRect.top, behavior: 'smooth' })
        }

        return true
      }
    },
    scrollInContainer (target) {
      const root = this.$root.$el.parentNode.getRootNode()

      const scrollbox = root.getElementById('scrollbox')
      const formContainer = root.getElementById('form_container')
      const container = root.body || root.querySelector('div')

      const padding = 64
      const boxRect = scrollbox.children[0].getBoundingClientRect()
      const targetRect = target.getBoundingClientRect()

      const targetTopRelativeToBox = targetRect.top - boxRect.top

      scrollbox.scrollTo({ top: targetTopRelativeToBox - container.offsetHeight + formContainer.offsetHeight + target.offsetHeight + padding, behavior: 'smooth' })
    },
    setAreaRef (el) {
      if (el) {
        this.areaRefs.push(el)
      }
    }
  }
}
</script>

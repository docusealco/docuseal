<template>
  <template
    v-for="(step, stepIndex) in steps"
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
            :values="values"
            :field="field"
            :area="area"
            :submittable="submittable"
            :field-index="fieldIndex"
            :scroll-padding="scrollPadding"
            :submitter="submitter"
            :with-field-placeholder="withFieldPlaceholder"
            :with-signature-id="withSignatureId"
            :is-active="currentStep === step"
            :with-label="withLabel && !withFieldPlaceholder && step.length < 2"
            :is-value-set="step.some((f) => f.uuid in values)"
            :attachments-index="attachmentsIndex"
            @click="[$emit('focus-step', stepIndex), maybeScrollOnClick(field, area)]"
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
    submittable: {
      type: Boolean,
      required: false,
      default: true
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
  computed: {
    isMobileContainer () {
      const root = this.$root.$el.parentNode.getRootNode()
      const container = root.body || root.querySelector('div')

      return container.style.overflow === 'hidden'
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
    maybeScrollOnClick (field, area) {
      if (['text', 'number', 'cells'].includes(field.type) && this.isMobileContainer) {
        this.scrollIntoArea(area)
      }
    },
    scrollIntoArea (area) {
      const areaRef = this.areaRefs.find((a) => a.area === area)

      if (areaRef) {
        if (this.isMobileContainer) {
          this.scrollInContainer(areaRef.$el)
        } else {
          const targetRect = areaRef.$refs.scrollToElem.getBoundingClientRect()
          const scrollEl = this.scrollEl || window

          let rootRect = {}

          if (this.scrollEl === document.documentElement) {
            rootRect = this.scrollEl.getBoundingClientRect()
          } else {
            const root = this.$root.$el?.parentNode?.classList?.contains('ds') ? this.$root.$el : document.body

            rootRect = root.getBoundingClientRect()
          }

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

      const isAndroid = /android/i.test(navigator.userAgent)
      const padding = isAndroid ? 128 : 64
      const scrollboxTop = isAndroid ? scrollbox.getBoundingClientRect().top : 0
      const boxRect = scrollbox.children[0].getBoundingClientRect()
      const targetRect = target.getBoundingClientRect()

      const targetTopRelativeToBox = targetRect.top - boxRect.top

      scrollbox.scrollTo({ top: targetTopRelativeToBox + scrollboxTop - container.offsetHeight + formContainer.offsetHeight + target.offsetHeight + padding, behavior: 'smooth' })
    },
    setAreaRef (el) {
      if (el) {
        this.areaRefs.push(el)
      }
    }
  }
}
</script>

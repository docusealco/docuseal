<template>
  <template
    v-for="(pages, docUuid) in textRuns"
    :key="docUuid"
  >
    <template
      v-for="(_, pageIndex) in pages"
      :key="pageIndex"
    >
      <template
        v-for="(pageElem, i) in [findPageElement(docUuid, pageIndex)]"
        :key="i"
      >
        <Teleport
          v-if="pageElem"
          :to="pageElem"
        >
          <template
            v-for="(item, index) in sortedItemsForPage(docUuid, pageIndex)"
            :key="index"
          >
            <template v-if="item.type === 'text_group'">
              <span
                class="absolute overflow-hidden text-transparent select-none pointer-events-none"
                :style="{ left: item.x * 100 + '%', top: item.y * 100 + '%', width: item.w * 100 + '%', height: item.h * 100 + '%' }"
              >{{ item.text }}</span>
              <span
                v-for="(run, runIndex) in item.items"
                :key="runIndex"
                aria-hidden="true"
                class="absolute overflow-hidden text-transparent"
                :style="{ left: run.x * 100 + '%', top: run.y * 100 + '%', width: run.w * 100 + '%', height: run.h * 100 + '%', fontSize: run.font_size ? (run.font_size / 10) + 'cqmin' : undefined, textAlign: 'justify', textAlignLast: 'justify', textJustify: 'inter-character' }"
              >{{ run.text }}</span>
            </template>
            <FieldArea
              v-else-if="item.type === 'field_area'"
              :ref="setAreaRef"
              v-model="values[item.field.uuid]"
              :values="values"
              :field="item.field"
              :area="item.area"
              :submittable="true"
              :page-width="1400"
              :page-height="(1400.0 / pageElem.offsetWidth) * pageElem.offsetHeight"
              :field-index="item.fieldIndex"
              :is-inline-size="isInlineSize"
              :scroll-padding="scrollPadding"
              :submitter="submitter"
              :with-field-placeholder="withFieldPlaceholder"
              :with-signature-id="withSignatureId"
              :is-active="currentStep === item.step"
              :with-label="withLabel && !withFieldPlaceholder && item.step.length < 2"
              :is-value-set="item.step.some((f) => f.uuid in values)"
              :attachments-index="attachmentsIndex"
              @click="[$emit('focus-step', item.stepIndex), maybeScrollOnClick(item.field, item.area)]"
            />
            <FieldArea
              v-else-if="item.type === 'readonly_field_area'"
              :model-value="readonlyConditionalFieldValues[item.field.uuid]"
              :values="readonlyConditionalFieldValues"
              :field="item.field"
              :area="item.area"
              :submittable="false"
              :page-width="1400"
              :page-height="(1400.0 / pageElem.offsetWidth) * pageElem.offsetHeight"
              :field-index="item.fieldIndex"
              :is-inline-size="isInlineSize"
              :submitter="submitter"
              :attachments-index="attachmentsIndex"
            />
            <FieldArea
              v-else-if="item.type === 'formula_area' && isMathLoaded"
              :model-value="calculateFormula(item.field)"
              :is-inline-size="isInlineSize"
              :field="item.field"
              :area="item.area"
              :submittable="false"
              :field-index="item.fieldIndex"
            />
          </template>
        </Teleport>
      </template>
    </template>
  </template>
</template>

<script>
import FieldArea from './area'
import FormulaAreas from './formula_areas'
import FieldAreas from './areas'

export default {
  name: 'AccessibilityAreas',
  components: {
    FieldArea
  },
  inject: ['baseUrl', 't'],
  props: {
    submitterSlug: {
      type: String,
      required: true
    },
    filledFieldsIndex: {
      type: Object,
      required: false,
      default: null
    },
    steps: {
      type: Array,
      required: false,
      default: () => []
    },
    readonlyConditionalFields: {
      type: Array,
      required: false,
      default: () => []
    },
    readonlyConditionalFieldValues: {
      type: Object,
      required: false,
      default: () => ({})
    },
    formulaFields: {
      type: Array,
      required: false,
      default: () => []
    },
    values: {
      type: Object,
      required: false,
      default: () => ({})
    },
    readonlyValues: {
      type: Object,
      required: false,
      default: () => ({})
    },
    submitter: {
      type: Object,
      required: true
    },
    currentStep: {
      type: Array,
      required: false,
      default: () => []
    },
    withFieldPlaceholder: {
      type: Boolean,
      required: false,
      default: false
    },
    withSignatureId: {
      type: Boolean,
      required: false,
      default: false
    },
    withLabel: {
      type: Boolean,
      required: false,
      default: true
    },
    scrollPadding: {
      type: String,
      required: false,
      default: '-80px'
    },
    scrollEl: {
      type: Object,
      required: false,
      default: null
    },
    attachmentsIndex: {
      type: Object,
      required: false,
      default: () => ({})
    },
    fetchOptions: {
      type: Object,
      required: false,
      default: () => ({})
    }
  },
  emits: ['focus-step'],
  data () {
    return {
      isMathLoaded: false,
      math: null,
      textRuns: {},
      areaRefs: []
    }
  },
  computed: {
    fieldValuesIndex () {
      return this.filledFieldsIndex || this.extractStaticValues()
    },
    isMobileContainer: FieldAreas.computed.isMobileContainer,
    isInlineSize: FieldAreas.computed.isInlineSize,
    fieldsUuidIndex () {
      return this.formulaFields.reduce((acc, field) => {
        acc[field.uuid] = field

        return acc
      }, {})
    },
    fieldAreasIndex () {
      const index = Object.create(null)

      this.steps.forEach((step, stepIndex) => {
        step.forEach((field, fieldIndex) => {
          (field.areas || []).forEach((area) => {
            index[area.attachment_uuid] ||= Object.create(null)
            index[area.attachment_uuid][area.page] ||= []
            index[area.attachment_uuid][area.page].push({
              type: 'field_area',
              field,
              area,
              step,
              stepIndex,
              fieldIndex,
              x: area.x,
              y: area.y,
              w: area.w,
              h: area.h
            })
          })
        })
      })

      return index
    },
    formulaAreasIndex () {
      const index = Object.create(null)

      this.formulaFields.forEach((field, fieldIndex) => {
        (field.areas || []).forEach((area) => {
          index[area.attachment_uuid] ||= Object.create(null)
          index[area.attachment_uuid][area.page] ||= []
          index[area.attachment_uuid][area.page].push({
            type: 'formula_area',
            field,
            area,
            fieldIndex,
            x: area.x,
            y: area.y,
            w: area.w,
            h: area.h
          })
        })
      })

      return index
    },
    readonlyFieldAreasIndex () {
      const index = Object.create(null)

      this.readonlyConditionalFields.forEach((field, fieldIndex) => {
        (field.areas || []).forEach((area) => {
          index[area.attachment_uuid] ||= Object.create(null)
          index[area.attachment_uuid][area.page] ||= []
          index[area.attachment_uuid][area.page].push({
            type: 'readonly_field_area',
            field,
            area,
            fieldIndex,
            x: area.x,
            y: area.y,
            w: area.w,
            h: area.h
          })
        })
      })

      return index
    }
  },
  beforeUpdate () {
    this.areaRefs = []
  },
  async mounted () {
    const [metadataResult] = await Promise.all([
      fetch(this.baseUrl + `/s/${this.submitterSlug}/metadata`, {
        ...this.fetchOptions
      }).then((r) => r.json()).catch(() => ({})),
      this.loadMath()
    ])

    this.textRuns = metadataResult.text_runs || {}
  },
  methods: {
    normalizeFormula: FormulaAreas.methods.normalizeFormula,
    calculateFormula: FormulaAreas.methods.calculateFormula,
    scrollInContainer: FieldAreas.methods.scrollInContainer,
    scrollIntoArea: FieldAreas.methods.scrollIntoArea,
    scrollIntoField: FieldAreas.methods.scrollIntoField,
    maybeScrollOnClick: FieldAreas.methods.maybeScrollOnClick,
    setAreaRef (el) {
      if (el) {
        this.areaRefs.push(el)
      }
    },
    async loadMath () {
      if (this.formulaFields.length && !this.isMathLoaded) {
        const { Calculator } = await import('./calculator')

        this.math = new Calculator()
        this.isMathLoaded = true
      }
    },
    extractStaticValues () {
      const result = Object.create(null)
      const root = this.$root.$el?.parentNode?.getRootNode() || document
      const pageContainers = root.querySelectorAll('page-container')

      pageContainers.forEach((container) => {
        const overlay = container.querySelector('[id^="page-"]')

        if (!overlay) return

        const parts = overlay.id.split('-')
        const pageIndex = parseInt(parts[parts.length - 1])
        const docUuid = parts.slice(1, -1).join('-')

        const fieldValues = overlay.querySelectorAll('field-value')

        if (!fieldValues.length) return

        result[docUuid] ||= Object.create(null)
        result[docUuid][pageIndex] = []

        fieldValues.forEach((el) => {
          const style = el.style
          const x = parseFloat(style.left) / 100
          const y = parseFloat(style.top) / 100
          const w = parseFloat(style.width) / 100
          const h = parseFloat(style.height) / 100
          const text = el.textContent.trim()

          if (text) {
            result[docUuid][pageIndex].push({ type: 'static_value', text, x, y, w, h })
          }
        })
      })

      return result
    },
    findPageElement (docUuid, pageIndex) {
      return (this.$root.$el?.parentNode?.getRootNode() || document).getElementById(`page-${docUuid}-${pageIndex}`)
    },
    sortedItemsForPage (docUuid, pageIndex) {
      const items = []

      const pageTextRuns = this.textRuns[docUuid]?.[pageIndex] || []

      pageTextRuns.forEach((run) => {
        items.push({
          type: 'text_run',
          text: run.text,
          x: run.x,
          y: run.y,
          w: run.w,
          h: run.h,
          font_size: run.font_size
        })
      })

      const fieldAreas = this.fieldAreasIndex[docUuid]?.[pageIndex] || []
      items.push(...fieldAreas)

      const readonlyFieldAreas = this.readonlyFieldAreasIndex[docUuid]?.[pageIndex] || []
      items.push(...readonlyFieldAreas)

      const formulaAreas = this.formulaAreasIndex[docUuid]?.[pageIndex] || []
      items.push(...formulaAreas)

      const pageFieldValues = this.fieldValuesIndex[docUuid]?.[pageIndex] || []
      items.push(...pageFieldValues)

      items.sort((a, b) => {
        const aCenterY = a.y + a.h / 2
        const bCenterY = b.y + b.h / 2
        const lineThreshold = Math.min(a.h, b.h) / 2

        if (Math.abs(aCenterY - bCenterY) < lineThreshold) {
          return a.x - b.x
        }

        return aCenterY - bCenterY
      })

      const grouped = []
      let currentGroup = null

      const closeGroup = () => {
        if (!currentGroup) return

        const groupItems = currentGroup.items
        const minX = Math.min(...groupItems.map((i) => i.x))
        const minY = Math.min(...groupItems.map((i) => i.y))
        const maxEndX = Math.max(...groupItems.map((i) => i.x + i.w))
        const maxEndY = Math.max(...groupItems.map((i) => i.y + i.h))

        currentGroup.x = minX
        currentGroup.y = minY
        currentGroup.w = maxEndX - minX
        currentGroup.h = maxEndY - minY
        currentGroup.text = groupItems.map((i) => i.text).join(' ').replace(/\s+/g, ' ').trim()

        grouped.push(currentGroup)
        currentGroup = null
      }

      for (const item of items) {
        const isTextLike = item.type === 'text_run' || item.type === 'static_value'

        if (!isTextLike) {
          closeGroup()
          grouped.push(item)
          continue
        }

        if (!currentGroup) {
          currentGroup = { type: 'text_group', items: [] }
        }

        currentGroup.items.push(item)
      }

      closeGroup()

      return grouped
    }
  }
}
</script>

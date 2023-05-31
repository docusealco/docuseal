<template>
  <template
    v-for="field in fields"
    :key="field.uuid"
  >
    <template
      v-for="(area, index) in field.areas"
      :key="index"
    >
      <Teleport :to="`#page-${area.attachment_uuid}-${area.page}`">
        <FieldArea
          :ref="setAreaRef"
          :field="field"
          :area="area"
          :attachments-index="attachmentsIndex"
          :value="values[field.uuid]"
          @click="$emit('focus-field', field)"
        />
      </Teleport>
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
    fields: {
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
    }
  },
  emits: ['focus-field'],
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
          area.$el.scrollIntoView({ behavior: 'smooth', block: 'center' })

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

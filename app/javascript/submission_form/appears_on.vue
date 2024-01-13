<template>
  <div
    v-if="uniqueAreas.length > 1"
    dir="auto"
    class="mb-2"
  >
    <div class="flex space-x-1 text-sm ml-1 -mt-3">
      <span>
        {{ t('appears_on') }}:
      </span>
      <a
        v-for="area in uniqueAreas"
        :key="area.uuid"
        href="#"
        class="link pr-0.5"
        @click.prevent="scrollIntoArea(area)"
      >
        {{ t('page') }} <template v-if="isMultipleDocs">{{ attachmentUuids.indexOf(area.attachment_uuid) + 1 }}-</template>{{ area.page + 1 }}
      </a>
    </div>
  </div>
</template>

<script>
export default {
  name: 'AppearsOn',
  inject: ['t', 'scrollIntoArea'],
  props: {
    field: {
      type: Object,
      required: true
    }
  },
  computed: {
    isMultipleDocs () {
      return this.attachmentUuids.length > 1
    },
    attachmentUuids () {
      return [...new Set(this.uniqueAreas.map((e) => e.attachment_uuid))]
    },
    uniqueAreas () {
      const areas = {}

      this.field.areas?.forEach((area) => {
        areas[area.attachment_uuid + area.page] ||= area
      })

      return Object.values(areas).slice(0, 6)
    }
  }
}
</script>

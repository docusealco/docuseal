<template>
  <div
    class="flex cursor-pointer bg-red-100 absolute"
    :style="computedStyle"
  >
    <img
      v-if="field.type === 'image' && image"
      :src="image.url"
    >
    <img
      v-else-if="field.type === 'signature' && signature"
      :src="signature.url"
    >
    <div v-else-if="field.type === 'attachment'">
      <a
        v-for="(attachment, index) in attachments"
        :key="index"
        :href="attachment.url"
      >
        {{ attachment.filename }}
      </a>
    </div>
    <span v-else>
      {{ value }}
    </span>
  </div>
</template>

<script>
export default {
  name: 'FieldArea',
  props: {
    field: {
      type: Object,
      required: true
    },
    value: {
      type: [Array, String, Number, Object],
      required: false,
      default: ''
    },
    attachmentsIndex: {
      type: Object,
      required: false,
      default: () => ({})
    },
    area: {
      type: Object,
      required: true
    }
  },
  computed: {
    image () {
      if (this.field.type === 'image') {
        return this.attachmentsIndex[this.value]
      } else {
        return null
      }
    },
    signature () {
      if (this.field.type === 'signature') {
        return this.attachmentsIndex[this.value]
      } else {
        return null
      }
    },
    attachments () {
      if (this.field.type === 'attachment') {
        return (this.value || []).map((uuid) => this.attachmentsIndex[uuid])
      } else {
        return []
      }
    },
    computedStyle () {
      const { x, y, w, h } = this.area

      return {
        top: y * 100 + '%',
        left: x * 100 + '%',
        width: w * 100 + '%',
        height: h * 100 + '%'
      }
    }
  }
}
</script>

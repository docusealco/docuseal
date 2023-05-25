<template>
  <div>
    <button @click="$emit('remove', field)">
      Remove
    </button>
    <div>
      {{ field.type }}
    </div>
    <div v-if="field.type !== 'signature'">
      <label>Name</label>
      <input
        v-model="field.name"
        type="text"
        required
      >
    </div>
    <div>
      <div
        v-for="(option, index) in field.options"
        :key="index"
        class="flex"
      >
        <input
          v-model="field.options[index]"
          type="text"
          required
        >
        <button @click="field.options.splice(index, 1)">
          Remove
        </button>
      </div>
      <button
        v-if="field.options"
        @click="field.options.push('')"
      >
        Add option
      </button>
    </div>
    <div>
      <div
        v-for="(area, index) in areas"
        :key="index"
      >
        Area {{ index + 1 }}
        <button @click="removeArea(area)">
          &times;
        </button>
      </div>
      <button
        class="block"
        @click="$emit('set-draw', field)"
      >
        Draw area
      </button>
    </div>
    <div>
      <input
        :id="`field_required_${field.uuid}`"
        v-model="field.required"
        type="checkbox"
        required
      >
      <label :for="`field_required_${field.uuid}`">Required</label>
    </div>
  </div>
</template>

<script>
export default {
  name: 'FlowField',
  props: {
    field: {
      type: Object,
      required: true
    }
  },
  emits: ['set-draw', 'remove'],
  computed: {
    areas () {
      return this.field.areas || []
    }
  },
  methods: {
    removeArea (area) {
      this.field.areas.splice(this.field.areas.indexOf(area), 1)
    }
  }
}
</script>

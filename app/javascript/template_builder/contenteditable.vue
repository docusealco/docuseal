<template>
  <div class="group flex items-center relative overflow-visible">
    <div
      ref="contenteditable"
      contenteditable
      style="min-width: 2px"
      class="peer outline-none"
      @keydown.enter.prevent="onEnter"
      @blur="onBlur"
    >
      {{ value }}
    </div>
    <IconPencil
      contenteditable="false"
      class="absolute ml-1 cursor-pointer inline opacity-0 group-hover:opacity-100 peer-focus:opacity-0 align-middle"
      :style="{ right: -(1.1 * iconWidth) + 'px' }"
      :width="iconWidth"
      @click="onPencilClick"
    />
  </div>
</template>

<script>
import { IconPencil } from '@tabler/icons-vue'

export default {
  name: 'ContenteditableField',
  components: {
    IconPencil
  },
  props: {
    modelValue: {
      type: String,
      required: false,
      default: ''
    },
    iconWidth: {
      type: Number,
      required: false,
      default: 30
    }
  },
  emits: ['update:model-value'],
  data () {
    return {
      value: ''
    }
  },
  watch: {
    modelValue: {
      handler (value) {
        this.value = value
      },
      immediate: true
    }
  },
  methods: {
    onBlur (e) {
      this.value = this.$refs.contenteditable.innerText.trim() || this.modelValue

      this.$emit('update:model-value', this.value)
    },
    onPencilClick () {
      this.$refs.contenteditable.focus()
    },
    onEnter () {
      this.$refs.contenteditable.blur()
    }
  }
}
</script>

<template>
  <div
    class="modal modal-open items-start !animate-none overflow-y-auto"
  >
    <div
      class="absolute top-0 bottom-0 right-0 left-0"
      @click.prevent="$emit('close')"
    />
    <div class="modal-box pt-4 pb-6 px-6 mt-20 max-h-none w-full max-w-xl">
      <div class="flex justify-between items-center border-b pb-2 mb-2 font-medium">
        <span>
          {{ field.name || buildDefaultName(field, template.fields) }}
        </span>
        <a
          href="#"
          class="text-xl"
          @click.prevent="$emit('close')"
        >&times;</a>
      </div>
      <div>
        <form @submit.prevent="saveAndClose">
          <div class="space-y-1 mb-1">
            <div>
              <label
                dir="auto"
                class="label text-sm"
                for="description_field"
              >
                {{ t('description') }}
              </label>
              <textarea
                id="description_field"
                ref="textarea"
                v-model="description"
                dir="auto"
                class="base-textarea !text-base w-full"
                :readonly="!editable"
                @input="resizeTextarea"
              />
            </div>
            <div>
              <label
                dir="auto"
                class="label text-sm"
                for="title_field"
              >
                {{ t('display_title') }} ({{ t('optional') }})
              </label>
              <input
                id="title_field"
                v-model="title"
                dir="auto"
                :readonly="!editable"
                class="base-input !text-base w-full"
              >
            </div>
          </div>
          <button
            class="base-button w-full mt-4"
          >
            {{ t('save') }}
          </button>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'DescriptionModal',
  inject: ['t', 'save', 'template'],
  props: {
    field: {
      type: Object,
      required: true
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    },
    buildDefaultName: {
      type: Function,
      required: true
    }
  },
  emits: ['close'],
  data () {
    return {
      description: this.field.description,
      title: this.field.title
    }
  },
  mounted () {
    this.resizeTextarea()
  },
  methods: {
    saveAndClose () {
      this.field.description = this.description
      this.field.title = this.title

      this.save()
      this.$emit('close')
    },
    resizeTextarea () {
      const textarea = this.$refs.textarea

      textarea.style.height = 'auto'
      textarea.style.height = textarea.scrollHeight + 'px'
    }
  }
}
</script>

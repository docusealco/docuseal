<template>
  <div>
    <div v-if="modelValue.length">
      <div
        v-for="(val, index) in modelValue"
        :key="index"
        class="flex mb-2"
      >
        <input
          :value="val"
          type="hidden"
          :name="`values[${field.uuid}][]`"
        >
        <a
          v-if="val"
          class="flex items-center space-x-1.5 w-full"
          :href="attachmentsIndex[val].url"
          target="_blank"
        >
          <IconPaperclip
            :width="16"
            class="flex-none"
            :heigh="16"
          />
          <span>
            {{ attachmentsIndex[val].filename }}
          </span>
        </a>
        <button
          v-if="modelValue"
          @click.prevent="removeAttachment(val)"
        >
          <IconTrashX
            :width="18"
            :heigh="19"
          />
        </button>
      </div>
    </div>
    <template v-else>
      <input
        value=""
        type="hidden"
        :name="`values[${field.uuid}][]`"
      >
    </template>
    <FileDropzone
      :message="`Upload ${field.name || 'Attachments'}`"
      :submitter-slug="submitterSlug"
      @upload="onUpload"
    />
  </div>
</template>

<script>
import FileDropzone from './dropzone'
import { IconPaperclip, IconTrashX } from '@tabler/icons-vue'

export default {
  name: 'AttachmentStep',
  components: {
    FileDropzone,
    IconPaperclip,
    IconTrashX
  },
  props: {
    field: {
      type: Object,
      required: true
    },
    submitterSlug: {
      type: String,
      required: true
    },
    attachmentsIndex: {
      type: Object,
      required: false,
      default: () => ({})
    },
    modelValue: {
      type: Array,
      required: false,
      default: () => []
    }
  },
  emits: ['attached', 'update:model-value'],
  methods: {
    removeAttachment (uuid) {
      this.modelValue.splice(this.modelValue.indexOf(uuid), 1)

      this.$emit('update:model-value', this.modelValue)
    },
    onUpload (attachments) {
      attachments.forEach((attachment) => {
        this.$emit('attached', attachment)
      })

      this.$emit('update:model-value', [...this.modelValue, ...attachments.map(a => a.uuid)])
    }
  }
}
</script>

<template>
  <div>
    <div v-if="value.length">
      <div
        v-for="(val, index) in value"
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
        <button @click.prevent="removeAttachment(val)">
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
    <div
      v-if="field.description && !modelValue.length"
      dir="auto"
      class="mb-3 px-1"
    >
      <MarkdownContent :string="field.description" />
    </div>
    <FileDropzone
      :message="`${t('upload')} ${field.name || t('files')}${field.required ? '' : ` (${t('optional')})`}`"
      :submitter-slug="submitterSlug"
      :multiple="true"
      :dry-run="dryRun"
      @upload="onUpload"
    />
  </div>
</template>

<script>
import FileDropzone from './dropzone'
import MarkdownContent from './markdown_content'
import { IconPaperclip, IconTrashX } from '@tabler/icons-vue'

export default {
  name: 'AttachmentStep',
  components: {
    FileDropzone,
    MarkdownContent,
    IconPaperclip,
    IconTrashX
  },
  inject: ['t'],
  props: {
    field: {
      type: Object,
      required: true
    },
    submitterSlug: {
      type: String,
      required: true
    },
    dryRun: {
      type: Boolean,
      required: false,
      default: false
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
  computed: {
    value: {
      set (value) {
        this.$emit('update:model-value', this.modelValue || [])
      },
      get () {
        return this.modelValue || []
      }
    }
  },
  methods: {
    removeAttachment (uuid) {
      this.value.splice(this.value.indexOf(uuid), 1)

      this.$emit('update:model-value', this.value)
    },
    onUpload (attachments) {
      attachments.forEach((attachment) => {
        this.$emit('attached', attachment)
      })

      this.$emit('update:model-value', [...this.value, ...attachments.map(a => a.uuid)])
    }
  }
}
</script>

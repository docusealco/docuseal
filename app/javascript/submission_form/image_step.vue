<template>
  <div v-if="modelValue">
    <div class="flex justify-between items-center w-full mb-2">
      <label
        class="label text-2xl"
      >{{ showFieldNames && field.name ? field.name : t('image') }}</label>
      <button
        class="btn btn-outline btn-sm"
        @click.prevent="remove"
      >
        <IconReload :width="16" />
        {{ t('reupload') }}
      </button>
    </div>
    <div>
      <img
        :src="attachmentsIndex[modelValue].url"
        class="h-52 border border-base-300 rounded mx-auto"
      >
    </div>
    <input
      :value="modelValue"
      type="hidden"
      :name="`values[${field.uuid}]`"
    >
  </div>
  <div
    v-if="!modelValue"
  >
    <div
      v-if="field.description"
      dir="auto"
      class="mb-3 px-1"
    >
      <MarkdownContent :string="field.description" />
    </div>
    <FileDropzone
      :message="`${t('upload')} ${field.name || t('image')}${field.required ? '' : ` (${t('optional')})`}`"
      :submitter-slug="submitterSlug"
      :dry-run="dryRun"
      :accept="'image/*'"
      @upload="onImageUpload"
    />
  </div>
</template>

<script>
import FileDropzone from './dropzone'
import { IconReload } from '@tabler/icons-vue'
import MarkdownContent from './markdown_content'

export default {
  name: 'ImageStep',
  components: {
    FileDropzone,
    IconReload,
    MarkdownContent
  },
  inject: ['t'],
  props: {
    field: {
      type: Object,
      required: true
    },
    showFieldNames: {
      type: Boolean,
      required: false,
      default: true
    },
    dryRun: {
      type: Boolean,
      required: false,
      default: false
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
      type: String,
      required: false,
      default: ''
    }
  },
  emits: ['attached', 'update:model-value'],
  methods: {
    remove () {
      this.$emit('update:model-value', '')
    },
    onImageUpload (attachments) {
      this.$emit('attached', attachments[0])

      this.$emit('update:model-value', attachments[0].uuid)
    }
  }
}
</script>

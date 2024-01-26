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
  <div>
    <FileDropzone
      v-if="!modelValue"
      :message="`${t('upload')} ${field.name || t('image')}${field.required ? '' : ` (${t('optional')})`}`"
      :submitter-slug="submitterSlug"
      :accept="'image/*'"
      :is-direct-upload="isDirectUpload"
      @upload="onImageUpload"
    />
  </div>
</template>

<script>
import FileDropzone from './dropzone'
import { IconReload } from '@tabler/icons-vue'

export default {
  name: 'ImageStep',
  components: {
    FileDropzone,
    IconReload
  },
  inject: ['t'],
  props: {
    field: {
      type: Object,
      required: true
    },
    isDirectUpload: {
      type: Boolean,
      required: true,
      default: false
    },
    showFieldNames: {
      type: Boolean,
      required: false,
      default: true
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

<template>
  <div
    class="dropdown"
    :class="{ 'dropdown-open': isLoading }"
  >
    <label tabindex="0">
      <IconBrandGoogleDrive
        width="19"
        class="inline-block mr-1 cursor-pointer"
      />
    </label>
    <ul
      tabindex="0"
      :style="{ backgroundColor }"
      class="dropdown-content z-[1] shadow menu rounded-box"
    >
      <li>
        <a
          :href="`https://drive.google.com/file/d/${googleDriveFileId}/view?usp=sharing`"
          data-turbo="false"
          target="_blank"
          class="flex items-center"
        >
          <IconExternalLink class="w-4 h-4 flex-shrink-0" />
          <span>{{ t('view') }}</span>
        </a>
      </li>
      <li>
        <button
          form="sync_form"
          type="submit"
          :disabled="isLoading"
        >
          <IconRefresh
            class="w-4 h-4 flex-shrink-0"
            :class="{ 'animate-spin': isLoading }"
          />
          <span>{{ message }}</span>
        </button>
      </li>
    </ul>
    <form
      id="sync_form"
      ref="form"
      class="hidden"
      @submit.prevent="upload({ path: uploadUrl })"
    >
      <input
        :id="inputId"
        ref="input"
        :value="googleDriveFileId"
        name="google_drive_file_ids[]"
      >
    </form>
  </div>
</template>

<script>
import Upload from './upload'
import { IconRefresh, IconBrandGoogleDrive, IconExternalLink } from '@tabler/icons-vue'

export default {
  name: 'GoogleDriveDocumentSettings',
  components: {
    IconRefresh,
    IconBrandGoogleDrive,
    IconExternalLink
  },
  inject: ['baseFetch', 't', 'backgroundColor'],
  props: {
    templateId: {
      type: [Number, String],
      required: true
    },
    googleDriveFileId: {
      type: String,
      required: true
    }
  },
  emits: ['success'],
  data () {
    return {
      isLoading: false
    }
  },
  computed: {
    inputId () {
      return 'el' + Math.random().toString(32).split('.')[1]
    },
    uploadUrl () {
      return `/templates/${this.templateId}/google_drive_documents`
    },
    message () {
      if (this.isLoading) {
        return this.t('syncing')
      } else {
        return this.t('sync')
      }
    }
  },
  methods: {
    upload: Upload.methods.upload
  }
}
</script>

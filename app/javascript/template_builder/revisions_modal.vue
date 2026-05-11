<template>
  <div class="modal modal-open items-start !animate-none overflow-y-auto">
    <div
      class="absolute top-0 bottom-0 right-0 left-0"
      @click.prevent="$emit('close')"
    />
    <div class="modal-box pt-4 pb-6 mt-20 w-full">
      <div class="flex justify-between items-center border-b pb-2 mb-3 font-medium">
        <span>{{ t('revisions') }}</span>
        <a
          href="#"
          class="text-xl"
          @click.prevent="$emit('close')"
        >&times;</a>
      </div>
      <ul class="space-y-1.5">
        <li
          v-for="revision in revisions"
          :key="revision.id"
        >
          <button
            type="button"
            class="w-full text-left rounded-lg p-3 border border-dashed border-base-200 transition-colors disabled:cursor-default hover:bg-base-200 hover:border-base-200"
            :disabled="loadingId !== null"
            @click="viewRevision(revision.id)"
          >
            <div class="flex justify-between items-center gap-2">
              <div class="flex flex-col">
                <span>{{ formatDate(revision.created_at) }}</span>
                <span class="-ml-0.5 flex items-center space-x-1 text-xs text-base-content/60 mt-0.5">
                  <IconUser class="w-3.5 h-3.5 flex-shrink-0" />
                  <span class="truncate">{{ revision.author.full_name || revision.author.email }}</span>
                </span>
              </div>
              <span class="btn btn-sm btn-neutral text-white pointer-events-none flex-shrink-0">
                <IconInnerShadowTop
                  v-if="loadingId === revision.id"
                  class="w-4 h-4 animate-spin"
                />
                <span v-else>{{ t('view') }}</span>
              </span>
            </div>
          </button>
        </li>
        <li
          v-if="!revisions.length"
          class="py-4 text-center text-base-content/60"
        >
          {{ t('no_revisions_yet') }}
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
import { IconUser, IconInnerShadowTop } from '@tabler/icons-vue'

export default {
  name: 'RevisionsModal',
  components: { IconUser, IconInnerShadowTop },
  inject: ['t', 'baseFetch'],
  props: {
    template: {
      type: Object,
      required: true
    },
    revisions: {
      type: Array,
      required: true
    },
    locale: {
      type: String,
      required: true
    }
  },
  emits: ['close', 'apply'],
  data () {
    return {
      loadingId: null
    }
  },
  methods: {
    viewRevision (id) {
      if (this.loadingId !== null) return

      this.loadingId = id

      this.baseFetch(`/templates/${this.template.id}/versions/${id}`)
        .then((r) => r.json())
        .then((revision) => { this.$emit('apply', revision) })
        .finally(() => { this.loadingId = null })
    },
    formatDate (string) {
      return new Date(string).toLocaleString(this.locale || undefined, {
        month: 'long',
        day: 'numeric',
        hour: 'numeric',
        minute: '2-digit'
      })
    }
  }
}
</script>

<template>
  <form
    ref="form"
    action="post"
    method="post"
    class="mx-auto"
    @submit.prevent="submit"
  >
    <input
      type="hidden"
      name="authenticity_token"
      :value="authenticityToken"
    >
    <div
      v-for="(submitter, index) in [...submitters, ...optionalSubmitters]"
      :key="submitter.uuid"
      :class="{ 'mt-4': index !== 0 }"
    >
      <input
        :value="submitter.uuid"
        hidden
        name="submission[submitters][][uuid]"
      >
      <label
        :for="submitter.uuid"
        dir="auto"
        class="label text-2xl"
      >
        {{ t('invite') }} {{ submitter.name }} <template v-if="!submitters.includes(submitter)">({{ t('optional') }})</template>
      </label>
      <input
        :id="submitter.uuid"
        dir="auto"
        class="base-input !text-2xl w-full"
        :placeholder="t('email')"
        type="email"
        :required="submitters.includes(submitter)"
        autofocus="true"
        name="submission[submitters][][email]"
      >
    </div>
    <div
      class="mt-4 md:mt-6"
    >
      <button
        type="submit"
        class="base-button w-full flex justify-center"
        :disabled="isSubmitting"
      >
        <span class="flex">
          <IconInnerShadowTop
            v-if="isSubmitting"
            class="mr-1 animate-spin"
          />
          <span>
            {{ t('complete') }}
          </span><span
            v-if="isSubmitting"
            class="w-6 flex justify-start mr-1"
          ><span>...</span></span>
        </span>
      </button>
    </div>
  </form>
</template>

<script>
import { IconInnerShadowTop } from '@tabler/icons-vue'

export default {
  name: 'InviteForm',
  components: {
    IconInnerShadowTop
  },
  inject: ['t'],
  props: {
    submitters: {
      type: Array,
      required: true
    },
    optionalSubmitters: {
      type: Array,
      required: false,
      default: () => []
    },
    url: {
      type: String,
      required: true
    },
    authenticityToken: {
      type: String,
      required: true
    },
    submitterSlug: {
      type: String,
      required: true
    }
  },
  emits: ['success'],
  data () {
    return {
      isSubmitting: false
    }
  },
  methods: {
    submit () {
      this.isSubmitting = true

      return fetch(this.url, {
        method: 'POST',
        body: new FormData(this.$refs.form)
      }).then((response) => {
        if (response.status === 200) {
          this.$emit('success')
        }
      }).finally(() => {
        this.isSubmitting = false
      })
    }
  }
}
</script>

<template>
  <Teleport :to="modalContainerEl">
    <div class="modal modal-open items-start !animate-none overflow-y-auto">
      <div
        class="absolute top-0 bottom-0 right-0 left-0"
        @click.prevent="$emit('close')"
      />
      <div class="modal-box pt-4 pb-6 px-6 mt-20 max-h-none w-full max-w-xl">
        <div class="flex justify-between items-center border-b pb-2 mb-2 font-medium">
          <span class="modal-title">
            {{ title }}
          </span>
          <a
            href="#"
            class="text-xl modal-close-button"
            @click.prevent="$emit('close')"
          >&times;</a>
        </div>
        <form @submit.prevent="$emit('save')">
          <slot />
          <button
            class="base-button w-full mt-4 modal-save-button"
            type="submit"
          >
            {{ t('save') }}
          </button>
        </form>
      </div>
    </div>
  </Teleport>
</template>

<script>
export default {
  name: 'ContextModal',
  inject: ['t'],
  props: {
    title: {
      type: String,
      required: true
    },
    modalContainerEl: {
      type: Element,
      required: true
    }
  },
  emits: ['close', 'save']
}
</script>

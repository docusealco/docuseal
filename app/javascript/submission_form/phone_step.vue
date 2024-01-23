<template>
  <div>
    <label
      :for="isCodeSent ? 'one_time_code' : field.uuid"
      class="label text-2xl mb-2"
    >{{ field.name || t('verified_phone_number') }}
      <template v-if="!field.required">({{ t('optional') }})</template>
    </label>
    <div>
      <input
        type="hidden"
        name="normalize_phone"
        value="true"
      >
      <div v-if="isCodeSent">
        <input
          id="one_time_code"
          class="base-input !text-2xl w-full text-center"
          name="one_time_code"
          type="text"
          autocomplete="one-time-code"
          :placeholder="t('six_digits_code')"
          required
          maxlength="6"
          autofocus
          inputmode="decimal"
          @input="onInputCode"
        >
        <div class="flex justify-between mt-2 -mb-2 md:-mb-4">
          <a
            v-if="!defaultValue"
            href="#"
            class="link"
            @click.prevent="isCodeSent = false"
          >
            {{ t('change_phone_number') }}
          </a>
          <a
            href="#"
            class="link"
            @click.prevent="resendCode"
          >
            {{ isResendLoading ? t('sending') : t('resend_code') }}
          </a>
        </div>
      </div>
      <input
        v-show="!isCodeSent"
        :id="field.uuid"
        ref="phone"
        :value="modelValue || defaultValue"
        :readonly="!!defaultValue"
        class="base-input !text-2xl w-full"
        autocomplete="tel"
        pattern="^\+[0-9\s\-]+$"
        :oninvalid="`this.value ? this.setCustomValidity('${t('use_international_format')}...') : ''`"
        oninput="this.setCustomValidity('')"
        type="tel"
        inputmode="tel"
        :required="field.required"
        placeholder="+1 234 567-8900"
        :name="`values[${field.uuid}]`"
        @input="$emit('update:model-value', $event.target.value)"
        @focus="$emit('focus')"
      >
    </div>
  </div>
</template>

<script>
function throttle (func, delay) {
  let lastCallTime = 0

  return function (...args) {
    const now = Date.now()

    if (now - lastCallTime >= delay) {
      func.apply(this, args)
      lastCallTime = now
    }
  }
}

export default {
  name: 'PhoneStep',
  inject: ['t', 'baseUrl'],
  props: {
    field: {
      type: Object,
      required: true
    },
    submitterSlug: {
      type: String,
      required: true
    },
    modelValue: {
      type: String,
      required: false,
      default: ''
    },
    defaultValue: {
      type: String,
      required: false,
      default: ''
    }
  },
  emits: ['update:model-value', 'focus', 'submit'],
  data () {
    return {
      isCodeSent: false,
      isResendLoading: false
    }
  },
  methods: {
    emitSubmit: throttle(function (e) {
      this.$emit('submit')
    }, 1000),
    onInputCode (e) {
      if (e.target.value.length === 6) {
        this.emitSubmit()
      }
    },
    resendCode () {
      this.isResendLoading = true

      this.sendVerificationCode().finally(() => {
        alert(this.t('verification_code_has_been_resent'))

        this.isResendLoading = false
      })
    },
    sendVerificationCode () {
      return fetch(this.baseUrl + '/api/send_phone_verification_code', {
        method: 'POST',
        body: JSON.stringify({
          submitter_slug: this.submitterSlug,
          phone: this.$refs.phone.value
        }),
        headers: { 'Content-Type': 'application/json' }
      })
    },
    async submit () {
      if (!this.$refs.phone.value.toString().startsWith('+')) {
        alert(this.t('use_international_format'))

        return Promise.reject(new Error('phone invalid'))
      } else if (!this.isCodeSent) {
        this.sendVerificationCode()

        this.$emit('update:model-value', this.$refs.phone.value)

        this.isCodeSent = true

        return Promise.reject(new Error('verify with code'))
      } else {
        return Promise.resolve({})
      }
    }
  }
}
</script>

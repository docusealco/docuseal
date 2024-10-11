<template>
  <div>
    <label
      :for="isCodeSent ? 'one_time_code' : field.uuid"
      class="label text-2xl"
      :class="{ 'mb-2': !field.description }"
    >
      <MarkdownContent
        v-if="field.title"
        :string="field.title"
      />
      <template v-else>
        {{ showFieldNames && field.name ? field.name : t('verified_phone_number') }}
        <template v-if="!field.required">
          ({{ t('optional') }})
        </template>
      </template>
    </label>
    <div
      v-if="field.description"
      dir="auto"
      class="mb-3 px-1"
    >
      <MarkdownContent :string="field.description" />
    </div>
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
      <div
        v-show="!isCodeSent"
        class="flex w-full rounded-full outline-neutral-content outline-2 outline-offset-2 focus-within:outline"
      >
        <div class="relative inline-block">
          <div class="btn bg-base-200 border border-neutral-300 text-2xl whitespace-nowrap font-normal rounded-l-full">
            {{ selectedCountry.flag }} +{{ selectedCountry.dial }}
          </div>
          <select
            class="absolute top-0 bottom-0 right-0 left-0 opacity-0 w-full h-full cursor-pointer"
            :disabled="!!defaultValue"
            @change="onCountrySelect(countries.find((country) => country.flag === $event.target.value))"
          >
            <option
              v-for="(country, index) in countries"
              :key="index"
              :value="country.flag"
            >
              {{ country.flag }} {{ country.name }}
            </option>
          </select>
        </div>
        <input
          :name="`values[${field.uuid}]`"
          :value="fullInternationalPhoneValue"
          hidden
        >
        <input
          :id="field.uuid"
          ref="phone"
          :value="phoneValue"
          :readonly="!!defaultValue"
          class="base-input !text-2xl !rounded-l-none !border-l-0 !outline-none w-full"
          autocomplete="tel"
          type="tel"
          inputmode="tel"
          :required="field.required"
          placeholder="234 567-8900"
          @input="onPhoneInput"
          @focus="$emit('focus')"
        >
      </div>
    </div>
  </div>
</template>

<script>
import MarkdownContent from './markdown_content'
import phoneData from './phone_data'

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
  components: {
    MarkdownContent
  },
  inject: ['t', 'baseUrl'],
  props: {
    field: {
      type: Object,
      required: true
    },
    verifiedValue: {
      type: String,
      required: false,
      default: ''
    },
    submitterSlug: {
      type: String,
      required: true
    },
    locale: {
      type: String,
      required: false,
      default: 'en'
    },
    showFieldNames: {
      type: Boolean,
      required: false,
      default: true
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
      isResendLoading: false,
      phoneValue: this.modelValue || this.defaultValue || '',
      selectedCountry: {}
    }
  },
  computed: {
    countries () {
      return phoneData.map(([name, dial, flag, tz]) => {
        return { name, dial, flag, tz }
      })
    },
    countriesDialIndex () {
      return this.countries.reduce((acc, item) => {
        acc[item.dial] ||= item

        return acc
      }, {})
    },
    dialCodesRegexp () {
      const dialCodes = this.countries.map((country) => country.dial).sort((a, b) => b.length - a.length)

      return new RegExp(`^\\+(${dialCodes.join('|')})`)
    },
    detectedPhoneValueDialCode () {
      return (this.phoneValue || '').replace(/[^\d+]/g, '').match(this.dialCodesRegexp)?.[1]
    },
    fullInternationalPhoneValue () {
      if (this.detectedPhoneValueDialCode) {
        return this.phoneValue
      } else if (this.phoneValue) {
        return ['+', this.selectedCountry.dial, this.phoneValue].filter(Boolean).join('')
      } else {
        return ''
      }
    }
  },
  mounted () {
    const browserTimeZone = Intl.DateTimeFormat().resolvedOptions().timeZone

    if (this.detectedPhoneValueDialCode) {
      this.selectedCountry = this.countriesDialIndex[this.detectedPhoneValueDialCode]
    } else if (browserTimeZone) {
      const tz = browserTimeZone.split('/')[1]

      this.selectedCountry = this.countries.find((country) => country.tz.includes(tz)) || this.countries[0]
    }
  },
  methods: {
    emitSubmit: throttle(function (e) {
      this.$emit('submit')
    }, 1000),
    onCountrySelect (country) {
      if (this.selectedCountry.flag !== country.flag) {
        this.phoneValue = this.phoneValue.replace(`+${this.selectedCountry.dial}`, `+${country.dial}`)
      }

      this.selectedCountry = country

      this.$refs.phone.focus()
    },
    onPhoneInput (e) {
      this.phoneValue = e.target.value

      if (this.detectedPhoneValueDialCode) {
        this.selectedCountry = this.countriesDialIndex[this.detectedPhoneValueDialCode]
      }
    },
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
          locale: this.locale,
          phone: this.fullInternationalPhoneValue
        }),
        headers: { 'Content-Type': 'application/json' }
      }).then(async (resp) => {
        if (resp.status === 422) {
          const data = await resp.json()

          alert(this.t('number_phone_is_invalid').replace('{number}', this.fullInternationalPhoneValue))

          return Promise.reject(new Error(data.error))
        }
      })
    },
    async submit () {
      if (this.verifiedValue && this.verifiedValue === this.modelValue) {
        return Promise.resolve({})
      }

      if (!this.fullInternationalPhoneValue.toString().startsWith('+')) {
        alert(this.t('use_international_format'))

        return Promise.reject(new Error('phone invalid'))
      } else if (!this.isCodeSent) {
        return this.sendVerificationCode().then(() => {
          this.$emit('update:model-value', this.fullInternationalPhoneValue)

          this.isCodeSent = true

          return Promise.reject(new Error('verify with code'))
        })
      } else {
        return Promise.resolve({})
      }
    }
  }
}
</script>

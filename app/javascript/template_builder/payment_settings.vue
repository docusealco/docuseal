<template>
  <span
    class="dropdown dropdown-end field-settings-dropdown"
    :class="{ 'dropdown-open': withForceOpen && !field.preferences?.price && !field.preferences?.formula && !field.preferences?.price_id && !field.preferences?.payment_link_id && !isLoading }"
  >
    <label
      tabindex="0"
      :title="t('settings')"
      class="cursor-pointer text-transparent group-hover:text-base-content"
    >
      <IconSettings
        :width="18"
        :stroke-width="1.6"
      />
    </label>
    <ul
      tabindex="0"
      class="mt-1.5 dropdown-content menu menu-xs p-2 shadow bg-base-100 rounded-box w-52 z-10"
      draggable="true"
      @dragstart.prevent.stop
      @click="closeDropdown"
    >
      <div
        v-if="isPaypal || (!('price_id' in field.preferences) && !('payment_link_id' in field.preferences))"
        class="field-settings-currency py-1.5 px-1 relative"
        @click.stop
      >
        <select
          v-model="field.preferences.currency"
          :placeholder="t('price')"
          class="select select-bordered select-xs font-normal w-full max-w-xs !h-7 !outline-0"
          @change="save"
        >
          <option
            v-for="currency in currenciesList"
            :key="currency"
            :value="currency"
          >
            {{ currency }}
          </option>
        </select>
        <label
          :style="{ backgroundColor: backgroundColor }"
          class="absolute -top-1 left-2.5 px-1 h-4"
          style="font-size: 8px"
        >
          {{ t('currency') }}
        </label>
      </div>
      <div
        class="field-settings-price py-1.5 px-1 relative"
        @click.stop
      >
        <input
          v-if="isStripe && 'payment_link_id' in field.preferences"
          v-model="field.preferences.payment_link_id"
          placeholder="plink_XXXXX"
          class="input input-bordered input-xs w-full max-w-xs h-7 !outline-0"
          @blur="save"
        >
        <input
          v-else-if="isStripe && 'price_id' in field.preferences"
          v-model="field.preferences.price_id"
          placeholder="Price ID: price_XXXXX"
          class="input input-bordered input-xs w-full max-w-xs h-7 !outline-0"
          @blur="save"
        >
        <input
          v-else-if="field.preferences.formula"
          type="number"
          :placeholder="t('price')"
          disabled="true"
          class="input input-bordered input-xs w-full max-w-xs h-7 !outline-0"
          @blur="save"
        >
        <input
          v-else
          v-model="field.preferences.price"
          type="number"
          :placeholder="t('price')"
          class="input input-bordered input-xs w-full max-w-xs h-7 !outline-0"
          @blur="save"
        >
        <label
          v-if="(field.preferences.price || field.preferences.price_id || field.preferences.payment_link_id) && (!field.preferences.formula || ('price_id' in field.preferences) || ('payment_link_id' in field.preferences))"
          :style="{ backgroundColor: backgroundColor }"
          class="absolute -top-1 left-2.5 px-1 h-4"
          style="font-size: 8px"
        >
          {{ 'payment_link_id' in field.preferences ? t('payment_link') : t('price') }}
        </label>
        <div
          v-if="isStripe && stripeConnected"
          class="flex items-center justify-center"
        >
          <a
            href="#"
            class="hover:underline"
            style="font-size: 11px"
            :class="{'underline': !('payment_link_id' in field.preferences)}"
            @click="[delete field.preferences.price_id, delete field.preferences.payment_link_id]"
          >{{ t('one_off') }}</a>
          <span class="h-2.5 border-l border-base-content mx-1" />
          <template
            v-if="field.preferences.price_id"
          >
            <a
              href="#"
              class="hover:underline"
              style="font-size: 11px"
              :class="{'underline': ('price_id' in field.preferences)}"
              @click="field.preferences.payment_link_id ??= ''"
            >{{ t('recurrent') }}</a>
            <span class="h-2.5 border-l border-base-content mx-1" />
          </template>
          <a
            href="#"
            class="hover:underline"
            style="font-size: 11px"
            :class="{'underline': ('payment_link_id' in field.preferences)}"
            @click="[delete field.preferences.price_id, field.preferences.payment_link_id ??= '']"
          >{{ t('payment_link') }}</a>
        </div>
      </div>
      <div
        v-if="!stripeConnected && !paypalConnected"
        class="flex flex-col gap-1 py-1.5 px-1"
        @click.stop
      >
        <a
          v-if="withPaypal"
          :href="paypalConnectUrl"
          target="_blank"
          data-turbo="false"
          class="btn bg-[#003087] hover:bg-[#012169] btn-sm text-white w-full"
        >
          <IconBrandPaypal class="w-4 h-4 inline" />
          <span>Connect PayPal</span>
        </a>
        <form
          v-if="withStripe"
          data-turbo="false"
          action="/auth/stripe_connect"
          accept-charset="UTF-8"
          target="_blank"
          method="post"
        >
          <input
            type="hidden"
            name="oauth_data"
            :value="oauthData"
            autocomplete="off"
          >
          <input
            type="hidden"
            name="redirect_uri"
            :value="redirectUri"
            autocomplete="off"
          >
          <input
            type="hidden"
            name="scope"
            value="read_write"
            autocomplete="off"
          >
          <input
            type="hidden"
            name="authenticity_token"
            :value="authenticityToken"
            autocomplete="off"
          >
          <button
            type="submit"
            :disabled="isLoading"
            class="btn bg-[#7B73FF] hover:bg-[#0A2540] btn-sm text-white w-full"
          >
            <IconInnerShadowTop
              v-if="isLoading"
              class="w-4 h-4 animate-spin inline"
            />
            <IconBrandStripe
              v-else
              class="w-4 h-4 inline"
            />
            <span>Connect Stripe</span>
          </button>
        </form>
      </div>
      <div
        v-if="isStripe && !stripeConnected"
        class="px-1 pb-1.5"
        @click.stop
      >
        <a
          class="block link text-center text-xs"
          href="https://www.docuseal.com/blog/accept-payments-and-request-signatures-with-ease"
          target="_blank"
          data-turbo="false"
        >{{ t('learn_more') }}</a>
      </div>
      <li
        class="field-settings-formula mb-1"
      >
        <label
          class="label-text cursor-pointer text-center w-full flex items-center"
          @click="$emit('click-formula')"
        >
          <IconMathFunction
            width="18"
          />
          <span class="text-sm">
            {{ 'payment_link_id' in field.preferences ? t('quantity') : t('formula') }}
          </span>
        </label>
      </li>
      <hr>
      <li class="field-settings-description">
        <label
          class="label-text cursor-pointer text-center w-full flex items-center"
          @click="$emit('click-description')"
        >
          <IconInfoCircle
            width="18"
          />
          <span class="text-sm">
            {{ t('description') }}
          </span>
        </label>
      </li>
      <li
        v-if="withCondition"
        class="field-settings-condition mt-1"
      >
        <label
          class="label-text cursor-pointer text-center w-full flex items-center"
          @click="$emit('click-condition')"
        >
          <IconRouteAltLeft
            width="18"
          />
          <span class="text-sm">
            {{ t('condition') }}
          </span>
        </label>
      </li>
      <hr
        v-if="withCustomFields"
        class="pb-0.5 mt-0.5"
      >
      <li
        v-if="withCustomFields"
        class="field-settings-save-as-custom-field"
      >
        <a
          href="#"
          class="text-sm py-1 px-2"
          @click.prevent="$emit('add-custom-field', field)"
        >
          <IconForms
            :width="20"
            :stroke-width="1.6"
          />
          {{ t('save_as_custom_field') }}
        </a>
      </li>
    </ul>
  </span>
</template>

<script>
import { IconMathFunction, IconSettings, IconInfoCircle, IconBrandStripe, IconBrandPaypal, IconInnerShadowTop, IconRouteAltLeft, IconForms } from '@tabler/icons-vue'
import { ref } from 'vue'

export const stripeConnectedRef = ref(false)
export const paypalConnectedRef = ref(false)

export default {
  name: 'PaymentSettings',
  components: {
    IconSettings,
    IconRouteAltLeft,
    IconInfoCircle,
    IconForms,
    IconMathFunction,
    IconInnerShadowTop,
    IconBrandStripe,
    IconBrandPaypal
  },
  inject: ['backgroundColor', 'save', 'currencies', 't', 'isStripeConnected', 'isPaypalConnected', 'withStripe', 'withPaypal'],
  props: {
    field: {
      type: Object,
      required: true
    },
    withForceOpen: {
      type: Boolean,
      required: false,
      default: true
    },
    withCustomFields: {
      type: Boolean,
      required: false,
      default: false
    },
    withCondition: {
      type: Boolean,
      required: false,
      default: true
    }
  },
  emits: ['click-condition', 'click-description', 'click-formula', 'add-custom-field'],
  data () {
    return {
      isLoading: false
    }
  },
  computed: {
    stripeConnected: () => stripeConnectedRef.value,
    paypalConnected: () => paypalConnectedRef.value,
    provider () {
      if (this.paypalConnected && !this.stripeConnected) return 'paypal'
      if (this.stripeConnected && !this.paypalConnected) return 'stripe'
      if (this.withPaypal && !this.withStripe) return 'paypal'

      return 'stripe'
    },
    isStripe () {
      return this.provider === 'stripe'
    },
    isPaypal () {
      return this.provider === 'paypal'
    },
    redirectUri () {
      return document.location.origin + '/auth/stripe_connect/callback'
    },
    paypalConnectUrl () {
      return `/auth/paypal_connect?redir=${encodeURIComponent(document.location.href)}`
    },
    defaultCurrencies () {
      return ['USD', 'EUR', 'GBP', 'CAD', 'AUD']
    },
    currenciesList () {
      return this.currencies.length ? this.currencies : this.defaultCurrencies
    },
    authenticityToken () {
      return document.querySelector('meta[name="csrf-token"]')?.content
    },
    oauthData () {
      const params = new URLSearchParams('')

      params.set('redir', document.location.href)

      return params.toString()
    },
    defaultCurrency () {
      const userTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone

      if (userTimezone.startsWith('Europe')) {
        return 'EUR'
      } else if (userTimezone.includes('London') || userTimezone.includes('Belfast')) {
        return 'GBP'
      } else if (userTimezone.includes('Vancouver') || userTimezone.includes('Toronto') || userTimezone.includes('Halifax') || userTimezone.includes('Edmonton')) {
        return 'CAD'
      } else if (userTimezone.startsWith('Australia')) {
        return 'AUD'
      } else {
        return 'USD'
      }
    }
  },
  created () {
    this.field.preferences ||= {}
  },
  mounted () {
    this.field.preferences.currency ||= this.defaultCurrency

    stripeConnectedRef.value ||= this.isStripeConnected
    paypalConnectedRef.value ||= this.isPaypalConnected

    if (this.withStripe && !this.stripeConnected && !this.paypalConnected) {
      this.checkStripeStatus()
    }

    if (this.withPaypal && !this.paypalConnected && !this.stripeConnected) {
      this.checkPaypalStatus()
      window.addEventListener('focus', this.onWindowFocus)
    }
  },
  beforeUnmount () {
    window.removeEventListener('focus', this.onWindowFocus)
  },
  methods: {
    onWindowFocus () {
      if (this.withPaypal && !this.paypalConnected) {
        this.checkPaypalStatus()
      }
    },
    checkStripeStatus () {
      this.isLoading = true

      fetch('/api/stripe_connect').then(async (resp) => {
        const { status } = await resp.json()

        if (status === 'connected') {
          stripeConnectedRef.value = true

          window.removeEventListener('focus', this.onWindowFocus)
        }
      }).finally(() => {
        this.isLoading = false
      })
    },
    checkPaypalStatus () {
      fetch('/api/paypal_connect').then(async (resp) => {
        const { status } = await resp.json()

        if (status === 'connected') {
          paypalConnectedRef.value = true

          window.removeEventListener('focus', this.onWindowFocus)
        }
      })
    },
    closeDropdown () {
      document.activeElement.blur()
    }
  }
}
</script>

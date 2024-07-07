<template>
  <span
    class="dropdown dropdown-end"
    :class="{ 'dropdown-open': (!field.preferences?.price || !isConnected) && !isLoading }"
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
        class="py-1.5 px-1 relative"
        @click.stop
      >
        <select
          v-model="field.preferences.currency"
          placeholder="Price"
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
          Currency
        </label>
      </div>
      <div
        class="py-1.5 px-1 relative"
        @click.stop
      >
        <input
          v-model="field.preferences.price"
          type="number"
          placeholder="Price"
          class="input input-bordered input-xs w-full max-w-xs h-7 !outline-0"
          @blur="save"
        >
        <label
          v-if="field.preferences.price"
          :style="{ backgroundColor: backgroundColor }"
          class="absolute -top-1 left-2.5 px-1 h-4"
          style="font-size: 8px"
        >
          Price
        </label>
      </div>
      <div
        v-if="!isConnected || isOauthSuccess"
        class="py-1.5 px-1 relative"
        @click.stop
      >
        <div
          v-if="isConnected && isOauthSuccess"
          class="text-sm text-center"
        >
          <IconCircleCheck
            class="inline text-green-600 w-4 h-4"
          />
          Stripe Connected
        </div>
        <form
          v-if="!isConnected"
          data-turbo="false"
          action="/auth/stripe_connect"
          accept-charset="UTF-8"
          target="_blank"
          method="post"
        >
          <input
            type="hidden"
            name="state"
            :value="oauthState"
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
            <span
              v-if="isLoading"
              class="flex items-center space-x-1"
            >
              <IconInnerShadowTop
                class="w-4 h-4 animate-spin inline"
              />
              <span>
                Connect Stripe
              </span>
            </span>
            <span
              v-else
              class="flex items-center space-x-1"
            >
              <IconBrandStripe
                class="w-4 h-4 inline"
              />
              <span>
                Connect Stripe
              </span>
            </span>
          </button>
        </form>
        <a
          v-if="!isConnected"
          class="block link text-center mt-1"
          href="https://www.docuseal.co/blog/accept-payments-and-request-signatures-with-ease"
          target="_blank"
          data-turbo="false"
        >Learn more</a>
      </div>
      <hr>
      <li class="mt-1">
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
      <li class="mt-1">
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
    </ul>
  </span>
</template>

<script>
import { IconSettings, IconCircleCheck, IconInfoCircle, IconBrandStripe, IconInnerShadowTop, IconRouteAltLeft } from '@tabler/icons-vue'
import { ref } from 'vue'

const isConnected = ref(false)

export default {
  name: 'PaymentSettings',
  components: {
    IconSettings,
    IconCircleCheck,
    IconRouteAltLeft,
    IconInfoCircle,
    IconInnerShadowTop,
    IconBrandStripe
  },
  inject: ['backgroundColor', 'save', 'currencies', 't', 'isPaymentConnected'],
  props: {
    field: {
      type: Object,
      required: true
    }
  },
  emits: ['click-condition', 'click-description'],
  data () {
    return {
      isLoading: false
    }
  },
  computed: {
    isConnected: () => isConnected.value,
    isOauthSuccess () {
      return document.location.search?.includes('stripe_connect_success')
    },
    redirectUri () {
      return document.location.origin + '/auth/stripe_connect/callback'
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
    oauthState () {
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

    isConnected.value ||= this.isPaymentConnected

    if (!this.isConnected) {
      this.checkStatus()
    }
  },
  methods: {
    checkStatus () {
      this.isLoading = true

      fetch('/api/stripe_connect').then(async (resp) => {
        const { status } = await resp.json()

        if (status === 'connected') {
          isConnected.value = true
        }
      }).finally(() => {
        this.isLoading = false
      })
    },
    closeDropdown () {
      document.activeElement.blur()
    }
  }
}
</script>

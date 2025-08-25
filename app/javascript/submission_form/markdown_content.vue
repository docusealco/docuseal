<template>
  <span>
    <span v-if="textOnly">
      {{ dom.body.textContent }}
    </span>
    <template v-else>
      <template
        v-for="(item, index) in nodes || dom.body.childNodes"
        :key="index"
      >
        <a
          v-if="item.tagName === 'A' && item.getAttribute('href') !== 'undefined'"
          :href="sanitizeUrl(item.getAttribute('href'))"
          rel="noopener noreferrer nofollow"
          :class="item.getAttribute('class') || 'link'"
          target="_blank"
        >
          <MarkdownContent :nodes="item.childNodes" />
        </a>
        <component
          :is="item.tagName"
          v-else-if="safeTags.includes(item.tagName)"
        >
          <MarkdownContent :nodes="item.childNodes" />
        </component>
        <br v-else-if="item.tagName === 'BR' || item.nodeValue === '\n'">
        <template v-else>
          {{ item.textContent }}
        </template>
      </template>
    </template>
  </span>
</template>

<script>
import snarkdown from 'snarkdown'
import { sanitizeUrl } from '@braintree/sanitize-url'

export default {
  name: 'MarkdownContent',
  props: {
    string: {
      type: String,
      required: false,
      default: ''
    },
    nodes: {
      type: [Array, Object],
      require: false,
      default: null
    },
    textOnly: {
      type: Boolean,
      required: false,
      default: false
    }
  },
  computed: {
    safeTags () {
      return ['UL', 'I', 'EM', 'B', 'STRONG', 'P']
    },
    dom () {
      const text = this.string.replace(/(?<!\(\s*)(https?:\/\/[^\s)]+)(?!\s*\))/g, (url) => `[${url}](${url})`)

      return new DOMParser().parseFromString(snarkdown(text.replace(/\n/g, '<br>')), 'text/html')
    }
  },
  methods: {
    sanitizeUrl
  }
}
</script>

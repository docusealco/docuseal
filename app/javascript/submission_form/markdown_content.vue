<template>
  <span>
    <template
      v-for="(item, index) in items"
      :key="index"
    >
      <a
        v-if="item.startsWith('<a') && item.endsWith('</a>')"
        :href="sanitizeHref(extractAttr(item, 'href'))"
        rel="noopener noreferrer nofollow"
        :class="extractAttr(item, 'class') || 'link'"
        target="_blank"
      >
        {{ extractText(item) }}
      </a>
      <b
        v-else-if="item.startsWith('<b>') || item.startsWith('<strong>')"
      >
        {{ extractText(item) }}
      </b>
      <i
        v-else-if="item.startsWith('<i>') || item.startsWith('<em>')"
      >
        {{ extractText(item) }}
      </i>
      <br
        v-else-if="item === '<br>' || item === '\n'"
      >
      <template
        v-else
      >
        {{ item }}
      </template>
    </template>
  </span>
</template>

<script>
import snarkdown from 'snarkdown'

const htmlSplitRegexp = /(<a.+?<\/a>|<i>.+?<\/i>|<b>.+?<\/b>|<em>.+?<\/em>|<strong>.+?<\/strong>|<br>)/

export default {
  name: 'MarkdownContent',
  props: {
    string: {
      type: String,
      required: false,
      default: ''
    }
  },
  computed: {
    items () {
      return snarkdown(this.string.replace(/\n/g, '<br>')).split(htmlSplitRegexp)
    }
  },
  methods: {
    sanitizeHref (href) {
      if (href && href.trim().match(/^((?:https?:\/\/)|\/)/)) {
        return href.replace(/javascript:/g, '')
      }
    },
    extractAttr (text, attr) {
      if (text.includes(attr)) {
        return text.split(attr).pop().split('"')[1]
      }
    },
    extractText (text) {
      if (text) {
        return text.match(/>(.+?)</)?.[1]
      }
    }
  }
}
</script>

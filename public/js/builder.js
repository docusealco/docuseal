// Self-hosted embed shim for the <docuseal-builder> web component.
// Upstream `EmbedScriptsController#show` returns an "Upgrade to Pro" stub;
// the Rails static middleware serves this file ahead of that route, so the
// real shim wins without touching the controller.
//
// What this does:
//   1. Reads the JWT minted by the embedding app from `data-token`.
//   2. Decodes its payload to discover `document_urls`, `name`,
//      `external_id`, and `template_id`.
//   3. Iframes either `/templates/:id/edit` (existing template) or
//      `/new?url=...&filename=...&external_id=...` (fresh upload flow).
//   4. Relays the inner builder's `save` postMessage up as a DOM
//      `CustomEvent('save')` on the outer element so `@docuseal/react`'s
//      `onSave` callback fires.
//
// JWT signature is NOT verified here — host DocuSeal session cookies carry
// auth, and the calling app signs with the shared secret it controls.
(function () {
  function decodeJwtPayload(token) {
    try {
      var part = token.split('.')[1]
      if (!part) return null
      var b64 = part.replace(/-/g, '+').replace(/_/g, '/')
      var pad = b64.length % 4
      if (pad) b64 += '='.repeat(4 - pad)
      return JSON.parse(decodeURIComponent(escape(atob(b64))))
    } catch (e) {
      return null
    }
  }

  // Discover the DocuSeal host from this script's own src so embedders
  // don't have to set data-host on every element.
  var SCRIPT_HOST = (function () {
    try {
      var current = document.currentScript
      var src = current ? current.src : ''
      if (!src) {
        var all = document.getElementsByTagName('script')
        for (var i = 0; i < all.length; i++) {
          if (/\/js\/(builder|form)\.js/.test(all[i].src)) {
            src = all[i].src
            break
          }
        }
      }
      return src ? new URL(src).host : ''
    } catch (e) {
      return ''
    }
  })()

  // Relay `save` postMessage from the iframe (templates_builder fires it
  // after a successful manual SAVE) up as a DOM `save` CustomEvent on the
  // outer <docuseal-builder> element so React listeners can close the
  // embedding sheet.
  if (!window.__docusealEmbedListenerInstalled) {
    window.__docusealEmbedListenerInstalled = true
    window.addEventListener('message', function (ev) {
      var d = ev && ev.data
      if (!d || d.source !== 'docuseal-embed' || d.type !== 'save') return
      document.querySelectorAll('docuseal-builder, docuseal-form').forEach(function (el) {
        el.dispatchEvent(new CustomEvent('save', { detail: { template_id: d.template_id } }))
      })
    })
  }

  var EmbedBuilder = class extends HTMLElement {
    static get observedAttributes() {
      return ['data-token', 'data-host']
    }
    connectedCallback() {
      this._maybeMount()
    }
    attributeChangedCallback() {
      this._maybeMount()
    }
    _maybeMount() {
      if (this._mounted) return
      var token = this.getAttribute('data-token') || ''
      if (!token) return
      this._mounted = true
      var host = this.getAttribute('data-host') || SCRIPT_HOST || window.location.host
      var payload = decodeJwtPayload(token) || {}
      var docUrl = (payload.document_urls && payload.document_urls[0]) || ''
      var name = payload.name || 'Untitled'
      var filename = name.replace(/[^A-Za-z0-9_\-]+/g, '_') + '.pdf'

      // Match parent page scheme. Both ends run TLS locally (mkcert), so
      // https parent -> https iframe with no mixed-content blocking.
      var origin = window.location.protocol + '//' + host
      var src
      if (payload.template_id) {
        // Existing template: open the editor directly so prior field
        // edits are preserved. Posting to /new would create another
        // template and orphan the original.
        src = origin + '/templates/' + encodeURIComponent(payload.template_id) + '/edit'
      } else {
        var qs = new URLSearchParams()
        if (docUrl) qs.set('url', docUrl)
        qs.set('filename', filename)
        if (payload.external_id) qs.set('external_id', payload.external_id)
        src = origin + '/new?' + qs.toString()
      }
      var iframe = document.createElement('iframe')
      iframe.src = src
      iframe.style.cssText = 'width:100%;height:100%;min-height:600px;border:0;display:block'
      iframe.setAttribute('allow', 'clipboard-write')
      this.style.display = 'block'
      this.style.height = this.style.height || '100%'
      this.appendChild(iframe)
    }
  }

  if (!window.customElements.get('docuseal-builder')) {
    window.customElements.define('docuseal-builder', EmbedBuilder)
  }

  if (!window.customElements.get('docuseal-form')) {
    window.customElements.define('docuseal-form', class extends EmbedBuilder {})
  }
})()

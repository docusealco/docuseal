import { target, targetable } from '@github/catalyst/lib/targetable'

export default targetable(class extends HTMLElement {
  static [target.static] = ['form']

  connectedCallback () {
    const bridge = window.webkit?.messageHandlers?.native

    if (!bridge || !this.form) return

    const url = new URL(this.form.action)

    new FormData(this.form).forEach((value, key) => {
      if (key !== 'q' && value) url.searchParams.set(key, value)
    })

    this.declared = true

    bridge.postMessage({ type: 'search', op: 'add', url: url.pathname + url.search })
  }

  disconnectedCallback () {
    if (this.declared) {
      window.webkit?.messageHandlers?.native?.postMessage({ type: 'search', op: 'remove' })
    }
  }
})

let counter = 0

export default class extends HTMLElement {
  connectedCallback () {
    const bridge = window.webkit?.messageHandlers?.native

    if (!bridge) return

    const target = this.querySelector('a, button, [role="button"]') || this.firstElementChild

    if (!target && !this.dataset.native) return

    this.nativeId ||= `native-action-${++counter}`

    if (target) target.dataset.nativeId = this.nativeId

    bridge.postMessage({
      type: 'action',
      op: 'add',
      id: this.nativeId,
      title: this.dataset.label || target?.textContent.trim(),
      icon: this.dataset.icon,
      placement: this.dataset.placement || 'menu',
      native: this.dataset.native,
      url: this.dataset.url,
      accept: this.dataset.accept,
      destructive: this.dataset.destructive === 'true'
    })
  }

  disconnectedCallback () {
    if (this.nativeId) {
      window.webkit?.messageHandlers?.native?.postMessage({ type: 'action', op: 'remove', id: this.nativeId })
    }
  }
}

export default class extends HTMLElement {
  connectedCallback () {
    this.addEventListener('click', this.dispatch)
  }

  disconnectedCallback () {
    this.removeEventListener('click', this.dispatch)
  }

  dispatch = async () => {
    const bridge = window.webkit?.messageHandlers?.modal

    if (!bridge || this.dataset.loading) return

    let detail = this.dataset.detail || 'null'

    if (this.dataset.src) {
      this.dataset.loading = 'true'

      try {
        const response = await fetch(this.dataset.src, { headers: { Accept: 'application/json' } })

        if (!response.ok) return

        detail = await response.text()
      } catch {
        return
      } finally {
        delete this.dataset.loading
      }
    }

    bridge.postMessage({ action: 'dispatch', name: this.dataset.name, detail })
  }
}

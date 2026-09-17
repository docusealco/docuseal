import { renderStreamMessage } from '@hotwired/turbo'

export default class extends HTMLElement {
  connectedCallback () {
    if (!this.dataset.src) return

    this.observer = new IntersectionObserver((entries) => {
      if (entries.some((entry) => entry.isIntersecting)) {
        this.load()
      }
    }, { rootMargin: '400px' })

    this.observer.observe(this)
  }

  disconnectedCallback () {
    this.observer?.disconnect()
  }

  load () {
    if (this.loading || !this.dataset.src) return

    this.loading = true

    fetch(this.dataset.src, {
      headers: { 'X-Turbo-Infinite-Scroll': 'true' }
    }).then(async (response) => {
      if (!response.ok) return

      delete this.dataset.src

      renderStreamMessage(await response.text())
    }).finally(() => {
      this.loading = false
    })
  }
}

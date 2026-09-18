import { renderStreamMessage, session } from '@hotwired/turbo'

export default class extends HTMLElement {
  connectedCallback () {
    if (this.dataset.limit) this.replaceLimitParam()

    if (!this.dataset.src) {
      this.remove()

      return
    }

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

  replaceLimitParam () {
    const url = new URL(window.location.href)

    url.searchParams.set('limit', this.dataset.limit)

    session.history.replace(url, session.history.restorationIdentifier)
    session.view.lastRenderedLocation = url
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

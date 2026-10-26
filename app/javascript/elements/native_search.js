export default class extends HTMLElement {
  connectedCallback () {
    document.addEventListener('native:search', this.onSearch)
    document.addEventListener('turbo:before-cache', this.onBeforeCache)
    this.addEventListener('touchstart', this.onTouchStart, { passive: true })
    this.addEventListener('scroll', this.onScroll, { capture: true, passive: true })

    const scroller = this.querySelector('[data-scroll-top]')

    if (scroller) scroller.scrollTop = scroller.dataset.scrollTop
  }

  disconnectedCallback () {
    document.removeEventListener('native:search', this.onSearch)
    document.removeEventListener('turbo:before-cache', this.onBeforeCache)
  }

  onBeforeCache = () => {
    if (this.scroller) this.scroller.dataset.scrollTop = this.scroller.scrollTop
  }

  onTouchStart = () => {
    this.isTouching = true
  }

  onScroll = (event) => {
    this.scroller = event.target

    if (!this.isTouching) return

    this.isTouching = false

    window.webkit?.messageHandlers?.native?.postMessage({ type: 'dismiss-keyboard' })
  }

  onSearch = (event) => {
    const query = (event.detail?.q || '').trim()

    if (query === (this.dataset.q || '')) return

    this.dataset.q = query

    const url = new URL(this.frame.src || this.dataset.src, window.location.href)

    url.searchParams.delete('page')

    if (query) {
      url.searchParams.set('q', query)
    } else {
      url.searchParams.delete('q')
    }

    this.frame.src = url.toString()
  }

  get frame () {
    return this.querySelector('turbo-frame')
  }
}

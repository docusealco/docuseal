export default class extends HTMLElement {
  connectedCallback () {
    document.addEventListener('native:search', this.onSearch)
  }

  disconnectedCallback () {
    document.removeEventListener('native:search', this.onSearch)
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

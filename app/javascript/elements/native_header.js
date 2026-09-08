export default class extends HTMLElement {
  connectedCallback () {
    window.webkit?.messageHandlers?.native?.postMessage({
      type: 'header',
      op: 'add',
      title: this.dataset.label || this.querySelector('h1')?.textContent?.trim() || '',
      search: 'search' in this.dataset
    })
  }

  disconnectedCallback () {
    window.webkit?.messageHandlers?.native?.postMessage({ type: 'header', op: 'remove' })
  }
}

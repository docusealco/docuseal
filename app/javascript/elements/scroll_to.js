export default class extends HTMLElement {
  connectedCallback () {
    this.selector = document.getElementById(this.dataset.selectorId)

    this.addEventListener('click', () => {
      this.selector.scrollIntoView({ behavior: 'smooth', block: 'start' })
      history.replaceState(null, null, `#${this.dataset.selectorId}`)
    })
  }
}

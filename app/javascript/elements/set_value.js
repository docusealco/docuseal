export default class extends HTMLElement {
  connectedCallback () {
    const input = this.dataset.inputId ? document.getElementById(this.dataset.inputId) : this.querySelector('input')

    this.firstElementChild.addEventListener(this.dataset.on || 'click', () => {
      if (this.dataset.emptyOnly !== 'true' || !input.value) {
        input.value = this.dataset.value
      }
    })
  }
}

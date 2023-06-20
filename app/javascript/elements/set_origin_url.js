export default class extends HTMLElement {
  connectedCallback () {
    if (this.dataset.inputId) {
      document.getElementById(this.dataset.inputId).value = document.location.origin
    }
  }
}

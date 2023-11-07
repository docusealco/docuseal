export default class extends HTMLElement {
  connectedCallback () {
    this.querySelector('form').requestSubmit()
  }
}

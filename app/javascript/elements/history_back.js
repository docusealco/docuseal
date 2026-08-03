export default class extends HTMLElement {
  connectedCallback () {
    this.addEventListener('click', this.onClick)
  }

  disconnectedCallback () {
    this.removeEventListener('click', this.onClick)
  }

  onClick = (e) => {
    e.preventDefault()

    window.history.back()
  }
}

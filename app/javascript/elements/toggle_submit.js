export default class extends HTMLElement {
  connectedCallback () {
    this.button.disabled = false

    this.form.addEventListener('submit', () => {
      this.button.disabled = true
    })
  }

  disconnectedCallback () {
    this.button.disabled = false
  }

  get button () {
    return this.querySelector('[type="submit"]')
  }

  get form () {
    return this.querySelector('form') || this.closest('form')
  }
}

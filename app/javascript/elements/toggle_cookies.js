export default class extends HTMLElement {
  connectedCallback () {
    this.button.addEventListener('click', (e) => {
      const expirationDate = new Date()
      expirationDate.setFullYear(expirationDate.getFullYear() + 10)
      const expires = expirationDate.toUTCString()
      document.cookie = this.dataset.key + '=' + this.dataset.value + '; expires=' + expires + '; path=/'

      const form = this.closest('form')
      if (form) {
        e.preventDefault()
        form.requestSubmit(this.button)
      }
    })
  }

  get button () {
    return this.querySelector('button')
  }
}

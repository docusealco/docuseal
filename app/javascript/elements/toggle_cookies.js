export default class extends HTMLElement {
  connectedCallback () {
    this.button.addEventListener('click', () => {
      const expirationDate = new Date()

      expirationDate.setFullYear(expirationDate.getFullYear() + 10)

      const expires = expirationDate.toUTCString()

      document.cookie = this.dataset.key + '=' + this.dataset.value + '; expires=' + expires + '; path=/'
    })
  }

  get button () {
    return this.querySelector('button')
  }
}

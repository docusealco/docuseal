export default class extends HTMLElement {
  connectedCallback () {
    const maskedToken = this.input.value

    this.input.addEventListener('focus', () => {
      this.input.value = this.dataset.token
      this.input.select()
    })

    this.input.addEventListener('focusout', () => {
      this.input.value = maskedToken
    })
  }

  get input () {
    return this.querySelector('input')
  }
}

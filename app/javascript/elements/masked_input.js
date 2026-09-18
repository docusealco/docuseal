export default class extends HTMLElement {
  connectedCallback () {
    this.input.addEventListener('focus', () => {
      this.maskedToken = this.input.value
      this.input.value = this.dataset.token
      this.input.select()
    })

    this.input.addEventListener('focusout', () => {
      this.input.value = this.maskedToken
    })
  }

  get input () {
    return this.querySelector('input')
  }
}

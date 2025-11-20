export default class extends HTMLElement {
  connectedCallback () {
    const input = this.querySelector('input')
    const invalidMessage = this.dataset.invalidMessage || ''

    input.addEventListener('invalid', () => {
      input.setCustomValidity(input.value ? invalidMessage : '')
    })

    input.addEventListener('input', () => {
      input.setCustomValidity('')
    })
  }
}

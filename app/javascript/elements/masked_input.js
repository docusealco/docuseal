export default class extends HTMLElement {
  connectedCallback () {
    const maskedToken = this.input.value

    const hintId = `masked-input-hint-${Math.random().toString(36).slice(2, 8)}`
    const hint = document.createElement('span')
    hint.id = hintId
    hint.className = 'sr-only'
    hint.textContent = this.dataset.maskHint || 'Value is masked. Focus to reveal.'
    this.appendChild(hint)

    const existing = this.input.getAttribute('aria-describedby')
    this.input.setAttribute('aria-describedby', existing ? `${existing} ${hintId}` : hintId)

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

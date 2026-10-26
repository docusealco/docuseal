import { target, targetable } from '@github/catalyst/lib/targetable'

export default targetable(class extends HTMLElement {
  static [target.static] = [
    'prompt',
    'processing',
    'logo'
  ]

  connectedCallback () {
    this.form.addEventListener('submit', this.onSubmit)
  }

  disconnectedCallback () {
    this.form.removeEventListener('submit', this.onSubmit)
  }

  onSubmit = () => {
    this.prompt.classList.add('hidden')
    this.processing.classList.remove('hidden')
    this.logo.classList.add('animate-bounce')
  }

  get form () {
    return this.querySelector('form')
  }
})

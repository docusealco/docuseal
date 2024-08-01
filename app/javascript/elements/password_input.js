import { target, targetable } from '@github/catalyst/lib/targetable'

export default targetable(class extends HTMLElement {
  static [target.static] = [
    'visiblePasswordIcon',
    'hiddenPasswordIcon',
    'passwordInput',
    'togglePasswordVisibility'
  ]

  connectedCallback () {
    this.togglePasswordVisibility.addEventListener('click', this.handleTogglePasswordVisibility)
    document.addEventListener('turbo:submit-start', this.setInitialPasswordType)
  }

  disconnectedCallback () {
    this.togglePasswordVisibility.removeEventListener('click', this.handleTogglePasswordVisibility)
    document.removeEventListener('turbo:submit-start', this.setInitialPasswordType)
  }

  handleTogglePasswordVisibility = () => {
    this.passwordInput.type = this.passwordInput.type === 'password' ? 'text' : 'password'
    this.toggleIcon()
  }

  setInitialPasswordType = () => {
    this.passwordInput.type = 'password'
    this.toggleIcon()
  }

  toggleIcon = () => {
    this.visiblePasswordIcon.classList.toggle('hidden', this.passwordInput.type === 'password')
    this.hiddenPasswordIcon.classList.toggle('hidden', this.passwordInput.type === 'text')
  }
})

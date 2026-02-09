import { target, targetable } from '@github/catalyst/lib/targetable'

export default targetable(class extends HTMLElement {
  static [target.static] = [
    'visiblePasswordIcon',
    'hiddenPasswordIcon',
    'passwordInput',
    'togglePasswordVisibility'
  ]

  connectedCallback () {
    // Make toggle button keyboard accessible
    if (!this.togglePasswordVisibility.hasAttribute('tabindex')) {
      this.togglePasswordVisibility.setAttribute('tabindex', '0')
    }
    if (!this.togglePasswordVisibility.hasAttribute('role')) {
      this.togglePasswordVisibility.setAttribute('role', 'button')
    }

    this.togglePasswordVisibility.addEventListener('click', this.handleTogglePasswordVisibility)

    // Add keyboard support for Enter and Space keys
    this.handleKeydown = (e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault()
        this.handleTogglePasswordVisibility()
      }
    }
    this.togglePasswordVisibility.addEventListener('keydown', this.handleKeydown)

    document.addEventListener('turbo:submit-start', this.setInitialPasswordType)
  }

  disconnectedCallback () {
    this.togglePasswordVisibility.removeEventListener('click', this.handleTogglePasswordVisibility)
    this.togglePasswordVisibility.removeEventListener('keydown', this.handleKeydown)
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

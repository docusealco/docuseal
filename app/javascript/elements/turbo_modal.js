import { actionable } from '@github/catalyst/lib/actionable'

const FOCUSABLE = 'button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'

export default actionable(class extends HTMLElement {
  connectedCallback () {
    document.body.classList.add('overflow-hidden')

    this.setAttribute('role', 'dialog')
    this.setAttribute('aria-modal', 'true')

    this._previousFocus = document.activeElement

    document.addEventListener('keyup', this.onEscKey)
    document.addEventListener('keydown', this.onTabKey)
    document.addEventListener('turbo:before-cache', this.close)

    if (this.dataset.closeAfterSubmit !== 'false') {
      document.addEventListener('turbo:submit-end', this.onSubmit)
    }

    requestAnimationFrame(() => {
      const first = this.querySelector(FOCUSABLE)
      first?.focus()
    })
  }

  disconnectedCallback () {
    document.body.classList.remove('overflow-hidden')

    document.removeEventListener('keyup', this.onEscKey)
    document.removeEventListener('keydown', this.onTabKey)
    document.removeEventListener('turbo:submit-end', this.onSubmit)
    document.removeEventListener('turbo:before-cache', this.close)

    this._previousFocus?.focus()
  }

  onSubmit = (e) => {
    if (e.detail.success && e.detail?.formSubmission?.formElement?.dataset?.closeOnSubmit !== 'false') {
      this.close()
    }
  }

  onEscKey = (e) => {
    if (e.code === 'Escape') {
      this.close()
    }
  }

  onTabKey = (e) => {
    if (e.key !== 'Tab') return

    const focusable = Array.from(this.querySelectorAll(FOCUSABLE))
    if (focusable.length === 0) return

    const first = focusable[0]
    const last = focusable[focusable.length - 1]

    if (e.shiftKey) {
      if (document.activeElement === first) {
        e.preventDefault()
        last.focus()
      }
    } else {
      if (document.activeElement === last) {
        e.preventDefault()
        first.focus()
      }
    }
  }

  close = (e) => {
    e?.preventDefault()

    this.remove()
  }
})

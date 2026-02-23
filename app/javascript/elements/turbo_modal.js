import { actionable } from '@github/catalyst/lib/actionable'

export default actionable(class extends HTMLElement {
  connectedCallback () {
    document.body.classList.add('overflow-hidden')

    this.addEventListener('click', this.onClick)
    document.addEventListener('keyup', this.onEscKey)
    document.addEventListener('turbo:before-cache', this.close)

    if (this.dataset.closeAfterSubmit !== 'false') {
      document.addEventListener('turbo:submit-end', this.onSubmit)
    }
  }

  disconnectedCallback () {
    document.body.classList.remove('overflow-hidden')

    this.removeEventListener('click', this.onClick)
    document.removeEventListener('keyup', this.onEscKey)
    document.removeEventListener('turbo:submit-end', this.onSubmit)
    document.removeEventListener('turbo:before-cache', this.close)
  }

  onClick = (e) => {
    const isCloseButton = e.target.closest('[data-turbo-modal-close]')
    const isOutsideContent = !e.target.closest('[data-turbo-modal-content]')
    if (isCloseButton || isOutsideContent) {
      e.preventDefault()
      e.stopPropagation()
      this.close()
    }
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

  close = (e) => {
    e?.preventDefault()

    this.remove()
  }
})

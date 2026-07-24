import { actionable } from '@github/catalyst/lib/actionable'

export default actionable(class extends HTMLElement {
  connectedCallback () {
    document.body.classList.add('overflow-hidden')

    document.addEventListener('keyup', this.onEscKey)

    document.addEventListener('turbo:before-cache', this.onBeforeCache)

    if (this.dataset.closeAfterSubmit !== 'false') {
      document.addEventListener('turbo:submit-end', this.onSubmit)
    }
  }

  disconnectedCallback () {
    document.body.classList.remove('overflow-hidden')

    document.removeEventListener('keyup', this.onEscKey)
    document.removeEventListener('turbo:submit-end', this.onSubmit)
    document.removeEventListener('turbo:before-cache', this.onBeforeCache)
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

  onBeforeCache = () => {
    if (this.closest('turbo-frame')?.src) {
      this.remove()
    }
  }

  close = (e) => {
    e?.preventDefault()

    if (!this.closest('turbo-frame')?.src && window.history.length > 1) {
      window.history.back()
    } else {
      this.remove()
    }
  }
})

import { actionable } from '@github/catalyst/lib/actionable'

export default actionable(class extends HTMLElement {
  connectedCallback () {
    document.body.classList.add('overflow-hidden')

    document.addEventListener('keyup', this.onEscKey)

    document.addEventListener('turbo:before-cache', this.close)

    if (this.dataset.closeAfterSubmit !== 'false') {
      document.addEventListener('turbo:submit-end', this.onSubmit)
    }
  }

  disconnectedCallback () {
    document.body.classList.remove('overflow-hidden')

    document.removeEventListener('keyup', this.onEscKey)
    document.removeEventListener('turbo:submit-end', this.onSubmit)
    document.removeEventListener('turbo:before-cache', this.close)
  }

  onSubmit = (e) => {
    if (e.detail.success) {
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

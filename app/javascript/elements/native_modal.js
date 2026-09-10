export default class extends HTMLElement {
  connectedCallback () {
    document.addEventListener('turbo:submit-end', this.onSubmit)
  }

  disconnectedCallback () {
    document.removeEventListener('turbo:submit-end', this.onSubmit)
  }

  onSubmit = (e) => {
    if (!e.detail.success || e.detail.fetchResponse?.redirected) return
    if (this.dataset.closeAfterSubmit === 'false') return
    if (e.detail.formSubmission?.formElement?.dataset?.closeOnSubmit === 'false') return

    window.webkit?.messageHandlers?.modal?.postMessage({ action: 'submitted' })
  }
}

export default class extends HTMLElement {
  connectedCallback () {
    document.addEventListener('turbo:submit-end', this.onSubmit)
    this.addEventListener('click', this.onClick)
  }

  disconnectedCallback () {
    document.removeEventListener('turbo:submit-end', this.onSubmit)
  }

  onSubmit = (e) => {
    if (!e.detail.success) return
    if (e.detail.fetchResponse?.redirected && e.detail.fetchResponse.location.href !== window.location.href) return
    if (e.detail.formSubmission?.formElement?.method === 'get') return
    if (this.dataset.closeAfterSubmit === 'false') return
    if (e.detail.formSubmission?.formElement?.dataset?.closeOnSubmit === 'false') return
    if (e.detail.formSubmission?.formElement?.closest('native-event[data-on="submit"]')) return

    window.webkit?.messageHandlers?.modal?.postMessage({ action: 'submitted' })
  }

  onClick = () => {
    setTimeout(() => {
      if (document.documentElement.scrollHeight > window.innerHeight) {
        window.webkit?.messageHandlers?.modal?.postMessage({ action: 'expand' })
      }
    }, 300)
  }
}

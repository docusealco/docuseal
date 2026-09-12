export default class extends HTMLElement {
  connectedCallback () {
    if (this.dataset.on === 'submit') {
      document.addEventListener('turbo:submit-end', this.onSubmitEnd)
    } else {
      this.addEventListener('click', this.dispatch)
    }
  }

  disconnectedCallback () {
    document.removeEventListener('turbo:submit-end', this.onSubmitEnd)
    this.removeEventListener('click', this.dispatch)
  }

  onSubmitEnd = async (e) => {
    const form = e.detail.formSubmission?.formElement

    if (!e.detail.success || !form || !this.contains(form)) return

    this.post(JSON.stringify({ form: form.id, action: form.action, body: await e.detail.fetchResponse.responseText }))
  }

  dispatch = async () => {
    if (this.dataset.loading) return

    let detail = this.dataset.detail || 'null'

    if (this.dataset.src) {
      this.dataset.loading = 'true'

      try {
        const response = await fetch(this.dataset.src, { headers: { Accept: 'application/json' } })

        if (!response.ok) return

        detail = await response.text()
      } catch {
        return
      } finally {
        delete this.dataset.loading
      }
    }

    this.post(detail)
  }

  post (detail) {
    window.webkit?.messageHandlers?.modal?.postMessage({ action: 'dispatch', name: this.dataset.name, detail, dismiss: this.dataset.dismiss || 'true' })
  }
}

export default class extends HTMLElement {
  connectedCallback () {
    this.addEventListener('click', this.prompt)
    document.addEventListener('turbo:submit-end', this.onSubmitEnd)
  }

  disconnectedCallback () {
    this.removeEventListener('click', this.prompt)
    document.removeEventListener('turbo:submit-end', this.onSubmitEnd)
  }

  get form () {
    return this.querySelector('form')
  }

  prompt = () => {
    const label = this.form.querySelector('label')
    const input = this.form.querySelector(`#${CSS.escape(label.htmlFor)}`)
    const value = window.prompt(label.textContent.trim(), input.value)?.trim()

    if (!value || value === input.value) return

    input.value = value

    this.form.requestSubmit()
  }

  onSubmitEnd = (e) => {
    if (e.detail.success && e.detail.formSubmission?.formElement === this.form && this.dataset.refresh !== 'false') {
      window.Turbo.visit(window.location.href, { action: 'replace' })
    }
  }
}

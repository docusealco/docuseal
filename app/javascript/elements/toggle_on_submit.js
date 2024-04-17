export default class extends HTMLElement {
  connectedCallback () {
    document.addEventListener('turbo:submit-end', this.onSubmitEnd)

    this.form.addEventListener('submit', this.onSubmit)
  }

  disconnectedCallback () {
    document.removeEventListener('turbo:submit-end', this.onSubmitEnd)

    this.form.removeEventListener('submit', this.onSubmit)
  }

  onSubmit = () => {
    this.element.classList.add('invisible')
  }

  onSubmitEnd = (event) => {
    if (event.target === this.form) {
      const resp = event.detail?.formSubmission?.result?.fetchResponse?.response

      if (resp?.status / 100 === 2) {
        this.element.classList.remove('invisible')
      }
    }
  }

  get element () {
    return document.getElementById(this.dataset.elementId)
  }

  get form () {
    return this.closest('form')
  }
}

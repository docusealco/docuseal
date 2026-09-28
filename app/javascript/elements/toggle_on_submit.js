export default class extends HTMLElement {
  connectedCallback () {
    this.form.addEventListener('submit', this.onSubmit)
    this.form.addEventListener('turbo:before-fetch-response', this.onFetchResponse)
  }

  disconnectedCallback () {
    this.form.removeEventListener('submit', this.onSubmit)
    this.form.removeEventListener('turbo:before-fetch-response', this.onFetchResponse)
  }

  onSubmit = () => {
    this.element.classList.add('invisible')
  }

  onFetchResponse = (event) => {
    if (event.detail.fetchResponse.succeeded) {
      this.element.classList.remove('invisible')
    }
  }

  get element () {
    return document.getElementById(this.dataset.elementId)
  }

  get form () {
    return this.closest('form')
  }
}

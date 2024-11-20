export default class extends HTMLElement {
  connectedCallback () {
    this.dateFrom = this.dataset.fromValue
    this.dateTo = this.dataset.toValue
    this.dateFromInput = document.getElementById(this.dataset.fromId)
    this.dateToInput = document.getElementById(this.dataset.toId)

    this.button.addEventListener('click', () => {
      this.dateFromInput.value = this.dateFrom || ''
      this.dateToInput.value = this.dateTo || ''
    })
  }

  get button () {
    return this.querySelector('button')
  }
}

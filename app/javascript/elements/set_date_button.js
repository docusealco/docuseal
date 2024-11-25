export default class extends HTMLElement {
  connectedCallback () {
    this.button.addEventListener('click', () => {
      this.fromInput.value = this.dataset.fromValue || ''
      this.toInput.value = this.dataset.toValue || ''
    })
  }

  get button () {
    return this.querySelector('button')
  }

  get fromInput () {
    return document.getElementById(this.dataset.fromId)
  }

  get toInput () {
    return document.getElementById(this.dataset.toId)
  }
}

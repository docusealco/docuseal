export default class extends HTMLElement {
  connectedCallback () {
    this.input = document.getElementById(this.dataset.inputId)

    this.input.addEventListener('input', () => {
      if (this.input.value.trim().length > 0) {
        this.classList.remove('hidden')
      } else {
        this.classList.add('hidden')
        this.querySelectorAll('input').forEach(input => { input.value = '' })
      }
    })
  }
}

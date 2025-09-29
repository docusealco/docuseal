export default class extends HTMLElement {
  connectedCallback () {
    this.addEventListener('change', (event) => {
      const targetValue = this.dataset.value
      const selectorId = this.dataset.selectorId
      const targetElement = document.getElementById(selectorId)

      if (event.target.value === targetValue) {
        targetElement.classList.remove('hidden')
      } else {
        targetElement.classList.add('hidden')
        targetElement.value = ''
        event.target.form.requestSubmit()
      }
    })
  }
}

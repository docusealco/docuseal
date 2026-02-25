export default class extends HTMLElement {
  connectedCallback () {
    this.addEventListener('click', this.handleCheck)
    this.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault()
        this.handleCheck()
      }
    })
  }

  handleCheck = () => {
    if (this.element && !this.element.disabled && !this.element.checked) {
      this.element.checked = true
      this.element.dispatchEvent(new Event('change', { bubbles: true }))
    }
  }

  get element () {
    return document.getElementById(this.dataset.elementId)
  }
}

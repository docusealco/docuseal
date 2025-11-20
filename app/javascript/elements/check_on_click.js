export default class extends HTMLElement {
  connectedCallback () {
    this.addEventListener('click', () => {
      if (this.element && !this.element.disabled && !this.element.checked) {
        this.element.checked = true
        this.element.dispatchEvent(new Event('change', { bubbles: true }))
      }
    })
  }

  get element () {
    return document.getElementById(this.dataset.elementId)
  }
}

export default class extends HTMLElement {
  connectedCallback () {
    const originalFontValue = this.field.style.fontSize

    if (this.field.scrollHeight > this.field.clientHeight) {
      this.field.style.fontSize = `calc(${originalFontValue} / 1.5)`
      this.field.style.lineHeight = `calc(${this.field.style.fontSize} * 1.3)`

      if (this.field.scrollHeight > this.field.clientHeight) {
        this.field.style.fontSize = `calc(${originalFontValue} / 2.0)`
        this.field.style.lineHeight = `calc(${this.field.style.fontSize} * 1.3)`
      }
    }

    this.field.classList.remove('hidden')
  }

  get field () {
    return this.closest('field-value')
  }
}

export default class extends HTMLElement {
  connectedCallback () {
    this.resize()

    this.textarea.addEventListener('input', () => this.resize())
  }

  resize () {
    if (this.textarea.clientHeight < this.textarea.scrollHeight) {
      this.textarea.style.height = `${this.textarea.scrollHeight + 5}px`
    }
  }

  get textarea () {
    return this.querySelector('textarea')
  }
}

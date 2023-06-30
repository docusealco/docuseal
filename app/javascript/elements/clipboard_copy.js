export default class extends HTMLElement {
  connectedCallback () {
    this.clearChecked()

    this.addEventListener('click', (e) => {
      e.stopPropagation()

      navigator.clipboard.writeText(this.dataset.text || this.innerText.trim())
    })
  }

  clearChecked () {
    this.querySelectorAll('input').forEach((e) => {
      e.checked = false
    })
  }
}

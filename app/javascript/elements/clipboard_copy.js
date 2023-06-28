export default class extends HTMLElement {
  connectedCallback () {
    this.addEventListener('click', (e) => {
      e.stopPropagation()

      navigator.clipboard.writeText(this.dataset.text || this.innerText.trim())
    })
  }

  disconnectedCallback () {
    this.querySelectorAll('input').forEach((e) => {
      e.checked = false
    })
  }
}

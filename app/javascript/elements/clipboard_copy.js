export default class extends HTMLElement {
  connectedCallback () {
    this.clearChecked()

    this.addEventListener('click', (e) => {
      e.stopPropagation()

      const text = this.dataset.text || this.innerText.trim()

      if (navigator.clipboard) {
        navigator.clipboard.writeText(text)
      } else {
        if (e.target.tagName !== 'INPUT') {
          alert(`Clipboard not available. Make sure you're using https://\nCopy text: ${text}`)
        }
      }
    })
  }

  clearChecked () {
    this.querySelectorAll('input').forEach((e) => {
      e.checked = false
    })
  }
}

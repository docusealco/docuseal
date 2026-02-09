export default class extends HTMLElement {
  connectedCallback () {
    this.clearChecked()

    // Make element keyboard accessible
    if (!this.hasAttribute('tabindex')) {
      this.setAttribute('tabindex', '0')
    }
    if (!this.hasAttribute('role')) {
      this.setAttribute('role', 'button')
    }

    const copyToClipboard = (e) => {
      const text = this.dataset.text || this.innerText.trim()

      if (navigator.clipboard) {
        navigator.clipboard.writeText(text)
      } else {
        if (e.target.tagName !== 'INPUT') {
          alert(`Clipboard not available. Make sure you're using https://\nCopy text: ${text}`)
        }
      }
    }

    this.addEventListener('click', copyToClipboard)

    // Add keyboard support for Enter and Space keys
    this.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault()
        copyToClipboard(e)
      }
    })
  }

  clearChecked () {
    this.querySelectorAll('input').forEach((e) => {
      e.checked = false
    })
  }
}

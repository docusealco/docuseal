export default class extends HTMLElement {
  connectedCallback () {
    this.addEventListener('turbo:morph-element', this.onMorph)

    this.show()
  }

  disconnectedCallback () {
    this.removeEventListener('turbo:morph-element', this.onMorph)

    clearTimeout(this.closeTimeout)
  }

  onMorph = (event) => {
    if (event.target !== this) return

    this.show()
  }

  show () {
    clearTimeout(this.closeTimeout)

    this.hideAnimation?.cancel()

    this.animate([
      { transform: 'translateY(-100%)', opacity: 0 },
      { transform: 'translateY(0)', opacity: 1 }
    ], { duration: 200, easing: 'cubic-bezier(0.34, 1.56, 0.64, 1)' })

    this.closeTimeout = setTimeout(this.close, 2000)
  }

  close = () => {
    clearTimeout(this.closeTimeout)

    this.hideAnimation = this.animate([
      { transform: 'translateY(0)', opacity: 1 },
      { transform: 'translateY(-100%)', opacity: 0 }
    ], { duration: 150, easing: 'ease-in', fill: 'forwards' })

    this.hideAnimation.onfinish = () => this.remove()
  }
}

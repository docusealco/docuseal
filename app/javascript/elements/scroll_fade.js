export default class extends HTMLElement {
  connectedCallback () {
    this.addEventListener('scroll', this.updateFade, { passive: true })
    window.addEventListener('resize', this.updateFade)

    this.updateFade()
  }

  disconnectedCallback () {
    window.removeEventListener('resize', this.updateFade)
  }

  updateFade = () => {
    const maxScroll = this.scrollWidth - this.clientWidth
    const fadeGradient = {
      right: 'linear-gradient(to right, black calc(100% - 24px), transparent)',
      left: 'linear-gradient(to right, transparent, black 24px)',
      both: 'linear-gradient(to right, transparent, black 24px, black calc(100% - 24px), transparent)'
    }

    let state = 'none'

    if (maxScroll > 4) {
      if (this.scrollLeft <= 4) {
        state = 'right'
      } else if (this.scrollLeft >= maxScroll - 4) {
        state = 'left'
      } else {
        state = 'both'
      }
    }

    this.applyFade(fadeGradient[state] || '')
  }

  applyFade (gradient) {
    this.style.maskImage = gradient
    this.style.webkitMaskImage = gradient
  }
}

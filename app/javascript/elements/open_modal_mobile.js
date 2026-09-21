export default class extends HTMLElement {
  connectedCallback () {
    this.addEventListener('pointerdown', this.onPointerdown)
  }

  onPointerdown = (event) => {
    if (this.dataset.disabled === 'true') return
    if (/Hotwire Native/.test(navigator.userAgent)) return
    if (!this.isMobile()) return
    if (window.innerWidth >= 768) return

    const link = event.target.closest('a[data-turbo-frame]')

    if (link) link.dataset.turboFrame = '_top'
  }

  isMobile () {
    const isTouchWebkit = 'ontouchstart' in window && navigator.maxTouchPoints > 0 && /AppleWebKit|android/i.test(navigator.userAgent)

    return isTouchWebkit || /iPhone|iPad|iPod/i.test(navigator.userAgent)
  }
}

export default class extends HTMLElement {
  connectedCallback () {
    if (this.dataset.disabled === 'true') return
    if (!this.isMobile()) return
    if (window.innerWidth >= 768) return

    this.querySelectorAll('a[data-turbo-frame]').forEach((link) => {
      link.dataset.turboFrame = '_top'
    })
  }

  isMobile () {
    const isTouchWebkit = 'ontouchstart' in window && navigator.maxTouchPoints > 0 && /AppleWebKit|android/i.test(navigator.userAgent)

    return isTouchWebkit || /iPhone|iPad|iPod/i.test(navigator.userAgent)
  }
}

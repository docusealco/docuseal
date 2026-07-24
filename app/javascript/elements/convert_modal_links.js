export default class extends HTMLElement {
  connectedCallback () {
    if (!this.isMobile()) return

    document.querySelectorAll('a[data-turbo-frame="modal"]').forEach((link) => {
      link.dataset.turboFrame = '_top'
    })
  }

  isMobile () {
    const isTouchWebkit = 'ontouchstart' in window && navigator.maxTouchPoints > 0 && /AppleWebKit|android/i.test(navigator.userAgent)

    return isTouchWebkit || /iPhone|iPad|iPod/i.test(navigator.userAgent)
  }
}

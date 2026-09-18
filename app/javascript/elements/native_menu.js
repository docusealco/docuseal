let counter = 0

export default class extends HTMLElement {
  connectedCallback () {
    if (window.webkit?.messageHandlers?.native) {
      this.addEventListener('click', this.onClick)
    } else {
      document.addEventListener('pointerdown', this.onPointerDown)
    }
  }

  disconnectedCallback () {
    this.removeEventListener('click', this.onClick)
    document.removeEventListener('pointerdown', this.onPointerDown)
  }

  onPointerDown = (event) => {
    if (this.contains(document.activeElement) && !this.contains(event.target)) {
      document.activeElement.blur()
    }
  }

  onClick = (event) => {
    if (event.target.closest('native-menu-action')) return

    const rect = this.firstElementChild.getBoundingClientRect()

    const items = [...this.querySelectorAll('native-menu-action')].map((action) => {
      const target = action.querySelector('a, button, [role="button"]') || action.firstElementChild

      target.dataset.nativeId ||= `native-menu-${++counter}`

      return {
        id: target.dataset.nativeId,
        title: action.dataset.label || target.textContent.trim(),
        icon: action.dataset.icon,
        destructive: action.dataset.destructive === 'true',
        selected: action.dataset.selected === 'true',
        haptic: action.dataset.haptic === 'true'
      }
    })

    window.webkit.messageHandlers.native.postMessage({
      type: 'menu',
      rect: { x: rect.left + window.scrollX, y: rect.top + window.scrollY, width: rect.width, height: rect.height },
      items
    })
  }
}

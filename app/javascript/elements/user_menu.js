export default class extends HTMLElement {
  connectedCallback () {
    this._trigger = this.querySelector('[aria-haspopup]')
    this._menu = this.querySelector('ul')

    if (!this._trigger || !this._menu) return

    this._menu.setAttribute('role', 'menu')
    this._menu.querySelectorAll('a[href], button').forEach((el) => {
      el.setAttribute('role', 'menuitem')
    })

    this.addEventListener('focusin', this._onFocusin)
    this.addEventListener('focusout', this._onFocusout)
    this._trigger.addEventListener('keydown', this._onTriggerKeydown)
    this._menu.addEventListener('keydown', this._onMenuKeydown)
  }

  _onFocusin = () => {
    this._trigger.setAttribute('aria-expanded', 'true')
  }

  _onFocusout = (e) => {
    if (!this.contains(e.relatedTarget)) {
      this._trigger.setAttribute('aria-expanded', 'false')
    }
  }

  _onTriggerKeydown = (e) => {
    if (e.key === 'Enter' || e.key === ' ' || e.key === 'ArrowDown') {
      e.preventDefault()
      this._focusItem(0)
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      this._focusItem(-1)
    }
  }

  _onMenuKeydown = (e) => {
    const items = this._menuItems()
    const idx = items.indexOf(document.activeElement)

    if (e.key === 'ArrowDown') {
      e.preventDefault()
      items[(idx + 1) % items.length]?.focus()
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      items[(idx - 1 + items.length) % items.length]?.focus()
    } else if (e.key === 'Home') {
      e.preventDefault()
      items[0]?.focus()
    } else if (e.key === 'End') {
      e.preventDefault()
      items[items.length - 1]?.focus()
    } else if (e.key === 'Escape') {
      e.preventDefault()
      this._closeMenu()
    }
  }

  _menuItems () {
    return Array.from(this._menu.querySelectorAll('a[href], button:not([disabled])'))
  }

  _focusItem (idx) {
    const items = this._menuItems()
    const target = idx >= 0 ? items[idx] : items[items.length + idx]
    target?.focus()
  }

  _closeMenu () {
    // Force-hide while focusing trigger to prevent CSS :focus-within from re-opening it
    this._menu.style.setProperty('display', 'none', 'important')
    this._trigger.setAttribute('aria-expanded', 'false')
    this._trigger.focus()
    this._trigger.addEventListener('blur', () => {
      this._menu.style.removeProperty('display')
    }, { once: true })
  }
}

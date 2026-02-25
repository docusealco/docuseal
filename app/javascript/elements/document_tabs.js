export default class extends HTMLElement {
  connectedCallback () {
    this._tabs = Array.from(this.querySelectorAll('[role="tab"]'))
    this._panels = Array.from(this.querySelectorAll('[role="tabpanel"]'))

    this._tabs.forEach((tab) => {
      tab.addEventListener('click', () => this._selectTab(tab))
      tab.addEventListener('keydown', (e) => this._onKeydown(e))
    })

    const saved = localStorage.getItem('docuseal_document_view')
    const savedTab = saved && this._tabs.find((t) => t.id === saved)
    this._selectTab(savedTab || this._tabs[0], false)
  }

  _selectTab (selectedTab, save = true) {
    this._tabs.forEach((tab) => {
      const isSelected = tab === selectedTab
      tab.setAttribute('aria-selected', isSelected ? 'true' : 'false')
      tab.setAttribute('tabindex', isSelected ? '0' : '-1')
      tab.classList.toggle('border-primary', isSelected)
      tab.classList.toggle('text-primary', isSelected)
      tab.classList.toggle('border-transparent', !isSelected)
      tab.classList.toggle('text-base-content', !isSelected)
    })
    this._panels.forEach((panel) => {
      panel.hidden = panel.id !== selectedTab.getAttribute('aria-controls')
    })
    if (save) localStorage.setItem('docuseal_document_view', selectedTab.id)
  }

  _onKeydown (e) {
    const tabs = this._tabs
    const idx = tabs.indexOf(e.currentTarget)
    let next
    if (e.key === 'ArrowRight') next = tabs[(idx + 1) % tabs.length]
    else if (e.key === 'ArrowLeft') next = tabs[(idx - 1 + tabs.length) % tabs.length]
    else if (e.key === 'Home') next = tabs[0]
    else if (e.key === 'End') next = tabs[tabs.length - 1]
    else return
    e.preventDefault()
    this._selectTab(next)
    next.focus()
  }
}

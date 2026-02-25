import { actionable } from '@github/catalyst/lib/actionable'

export default actionable(class extends HTMLElement {
  trigger (event) {
    const elementIds = JSON.parse(this.dataset.elementIds)

    if (event.target.type === 'checkbox') {
      elementIds.forEach((elementId) => {
        const el = document.getElementById(elementId)
        if (!el) return
        el.classList.toggle('hidden')
        el.setAttribute('aria-hidden', el.classList.contains('hidden') ? 'true' : 'false')
      })
      event.target.setAttribute('aria-expanded', event.target.checked ? 'true' : 'false')
    } else {
      elementIds.forEach((elementId) => {
        const el = document.getElementById(elementId)
        if (!el) return
        const hide = (event.target.dataset.toggleId || event.target.value) !== elementId
        el.classList.toggle('hidden', hide)
        el.setAttribute('aria-hidden', hide ? 'true' : 'false')
      })
    }

    if (this.dataset.focusId) {
      document.getElementById(this.dataset.focusId)?.focus()
    }
  }
})

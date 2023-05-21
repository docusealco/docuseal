import { actionable } from '@github/catalyst/lib/actionable'

export default actionable(class extends HTMLElement {
  trigger (event) {
    const elementIds = JSON.parse(this.dataset.elementIds)

    elementIds.forEach((elementId) => {
      document.getElementById(elementId).classList.toggle('hidden', event.target.value !== elementId)
    })
  }
})

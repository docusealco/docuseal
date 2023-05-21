import { actionable } from '@github/catalyst/lib/actionable'
import { targets, targetable } from '@github/catalyst/lib/targetable'

export default actionable(targetable(class extends HTMLElement {
  static [targets.static] = [
    'items'
  ]

  add (e) {
    const elem = document.createElement('input')
    elem.value = e.detail.uuid
    elem.name = `values[${this.dataset.fieldUuid}][]`

    this.prepend(elem)
  }
}))

import { actionable } from '@github/catalyst/lib/actionable'
import { targets, targetable } from '@github/catalyst/lib/targetable'

export default actionable(targetable(class extends HTMLElement {
  static [targets.static] = ['items']

  addItem (e) {
    e.preventDefault()

    const originalItem = this.items[0]
    const duplicateItem = originalItem.cloneNode(true)
    const uniqueId = Math.floor(Math.random() * 10 ** 16)

    duplicateItem.querySelectorAll("select, textarea, input:not([type='hidden'])").forEach((input) => {
      input.value = ''
      input.checked = false
      input.removeAttribute('selected')
    })

    duplicateItem.querySelectorAll('select, textarea, input').forEach((input) => {
      input.name = input.name.replace('[1]', `[${uniqueId}]`)
    })

    duplicateItem.querySelectorAll('a.hidden').forEach((button) => button.classList.toggle('hidden'))

    originalItem.parentNode.append(duplicateItem)
  }

  removeItem (e) {
    e.preventDefault()

    this.items.find((item) => item.contains(e.target))?.remove()
  }
}))

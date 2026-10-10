import { actionable } from '@github/catalyst/lib/actionable'
import { targets, targetable } from '@github/catalyst/lib/targetable'

export default actionable(targetable(class extends HTMLElement {
  static [targets.static] = ['items', 'groups']

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

    this.toggleMultipleClasses()

    duplicateItem.querySelector("input:not([type='hidden'])")?.focus()
  }

  removeItem (e) {
    e.preventDefault()

    this.items.find((item) => item.contains(e.target))?.remove()

    this.toggleMultipleClasses()
  }

  toggleMultipleClasses () {
    const isMultiple = this.items.length > 1
    const elements = [...this.items, ...this.groups]

    elements.forEach((element) => {
      const classes = element.dataset.multipleClasses || this.dataset.multipleClasses

      classes?.split(' ').forEach((cls) => element.classList.toggle(cls, isMultiple))
    })
  }
}))

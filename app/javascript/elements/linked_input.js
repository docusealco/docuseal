export default class extends HTMLElement {
  connectedCallback () {
    if (this.target) {
      this.input.value = this.target.value

      this.target.addEventListener('input', (e) => {
        this.input.value = e.target.value
      })

      this.target.addEventListener('linked-input.update', (e) => {
        this.input.value = e.target.value
      })
    }
  }

  get input () {
    return this.querySelector('input')
  }

  get target () {
    if (this.dataset.targetId) {
      const listItem = this.closest('[data-targets="dynamic-list.items"]')

      if (listItem) {
        return listItem.querySelector(`#${this.dataset.targetId}`)
      } else {
        return document.getElementById(this.dataset.targetId)
      }
    }
  }
}

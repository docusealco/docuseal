export default class extends HTMLElement {
  connectedCallback () {
    this.input.addEventListener('change', (event) => {
      if (!this.target) return

      const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value
      const dataValue = this.dataset.value === 'false' ? false : this.dataset.value || true

      if (this.dataset.attribute) {
        this.target[this.dataset.attribute] = value === dataValue
      }

      if (this.dataset.className) {
        this.target.classList.toggle(this.dataset.className, value !== dataValue)

        if (this.dataset.className === 'hidden' && this.target.tagName === 'INPUT') {
          this.target.disabled = event.target.value !== this.dataset.value
        }
      }

      if (this.dataset.attribute === 'disabled') {
        this.target.value = ''
      }
    })
  }

  get input () {
    return this.querySelector('input[type="checkbox"]') || this.querySelector('select')
  }

  get target () {
    return document.getElementById(this.dataset.targetId)
  }
}

export default class extends HTMLElement {
  connectedCallback () {
    if (this.dataset.indeterminate === 'true') {
      this.checkbox.indeterminate = true
      this.checkbox.readOnly = true
    }

    this.checkbox.addEventListener('click', () => {
      this.checkbox.setAttribute('name', this.dataset.name)

      if (this.showIndeterminateEl) {
        this.showIndeterminateEl.classList.add('hidden')
      }

      if (this.checkbox.readOnly) {
        this.checkbox.checked = this.checkbox.readOnly = false
      } else if (!this.checkbox.checked) {
        if (this.showIndeterminateEl) {
          this.showIndeterminateEl.classList.remove('hidden')
        }

        this.checkbox.setAttribute('name', this.dataset.indeterminateName)
        this.checkbox.checked = this.checkbox.readOnly = this.checkbox.indeterminate = true
      }
    })
  }

  get checkbox () {
    return this.querySelector('input[type="checkbox"]')
  }

  get showIndeterminateEl () {
    return document.getElementById(this.dataset.showIndeterminateId)
  }
}

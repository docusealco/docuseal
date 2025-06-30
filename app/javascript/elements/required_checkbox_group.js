export default class extends HTMLElement {
  connectedCallback () {
    this.querySelectorAll('input[type="checkbox"]').forEach(checkbox => {
      checkbox.addEventListener('change', this.handleChange)
    })
  }

  handleChange = () => {
    if (this.checkedCount !== 0) {
      this.closest('form')?.requestSubmit()
    }
  }

  get checkedCount () {
    return this.querySelectorAll('input[type="checkbox"]:checked').length
  }
}

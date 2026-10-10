export default class extends HTMLElement {
  connectedCallback () {
    this.form.addEventListener('change', this.toggle)

    this.toggle()
  }

  disconnectedCallback () {
    this.form.removeEventListener('change', this.toggle)
  }

  toggle = () => {
    const selector = this.dataset.names.split(' ').map((name) => `[name="${name}"]:checked:enabled`).join(', ')
    const isChecked = !!this.form.querySelector(selector)

    this.firstElementChild.classList.toggle('hidden', !isChecked)
    this.lastElementChild.classList.toggle('hidden', isChecked)
  }

  get form () {
    return this.closest('form')
  }
}

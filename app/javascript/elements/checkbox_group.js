export default class extends HTMLElement {
  connectedCallback () {
    this.items.forEach((item) => {
      item.addEventListener('change', (e) => {
        this.items.forEach((item) => {
          item.checked = item === e.target && e.target.checked
        })
      })
    })
  }

  get items () {
    return this.querySelectorAll('input[type="checkbox"]')
  }
}

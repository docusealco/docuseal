export default class extends HTMLElement {
  connectedCallback () {
    const button = this.querySelector('a, button')

    button.addEventListener('click', () => {
      this.dataset.classes.split(' ').forEach((cls) => {
        button.classList.toggle(cls)
      })
    })
  }
}

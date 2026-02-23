export default class extends HTMLElement {
  connectedCallback () {
    const button = this.querySelector('a, button, label')

    const target = this.dataset.targetId ? document.getElementById(this.dataset.targetId) : button

    button.addEventListener('click', () => {
      this.dataset.classes.split(' ').forEach((cls) => {
        if (this.dataset.action === 'remove') {
          target.classList.remove(cls)
        } else if (this.dataset.action === 'add') {
          target.classList.add(cls)
        } else {
          target.classList.toggle(cls)
        }
      })
    })
  }
}

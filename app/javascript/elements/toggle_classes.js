export default class extends HTMLElement {
  connectedCallback () {
    this.addEventListener('click', this.onClick)
  }

  onClick = (event) => {
    const button = this.querySelector('a, button, label')

    if (!button?.contains(event.target)) return

    const target = this.dataset.targetId ? document.getElementById(this.dataset.targetId) : button

    this.dataset.classes.split(' ').forEach((cls) => {
      if (this.dataset.action === 'remove') {
        target.classList.remove(cls)
      } else if (this.dataset.action === 'add') {
        target.classList.add(cls)
      } else {
        target.classList.toggle(cls)
      }
    })
  }
}

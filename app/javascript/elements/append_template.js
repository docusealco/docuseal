export default class extends HTMLElement {
  connectedCallback () {
    this.addEventListener('click', this.onClick)
  }

  disconnectedCallback () {
    this.removeEventListener('click', this.onClick)
  }

  onClick = (e) => {
    e.preventDefault()

    const target = document.getElementById(this.dataset.targetId)
    const item = this.querySelector('template').content.firstElementChild.cloneNode(true)

    item.querySelector('a').addEventListener('click', (e) => {
      e.preventDefault()

      item.remove()

      target.classList.toggle('hidden', !target.childElementCount)
    })

    target.append(item)
    target.classList.remove('hidden')

    item.querySelector('input').focus()
  }
}

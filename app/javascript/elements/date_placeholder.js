export default class extends HTMLElement {
  connectedCallback () {
    const input = this.querySelector('input')
    const placeholder = this.querySelector('span')

    input.addEventListener('change', () => {
      placeholder.classList.toggle('hidden', !!input.value)
    })
  }
}

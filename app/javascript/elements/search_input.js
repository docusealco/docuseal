export default class extends HTMLElement {
  connectedCallback () {
    this.button.addEventListener('click', (event) => {
      if (!this.input.value && document.activeElement !== this.input) {
        event.preventDefault()

        this.input.focus()
      }
    })

    document.addEventListener('turbo:before-cache', this.onBeforeCache)
  }

  disconnectedCallback () {
    document.removeEventListener('turbo:before-cache', this.onBeforeCache)
  }

  onBeforeCache = () => {
    this.input.value = this.input.getAttribute('value') || ''
  }

  get input () {
    return this.querySelector('input')
  }

  get button () {
    return this.querySelector('button')
  }
}

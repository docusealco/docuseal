export default class extends HTMLElement {
  connectedCallback () {
    this.addEventListener('click', this.onClick)

    document.addEventListener('turbo:before-cache', this.onBeforeCache)

    if (this.input?.value) {
      this.input.focus()
      this.input.setSelectionRange(this.input.value.length, this.input.value.length)
    }
  }

  disconnectedCallback () {
    document.removeEventListener('turbo:before-cache', this.onBeforeCache)
  }

  onClick = (event) => {
    if (!event.target.closest('button')) return

    if (!this.input.value && document.activeElement !== this.input) {
      event.preventDefault()

      this.input.focus()
    }
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

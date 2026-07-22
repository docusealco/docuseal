export default class extends HTMLElement {
  connectedCallback () {
    this.input.addEventListener('focus', () => {
      if (this.title) {
        this.titleContainer.classList.add('max-md:hidden')
      }
    })

    this.input.addEventListener('blur', (e) => {
      if (this.title && !e.target.value) {
        this.title.classList.remove('hidden')
        this.titleContainer.classList.remove('max-md:hidden')
      }
    })

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

    if (this.title) {
      this.titleContainer.classList.remove('max-md:hidden')
    }
  }

  get input () {
    return this.querySelector('input')
  }

  get title () {
    return document.querySelector(this.dataset.title)
  }

  get titleContainer () {
    const parent = this.title.parentElement

    if (parent && !parent.contains(this)) {
      return parent
    }

    return this.title
  }

  get button () {
    return this.querySelector('button')
  }
}

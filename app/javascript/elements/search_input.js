export default class extends HTMLElement {
  connectedCallback () {
    this.input.addEventListener('focus', () => {
      if (this.title) {
        this.title.classList.add('hidden', 'md:block')
        this.input.classList.add('w-60')
      }
    })

    this.input.addEventListener('blur', (e) => {
      if (this.title && !e.target.value) {
        this.title.classList.remove('hidden')
        this.input.classList.remove('w-60')
      }
    })

    this.button.addEventListener('click', (event) => {
      if (!this.input.value && document.activeElement !== this.input) {
        event.preventDefault()

        this.input.focus()
      }
    })
  }

  get input () {
    return this.querySelector('input')
  }

  get title () {
    return document.querySelector(this.dataset.title)
  }

  get button () {
    return this.querySelector('button')
  }
}

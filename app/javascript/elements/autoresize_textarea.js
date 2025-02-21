export default class extends HTMLElement {
  connectedCallback () {
    this.resize()

    this.textarea.addEventListener('input', () => this.resize())

    this.observeVisibility()
  }

  resize () {
    if (this.textarea.clientHeight < this.textarea.scrollHeight) {
      this.textarea.style.height = `${this.textarea.scrollHeight + 5}px`
    }
  }

  observeVisibility () {
    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            this.resize()
            this.observer.unobserve(this.textarea)
          }
        })
      },
      {
        threshold: 0.1
      }
    )

    this.observer.observe(this.textarea)
  }

  disconnectedCallback () {
    this.observer.unobserve(this.textarea)
  }

  get textarea () {
    return this.querySelector('textarea')
  }
}

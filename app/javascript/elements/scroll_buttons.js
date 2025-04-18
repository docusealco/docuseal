export default class extends HTMLElement {
  connectedCallback () {
    this.header = document.querySelector('#signing_form_header')

    window.addEventListener('scroll', this.onScroll.bind(this))
    window.addEventListener('resize', this.onResize.bind(this))

    this.onResize()
  }

  disconnectedCallback () {
    window.removeEventListener('scroll', this.onScroll.bind(this))
    window.removeEventListener('resize', this.onResize.bind(this))
  }

  onResize () {
    if (this.isNarrow()) {
      this.hideButtons(true)
    } else if (this.isHeaderNotVisible()) {
      this.showButtons()
    }
  }

  isNarrow () {
    return window.innerWidth < 1366
  }

  onScroll () {
    if (this.isHeaderNotVisible() && !this.isNarrow()) {
      this.showButtons()
    } else {
      this.hideButtons()
    }
  }

  isHeaderNotVisible () {
    const rect = this.header.getBoundingClientRect()
    return rect.bottom <= 0 || rect.top >= window.innerHeight
  }

  showButtons () {
    this.classList.remove('hidden', '-translate-y-10', 'opacity-0')
    this.classList.add('translate-y-0', 'opacity-100')
  }

  hideButtons () {
    this.classList.remove('translate-y-0', 'opacity-100')
    this.classList.add('-translate-y-10', 'opacity-0')

    setTimeout(() => {
      if (this.classList.contains('-translate-y-10')) {
        this.classList.add('hidden')
      }
    }, 300)
  }
}

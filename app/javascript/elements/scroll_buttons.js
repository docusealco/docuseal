export default class extends HTMLElement {
  connectedCallback () {
    this.header = document.querySelector('#signing_form_header')

    window.addEventListener('scroll', this.onScroll)
    window.addEventListener('resize', this.onResize)

    if (!this.isNarrow() && this.isHeaderNotVisible()) {
      this.showButtons({ animate: false })
    }
  }

  disconnectedCallback () {
    window.removeEventListener('scroll', this.onScroll)
    window.removeEventListener('resize', this.onResize)
  }

  onResize = () => {
    if (this.isNarrow()) {
      this.hideButtons(true)
    } else if (this.isHeaderNotVisible()) {
      this.showButtons()
    }
  }

  isNarrow () {
    return window.innerWidth < 1230
  }

  onScroll = () => {
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

  showButtons ({ animate } = { animate: true }) {
    if (animate) {
      this.classList.add('transition-transform', 'duration-300')
    }

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

export default class extends HTMLElement {
  connectedCallback () {
    this.selector = document.getElementById(this.dataset.selectorId)

    const scrollToTarget = () => {
      this.selector.scrollIntoView({ behavior: 'smooth', block: 'start' })
      history.replaceState(null, null, `#${this.dataset.selectorId}`)

      if (this.selector.tabIndex < 0) {
        this.selector.tabIndex = -1
      }

      this.selector.focus({ preventScroll: true })
    }

    this.addEventListener('click', scrollToTarget)
    this.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault()
        scrollToTarget()
      }
    })
  }
}

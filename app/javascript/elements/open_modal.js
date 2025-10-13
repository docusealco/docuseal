export default class extends HTMLElement {
  connectedCallback () {
    const src = this.getAttribute('src')
    const link = document.createElement('a')

    link.href = src
    link.setAttribute('data-turbo-frame', 'modal')
    link.style.display = 'none'

    this.appendChild(link)

    link.click()

    window.history.replaceState({}, document.title, window.location.pathname)
  }
}

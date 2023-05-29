export default class extends HTMLElement {
  connectedCallback () {
    this.querySelectorAll('a').forEach((link) => {
      if (document.location.pathname.startsWith(link.pathname)) {
        link.classList.add('bg-base-300')
      }
    })
  }
}

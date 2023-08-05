export default class extends HTMLElement {
  connectedCallback () {
    this.querySelectorAll('a').forEach((link) => {
      if (document.location.pathname.startsWith(link.pathname) && !link.getAttribute('href').startsWith('http')) {
        link.classList.add('bg-base-300')
      }
    })
  }
}

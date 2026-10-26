export default class extends HTMLElement {
  connectedCallback () {
    this.id = `menu-active-${Math.random().toString(32).split('.')[1]}`

    this.querySelectorAll('a').forEach((link) => {
      if (document.location.pathname.startsWith(link.pathname) && !link.getAttribute('href').startsWith('http')) {
        link.classList.add('bg-base-300')
      }
    })
  }
}

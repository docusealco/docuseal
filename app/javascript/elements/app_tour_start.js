export default class extends HTMLElement {
  connectedCallback () {
    this.querySelector('form').addEventListener('submit', () => {
      window.app_tour.start()
    })
  }
}

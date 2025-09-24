export default class extends HTMLElement {
  connectedCallback () {
    const eventType = this.dataset.on || 'click'
    const selector = document.getElementById(this.dataset.selectorId) || this
    const eventElement = eventType === 'submit' ? this.querySelector('form') : this

    eventElement.addEventListener(eventType, (event) => {
      if (eventType === 'click') {
        event.preventDefault()
      }

      selector.remove()
    })
  }
}

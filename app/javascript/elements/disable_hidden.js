export default class extends HTMLElement {
  static observedAttributes = ['class']

  connectedCallback () {
    this.trigger()
  }

  attributeChangedCallback (attributeName, oldValue, newValue) {
    if (attributeName === 'class' && oldValue !== newValue) {
      this.trigger()
    }
  }

  trigger () {
    const hasHiddenClass = this.classList.contains('hidden')
    const elements = this.querySelectorAll('input, textarea, select')

    elements.forEach((element) => {
      if (hasHiddenClass) {
        element.disabled = true

        if (!element.dataset.wasRequired) {
          element.dataset.wasRequired = element.required
        }

        element.required = false
      } else {
        element.disabled = false

        if (element.dataset.wasRequired) {
          element.required = element.dataset.wasRequired === 'true'

          delete element.dataset.wasRequired
        }
      }
    })
  }
}

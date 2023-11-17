export default class extends HTMLElement {
  connectedCallback () {
    if (this.dataset.inputId) {
      const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone

      if (this.dataset.params === 'true') {
        const params = new URLSearchParams(this.input.value)

        params.set('timezone', timezone)

        this.input.value = params.toString()
      } else {
        this.input.value = timezone
      }
    }
  }

  get input () {
    return document.getElementById(this.dataset.inputId)
  }
}

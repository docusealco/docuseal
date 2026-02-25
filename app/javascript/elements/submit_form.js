import { announcePolite } from './aria_announce'

export default class extends HTMLElement {
  connectedCallback () {
    const form = this.querySelector('form') || (this.querySelector('input, button, select') || this.lastElementChild).form

    if (this.dataset.interval) {
      this.interval = setInterval(() => {
        form.requestSubmit()
      }, parseInt(this.dataset.interval))
    } else if (this.dataset.on) {
      this.lastElementChild.addEventListener(this.dataset.on, (event) => {
        if (this.dataset.disable === 'true') {
          form.querySelector('[type="submit"]')?.setAttribute('disabled', true)
        }

        if (this.dataset.submitIfValue === 'true') {
          if (event.target.value) {
            if (this.dataset.announceSubmit) announcePolite(this.dataset.announceSubmit)
            form.requestSubmit()
          }
        } else {
          if (this.dataset.announceSubmit) announcePolite(this.dataset.announceSubmit)
          form.requestSubmit()
        }
      })
    } else {
      form.requestSubmit()
    }
  }

  disconnectedCallback () {
    if (this.interval) {
      clearInterval(this.interval)
    }
  }
}

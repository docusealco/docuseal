export default class extends HTMLElement {
  connectedCallback () {
    if (this.dataset.interval) {
      this.interval = setInterval(() => {
        this.querySelector('form').requestSubmit()
      }, parseInt(this.dataset.interval))
    } else if (this.dataset.on) {
      this.lastElementChild.addEventListener(this.dataset.on, () => {
        this.lastElementChild.form.requestSubmit()
      })
    } else {
      this.querySelector('form').requestSubmit()
    }
  }

  disconnectedCallback () {
    if (this.interval) {
      clearInterval(this.interval)
    }
  }
}

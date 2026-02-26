import { announceError, announcePolite } from './aria_announce'

export default class extends HTMLElement {
  connectedCallback () {
    this.form.addEventListener('submit', (e) => {
      e.preventDefault()

      this.submit()
    })

    if (this.dataset.onload === 'true') {
      this.form.querySelector('button').click()
    }
  }

  submit () {
    fetch(this.form.action, {
      method: this.form.method,
      body: new FormData(this.form)
    }).then(async (resp) => {
      if (!resp.ok) {
        try {
          const data = JSON.parse(await resp.text())

          if (data.error) {
            announceError(data.error)
          }
        } catch (err) {
          console.error(err)
        }
      } else if (this.dataset.successMessage) {
        announcePolite(this.dataset.successMessage)
      }
    })
  }

  get form () {
    return this.querySelector('form')
  }
}

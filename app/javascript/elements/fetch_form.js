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
            alert(data.error)
          }
        } catch (err) {
          console.error(err)
        }
      }
    })
  }

  get form () {
    return this.querySelector('form')
  }
}

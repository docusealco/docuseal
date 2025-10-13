export default class extends HTMLElement {
  connectedCallback () {
    const iframeTemplate = this.querySelector('template')

    this.observer = new IntersectionObserver((entries) => {
      if (entries.some(e => e.isIntersecting)) {
        iframeTemplate.parentElement.prepend(iframeTemplate.content)

        this.observer.disconnect()
      }
    })

    this.observer.observe(this)

    window.addEventListener('message', this.messageHandler)
  }

  messageHandler = (event) => {
    if (event.data.type === 'google-drive-files-picked') {
      this.form.querySelectorAll('input[name="google_drive_file_ids[]"]').forEach(el => el.remove())

      const files = event.data.files || []

      files.forEach((file) => {
        const input = document.createElement('input')
        input.type = 'hidden'
        input.name = 'google_drive_file_ids[]'
        input.value = file.id
        this.form.appendChild(input)
      })

      this.form.querySelector('button[type="submit"]').click()
      this.loader.classList.remove('hidden')
    } else if (event.data.type === 'google-drive-picker-loaded') {
      this.loader.classList.add('hidden')
      this.form.classList.remove('hidden')
    } else if (event.data.type === 'google-drive-picker-request-oauth') {
      document.getElementById(this.dataset.oauthButtonId).classList.remove('hidden')
      this.classList.add('hidden')
    }
  }

  disconnectedCallback () {
    this.observer?.unobserve(this)
    window.removeEventListener('message', this.messageHandler)
  }

  get form () {
    return this.querySelector('form')
  }

  get loader () {
    return document.getElementById('google_drive_loader')
  }
}

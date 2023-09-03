import { createApp, reactive } from 'vue'

import Form from './submission_form/form'
import DownloadButton from './elements/download_button'

window.customElements.define('download-button', DownloadButton)
window.customElements.define('submission-form', class extends HTMLElement {
  connectedCallback () {
    this.appElem = document.createElement('div')

    this.app = createApp(Form, {
      submitter: JSON.parse(this.dataset.submitter),
      authenticityToken: this.dataset.authenticityToken,
      canSendEmail: this.dataset.canSendEmail === 'true',
      isDirectUpload: this.dataset.isDirectUpload === 'true',
      isDemo: this.dataset.isDemo === 'true',
      attribution: this.dataset.attribution !== 'false',
      withConfetti: true,
      values: reactive(JSON.parse(this.dataset.values)),
      attachments: reactive(JSON.parse(this.dataset.attachments)),
      fields: JSON.parse(this.dataset.fields)
    })

    this.app.mount(this.appElem)

    this.appendChild(this.appElem)
  }

  disconnectedCallback () {
    this.app?.unmount()
    this.appElem?.remove()
  }
})

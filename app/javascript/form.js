import { createApp, reactive } from 'vue'

import Form from './submission_form/form'

window.customElements.define('submission-form', class extends HTMLElement {
  connectedCallback () {
    this.appElem = document.createElement('div')

    this.app = createApp(Form, {
      submitterSlug: this.dataset.submitterSlug,
      submitterUuid: this.dataset.submitterUuid,
      authenticityToken: this.dataset.authenticityToken,
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

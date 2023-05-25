import { createApp, reactive } from 'vue'

import Flow from './flow_form/form'

window.customElements.define('flow-form', class extends HTMLElement {
  connectedCallback () {
    this.appElem = document.createElement('div')

    this.app = createApp(Flow, {
      submissionSlug: this.dataset.submissionSlug,
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

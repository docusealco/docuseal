import { createApp, reactive } from 'vue'

import Form from './submission_form/form'
import DownloadButton from './elements/download_button'
import ToggleSubmit from './elements/toggle_submit'
import FetchForm from './elements/fetch_form'
import ScrollButtons from './elements/scroll_buttons'

const safeRegisterElement = (name, element, options = {}) => !window.customElements.get(name) && window.customElements.define(name, element, options)

safeRegisterElement('download-button', DownloadButton)
safeRegisterElement('toggle-submit', ToggleSubmit)
safeRegisterElement('fetch-form', FetchForm)
safeRegisterElement('scroll-buttons', ScrollButtons)
safeRegisterElement('submission-form', class extends HTMLElement {
  connectedCallback () {
    this.appElem = document.createElement('div')

    this.app = createApp(Form, {
      submitter: JSON.parse(this.dataset.submitter),
      inviteSubmitters: JSON.parse(this.dataset.inviteSubmitters),
      optionalInviteSubmitters: JSON.parse(this.dataset.optionalInviteSubmitters),
      schema: JSON.parse(this.dataset.schema),
      canSendEmail: this.dataset.canSendEmail === 'true',
      previousSignatureValue: this.dataset.previousSignatureValue,
      goToLast: this.dataset.goToLast === 'true',
      isDemo: this.dataset.isDemo === 'true',
      attribution: this.dataset.attribution !== 'false',
      scrollPadding: this.dataset.scrollPadding || '-80px',
      language: this.dataset.language,
      dryRun: this.dataset.dryRun === 'true',
      expand: ['true', 'false'].includes(this.dataset.expand) ? this.dataset.expand === 'true' : null,
      withSignatureId: this.dataset.withSignatureId === 'true',
      requireSigningReason: this.dataset.requireSigningReason === 'true',
      withConfetti: this.dataset.withConfetti !== 'false',
      withDisclosure: this.dataset.withDisclosure === 'true',
      reuseSignature: this.dataset.reuseSignature !== 'false',
      withTypedSignature: this.dataset.withTypedSignature !== 'false',
      authenticityToken: document.querySelector('meta[name="csrf-token"]')?.content,
      rememberSignature: this.dataset.rememberSignature === 'true',
      values: reactive(JSON.parse(this.dataset.values)),
      completedButton: JSON.parse(this.dataset.completedButton || '{}'),
      withQrButton: true,
      completedMessage: JSON.parse(this.dataset.completedMessage || '{}'),
      completedRedirectUrl: this.dataset.completedRedirectUrl,
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

import '@hotwired/turbo'
import { FetchRequest } from '@hotwired/turbo';

import { createApp, reactive } from 'vue'
import TemplateBuilder from './template_builder/builder'
import ImportList from './template_builder/import_list'

import ToggleVisible from './elements/toggle_visible'
import ToggleCookies from './elements/toggle_cookies'
import DisableHidden from './elements/disable_hidden'
import TurboModal from './elements/turbo_modal'
import FileDropzone from './elements/file_dropzone'
import MenuActive from './elements/menu_active'
import ClipboardCopy from './elements/clipboard_copy'
import DynamicList from './elements/dynamic_list'
import DownloadButton from './elements/download_button'
import SetOriginUrl from './elements/set_origin_url'
import SetTimezone from './elements/set_timezone'
import AutoresizeTextarea from './elements/autoresize_textarea'
import SubmittersAutocomplete from './elements/submitter_autocomplete'
import FolderAutocomplete from './elements/folder_autocomplete'
import SignatureForm from './elements/signature_form'
import SubmitForm from './elements/submit_form'
import PromptPassword from './elements/prompt_password'
import EmailsTextarea from './elements/emails_textarea'
import ToggleOnSubmit from './elements/toggle_on_submit'
import PasswordInput from './elements/password_input'
import SearchInput from './elements/search_input'
import ToggleAttribute from './elements/toggle_attribute'
import LinkedInput from './elements/linked_input'
import CheckboxGroup from './elements/checkbox_group'
import MaskedInput from './elements/masked_input'
import SetDateButton from './elements/set_date_button'
import IndeterminateCheckbox from './elements/indeterminate_checkbox'
import AppTour from './elements/app_tour'

import * as TurboInstantClick from './lib/turbo_instant_click'

TurboInstantClick.start()

document.addEventListener('turbo:before-cache', () => {
  window.flash?.remove()
})

document.addEventListener('keyup', (e) => {
  if (e.code === 'Escape') {
    document.activeElement?.blur()
  }
})

document.addEventListener('turbo:before-fetch-request', FetchRequest.encodeMethodIntoRequestBody)
document.addEventListener('turbo:submit-end', async (event) => {
  const resp = event.detail?.formSubmission?.result?.fetchResponse?.response

  if (!resp?.headers?.get('content-disposition')?.includes('attachment')) {
    return
  }

  const url = URL.createObjectURL(await resp.blob())
  const link = document.createElement('a')

  link.href = url
  link.setAttribute('download', decodeURIComponent(resp.headers.get('content-disposition').split('"')[1]))

  document.body.appendChild(link)

  link.click()

  document.body.removeChild(link)

  URL.revokeObjectURL(url)
})

const safeRegisterElement = (name, element, options = {}) => !window.customElements.get(name) && window.customElements.define(name, element, options)

safeRegisterElement('toggle-visible', ToggleVisible)
safeRegisterElement('disable-hidden', DisableHidden)
safeRegisterElement('turbo-modal', TurboModal)
safeRegisterElement('file-dropzone', FileDropzone)
safeRegisterElement('menu-active', MenuActive)
safeRegisterElement('clipboard-copy', ClipboardCopy)
safeRegisterElement('dynamic-list', DynamicList)
safeRegisterElement('download-button', DownloadButton)
safeRegisterElement('set-origin-url', SetOriginUrl)
safeRegisterElement('set-timezone', SetTimezone)
safeRegisterElement('autoresize-textarea', AutoresizeTextarea)
safeRegisterElement('submitters-autocomplete', SubmittersAutocomplete)
safeRegisterElement('folder-autocomplete', FolderAutocomplete)
safeRegisterElement('signature-form', SignatureForm)
safeRegisterElement('submit-form', SubmitForm)
safeRegisterElement('prompt-password', PromptPassword)
safeRegisterElement('emails-textarea', EmailsTextarea)
safeRegisterElement('toggle-cookies', ToggleCookies)
safeRegisterElement('toggle-on-submit', ToggleOnSubmit)
safeRegisterElement('password-input', PasswordInput)
safeRegisterElement('search-input', SearchInput)
safeRegisterElement('toggle-attribute', ToggleAttribute)
safeRegisterElement('linked-input', LinkedInput)
safeRegisterElement('checkbox-group', CheckboxGroup)
safeRegisterElement('masked-input', MaskedInput)
safeRegisterElement('set-date-button', SetDateButton)
safeRegisterElement('indeterminate-checkbox', IndeterminateCheckbox)
safeRegisterElement('app-tour', AppTour)

safeRegisterElement('template-builder', class extends HTMLElement {
  connectedCallback () {
    document.addEventListener('turbo:submit-end', this.onSubmit)

    this.appElem = document.createElement('div')

    this.appElem.classList.add('md:h-screen')

    this.app = createApp(TemplateBuilder, {
      template: reactive(JSON.parse(this.dataset.template)),
      backgroundColor: '#faf7f5',
      locale: this.dataset.locale,
      withPhone: this.dataset.withPhone === 'true',
      withVerification: ['true', 'false'].includes(this.dataset.withVerification) ? this.dataset.withVerification === 'true' : null,
      withLogo: this.dataset.withLogo !== 'false',
      editable: this.dataset.editable !== 'false',
      authenticityToken: document.querySelector('meta[name="csrf-token"]')?.content,
      withPayment: this.dataset.withPayment === 'true',
      isPaymentConnected: this.dataset.isPaymentConnected === 'true',
      withFormula: this.dataset.withFormula === 'true',
      withSendButton: this.dataset.withSendButton !== 'false',
      withSignYourselfButton: this.dataset.withSignYourselfButton !== 'false',
      withConditions: this.dataset.withConditions === 'true',
      currencies: (this.dataset.currencies || '').split(',').filter(Boolean),
      acceptFileTypes: this.dataset.acceptFileTypes,
      showTourStartForm: this.dataset.showTourStartForm === 'true'
    })

    this.component = this.app.mount(this.appElem)

    this.appendChild(this.appElem)
  }

  onSubmit = (e) => {
    if (e.detail.success && e.detail?.formSubmission?.formElement?.id === 'submitters_form') {
      e.detail.fetchResponse.response.json().then((data) => {
        this.component.template.submitters = data.submitters
      })
    }
  }

  disconnectedCallback () {
    document.removeEventListener('turbo:submit-end', this.onSubmit)

    this.app?.unmount()
    this.appElem?.remove()
  }
})

safeRegisterElement('import-list', class extends HTMLElement {
  connectedCallback () {
    this.appElem = document.createElement('div')

    this.app = createApp(ImportList, {
      template: JSON.parse(this.dataset.template),
      multitenant: this.dataset.multitenant === 'true',
      authenticityToken: document.querySelector('meta[name="csrf-token"]')?.content,
      i18n: JSON.parse(this.dataset.i18n || '{}')
    })

    this.app.mount(this.appElem)

    this.appendChild(this.appElem)
  }

  disconnectedCallback () {
    this.app?.unmount()
    this.appElem?.remove()
  }
})

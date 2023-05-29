import '@hotwired/turbo-rails'

import { createApp, reactive } from 'vue'

import ToggleVisible from './elements/toggle_visible'
import DisableHidden from './elements/disable_hidden'
import TurboModal from './elements/turbo_modal'
import FileDropzone from './elements/file_dropzone'
import MenuActive from './elements/menu_active'

import FlowBuilder from './flow_builder/builder'

document.addEventListener('turbo:before-cache', () => {
  window.flash?.remove()
})

window.customElements.define('toggle-visible', ToggleVisible)
window.customElements.define('disable-hidden', DisableHidden)
window.customElements.define('turbo-modal', TurboModal)
window.customElements.define('file-dropzone', FileDropzone)
window.customElements.define('menu-active', MenuActive)

window.customElements.define('flow-builder', class extends HTMLElement {
  connectedCallback () {
    this.appElem = document.createElement('div')

    this.app = createApp(FlowBuilder, {
      flow: reactive(JSON.parse(this.dataset.flow))
    })

    this.app.mount(this.appElem)

    this.appendChild(this.appElem)
  }

  disconnectedCallback () {
    this.app?.unmount()
    this.appElem?.remove()
  }
})

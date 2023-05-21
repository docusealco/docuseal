import '@hotwired/turbo-rails'

import { createApp } from 'vue'

import ToggleVisible from './elements/toggle_visible'
import DisableHidden from './elements/disable_hidden'
import TurboModal from './elements/turbo_modal'
import FlowArea from './elements/flow_area'
import FlowView from './elements/flow_view'

import Builder from './components/builder'

window.customElements.define('toggle-visible', ToggleVisible)
window.customElements.define('disable-hidden', DisableHidden)
window.customElements.define('turbo-modal', TurboModal)
window.customElements.define('flow-view', FlowView)
window.customElements.define('flow-area', FlowArea)

window.customElements.define('flow-builder', class extends HTMLElement {
  connectedCallback () {
    this.appElem = document.createElement('div')

    this.app = createApp(Builder, {
      dataFlow: this.dataset.flow
    })

    this.app.mount(this.appElem)

    this.appendChild(this.appElem)
  }

  disconnectedCallback () {
    this.app?.unmount()
    this.appElem?.remove()
  }
})

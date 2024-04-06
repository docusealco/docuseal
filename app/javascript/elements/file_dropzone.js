import { actionable } from '@github/catalyst/lib/actionable'
import { target, targetable } from '@github/catalyst/lib/targetable'

export default actionable(targetable(class extends HTMLElement {
  static [target.static] = [
    'loading',
    'icon',
    'input'
  ]

  connectedCallback () {
    this.addEventListener('drop', this.onDrop)

    this.addEventListener('dragover', (e) => e.preventDefault())

    document.addEventListener('turbo:submit-end', this.toggleLoading)
  }

  disconnectedCallback () {
    document.removeEventListener('turbo:submit-end', this.toggleLoading)
  }

  onDrop (e) {
    e.preventDefault()

    this.input.files = e.dataTransfer.files

    this.uploadFiles(e.dataTransfer.files)
  }

  onSelectFiles (e) {
    e.preventDefault()

    this.uploadFiles(this.input.files)
  }

  toggleLoading = (e) => {
    if (e && e.target && !e.target.contains(this)) {
      return
    }

    this.loading.classList.toggle('hidden')
    this.icon.classList.toggle('hidden')
    this.classList.toggle('opacity-50')
  }

  uploadFiles () {
    this.toggleLoading()

    if (this.dataset.submitOnUpload) {
      this.closest('form').querySelector('button[type="submit"]').click()
    }
  }
}))

import { actionable } from '@github/catalyst/lib/actionable'
import { target, targetable } from '@github/catalyst/lib/targetable'

export default actionable(targetable(class extends HTMLElement {
  static [target.static] = [
    'loading',
    'icon',
    'input',
    'area'
  ]

  connectedCallback () {
    this.addEventListener('dragover', (e) => e.preventDefault())
    this.addEventListener('drop', this.onDrop)
    document.addEventListener('turbo:submit-end', this.toggleLoading)
    this.area?.addEventListener('dragover', this.onDragover)
    this.area?.addEventListener('dragleave', this.onDragleave)
  }

  disconnectedCallback () {
    this.removeEventListener('drop', this.onDrop)
    document.removeEventListener('turbo:submit-end', this.toggleLoading)
    this.area?.removeEventListener('dragover', this.onDragover)
    this.area?.removeEventListener('dragleave', this.onDragleave)
  }

  onDragover (e) {
    if (e.dataTransfer?.types?.includes('Files')) {
      this.style.backgroundColor = '#F7F3F0'
      this.classList.remove('border-base-300', 'hover:bg-base-200/30')
      this.classList.add('border-base-content/30')
    }
  }

  onDragleave () {
    this.style.backgroundColor = null
    this.classList.remove('border-base-content/30')
    this.classList.add('border-base-300', 'hover:bg-base-200/30')
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
    if (e && e.target && (!e.target.contains(this) || !e.detail?.formSubmission?.formElement?.contains(this))) {
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

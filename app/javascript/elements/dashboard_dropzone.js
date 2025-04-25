import { actionable } from '@github/catalyst/lib/actionable'
import { target, targets, targetable } from '@github/catalyst/lib/targetable'

export default actionable(targetable(class extends HTMLElement {
  static [targets.static] = ['hiddenOnHover']
  static [target.static] = [
    'loading',
    'icon',
    'input',
    'fileDropzone'
  ]

  connectedCallback () {
    this.showOnlyOnWindowHover = this.dataset.showOnlyOnWindowHover === 'true'

    document.addEventListener('drop', this.onWindowDragdrop)
    document.addEventListener('dragover', this.onWindowDropover)
    window.addEventListener('dragleave', this.onWindowDragleave)

    this.addEventListener('dragover', this.onDragover)
    this.addEventListener('dragleave', this.onDragleave)

    this.fileDropzone.addEventListener('drop', this.onDrop)
    this.fileDropzone.addEventListener('turbo:submit-start', this.showDraghover)
    this.fileDropzone.addEventListener('turbo:submit-end', this.hideDraghover)
  }

  disconnectedCallback () {
    document.removeEventListener('drop', this.onWindowDragdrop)
    document.removeEventListener('dragover', this.onWindowDropover)
    window.removeEventListener('dragleave', this.onWindowDragleave)

    this.removeEventListener('dragover', this.onDragover)
    this.removeEventListener('dragleave', this.onDragleave)

    this.fileDropzone.removeEventListener('drop', this.onDrop)
    this.fileDropzone.removeEventListener('turbo:submit-start', this.showDraghover)
    this.fileDropzone.removeEventListener('turbo:submit-end', this.hideDraghover)
  }

  onDrop = (e) => {
    e.preventDefault()

    this.input.files = e.dataTransfer.files

    this.uploadFiles(e.dataTransfer.files)
  }

  onWindowDragdrop = () => {
    if (!this.hovered) this.hideDraghover()
  }

  onSelectFiles (e) {
    e.preventDefault()

    this.uploadFiles(this.input.files)
  }

  toggleLoading = (e) => {
    if (e && e.target && (!e.target.contains(this) || !e.detail?.formSubmission?.formElement?.contains(this))) {
      return
    }

    this.loading?.classList?.toggle('hidden')
    this.icon?.classList?.toggle('hidden')
  }

  uploadFiles () {
    this.toggleLoading()

    this.fileDropzone.querySelector('button[type="submit"]').click()
  }

  onWindowDropover = (e) => {
    e.preventDefault()

    if (e.dataTransfer?.types?.includes('Files')) {
      this.showDraghover()
    }
  }

  onWindowDragleave = (e) => {
    if (e.clientX <= 0 || e.clientY <= 0 || e.clientX >= window.innerWidth || e.clientY >= window.innerHeight) {
      this.hideDraghover()
    }
  }

  onDragover (e) {
    e.preventDefault()

    this.hovered = true
    this.style.backgroundColor = '#F7F3F0'
  }

  onDragleave (e) {
    e.preventDefault()

    this.hovered = false
    this.style.backgroundColor = null
  }

  showDraghover = () => {
    if (this.showOnlyOnWindowHover) {
      this.classList.remove('hidden')
    }

    this.classList.remove('bg-base-200', 'border-transparent')
    this.classList.add('bg-base-100', 'border-base-300', 'border-dashed')
    this.fileDropzone.classList.remove('hidden')
    this.hiddenOnHover.forEach((el) => { el.style.display = 'none' })
  }

  hideDraghover = () => {
    if (this.showOnlyOnWindowHover) {
      this.classList.add('hidden')
    }

    this.classList.add('bg-base-200', 'border-transparent')
    this.classList.remove('bg-base-100', 'border-base-300', 'border-dashed')
    this.fileDropzone.classList.add('hidden')
    this.hiddenOnHover.forEach((el) => { el.style.display = null })
  }
}))

import { target, targets, targetable } from '@github/catalyst/lib/targetable'

export default targetable(class extends HTMLElement {
  static [targets.static] = [
    'hiddenOnDrag',
    'folderCards',
    'templateCards'
  ]

  static [target.static] = [
    'form',
    'fileDropzone',
    'fileDropzoneLoading'
  ]

  connectedCallback () {
    document.addEventListener('drop', this.onWindowDragdrop)
    document.addEventListener('dragover', this.onWindowDropover)

    window.addEventListener('dragleave', this.onWindowDragleave)

    this.fileDropzone?.addEventListener('drop', this.onDropFile)

    this.folderCards.forEach((el) => el.addEventListener('drop', this.onDropFolder))
    this.templateCards.forEach((el) => el.addEventListener('drop', this.onDropTemplate))

    return [this.fileDropzone, ...this.folderCards, ...this.templateCards].forEach((el) => {
      el?.addEventListener('dragover', this.onDragover)
      el?.addEventListener('dragleave', this.onDragleave)
    })
  }

  disconnectedCallback () {
    document.removeEventListener('drop', this.onWindowDragdrop)
    document.removeEventListener('dragover', this.onWindowDropover)

    window.removeEventListener('dragleave', this.onWindowDragleave)

    this.fileDropzone?.removeEventListener('drop', this.onDropFile)

    this.folderCards.forEach((el) => el.removeEventListener('drop', this.onDropFolder))
    this.templateCards.forEach((el) => el.removeEventListener('drop', this.onDropTemplate))

    return [this.fileDropzone, ...this.folderCards, ...this.templateCards].forEach((el) => {
      el?.removeEventListener('dragover', this.onDragover)
      el?.removeEventListener('dragleave', this.onDragleave)
    })
  }

  onDropFile = (e) => {
    e.preventDefault()

    this.fileDropzoneLoading.classList.remove('hidden')
    this.fileDropzoneLoading.previousElementSibling.classList.add('hidden')
    this.fileDropzoneLoading.classList.add('opacity-50')

    this.uploadFiles(e.dataTransfer.files, '/templates_upload')
  }

  onDropFolder = (e) => {
    e.preventDefault()

    const loading = document.createElement('div')
    const svg = e.target.querySelector('svg')

    loading.innerHTML = this.loadingIconHtml
    loading.children[0].classList.add(...svg.classList)

    e.target.replaceChild(loading.children[0], svg)
    e.target.classList.add('opacity-50')

    const params = new URLSearchParams({ folder_name: e.target.innerText }).toString()

    this.uploadFiles(e.dataTransfer.files, `/templates_upload?${params}`)
  }

  onDropTemplate = (e) => {
    e.preventDefault()

    const loading = document.createElement('div')
    loading.classList.add('bottom-5', 'left-0', 'flex', 'justify-center', 'w-full', 'absolute')
    loading.innerHTML = this.loadingIconHtml

    e.target.appendChild(loading)
    e.target.classList.add('opacity-50')

    const id = e.target.href.split('/').pop()

    this.uploadFiles(e.dataTransfer.files, `/templates/${id}/clone_and_replace`)
  }

  onWindowDragdrop = () => {
    if (!this.isLoading) this.hideDraghover()
  }

  uploadFiles (files, url) {
    this.isLoading = true

    this.form.action = url

    this.form.querySelector('[type="file"]').files = files

    this.form.querySelector('[type="submit"]').click()
  }

  onWindowDropover = (e) => {
    e.preventDefault()

    if (e.dataTransfer?.types?.includes('Files')) {
      this.showDraghover()
    }
  }

  onDragover () {
    this.style.backgroundColor = '#F7F3F0'
  }

  onDragleave () {
    this.style.backgroundColor = null
  }

  onWindowDragleave = (e) => {
    if (e.clientX <= 0 || e.clientY <= 0 || e.clientX >= window.innerWidth || e.clientY >= window.innerHeight) {
      this.hideDraghover()
    }
  }

  showDraghover = () => {
    if (this.isDrag) return

    this.isDrag = true

    this.fileDropzone?.classList?.remove('hidden')

    this.hiddenOnDrag.forEach((el) => { el.style.display = 'none' })

    return [...this.folderCards, ...this.templateCards].forEach((el) => {
      el.classList.remove('bg-base-200', 'before:hidden')
    })
  }

  hideDraghover = () => {
    this.isDrag = false

    this.fileDropzone?.classList?.add('hidden')

    this.hiddenOnDrag.forEach((el) => { el.style.display = null })

    return [...this.folderCards, ...this.templateCards].forEach((el) => {
      el.classList.add('bg-base-200', 'before:hidden')
    })
  }

  get loadingIconHtml () {
    return `<svg xmlns="http://www.w3.org/2000/svg" class="animate-spin" width="44" height="44" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
  <path stroke="none" d="M0 0h24v24H0z" fill="none" />
  <path d="M12 3a9 9 0 1 0 9 9" />
</svg>`
  }
})

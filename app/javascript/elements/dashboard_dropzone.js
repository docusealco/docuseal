import { target, targets, targetable } from '@github/catalyst/lib/targetable'

const loadingIconHtml = `<svg xmlns="http://www.w3.org/2000/svg" class="animate-spin" width="44" height="44" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
  <path stroke="none" d="M0 0h24v24H0z" fill="none" />
  <path d="M12 3a9 9 0 1 0 9 9" />
</svg>`

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

    this.folderCards.forEach((el) => el.addEventListener('drop', (e) => this.onDropFolder(e, el)))
    this.templateCards.forEach((el) => el.addEventListener('drop', this.onDropTemplate))
    this.templateCards.forEach((el) => el.addEventListener('dragstart', this.onTemplateDragStart))

    return [this.fileDropzone, ...this.folderCards, ...this.templateCards].forEach((el) => {
      el?.addEventListener('dragover', this.onDragover)
      el?.addEventListener('dragleave', this.onDragleave)
    })
  }

  disconnectedCallback () {
    document.removeEventListener('drop', this.onWindowDragdrop)
    document.removeEventListener('dragover', this.onWindowDropover)

    window.removeEventListener('dragleave', this.onWindowDragleave)
  }

  onTemplateDragStart = (e) => {
    const id = e.target.href.split('/').pop()

    e.dataTransfer.effectAllowed = 'move'

    if (id) {
      e.dataTransfer.setData('template_id', id)

      const dragPreview = e.target.cloneNode(true)
      const rect = e.target.getBoundingClientRect()

      const height = e.target.children[0].getBoundingClientRect().height + 50

      dragPreview.children[1].remove()
      dragPreview.style.width = `${rect.width}px`
      dragPreview.style.height = `${height}px`
      dragPreview.style.position = 'absolute'
      dragPreview.style.top = '-1000px'
      dragPreview.style.pointerEvents = 'none'
      dragPreview.style.opacity = '0.9'

      document.body.appendChild(dragPreview)

      e.dataTransfer.setDragImage(dragPreview, rect.width / 2, height / 2)

      setTimeout(() => document.body.removeChild(dragPreview), 0)
    }
  }

  onDropFile = (e) => {
    e.preventDefault()

    this.fileDropzoneLoading.classList.remove('hidden')
    this.fileDropzoneLoading.previousElementSibling.classList.add('hidden')
    this.fileDropzoneLoading.classList.add('opacity-50')

    this.uploadFiles(e.dataTransfer.files, '/templates_upload')
  }

  onDropFolder = (e, el) => {
    e.preventDefault()

    const templateId = e.dataTransfer.getData('template_id')

    if (e.dataTransfer.files.length || templateId) {
      const loading = document.createElement('div')
      const svg = el.querySelector('svg')

      loading.innerHTML = loadingIconHtml
      loading.children[0].classList.add(...svg.classList)

      el.replaceChild(loading.children[0], svg)
      el.classList.add('opacity-50')

      if (e.dataTransfer.files.length) {
        const params = new URLSearchParams({ folder_name: el.innerText }).toString()

        this.uploadFiles(e.dataTransfer.files, `/templates_upload?${params}`)
      } else {
        const formData = new FormData()

        formData.append('name', el.innerText)

        fetch(`/templates/${templateId}/folder`, {
          method: 'PUT',
          redirect: 'manual',
          body: formData,
          headers: {
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
          }
        }).finally(() => {
          window.Turbo.cache.clear()
          window.Turbo.visit(location.href)
        })
      }
    }
  }

  onDropTemplate = (e) => {
    e.preventDefault()

    if (e.dataTransfer.files.length) {
      const loading = document.createElement('div')
      loading.classList.add('bottom-5', 'left-0', 'flex', 'justify-center', 'w-full', 'absolute')
      loading.innerHTML = loadingIconHtml

      e.target.appendChild(loading)
      e.target.classList.add('opacity-50')

      const id = e.target.href.split('/').pop()

      this.uploadFiles(e.dataTransfer.files, `/templates/${id}/clone_and_replace`)
    }
  }

  onWindowDragdrop = (e) => {
    e.preventDefault()

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

  onDragover (e) {
    if (e.dataTransfer?.types?.includes('Files') || this.dataset.targets !== 'dashboard-dropzone.templateCards') {
      this.style.backgroundColor = '#F7F3F0'

      if (this.classList.contains('before:border-base-300')) {
        this.classList.remove('before:border-base-300')
        this.classList.add('before:border-base-content/30')
      } else if (this.classList.contains('border-base-300')) {
        this.classList.remove('border-base-300')
        this.classList.add('border-base-content/30')
      }
    }
  }

  onDragleave () {
    this.style.backgroundColor = null

    if (this.classList.contains('before:border-base-content/30')) {
      this.classList.remove('before:border-base-content/30')
      this.classList.add('before:border-base-300')
    } else if (this.classList.contains('border-base-content/30')) {
      this.classList.remove('border-base-content/30')
      this.classList.add('border-base-300')
    }
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
})

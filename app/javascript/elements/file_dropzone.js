import { DirectUpload } from '@rails/activestorage'

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
  }

  onDrop (e) {
    e.preventDefault()

    this.uploadFiles(e.dataTransfer.files)
  }

  onSelectFiles (e) {
    e.preventDefault()

    this.uploadFiles(this.input.files).then(() => {
      this.input.value = ''
    })
  }

  toggleLoading () {
    this.loading.classList.toggle('hidden')
    this.icon.classList.toggle('hidden')
    this.classList.toggle('opacity-50')
  }

  async uploadFiles (files) {
    this.toggleLoading()

    await Promise.all(
      Array.from(files).map(async (file) => {
        const upload = new DirectUpload(
          file,
          '/direct_uploads',
          this.input
        )

        return new Promise((resolve, reject) => {
          upload.create((error, blob) => {
            if (error) {
              console.error(error)

              return reject(error)
            } else {
              return resolve(blob)
            }
          })
        }).catch((error) => {
          console.error(error)
        })
      })
    ).then((blobs) => {
      if (this.dataset.submitOnUpload) {
        this.querySelectorAll('[name="blob_signed_ids[]"]').forEach((e) => e.remove())
      }

      blobs.forEach((blob) => {
        const input = document.createElement('input')

        input.type = 'hidden'
        input.name = 'blob_signed_ids[]'
        input.value = blob.signed_id

        this.append(input)
      })

      if (this.dataset.submitOnUpload) {
        this.closest('form').querySelector('button[type="submit"]').click()
      }
    }).finally(() => {
      this.toggleLoading()
    })
  }
}))

import { DirectUpload } from '@rails/activestorage'

import { actionable } from '@github/catalyst/lib/actionable'
import { target, targetable } from '@github/catalyst/lib/targetable'

export default actionable(targetable(class extends HTMLElement {
  static [target.static] = [
    'loading',
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

  async uploadFiles (files) {
    const blobs = await Promise.all(
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
    )

    await Promise.all(
      blobs.map((blob) => {
        return fetch('/api/attachments', {
          method: 'POST',
          body: JSON.stringify({
            name: 'attachments',
            blob_signed_id: blob.signed_id,
            submission_slug: this.dataset.submissionSlug
          }),
          headers: { 'Content-Type': 'application/json' }
        }).then(resp => resp.json()).then((data) => {
          return data
        })
      })).then((result) => {
      result.forEach((attachment) => {
        this.dispatchEvent(new CustomEvent('upload', { detail: attachment }))
      })
    })
  }
}))

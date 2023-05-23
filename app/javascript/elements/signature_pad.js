import SignaturePad from 'signature_pad'
import { target, targetable } from '@github/catalyst/lib/targetable'
import { actionable } from '@github/catalyst/lib/actionable'

import { DirectUpload } from '@rails/activestorage'

export default actionable(targetable(class extends HTMLElement {
  static [target.static] = [
    'canvas',
    'input',
    'okButton',
    'image',
    'clearButton',
    'redrawButton',
    'nextButton'
  ]

  connectedCallback () {
    this.pad = new SignaturePad(this.canvas)
  }

  submit (e) {
    e?.preventDefault()

    this.okButton.disabled = true

    this.canvas.toBlob((blob) => {
      const file = new File([blob], 'signature.png', { type: 'image/png' })

      new DirectUpload(
        file,
        '/direct_uploads'
      ).create((_error, data) => {
        fetch('/api/attachments', {
          method: 'POST',
          body: JSON.stringify({
            submission_slug: this.dataset.submissionSlug,
            blob_signed_id: data.signed_id,
            name: 'signatures'
          }),
          headers: { 'Content-Type': 'application/json' }
        }).then((resp) => resp.json()).then((attachment) => {
          this.input.value = attachment.uuid
          this.dispatchEvent(new CustomEvent('upload', { detail: attachment }))
        })
      })
    }, 'image/png')
  }

  redraw (e) {
    e?.preventDefault()

    this.input.value = ''

    this.canvas.classList.remove('hidden')
    this.clearButton.classList.remove('hidden')
    this.okButton.classList.remove('hidden')
    this.image.remove()
    this.redrawButton.remove()
    this.nextButton.remove()
  }

  clear (e) {
    e?.preventDefault()

    this.pad.clear()
  }
}))

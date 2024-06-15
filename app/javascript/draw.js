import SignaturePad from 'signature_pad'
import { cropCanvasAndExportToPNG } from './submission_form/crop_canvas'

window.customElements.define('draw-signature', class extends HTMLElement {
  connectedCallback () {
    const scale = 3

    this.canvas.width = this.canvas.parentNode.clientWidth * scale
    this.canvas.height = this.canvas.parentNode.clientHeight * scale

    this.canvas.getContext('2d').scale(scale, scale)

    this.pad = new SignaturePad(this.canvas)

    this.pad.addEventListener('endStroke', () => {
      this.updateSubmitButtonVisibility()
    })

    this.clearButton.addEventListener('click', (e) => {
      e.preventDefault()

      this.clearSignaturePad()
    })

    this.form.addEventListener('submit', (e) => {
      e.preventDefault()

      this.submitButton.disabled = true

      this.submitImage().then((data) => {
        this.valueInput.value = data.uuid

        return fetch(this.form.action, {
          method: 'PUT',
          body: new FormData(this.form)
        }).then((response) => {
          this.form.classList.add('hidden')
          this.success.classList.remove('hidden')

          return response
        })
      }).finally(() => {
        this.submitButton.disabled = false
      })
    })
  }

  clearSignaturePad () {
    this.pad.clear()
    this.updateSubmitButtonVisibility()
  }

  updateSubmitButtonVisibility () {
    if (this.pad.isEmpty()) {
      this.submitButton.style.display = 'none'
      this.placeholderButton.style.display = 'block'
    } else {
      this.submitButton.style.display = 'block'
      this.placeholderButton.style.display = 'none'
    }
  }

  async submitImage () {
    return new Promise((resolve, reject) => {
      cropCanvasAndExportToPNG(this.canvas, { errorOnTooSmall: true }).then(async (blob) => {
        const file = new File([blob], 'signature.png', { type: 'image/png' })

        const formData = new FormData()

        formData.append('file', file)
        formData.append('submitter_slug', this.dataset.slug)
        formData.append('name', 'attachments')
        formData.append('remember_signature', 'true')

        return fetch('/api/attachments', {
          method: 'POST',
          body: formData
        }).then((resp) => resp.json()).then((attachment) => {
          return resolve(attachment)
        })
      }).catch((error) => {
        return reject(error)
      })
    })
  }

  get submitButton () {
    return this.querySelector('button[type="submit"]')
  }

  get clearButton () {
    return this.querySelector('button[aria-label="Clear"]')
  }

  get placeholderButton () {
    return this.querySelector('button[disabled]')
  }

  get canvas () {
    return this.querySelector('canvas')
  }

  get valueInput () {
    return this.querySelector('input[name^="values"]')
  }

  get form () {
    return this.querySelector('form')
  }

  get success () {
    return this.querySelector('#success')
  }
})

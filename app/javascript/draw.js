import SignaturePad from 'signature_pad'
import { cropCanvasAndExportToPNG } from './submission_form/crop_canvas'
import { isValidSignatureCanvas } from './submission_form/validate_signature'

window.customElements.define('draw-signature', class extends HTMLElement {
  connectedCallback () {
    this.setCanvasSize()

    this.pad = new SignaturePad(this.canvas)

    this.resizeObserver = new ResizeObserver(() => {
      requestAnimationFrame(() => {
        if (!this.canvas) return

        const { width, height } = this.canvas

        this.setCanvasSize()

        if (this.canvas.width !== width || this.canvas.height !== height) {
          this.redrawCanvas(width, height)
        }
      })
    })

    this.resizeObserver.observe(this.canvas.parentNode)

    if (this.dataset.color) {
      this.pad.penColor = this.dataset.color
    }

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
      }).catch(error => {
        console.log(error)
      }).finally(() => {
        this.submitButton.disabled = false
      })
    })
  }

  clearSignaturePad () {
    this.pad.clear()
    this.updateSubmitButtonVisibility()
  }

  disconnectedCallback () {
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
    }
  }

  setCanvasSize () {
    const scale = 3

    const width = this.canvas.parentNode.clientWidth
    const height = this.canvas.parentNode.clientHeight

    if (this.canvas.width !== width * scale || this.canvas.height !== height * scale) {
      this.canvas.width = width * scale
      this.canvas.height = height * scale

      this.canvas.getContext('2d').scale(scale, scale)
    }
  }

  redrawCanvas (oldWidth, oldHeight) {
    if (this.pad && !this.pad.isEmpty() && oldWidth > 0 && oldHeight > 0) {
      const sx = this.canvas.width / oldWidth
      const sy = this.canvas.height / oldHeight

      const scaledData = this.pad.toData().map((stroke) => ({
        ...stroke,
        points: stroke.points.map((p) => ({ ...p, x: p.x * sx, y: p.y * sy }))
      }))

      this.pad.fromData(scaledData)
    }
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
    if (!isValidSignatureCanvas(this.pad.toData())) {
      alert('Signature is too small or simple. Please redraw.')

      return Promise.reject(new Error('Image too small or simple'))
    }

    return cropCanvasAndExportToPNG(this.canvas).then(async (blob) => {
      const file = new File([blob], 'signature.png', { type: 'image/png' })

      const formData = new FormData()

      formData.append('file', file)
      formData.append('submitter_slug', this.dataset.slug)
      formData.append('name', 'attachments')
      formData.append('remember_signature', 'true')

      return fetch('/api/attachments', {
        method: 'POST',
        body: formData
      }).then(resp => resp.json())
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

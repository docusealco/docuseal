import { target, targetable } from '@github/catalyst/lib/targetable'
import { cropCanvasAndExportToPNG } from '../submission_form/crop_canvas'

export default targetable(class extends HTMLElement {
  static [target.static] = ['canvas', 'input', 'clear', 'button']

  async connectedCallback () {
    this.canvas.width = this.canvas.parentNode.parentNode.clientWidth
    this.canvas.height = this.canvas.parentNode.parentNode.clientWidth / 3

    const { default: SignaturePad } = await import('signature_pad')

    this.pad = new SignaturePad(this.canvas)

    this.clear.addEventListener('click', (e) => {
      e.preventDefault()

      this.pad.clear()
    })

    this.button.addEventListener('click', (e) => {
      e.preventDefault()

      this.button.disabled = true

      this.submit()
    })
  }

  async submit () {
    const blob = await cropCanvasAndExportToPNG(this.canvas)
    const file = new File([blob], 'signature.png', { type: 'image/png' })

    const dataTransfer = new DataTransfer()

    dataTransfer.items.add(file)

    this.input.files = dataTransfer.files

    if (this.input.webkitEntries.length) {
      this.input.dataset.file = `${dataTransfer.files[0].name}`
    }

    this.closest('form').requestSubmit()
  }
})

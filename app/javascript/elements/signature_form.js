import { target, targetable } from '@github/catalyst/lib/targetable'
import { cropCanvasAndExportToPNG } from '../submission_form/crop_canvas'

export default targetable(class extends HTMLElement {
  static [target.static] = ['canvas', 'input', 'clear', 'button']

  async connectedCallback () {
    const { default: SignaturePad } = await import('signature_pad')

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

  disconnectedCallback () {
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
    }
  }

  setCanvasSize () {
    const scale = 3

    const width = this.canvas.parentNode.clientWidth
    const height = this.canvas.parentNode.clientWidth / 2.5

    if (this.canvas.width !== width * scale || this.canvas.height !== height * scale) {
      this.canvas.width = width * scale
      this.canvas.height = height * scale

      this.canvas.getContext('2d').scale(scale, scale)
    }
  }

  redrawCanvas (oldWidth, oldHeight) {
    if (this.pad && !this.pad.isEmpty()) {
      const sx = this.canvas.width / oldWidth
      const sy = this.canvas.height / oldHeight

      const scaledData = this.pad.toData().map((stroke) => ({
        ...stroke,
        points: stroke.points.map((p) => ({ ...p, x: p.x * sx, y: p.y * sy }))
      }))

      this.pad.fromData(scaledData)
    }
  }
})

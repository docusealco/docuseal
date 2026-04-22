import { target, targetable } from '@github/catalyst/lib/targetable'
import { cropCanvasAndExportToPNG } from '../submission_form/crop_canvas'

const SIGNATURE_FONTS = {
  'Dancing Script': 'DancingScript-Regular.otf',
  'Great Vibes': 'GreatVibes-Regular.ttf',
  Pacifico: 'Pacifico-Regular.ttf',
  Caveat: 'Caveat-Regular.ttf',
  'Homemade Apple': 'HomemadeApple-Regular.ttf',
  'Mrs Saint Delafield': 'MrsSaintDelafield-Regular.ttf',
  'Shadows Into Light': 'ShadowsIntoLight-Regular.ttf',
  'Alex Brush': 'AlexBrush-Regular.ttf',
  Kalam: 'Kalam-Regular.ttf',
  Sacramento: 'Sacramento-Regular.ttf',
  'Herr Von Muellerhoff': 'HerrVonMuellerhoff-Regular.ttf'
}

const fontLoadPromises = {}
const scale = 3

export default targetable(class extends HTMLElement {
  static [target.static] = ['canvas', 'textInput', 'fontSelect', 'input', 'button', 'fontHidden']

  async connectedCallback () {
    this.setCanvasSize()

    this.resizeObserver = new ResizeObserver(() => {
      requestAnimationFrame(() => {
        if (!this.canvas) return

        this.setCanvasSize()
        this.updateCanvas()
      })
    })

    this.resizeObserver.observe(this.canvas.parentNode)

    this.textInput.addEventListener('input', () => this.updateCanvas())

    this.fontSelect.addEventListener('change', async () => {
      this.fontHidden.value = this.fontSelect.value
      await this.loadFont(this.fontSelect.value)
      this.updateCanvas()
    })

    this.button.addEventListener('click', (e) => {
      e.preventDefault()

      if (!this.textInput.value.trim()) return

      this.button.disabled = true
      this.submit()
    })

    await this.loadFont(this.fontSelect.value)

    if (this.textInput.value) {
      this.updateCanvas()
    }
  }

  disconnectedCallback () {
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
    }
  }

  setCanvasSize () {
    const width = this.canvas.parentNode.clientWidth
    const height = width / 2.5

    if (this.canvas.width !== width * scale || this.canvas.height !== height * scale) {
      this.canvas.width = width * scale
      this.canvas.height = height * scale
      this.canvas.getContext('2d').scale(scale, scale)
    }
  }

  loadFont (fontName) {
    const file = SIGNATURE_FONTS[fontName]
    if (!file) return Promise.resolve()

    if (!fontLoadPromises[fontName]) {
      const ext = file.endsWith('.otf') ? 'opentype' : 'truetype'
      const font = new FontFace(fontName, `url(/fonts/${file}) format("${ext}")`)

      fontLoadPromises[fontName] = font.load().then((loadedFont) => {
        document.fonts.add(loadedFont)
      }).catch((error) => {
        console.error('Font loading failed:', error)
      })
    }

    return fontLoadPromises[fontName]
  }

  updateCanvas () {
    const context = this.canvas.getContext('2d')
    const text = this.textInput.value
    const fontFamily = this.fontSelect.value
    const initialFontSize = 44

    const setFontSize = (size) => {
      context.font = `italic ${size}px "${fontFamily}"`
    }

    const maxWidth = this.canvas.width / scale
    let size = initialFontSize

    setFontSize(size)

    while (context.measureText(text).width > maxWidth && size > 1) {
      size -= 1
      setFontSize(size)
    }

    context.textAlign = 'center'
    context.clearRect(0, 0, this.canvas.width / scale, this.canvas.height / scale)
    context.fillText(text, this.canvas.width / 2 / scale, this.canvas.height / 2 / scale + 11)
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

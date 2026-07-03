export function convertImage (sourceFile, targetType, quality) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()

    reader.onload = function (event) {
      const img = new Image()

      img.onload = function () {
        const canvas = document.createElement('canvas')
        const ctx = canvas.getContext('2d')

        canvas.width = img.width
        canvas.height = img.height
        ctx.drawImage(img, 0, 0)
        canvas.toBlob(function (blob) {
          const ext = targetType === 'image/jpeg' ? '.jpg' : '.png'
          const newFile = new File([blob], sourceFile.name.replace(/\.\w+$/, ext), { type: targetType })
          resolve(newFile)
        }, targetType, quality)
      }

      img.onerror = () => reject(new Error(`browser cannot decode ${sourceFile.type || sourceFile.name}`))

      img.src = event.target.result
    }
    reader.onerror = reject
    reader.readAsDataURL(sourceFile)
  })
}

export async function convertImagesInInput (input) {
  if (!input.files || input.files.length === 0) return

  const dt = new DataTransfer()
  let didConvert = false

  for (const file of Array.from(input.files)) {
    let converted = file

    try {
      if (['image/bmp', 'image/vnd.microsoft.icon', 'image/svg+xml', 'image/gif'].includes(file.type)) {
        converted = await convertImage(file, 'image/png')
        didConvert = true
      } else if (['image/heic', 'image/heif', 'image/heic-sequence', 'image/heif-sequence', 'image/avif', 'image/avif-sequence', 'image/webp'].includes(file.type)) {
        converted = await convertImage(file, 'image/jpeg', 0.9)
        didConvert = true
      }
    } catch (e) {
      alert(e.message)
    }

    dt.items.add(converted)
  }

  if (didConvert) {
    input.files = dt.files
  }
}

export default class extends HTMLElement {
  connectedCallback () {
    const input = this.querySelector('input[type="file"]')
    const form = input.form

    input.addEventListener('change', async () => {
      await convertImagesInInput(input)

      form.querySelector('[type="submit"]')?.setAttribute('disabled', true)

      form.requestSubmit()
    })
  }
}

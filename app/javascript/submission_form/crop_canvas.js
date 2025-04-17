function cropCanvasAndExportToPNG (canvas, { errorOnTooSmall } = { errorOnTooSmall: false }) {
  const ctx = canvas.getContext('2d')

  const width = canvas.width
  const height = canvas.height

  let topmost = height
  let bottommost = 0
  let leftmost = width
  let rightmost = 0

  const imageData = ctx.getImageData(0, 0, width, height)
  const pixels = imageData.data

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const pixelIndex = (y * width + x) * 4
      const alpha = pixels[pixelIndex + 3]
      if (alpha !== 0) {
        topmost = Math.min(topmost, y)
        bottommost = Math.max(bottommost, y)
        leftmost = Math.min(leftmost, x)
        rightmost = Math.max(rightmost, x)
      }
    }
  }

  const croppedWidth = rightmost - leftmost + 1
  const croppedHeight = bottommost - topmost + 1

  const croppedCanvas = document.createElement('canvas')
  croppedCanvas.width = croppedWidth
  croppedCanvas.height = croppedHeight
  const croppedCtx = croppedCanvas.getContext('2d')

  if (errorOnTooSmall && (croppedWidth < 20 || croppedHeight < 20)) {
    return Promise.reject(new Error('Image too small'))
  }

  croppedCtx.drawImage(canvas, leftmost, topmost, croppedWidth, croppedHeight, 0, 0, croppedWidth, croppedHeight)

  return new Promise((resolve, reject) => {
    croppedCanvas.toBlob((blob) => {
      if (blob) {
        resolve(blob)
      } else {
        reject(new Error('Failed to create a PNG blob.'))
      }
    }, 'image/png')
  })
}

export { cropCanvasAndExportToPNG }

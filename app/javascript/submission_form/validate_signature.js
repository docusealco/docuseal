function isValidSignatureCanvas (data) {
  if (data.length === 0) return false

  const strokes = data.filter(stroke => Array.isArray(stroke.points) && stroke.points.length > 2)

  if (strokes.length === 0) return false

  let skippedStraightLine = 0

  const validStrokes = strokes.filter(stroke => {
    const points = stroke.points
    const first = points[0]
    const last = points[points.length - 1]
    const A = last.y - first.y
    const B = first.x - last.x
    const C = last.x * first.y - first.x * last.y
    const lineLength = Math.sqrt(A * A + B * B)

    const totalDeviation = points.reduce((sum, p) => {
      const distanceToLine = Math.abs(A * p.x + B * p.y + C) / lineLength
      return sum + distanceToLine
    }, 0)

    const avgDeviation = totalDeviation / points.length

    if (avgDeviation < 3 && skippedStraightLine < 2) {
      skippedStraightLine++

      return false
    }

    return true
  })

  return validStrokes.length > 0
}

function isCanvasBlocked () {
  try {
    const testCanvas = document.createElement('canvas')

    testCanvas.width = 2
    testCanvas.height = 2

    const ctx = testCanvas.getContext('2d')

    ctx.fillStyle = 'rgb(255, 0, 0)'
    ctx.fillRect(0, 0, 2, 2)

    const pixel = ctx.getImageData(0, 0, 1, 1).data

    return pixel[0] !== 255 || pixel[1] !== 0 || pixel[2] !== 0 || pixel[3] !== 255
  } catch (e) {
    return true
  }
}

export { isValidSignatureCanvas, isCanvasBlocked }

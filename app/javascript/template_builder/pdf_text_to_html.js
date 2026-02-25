function escapeHtml (str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;')
}

function isNumberedHeading (line) {
  return line.length <= 80 && /^\d+\.\s+[A-Z]/.test(line) && !/[.!?,;]$/.test(line)
}

function isAllCapsHeading (line) {
  return line.length >= 3 && !/[.!?,;]$/.test(line) && line === line.toUpperCase() && /[A-Z]/.test(line)
}

export function pdfTextToHtml (pageText) {
  if (!pageText) return ''

  const lines = pageText.split(/\r?\n/)
  let output = ''
  let inList = false

  for (const line of lines) {
    const stripped = line.trim()

    if (!stripped) {
      if (inList) { output += '</ul>'; inList = false }
      continue
    }

    if (isNumberedHeading(stripped)) {
      if (inList) { output += '</ul>'; inList = false }
      output += `<h3>${escapeHtml(stripped)}</h3>`
    } else if (isAllCapsHeading(stripped)) {
      if (inList) { output += '</ul>'; inList = false }
      output += `<h2>${escapeHtml(stripped)}</h2>`
    } else {
      const match = stripped.match(/^[•*-]\s+(.+)/)
      if (match) {
        if (!inList) { output += '<ul>'; inList = true }
        output += `<li>${escapeHtml(match[1])}</li>`
      } else {
        if (inList) { output += '</ul>'; inList = false }
        output += `<p dir="auto">${escapeHtml(stripped)}</p>`
      }
    }
  }

  if (inList) output += '</ul>'
  return output
}

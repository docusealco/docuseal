export function announceError (message, timeout = 7000) {
  const el = document.createElement('div')
  el.setAttribute('role', 'alert')
  el.setAttribute('aria-live', 'assertive')
  el.className = 'sr-only'
  el.textContent = message
  document.body.append(el)
  setTimeout(() => el.remove(), timeout)
}

export function announcePolite (message, timeout = 5000) {
  const el = document.createElement('div')
  el.setAttribute('aria-live', 'polite')
  el.className = 'sr-only'
  el.textContent = message
  document.body.append(el)
  setTimeout(() => el.remove(), timeout)
}

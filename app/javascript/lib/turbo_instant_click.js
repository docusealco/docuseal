const requestCache = new Map()
const cacheTtl = 10 * 1000

function isPreloadable (linkElement) {
  const href = linkElement.getAttribute('href')

  if (!href || href === '#' || linkElement.dataset.turbo === 'false' || linkElement.dataset.prefetch === 'false') {
    return
  }

  if (linkElement.origin !== document.location.origin) {
    return
  }

  if (!['http:', 'https:'].includes(linkElement.protocol)) {
    return
  }

  if (linkElement.pathname + linkElement.search === document.location.pathname + document.location.search) {
    return
  }

  if (linkElement.dataset.turboMethod && linkElement.dataset.turboMethod !== 'get') {
    return
  }

  return true
}

function mouseoverListener (event) {
  let linkElement

  if (event.target.tagName === 'A') {
    linkElement = event.target
  } else {
    linkElement = event.target.closest('a')
  }

  if (!linkElement) {
    return
  }

  if (!isPreloadable(linkElement)) {
    return
  }

  const url = linkElement.getAttribute('href')
  const loc = new URL(url, location.protocol + '//' + location.host)
  const absoluteUrl = loc.toString()

  const cached = requestCache.get(absoluteUrl)

  if (cached && cached.ttl > new Date()) {
    return
  }

  const requestOptions = {
    credentials: 'same-origin',
    headers: { Accept: 'text/html, application/xhtml+xml', 'VND.PREFETCH': 'true' },
    method: 'GET',
    redirect: 'follow'
  }

  if (linkElement.dataset.turboFrame && linkElement.dataset.turboFrame !== '_top') {
    requestOptions.headers['Turbo-Frame'] = linkElement.dataset.turboFrame
  } else if (linkElement.dataset.turboFrame !== '_top') {
    const turboFrame = linkElement.closest('turbo-frame')

    if (turboFrame) {
      requestOptions.headers['Turbo-Frame'] = turboFrame.id
    }
  }

  requestCache.set(absoluteUrl, { request: fetch(absoluteUrl, requestOptions), ttl: new Date(new Date().getTime() + cacheTtl) })
}

function turboBeforeFetchRequest (event) {
  if (event.target.tagName !== 'FORM' && event.detail.fetchOptions.method === 'GET') {
    const cached = requestCache.get(event.detail.url.toString())

    if (cached && cached.ttl > new Date()) {
      event.detail.response = cached.request
    }
  }

  requestCache.clear()
}

function start () {
  if (!window.turboInstantClickEnabled) {
    document.addEventListener('turbo:before-fetch-request', turboBeforeFetchRequest)
    document.addEventListener('mouseover', mouseoverListener, { capture: true, passive: true })
  }

  window.turboInstantClickEnabled = true
}

export { start }

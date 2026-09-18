const handlers = window.webkit?.messageHandlers

if (handlers?.native && window === window.top) {
  handlers.native.postMessage({ type: 'reset' })

  const reportPathConfiguration = () => {
    const element = document.getElementById('native_path_configuration')

    if (element) handlers.native.postMessage({ type: 'path-configuration', json: element.textContent })
  }

  document.addEventListener('turbo:load', reportPathConfiguration)

  reportPathConfiguration()

  const reportFlash = (element) => {
    if (!element) return

    if (element.dataset.notice) handlers.flash.postMessage({ style: 'notice', message: element.dataset.notice })
    if (element.dataset.alert) handlers.flash.postMessage({ style: 'alert', message: element.dataset.alert })

    element.remove()
  }

  const reportPageFlash = () => reportFlash(document.getElementById('native_flash'))

  new MutationObserver(reportPageFlash).observe(document.documentElement, { childList: true, subtree: true })

  document.addEventListener('turbo:load', reportPageFlash)

  document.addEventListener('native:flash', (event) => {
    reportFlash(new DOMParser().parseFromString(event.detail.html, 'text/html').getElementById('native_flash'))
  })

  reportPageFlash()

  document.addEventListener('click', (event) => {
    const link = event.target.closest?.('a[href]')

    if (!link) return

    const action = link.closest('native-action, native-menu-action')
    const title = link.dataset.nativeTitle || link.getAttribute('aria-label') || link.closest('[data-native-title]')?.dataset.nativeTitle || action?.dataset.label || action?.textContent.replace(/\s+/g, ' ').trim()

    if (!title) return

    const actions = link.closest('[data-native-actions]')?.dataset.nativeActions

    handlers.native.postMessage({ type: 'title', url: link.href, title, actions: actions ? actions.split(',') : null })
  }, true)

  document.addEventListener('click', (event) => {
    if (document.querySelector('native-modal')) return

    const link = event.target.closest?.('a[data-turbo-frame="modal"], a[data-turbo-frame="drawer"]')

    if (!link?.href) return

    event.preventDefault()
    event.stopPropagation()

    handlers.modal.postMessage({ action: 'open', url: link.href, modal: link.closest('[data-native-modal]')?.dataset.nativeModal || '' })
  }, true)

  document.addEventListener('native:action', (event) => {
    document.querySelector(`[data-native-id="${event.detail.id}"]`)?.click()
  })

  document.addEventListener('native:title-bottom', (event) => {
    const rect = document.querySelector('h1, h2')?.getBoundingClientRect()

    event.detail.result = rect?.height ? rect.bottom - document.documentElement.getBoundingClientRect().top : null
  })
}

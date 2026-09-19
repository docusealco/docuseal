const ICONS = {
  ios: {
    link: 'link',
    archive: 'archivebox',
    folder: 'folder',
    trash: 'trash',
    rotate: 'arrow.counterclockwise',
    copy: 'doc.on.doc',
    pencil: 'pencil',
    logs: 'list.bullet.rectangle',
    external_link: 'arrow.up.right.square',
    download: 'arrow.down.circle',
    mail_forward: 'paperplane',
    send: 'paperplane',
    writing: 'signature',
    adjustments_horizontal: 'slider.horizontal.3',
    file_text: 'doc.text',
    files: 'doc.on.doc',
    plus: 'plus',
    eye: 'eye',
    check: 'checkmark',
    code: 'chevron.left.forwardslash.chevron.right',
    history: 'clock.arrow.circlepath',
    user: 'person',
    users: 'person.2',
    users_plus: 'person.badge.plus',
    photo: 'photo',
    settings: 'gearshape',
    logout: 'rectangle.portrait.and.arrow.right',
    upload: 'arrow.up.doc',
    scan: 'doc.viewfinder',
    pencil_plus: 'square.and.pencil',
    arrow_sort: 'arrow.up.arrow.down',
    sort_descending_numbers: 'calendar',
    sort_descending_small_big: 'clock.arrow.circlepath',
    sort_ascending_letters: 'textformat.abc',
    calendar: 'calendar',
    calendar_check: 'calendar.badge.checkmark',
    info_circle: 'info.circle',
    list: 'list.bullet',
    clock: 'clock',
    circle_check: 'checkmark.circle'
  }
}

const platform = navigator.userAgent.includes('Hotwire Native Android') ? 'android' : 'ios'

export function nativeIcon (name) {
  return ICONS[platform]?.[name] || name
}

const handlers = window.webkit?.messageHandlers

if (handlers?.native && window === window.top) {
  handlers.native.postMessage({ type: 'reset' })

  const reportPathConfiguration = () => {
    const element = document.getElementById('native_path_configuration')

    if (!element) return

    const config = JSON.parse(element.textContent)

    config.rules.forEach(({ properties }) => {
      if (properties.native_actions) properties.native_actions = properties.native_actions.map(nativeIcon)
    })

    handlers.native.postMessage({ type: 'path-configuration', json: JSON.stringify(config) })
  }

  document.addEventListener('turbo:load', reportPathConfiguration)

  document.addEventListener('turbo:before-cache', () => {
    document.getElementById('native_path_configuration')?.remove()
  })

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
    const link = event.target.closest('a[href]')

    if (!link) return

    const action = link.closest('native-action, native-menu-action')
    const title = link.dataset.nativeTitle || link.getAttribute('aria-label') || link.closest('[data-native-title]')?.dataset.nativeTitle || action?.dataset.label || action?.textContent.replace(/\s+/g, ' ').trim()

    if (!title) return

    const actions = link.closest('[data-native-actions]')?.dataset.nativeActions

    handlers.native.postMessage({ type: 'title', url: link.href, title, actions: actions ? actions.split(',').map(nativeIcon) : null })
  }, true)

  document.addEventListener('click', (event) => {
    if (document.querySelector('native-modal')) return

    const link = event.target.closest('a[data-turbo-frame="modal"], a[data-turbo-frame="drawer"]')

    if (!link?.href) return

    event.preventDefault()
    event.stopPropagation()

    handlers.modal.postMessage({ action: 'open', url: link.href, modal: link.closest('[data-native-modal]')?.dataset.nativeModal || '' })
  }, true)

  let isTouchPrefetch = false

  document.addEventListener('touchstart', (event) => {
    isTouchPrefetch = true
    event.target.closest('a[href]')?.dispatchEvent(new MouseEvent('mouseenter'))
    isTouchPrefetch = false
  }, { passive: true })

  document.addEventListener('turbo:before-prefetch', (event) => {
    if (!isTouchPrefetch || event.target.closest('a[data-turbo-frame="modal"], a[data-turbo-frame="drawer"]')) {
      event.preventDefault()
    }
  })

  document.addEventListener('native:action', (event) => {
    document.querySelector(`[data-native-id="${event.detail.id}"]`)?.click()
  })

  document.addEventListener('native:title-bottom', (event) => {
    const rect = document.querySelector('h1, h2')?.getBoundingClientRect()

    event.detail.result = rect?.height ? rect.bottom - document.documentElement.getBoundingClientRect().top : null
  })
}

if (handlers?.native && window.Turbo) {
  const staleSnapshots = new Set()
  let isRestoring = false

  window.Turbo.session.view.clearSnapshotCache = function () {
    this.snapshotCache.keys.forEach((key) => staleSnapshots.add(key))
  }

  window.Turbo.session.navigator.linkPrefetchingIsEnabledForLocation = () => !document.querySelector('native-modal')

  document.addEventListener('turbo:submit-end', (e) => {
    if (e.detail.success && !e.detail.formSubmission.isSafe) {
      handlers.native.postMessage({ type: 'stale' })
    }
  })

  document.addEventListener('native:pull-to-refresh', (event) => {
    const { session } = window.Turbo
    const url = new URL(document.baseURI)

    url.searchParams.delete('limit')

    session.history.replace(url, session.history.restorationIdentifier)
    session.view.lastRenderedLocation = url

    event.detail.result = new Promise((resolve) => {
      document.addEventListener('turbo:render', () => resolve(true), { once: true })
      document.addEventListener('turbo:fetch-request-error', () => resolve(true), { once: true })

      session.refresh(document.baseURI)
    })
  })

  document.addEventListener('native:refresh', () => {
    window.Turbo.session.refresh(document.baseURI)
  })

  document.addEventListener('native:turbo-stream', (e) => {
    if (!e.detail.body?.trimStart().startsWith('<turbo-stream')) return

    window.Turbo.renderStreamMessage(e.detail.body)
  })

  document.addEventListener('turbo:visit', (e) => {
    isRestoring = e.detail.action === 'restore'
  })

  document.addEventListener('turbo:load', () => {
    if (staleSnapshots.delete(window.location.href.split('#')[0]) && isRestoring && window.location.pathname !== '/search') {
      setTimeout(() => window.Turbo.session.refresh(document.baseURI))
    }
  })
}

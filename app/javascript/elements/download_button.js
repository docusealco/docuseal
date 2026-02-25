import { target, targetable } from '@github/catalyst/lib/targetable'
import { announceError } from './aria_announce'

export default targetable(class extends HTMLElement {
  static [target.static] = ['defaultButton', 'loadingButton']

  connectedCallback () {
    // Make element keyboard accessible
    if (!this.hasAttribute('tabindex')) {
      this.setAttribute('tabindex', '0')
    }
    if (!this.hasAttribute('role')) {
      this.setAttribute('role', 'button')
    }

    this.addEventListener('click', () => this.downloadFiles())

    // Add keyboard support for Enter and Space keys
    this.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault()
        this.downloadFiles()
      }
    })
  }

  toggleState () {
    this.defaultButton?.classList?.toggle('hidden')
    this.loadingButton?.classList?.toggle('hidden')
    // aria-busy reflects whether the loading state is now active (loadingButton visible)
    this.setAttribute('aria-busy', this.loadingButton?.classList?.contains('hidden') ? 'false' : 'true')
  }

  downloadFiles () {
    if (!this.dataset.src) return

    this.toggleState()

    fetch(this.dataset.src).then(async (response) => {
      if (response.ok) {
        const urls = await response.json()
        const isMobileSafariIos = 'ontouchstart' in window && navigator.maxTouchPoints > 0 && /AppleWebKit/i.test(navigator.userAgent)
        const isSafariIos = isMobileSafariIos || /iPhone|iPad|iPod/i.test(navigator.userAgent)

        if (isSafariIos && urls.length > 1) {
          this.downloadSafariIos(urls)
        } else {
          this.downloadUrls(urls)
        }
      } else {
        announceError('Failed to download files')
        this.toggleState()
      }
    })
  }

  downloadUrls (urls) {
    const fileRequests = urls.map((url) => {
      return () => {
        return fetch(url).then(async (resp) => {
          const blobUrl = URL.createObjectURL(await resp.blob())
          const link = document.createElement('a')

          link.href = blobUrl
          link.setAttribute('download', decodeURI(url.split('/').pop()))

          link.click()

          URL.revokeObjectURL(blobUrl)
        })
      }
    })

    fileRequests.reduce(
      (prevPromise, request) => prevPromise.then(() => request()),
      Promise.resolve()
    ).finally(() => {
      this.toggleState()
    })
  }

  downloadSafariIos (urls) {
    const fileRequests = urls.map((url) => {
      return fetch(url).then(async (resp) => {
        const blob = await resp.blob()
        const blobUrl = URL.createObjectURL(blob.slice(0, blob.size, 'application/octet-stream'))
        const link = document.createElement('a')

        link.href = blobUrl
        link.setAttribute('download', decodeURI(url.split('/').pop()))

        return link
      })
    })

    Promise.all(fileRequests).then((links) => {
      links.forEach((link, index) => {
        setTimeout(() => {
          link.click()

          URL.revokeObjectURL(link.href)
        }, index * 50)
      })
    }).finally(() => {
      this.toggleState()
    })
  }
})

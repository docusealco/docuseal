import { target, targetable } from '@github/catalyst/lib/targetable'

export default targetable(class extends HTMLElement {
  static [target.static] = ['defaultButton', 'loadingButton']

  connectedCallback () {
    this.addEventListener('click', () => this.downloadFiles())
  }

  toggleState () {
    this.defaultButton?.classList?.toggle('hidden')
    this.loadingButton?.classList?.toggle('hidden')
  }

  downloadFiles () {
    if (!this.dataset.src) return

    this.toggleState()

    fetch(this.dataset.src).then(async (response) => {
      if (response.ok) {
        const urls = await response.json()
        const isSafariIos = /iPhone|iPad|iPod/i.test(navigator.userAgent)

        if (isSafariIos && urls.length > 1) {
          this.downloadSafariIos(urls)
        } else {
          this.downloadUrls(urls)
        }
      } else {
        alert('Failed to download files')
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

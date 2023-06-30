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

    fetch(this.dataset.src).then((response) => response.json()).then((urls) => {
      const fileRequests = urls.map((url) => {
        return () => {
          return fetch(url).then(async (resp) => {
            const blobUrl = URL.createObjectURL(await resp.blob())
            const link = document.createElement('a')

            link.href = blobUrl
            link.setAttribute('download', decodeURI(url.split('/').pop()))

            link.click()

            URL.revokeObjectURL(url)
          })
        }
      })

      fileRequests.reduce(
        (prevPromise, request) => prevPromise.then(() => request()),
        Promise.resolve()
      )

      this.toggleState()
    })
  }
})

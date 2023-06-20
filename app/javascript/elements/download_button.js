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
      urls.forEach((url) => {
        fetch(url).then(async (resp) => {
          const blobUrl = URL.createObjectURL(await resp.blob())
          const link = document.createElement('a')

          link.href = blobUrl
          link.setAttribute('download', resp.headers.get('content-disposition').split('"')[1])

          link.click()

          URL.revokeObjectURL(url)
        })
      })
    }).finally(() => {
      this.toggleState()
    })
  }
})

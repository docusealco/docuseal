export default class extends HTMLElement {
  connectedCallback () {
    this.image.addEventListener('load', (e) => {
      this.image.setAttribute('width', e.target.naturalWidth)
      this.image.setAttribute('height', e.target.naturalHeight)

      this.style.aspectRatio = `${e.target.naturalWidth} / ${e.target.naturalHeight}`
    })
  }

  get image () {
    return this.querySelector('img')
  }
}

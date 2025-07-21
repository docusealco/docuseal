export default class extends HTMLElement {
  connectedCallback () {
    const image = this.querySelector('img')

    image.addEventListener('load', (e) => {
      image.setAttribute('width', e.target.naturalWidth)
      image.setAttribute('height', e.target.naturalHeight)

      this.style.aspectRatio = `${e.target.naturalWidth} / ${e.target.naturalHeight}`
    })
  }
}

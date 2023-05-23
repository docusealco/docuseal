export default class extends HTMLElement {
  setValue (value) {
    const { fieldType } = this.dataset

    if (fieldType === 'signature') {
      [...this.children].forEach(e => e.remove())

      const img = document.createElement('img')

      img.classList.add('w-full', 'h-full', 'object-contain')
      img.src = value.url

      this.append(img)
    } else {
      this.innerHTML = value
    }
  }
}

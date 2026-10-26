export default class extends HTMLElement {
  connectedCallback () {
    const dialog = document.getElementById(this.dataset.target)

    this.querySelector('button').addEventListener('click', () => {
      if (dialog) {
        dialog.inert = false
        dialog.showModal()
      }
    })

    if (dialog) {
      dialog.addEventListener('close', () => {
        dialog.inert = true
      })
    }
  }
}

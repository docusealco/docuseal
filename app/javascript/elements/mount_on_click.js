export default class extends HTMLElement {
  connectedCallback () {
    this.addEventListener('click', () => {
      document.body.append(this.template.content)
    })
  }

  get template () {
    return document.getElementById(this.dataset.templateId)
  }
}

export default class extends HTMLElement {
  connectedCallback () {
    this.events.forEach((event) => this.form.addEventListener(event, this.toggle))

    this.toggle()
  }

  disconnectedCallback () {
    this.events.forEach((event) => this.form.removeEventListener(event, this.toggle))
  }

  toggle = (event) => {
    if (event?.type === 'input' && event.target.matches(this.fieldSelector('name'))) return

    const isNameOnly = (field) => this.isFilled('name') && !this.isFilled(field)

    const isSend = (this.isChecked('send_email') && !isNameOnly('email')) ||
      (this.isChecked('send_sms') && !isNameOnly('phone'))

    this.firstElementChild.classList.toggle('hidden', !isSend)
    this.lastElementChild.classList.toggle('hidden', isSend)
  }

  isChecked (name) {
    return !!this.form.querySelector(`[name="${name}"]:checked:enabled`)
  }

  isFilled (field) {
    return [...this.form.querySelectorAll(this.fieldSelector(field))].some((input) => input.value.trim())
  }

  fieldSelector (field) {
    return `[name$="[][${field}]"]`
  }

  get events () {
    return ['change', 'input', 'linked-input.update']
  }

  get form () {
    return this.closest('form')
  }
}

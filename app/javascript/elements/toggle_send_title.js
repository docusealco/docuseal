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

    if (event?.type === 'focusin' && !this.isKeepSendUsed && this.isFocusFromName(event)) {
      this.isKeepSendUsed = true
      this.keepSendInput = event.target
    } else if (event?.type === 'focusout' && event.target === this.keepSendInput) {
      this.keepSendInput = null
    }

    const isNameOnly = (field) => this.isFilled('name') && !this.isFilled(field) && !this.keepSendInput?.matches(this.fieldSelector(field))

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

  isFocusFromName ({ target, relatedTarget }) {
    return !!relatedTarget?.matches(this.fieldSelector('name')) && !!relatedTarget.value.trim() &&
      ['email', 'phone'].some((field) => target.matches(this.fieldSelector(field)))
  }

  fieldSelector (field) {
    return `[name$="[][${field}]"]`
  }

  get events () {
    return ['change', 'input', 'linked-input.update', 'focusin', 'focusout']
  }

  get form () {
    return this.closest('form')
  }
}

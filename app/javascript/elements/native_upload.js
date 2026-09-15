import { convertImagesInInput } from './convert_upload'

export default class extends HTMLElement {
  connectedCallback () {
    this.files = []

    document.addEventListener('turbo:submit-end', this.onSubmitEnd)
  }

  disconnectedCallback () {
    document.removeEventListener('turbo:submit-end', this.onSubmitEnd)
  }

  get form () {
    return this.querySelector('form')
  }

  append (index, name, type, base64) {
    const file = this.files[index] ||= { name, type, chunks: [] }

    file.chunks.push(Uint8Array.from(atob(base64), (char) => char.charCodeAt(0)))
  }

  async submit (url) {
    const dataTransfer = new DataTransfer()

    this.files.forEach(({ name, type, chunks }) => dataTransfer.items.add(new File(chunks, name, { type })))
    this.files = []

    const input = this.form.querySelector('[type="file"]')

    input.files = dataTransfer.files

    await convertImagesInInput(input)

    this.form.action = url
    this.form.requestSubmit()
  }

  onSubmitEnd = (e) => {
    if (e.detail.formSubmission?.formElement !== this.form) return

    window.webkit?.messageHandlers?.native?.postMessage({ type: 'upload', success: e.detail.success })
  }
}

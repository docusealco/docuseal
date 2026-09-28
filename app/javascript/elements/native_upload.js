import { convertImagesInInput } from './convert_upload'

export default class extends HTMLElement {
  connectedCallback () {
    this.files = []

    document.addEventListener('turbo:submit-end', this.onSubmitEnd)
    document.addEventListener('native:upload-start', this.onUploadStart)
    document.addEventListener('native:upload-chunk', this.onUploadChunk)
    document.addEventListener('native:upload-submit', this.onUploadSubmit)
  }

  disconnectedCallback () {
    document.removeEventListener('turbo:submit-end', this.onSubmitEnd)
    document.removeEventListener('native:upload-start', this.onUploadStart)
    document.removeEventListener('native:upload-chunk', this.onUploadChunk)
    document.removeEventListener('native:upload-submit', this.onUploadSubmit)
  }

  get form () {
    return this.querySelector('form')
  }

  onUploadStart = (event) => {
    this.files = []

    event.detail.result = true
  }

  onUploadChunk = ({ detail: { index, name, type, chunk } }) => {
    const file = this.files[index] ||= { name, type, chunks: [] }

    file.chunks.push(Uint8Array.from(atob(chunk), (char) => char.charCodeAt(0)))
  }

  onUploadSubmit = (event) => {
    event.detail.result = this.submit(event.detail.url)
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

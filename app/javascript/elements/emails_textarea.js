const emailRegexp = /([^@;,<>\s]+@[^@;,<>\s]+)/g

export default class extends HTMLElement {
  connectedCallback () {
    if (this.dataset.limit) {
      this.textarea.addEventListener('input', () => {
        const emails = this.textarea.value.match(emailRegexp) || []

        this.updateCounter(emails.length)
      })
    }
  }

  updateCounter (count) {
    let counter = document.getElementById('emails_counter')
    let bulkMessage = document.getElementById('bulk_message')

    if (count < 2) {
      counter?.remove()

      return
    }

    if ((count + 10) > this.dataset.limit) {
      if (!counter) {
        counter = document.createElement('span')

        counter.id = 'emails_counter'
        counter.classList.add('text-xs', 'right-0', 'absolute')
        counter.style.bottom = '-15px'

        this.textarea.parentNode.append(counter)
      }

      counter.innerText = `${count} / ${this.dataset.limit}`
    }

    if (this.dataset.bulkEnabled !== 'true') {
      if (!bulkMessage) {
        bulkMessage = document.createElement('span')

        bulkMessage.id = 'bulk_message'
        bulkMessage.classList.add('text-xs', 'left-0', 'absolute')
        bulkMessage.style.bottom = '-15px'

        this.textarea.parentNode.append(bulkMessage)
      }

      bulkMessage.innerHTML = '<a class="link" data-turbo="false" href="/upgrade">Upgrade</a> to bulk send multiple recipients'
    }
  }

  get textarea () {
    return this.querySelector('textarea')
  }
}

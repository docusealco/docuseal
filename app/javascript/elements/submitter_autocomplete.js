import autocomplete from 'autocompleter'

export default class extends HTMLElement {
  connectedCallback () {
    autocomplete({
      input: this.input,
      preventSubmit: 1,
      minLength: 1,
      showOnFocus: true,
      onSelect: this.onSelect,
      render: this.render,
      fetch: this.fetch
    })
  }

  onSelect = (item) => {
    const fields = ['email', 'name', 'phone']
    const submitterItemEl = this.closest('submitter-item')

    fields.forEach((field) => {
      const input = submitterItemEl.querySelector(`submitters-autocomplete[data-field="${field}"] input`)
      const textarea = submitterItemEl.querySelector(`submitters-autocomplete[data-field="${field}"] textarea`)

      if (input && item[field]) {
        input.value = item[field]
      }

      if (textarea && item[field]) {
        textarea.value = textarea.value.replace(/[^;,\s]+$/, item[field] + ' ')
      }
    })
  }

  fetch = (text, resolve) => {
    const q = text.split(/[;,\s]+/).pop().trim()

    if (q) {
      const queryParams = new URLSearchParams({ q, field: this.dataset.field })

      fetch('/api/submitters_autocomplete?' + queryParams).then(async (resp) => {
        const items = await resp.json()

        if (q.length < 3) {
          resolve(items.filter((e) => e[this.dataset.field].startsWith(q)))
        } else {
          resolve(items)
        }
      }).catch(() => {
        resolve([])
      })
    } else {
      resolve([])
    }
  }

  render = (item) => {
    const div = document.createElement('div')

    div.setAttribute('dir', 'auto')

    div.textContent = item[this.dataset.field]

    return div
  }

  get input () {
    return this.querySelector('input') || this.querySelector('textarea')
  }
}

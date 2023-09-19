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

      if (input && item[field]) {
        input.value = item[field]
      }
    })
  }

  fetch = (text, resolve) => {
    if (text) {
      const queryParams = new URLSearchParams({ q: text, field: this.dataset.field })

      fetch('/api/submitters_autocomplete?' + queryParams).then(async (resp) => {
        const items = await resp.json()

        resolve(items)
      }).catch(() => {
        resolve([])
      })
    } else {
      resolve([])
    }
  }

  render = (item) => {
    const div = document.createElement('div')

    div.textContent = item[this.dataset.field]

    return div
  }

  get input () {
    return this.querySelector('input')
  }
}

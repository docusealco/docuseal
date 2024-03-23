import autocomplete from 'autocompleter'

export default class extends HTMLElement {
  connectedCallback () {
    autocomplete({
      input: this.input,
      preventSubmit: this.dataset.submitOnSelect === 'true' ? 0 : 1,
      minLength: 0,
      showOnFocus: true,
      onSelect: this.onSelect,
      render: this.render,
      fetch: this.fetch
    })
  }

  onSelect = (item) => {
    this.input.value = item.name
  }

  fetch = (text, resolve) => {
    const queryParams = new URLSearchParams({ q: text })

    fetch('/template_folders_autocomplete?' + queryParams).then(async (resp) => {
      const items = await resp.json()

      resolve(items)
    }).catch(() => {
      resolve([])
    })
  }

  render = (item) => {
    const div = document.createElement('div')

    div.setAttribute('dir', 'auto')

    div.textContent = item.name

    return div
  }

  get input () {
    return this.querySelector('input')
  }
}

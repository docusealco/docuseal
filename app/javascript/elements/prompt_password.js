export default class extends HTMLElement {
  connectedCallback () {
    this.showDialog()
  }

  showDialog () {
    const dialogId = `prompt-password-dialog-${Math.random().toString(36).slice(2)}`
    const inputId = `prompt-password-input-${Math.random().toString(36).slice(2)}`

    const dialog = document.createElement('div')
    dialog.setAttribute('role', 'dialog')
    dialog.setAttribute('aria-modal', 'true')
    dialog.setAttribute('aria-labelledby', `${dialogId}-title`)
    dialog.id = dialogId
    dialog.className = 'fixed inset-0 z-50 flex items-center justify-center bg-black/50'

    dialog.innerHTML = `
      <div class="bg-base-100 rounded-xl shadow-xl p-6 w-full max-w-sm mx-4">
        <h2 id="${dialogId}-title" class="text-lg font-semibold mb-4">PDF Password Required</h2>
        <div class="form-control mb-4">
          <label for="${inputId}" class="label label-text mb-1">Enter PDF password</label>
          <input id="${inputId}" type="password" class="base-input w-full" autocomplete="current-password" />
        </div>
        <div class="flex justify-end gap-2">
          <button type="button" class="btn btn-ghost" data-action="cancel">Cancel</button>
          <button type="button" class="btn btn-neutral" data-action="confirm">Open</button>
        </div>
      </div>
    `

    document.body.append(dialog)

    const input = dialog.querySelector(`#${inputId}`)
    const cancelBtn = dialog.querySelector('[data-action="cancel"]')
    const confirmBtn = dialog.querySelector('[data-action="confirm"]')

    requestAnimationFrame(() => input.focus())

    const confirm = () => {
      const passwordInput = document.createElement('input')
      passwordInput.type = 'hidden'
      passwordInput.name = 'password'
      passwordInput.value = input.value
      this.form.append(passwordInput)
      dialog.remove()
      this.form.requestSubmit()
      this.remove()
    }

    const cancel = () => {
      dialog.remove()
      this.remove()
    }

    confirmBtn.addEventListener('click', confirm)
    cancelBtn.addEventListener('click', cancel)

    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') confirm()
      if (e.key === 'Escape') cancel()
    })

    dialog.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') cancel()
    })
  }

  get form () {
    return this.closest('form')
  }
}

window.customElements.define('file-photo', class extends HTMLElement {
  connectedCallback () {

    this.clearButton.addEventListener('click', (e) => {
      e.preventDefault()
      this.valueInput.value = null
      this.inputFile.click()
    })

    this.inputFile.addEventListener('change', (e) => {
      e.preventDefault()
      this.updateSubmitButtonVisibility()
      this.uploadFiles(this.inputFile.files)
    })

    this.form.addEventListener('submit', (e) => {
      e.preventDefault();
      this.submitButton.disabled = true
      fetch(this.form.action, {
        method: 'PUT',
        body: new FormData(this.form)
      }).then((response) => {
        this.form.classList.add('hidden')
        this.success.classList.remove('hidden')
        return response
      }).finally(() => {
        this.submitButton.disabled = false
      })
    })

  }

  toggleLoading = (e) => {
    this.updateSubmitButtonVisibility()
    if (e && e.target && !e.target.contains(this)) {
      return
    }
    this.loading.classList.toggle('hidden')
    this.icon.classList.toggle('hidden')
    this.classList.toggle('opacity-50')
  }

  async uploadFiles (files) {
    this.toggleLoading()
    return await Promise.all(
        Array.from(files).map(async (file) => {
          const formData = new FormData()
          if (file.type === 'image/bmp') {
            file = await this.convertBmpToPng(file)
          }

          formData.append('file', file)
          formData.append('submitter_slug', this.dataset.slug)
          formData.append('name', 'attachments')

          return fetch('/api/attachments', {
            method: 'POST',
            body: formData
          }).then(resp => resp.json()).then((data) => {
            return data
          })
        })).then((result) => {
        this.valueInput.value = result[0].uuid
        return result[0]
    }).finally(() => {
      this.toggleLoading()
    })
  }

  convertBmpToPng (bmpFile) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader()

      reader.onload = function (event) {
        const img = new Image()

        img.onload = function () {
          const canvas = document.createElement('canvas')
          const ctx = canvas.getContext('2d')

          canvas.width = img.width
          canvas.height = img.height
          ctx.drawImage(img, 0, 0)
          canvas.toBlob(function (blob) {
            const newFile = new File([blob], bmpFile.name.replace(/\.\w+$/, '.png'), { type: 'image/png' })
            resolve(newFile)
          }, 'image/png')
        }

        img.src = event.target.result
      }
      reader.onerror = reject
      reader.readAsDataURL(bmpFile)
    })
  }

  updateSubmitButtonVisibility () {
    if (!this.valueInput.value) {
        this.submitButton.style.display = 'none'
        this.placeholderButton.style.display = 'block'
    } else {
        this.submitButton.style.display = 'block'
        this.placeholderButton.style.display = 'none'
    }
  }

  get submitButton () {
    return this.querySelector('button[type="submit"]')
  }

  get clearButton () {
    return this.querySelector('button[aria-label="Clear"]')
  }

  get placeholderButton () {
    return this.querySelector('button[disabled]')
  }

  get valueInput () {
    return this.querySelector('input[name^="values"]')
  }

  get inputFile () {
    return this.querySelector('input[id="file"]')
  }

  get icon () {
    return this.querySelector('#file-photo-icon')
  }

  get loading () {
    return this.querySelector('#file-photo-loading')
  }

  get form () {
    return this.querySelector('form')
  }

  get success () {
    return this.querySelector('#success')
  }
})

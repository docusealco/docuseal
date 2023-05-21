import { targets, target, targetable } from '@github/catalyst/lib/targetable'
import { actionable } from '@github/catalyst/lib/actionable'

export default actionable(targetable(class extends HTMLElement {
  static observedAttributes = ['data-scale']

  static [target.static] = [
    'form',
    'completed',
    'submitButton'
  ]

  static [targets.static] = [
    'areas',
    'fields',
    'steps'
  ]

  passValueToArea (e) {
    return (this.areas || []).forEach((area) => {
      if (area.dataset.fieldUuid === e.target.id) {
        area.setValue(e.target.value)
      }
    })
  }

  submitSignature () {
    this.submitButton.click()
  }

  setVisibleStep (uuid) {
    this.steps.forEach((step) => {
      step.classList.toggle('hidden', step.dataset.fieldUuid !== uuid)
    })

    this.fields.find(f => f.id === uuid).focus()
  }

  submitForm (e) {
    e.preventDefault()

    e.submitter.setAttribute('disabled', true)

    fetch(this.form.action, {
      method: this.form.method,
      body: new FormData(this.form)
    }).then(response => {
      console.log('Form submitted successfully!', response)
      this.moveNextStep()
    }).catch(error => {
      console.error('Error submitting form:', error)
    }).finally(() => {
      e.submitter.removeAttribute('disabled')
    })
  }

  moveStepBack (e) {
    e.preventDefault()

    const currentStepIndex = this.steps.findIndex((el) => !el.classList.contains('hidden'))

    const previousStep = this.steps[currentStepIndex - 1]

    if (previousStep) {
      this.setVisibleStep(previousStep.dataset.fieldUuid)
    }
  }

  moveNextStep () {
    const currentStepIndex = this.steps.findIndex((el) => !el.classList.contains('hidden'))

    const nextStep = this.steps[currentStepIndex + 1]

    if (nextStep) {
      this.setVisibleStep(nextStep.dataset.fieldUuid)
    } else {
      this.form.classList.add('hidden')
      this.completed.classList.remove('hidden')
    }
  }

  focusField ({ target }) {
    this.setVisibleStep(target.dataset.fieldUuid)
  }

  focusArea ({ target }) {
    const area = this.areas.find(a => target.id === a.dataset.fieldUuid)

    if (area) {
      area.scrollIntoView({ behavior: 'smooth', block: 'center' })
    }
  }
}))

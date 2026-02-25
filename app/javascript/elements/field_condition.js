export default class extends HTMLElement {
  connectedCallback () {
    this.targetId = this.dataset.targetId
    this.fieldId = this.dataset.fieldId
    this.action = (this.dataset.action || '').trim()
    this.expectedValue = this.dataset.value

    this.targetEl = document.getElementById(this.targetId)
    this.sourceEl = document.getElementById(this.fieldId)

    this.bindListeners()

    this.evaluateAndApply()
  }

  disconnectedCallback () {
    this.unbindListeners()
  }

  bindListeners () {
    this.eventsFor(this.sourceEl).forEach((ev) => {
      this.sourceEl.addEventListener(ev, this.evaluateAndApply)
    })
  }

  unbindListeners () {
    this.eventsFor(this.sourceEl).forEach((ev) => {
      this.sourceEl.removeEventListener(ev, this.evaluateAndApply)
    })
  }

  eventsFor (el) {
    if (!el) return []

    const tag = el.tagName.toLowerCase()

    if (tag === 'textarea') return ['input']
    if (tag === 'input') return ['input', 'change']

    return ['change']
  }

  evaluateAndApply = () => {
    const fieldConditions = document.querySelectorAll(`field-condition[data-target-id="${this.targetId}"]`)

    const result = [...fieldConditions].reduce((acc, cond) => {
      if (cond.dataset.operation === 'or') {
        acc.push(acc.pop() || cond.checkCondition())
      } else {
        acc.push(cond.checkCondition())
      }

      return acc
    }, [])

    this.apply(!result.includes(false))
  }

  checkCondition () {
    const action = this.action
    const actual = this.getSourceValue()
    const expected = this.expectedValue

    if (action === 'empty' || action === 'unchecked') return this.isEmpty(actual)
    if (action === 'not_empty' || action === 'checked') return !this.isEmpty(actual)

    if (['equal', 'not_equal', 'greater_than', 'less_than'].includes(action) && this.sourceEl?.getAttribute('type') === 'number') {
      if (this.isEmpty(actual) || this.isEmpty(expected)) return false

      const actualNumber = parseFloat(actual)
      const expectedNumber = parseFloat(expected)

      if (Number.isNaN(actualNumber) || Number.isNaN(expectedNumber)) return false

      if (action === 'equal') return Math.abs(actualNumber - expectedNumber) < Number.EPSILON
      if (action === 'not_equal') return Math.abs(actualNumber - expectedNumber) > Number.EPSILON
      if (action === 'greater_than') return actualNumber > expectedNumber
      if (action === 'less_than') return actualNumber < expectedNumber

      return false
    }

    if (action === 'equal') {
      const list = Array.isArray(actual) ? actual : [actual]
      return list.filter((v) => v !== null && v !== undefined).map(String).includes(String(expected))
    }

    if (action === 'contains') return this.contains(actual, expected)

    if (action === 'not_equal') {
      const list = Array.isArray(actual) ? actual : [actual]
      return !list.filter((v) => v !== null && v !== undefined).map(String).includes(String(expected))
    }

    if (action === 'does_not_contain') return !this.contains(actual, expected)

    return true
  }

  getSourceValue () {
    const el = this.sourceEl

    if (!el) return

    const tag = el.tagName.toLowerCase()
    const type = (el.getAttribute('type') || '').toLowerCase()

    if (tag === 'select') return el.value
    if (tag === 'textarea') return el.value
    if (tag === 'input' && type === 'checkbox') return el.checked ? (el.value || '1') : null
    if (tag === 'input') return el.value

    return el.value ?? null
  }

  isEmpty (obj) {
    if (obj == null) return true

    if (Array.isArray(obj)) {
      return obj.length === 0
    }

    if (typeof obj === 'string') {
      return obj.trim().length === 0
    }

    if (typeof obj === 'object') {
      return Object.keys(obj).length === 0
    }

    if (obj === false) {
      return true
    }

    return false
  }

  contains (actual, expected) {
    if (expected === null || expected === undefined) return false

    const exp = String(expected)

    if (Array.isArray(actual)) return actual.filter((v) => v !== null && v !== undefined).map(String).includes(exp)

    if (typeof actual === 'string') return actual.includes(exp)

    return actual !== null && actual !== undefined && String(actual) === exp
  }

  apply (passed) {
    const controls = this.targetEl.matches('input, select, textarea, button')
      ? [this.targetEl]
      : Array.from(this.targetEl.querySelectorAll('input, select, textarea, button'))

    if (passed) {
      this.targetEl.style.display = ''
      this.targetEl.removeAttribute('aria-hidden')
      this.targetEl.labels.forEach((label) => { label.style.display = '' })

      controls.forEach((c) => (c.disabled = false))
    } else {
      this.targetEl.style.display = 'none'
      this.targetEl.setAttribute('aria-hidden', 'true')
      this.targetEl.labels.forEach((label) => { label.style.display = 'none' })

      controls.forEach((c) => (c.disabled = true))
    }
  }
}

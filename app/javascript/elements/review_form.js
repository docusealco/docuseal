import { announcePolite } from './aria_announce'

export default class extends HTMLElement {
  connectedCallback () {
    this.querySelectorAll('input[type="radio"]').forEach(radio => {
      radio.addEventListener('change', (event) => {
        const rating = parseInt(event.target.value)

        if (rating === 10) {
          window.review_comment.value = ''
          window.review_comment.classList.add('hidden')
          window.review_submit.classList.add('hidden')
          announcePolite('Rating submitted')
          event.target.form.submit()
        } else {
          window.review_comment.classList.remove('hidden')
          window.review_submit.classList.remove('hidden')
        }
      })
    })
  }
}

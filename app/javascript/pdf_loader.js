document.addEventListener('DOMContentLoaded', function () {
  function showLoading () {
    document.getElementById('loader').style.display = 'block'
  }
  const editTemplateLink = document.getElementById('edit-template-link')
  if (editTemplateLink) {
    editTemplateLink.addEventListener('click', function (event) {
      event.preventDefault()
      showLoading()

      const template = this.getAttribute('data-template')
      setTimeout(function () {
        window.location.href = template
      }, 3000)
    })
  }
})

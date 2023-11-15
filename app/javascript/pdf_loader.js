document.addEventListener("DOMContentLoaded", function () {
  function showLoading() {
    document.getElementById("loader").style.display = "block";
  }
  var editTemplateLink = document.getElementById("edit-template-link");
  editTemplateLink.addEventListener("click", function (event) {
    event.preventDefault();
    showLoading();

    var template = this.getAttribute("data-template");
    setTimeout(function () {
      window.location.href = template;
    }, 3000);
  });
});

export function encodeMethodIntoRequestBody(event) {
  if (event.target instanceof HTMLFormElement) {
    const { target: form, detail: { fetchOptions } } = event

    form.addEventListener("turbo:submit-start", ({ detail: { formSubmission: { submitter } } }) => {
      const body = isBodyInit(fetchOptions.body) ? fetchOptions.body : new URLSearchParams()
      const method = determineFetchMethod(submitter, body, form)

      if (!/get/i.test(method)) {
        if (/post/i.test(method)) {
          body.delete("_method")
        } else {
          body.set("_method", method)
        }

        fetchOptions.method = "post"
      }
    }, { once: true })
  }
}

function determineFetchMethod(submitter, body, form) {
  const formMethod = determineFormMethod(submitter)
  const overrideMethod = body.get("_method")
  const method = form.getAttribute("method") || "get"

  if (typeof formMethod == "string") {
    return formMethod
  } else if (typeof overrideMethod == "string") {
    return overrideMethod
  } else {
    return method
  }
}

function determineFormMethod(submitter) {
  if (submitter instanceof HTMLButtonElement || submitter instanceof HTMLInputElement) {
    // Rails 7 ActionView::Helpers::FormBuilder#button method has an override
    // for formmethod if the button does not have name or value attributes
    // set, which is the default. This means that if you use <%= f.button
    // formmethod: :delete %>, it will generate a <button name="_method"
    // value="delete" formmethod="post">. Therefore, if the submitter's name
    // is already _method, it's value attribute already contains the desired
    // method.
    if (submitter.name === '_method') {
      return submitter.value
    } else if (submitter.hasAttribute("formmethod")) {
      return submitter.formMethod
    } else {
      return null
    }
  } else {
    return null
  }
}

function isBodyInit(body) {
  return body instanceof FormData || body instanceof URLSearchParams
}

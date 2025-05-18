# JavaScript Signing Form

### Example Code

```javascript
<script src="https://cdn.docuseal.com/js/form.js"></script>

<docuseal-form
  id="docusealForm"
  data-src="https://docuseal.com/d/{{template_slug}}"
  data-email="{{signer_email}}">
</docuseal-form>

<script>
  window.docusealForm.addEventListener('completed', (e) => e.detail)
</script>

```

### Attributes

```json
{
  "data-src": {
    "type": "string",
    "required": true,
    "description": "Public URL of the document signing form. There are two types of URLs: <li><code>/d/{slug}</code> - template form signing URL can be copied from the template page in the admin dashboard. Also template \"slug\" key can be obtained via the <code>/templates</code> API.</li><li><code>/s/{slug}</code> - individual signer URL. Signer \"slug\" key can be obtained via the <code>/submissions</code> API which is used to initiate signature requests for a template form with recipients.</li>"
  },
  "data-email": {
    "type": "string",
    "required": false,
    "description": "Email address of the signer. Additional email form step will be displayed if the email attribute is not specified."
  },
  "data-name": {
    "type": "string",
    "required": false,
    "description": "Name of the signer."
  },
  "data-role": {
    "type": "string",
    "required": false,
    "description": "The role name or title of the signer.",
    "example": "First Party"
  },
  "data-expand": {
    "type": "boolean",
    "required": false,
    "description": "Expand form on open.",
    "default": true
  },
  "data-minimize": {
    "type": "boolean",
    "required": false,
    "description": "Set to `true` to always minimize form fields. Requires to click on the field to expand the form.",
    "default": false
  },
  "data-order-as-on-page": {
    "type": "boolean",
    "required": false,
    "default": false,
    "description": "Order form fields based on their position on the pages."
  },
  "data-preview": {
    "type": "boolean",
    "required": false,
    "default": false,
    "description": "Show form in preview mode without ability to submit it."
  },
  "data-logo": {
    "type": "string",
    "required": false,
    "description": "Public logo image URL to use in the signing form."
  },
  "data-language": {
    "type": "string",
    "required": false,
    "description": "UI language: en, es, it, de, fr, nl, pl, uk, cs, pt, he, ar, kr, ja languages are available. Be default the form is displayed in the user browser language automatically."
  },
  "data-i18n": {
    "type": "string",
    "required": false,
    "default": "{}",
    "description": "JSON encoded string that contains i18n keys to replace the default UI text with custom values. See <a href=\"https://github.com/docusealco/docuseal/blob/master/app/javascript/submission_form/i18n.js\" class=\"link\" target=\"_blank\" rel=\"nofollow\">submission_form/i18n.js</a> for available i18n keys."
  },
  "data-go-to-last": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Navigate to the last unfinished step."
  },
  "data-skip-fields": {
    "type": "boolean",
    "required": false,
    "default": false,
    "description": "Allow skipping form fields."
  },
  "data-autoscroll-fields": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Set `false` to disable auto-scrolling to the next document field."
  },
  "data-send-copy-email": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Set `false` to disable automatic email sending with signed documents to the signers. Emails with signed documents are sent to the signers by default."
  },
  "data-with-title": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Set `false` to remove the document title from the form."
  },
  "data-with-decline": {
    "type": "boolean",
    "required": false,
    "default": false,
    "description": "Set `true` to display the decline button in the form."
  },
  "data-with-field-names": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Set `false` to hide field name. Hidding field names can be useful for when they are not in the human readable format. Field names are displayed by default."
  },
  "data-with-field-placeholder": {
    "type": "boolean",
    "required": false,
    "default": false,
    "description": "Set `true` to display field name placeholders instead of the field type icons."
  },
  "data-with-download-button": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Set `false` to remove the signed document download button from the completed form card."
  },
  "data-with-send-copy-button": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Set `false` to remove the signed document send email button from the completed form card."
  },
  "data-with-complete-button": {
    "type": "boolean",
    "required": false,
    "default": false,
    "description": "Set `true` to display the complete button in the form header."
  },
  "data-allow-to-resubmit": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Set `false` to disallow users to re-submit the form."
  },
  "data-allow-typed-signature": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Set `false` to disallow users to type their signature."
  },
  "data-signature": {
    "type": "string",
    "required": false,
    "description": "Allows pre-filling signature fields. The value can be a base64 encoded image string, a public URL to an image, or plain text that will be rendered as a typed signature using a standard font."
  },
  "data-remember-signature": {
    "type": "boolean",
    "required": false,
    "description": "Allows to specify whether the signature should be remembered for future use. Remembered signatures are stored in the signer's browser local storage and can be automatically reused to prefill signature fields in new forms for the signer when the value is set to `true`."
  },
  "data-reuse-signature": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Set `false` to not reuse the signature in the second signature field and collect a new one."
  },
  "data-background-color": {
    "type": "string",
    "required": false,
    "description": "Form background color. Only HEX color codes are supported.",
    "example": "#d9d9d9"
  },
  "data-values": {
    "type": "object",
    "required": false,
    "description": "Pre-assigned values for form fields.",
    "example": "{\"First Name\":\"Jon\",\"Last Name\":\"Doe\"}"
  },
  "data-external-id": {
    "type": "string",
    "required": false,
    "description": "Your application-specific unique string key to identify signer within your app."
  },
  "data-metadata": {
    "type": "object",
    "required": false,
    "description": "Signer metadata Object in JSON format. ",
    "example": "{\"customData\":\"customValue\"}"
  },
  "data-readonly-fields": {
    "type": "string",
    "required": false,
    "description": "Comma separated read-only field names",
    "example": "First Name,Last Name"
  },
  "data-completed-redirect-url": {
    "type": "string",
    "required": false,
    "description": "URL to redirect to after the submission completion.",
    "example": "https://docuseal.com/success"
  },
  "data-completed-message-title": {
    "type": "string",
    "required": false,
    "description": "Message title displayed after the form completion.",
    "example": "Documents have been completed"
  },
  "data-completed-message-body": {
    "type": "string",
    "required": false,
    "description": "Message body displayed after the form completion.",
    "example": "If you have any questions, please contact us."
  },
  "data-completed-button-title": {
    "type": "string",
    "required": false,
    "description": "Button title displayed after the form completion.",
    "example": "Go Back"
  },
  "data-completed-button-url": {
    "type": "string",
    "required": false,
    "description": "URL of the button displayed after the form completion.",
    "example": "https://example.com"
  },
  "data-custom-css": {
    "type": "string",
    "required": false,
    "description": "Custom CSS styles to be applied to the form.",
    "example": "#submit_form_button { background-color: #d9d9d9; }"
  }
}
```

### Callback

```json
{
  "init": {
    "type": "event",
    "required": false,
    "description": "Custom event to be triggered on initializing the form component.",
    "example": "document.querySelector('docuseal-form').addEventListener('init', () => console.log('init'))"
  },
  "load": {
    "type": "event",
    "required": false,
    "description": "Custom event to be triggered on loading the form data.",
    "example": "document.querySelector('docuseal-form').addEventListener('load', (e) => e.detail)"
  },
  "completed": {
    "type": "event",
    "required": false,
    "description": "Custom event to be triggered after form completion.",
    "example": "document.querySelector('docuseal-form').addEventListener('completed', (e) => e.detail)"
  },
  "declined": {
    "type": "event",
    "description": "Custom event to be triggered after form decline.",
    "example": "document.querySelector('docuseal-form').addEventListener('declined', (e) => e.detail)"
  }
}
```

# Vue Form Builder

### Example Code

```vue
<template>
  <DocusealBuilder
    v-if="token"
    :token="token"
  />
</template>

<script>
import { DocusealBuilder } from '@docuseal/vue'

export default {
  name: 'App',
  components: { DocusealBuilder },
  data () {
    return { token: '' }
  },
  mounted () {
    fetch('/api/docuseal/builder_token', {
      method: 'POST'
    }).then(async (resp) => {
      const data = await resp.json()

      this.token = data.token
    })
  }
}
</script>

```

```javascript
const jwt = require('jsonwebtoken');

const token = jwt.sign({
  user_email: '{{admin_user_email}}',
  integration_email: '{{signer_email}}',
  external_id: 'TestForm123',
  name: 'Integration W-9 Test Form',
  document_urls: ['https://www.irs.gov/pub/irs-pdf/fw9.pdf'],
}, '{{api_key}}');

```

### Attributes

```json
{
  "token": {
    "type": "string",
    "doc_type": "object",
    "description": "JSON Web Token (JWT HS256) with a payload signed using the API key. <br><b>Ensure that the JWT token is generated on the backend to prevent unauthorized access to your documents</b>.",
    "required": true,
    "properties": {
      "user_email": {
        "type": "string",
        "required": true,
        "description": "Email of the owner of the API signing key - admin user email."
      },
      "integration_email": {
        "type": "string",
        "required": false,
        "description": "Email of the user to create a template for.",
        "example": "signer@example.com"
      },
      "template_id": {
        "type": "number",
        "required": false,
        "description": "ID of the template to open in the form builder. Optional when `document_urls` are specified."
      },
      "external_id": {
        "type": "string",
        "description": "Your application-specific unique string key to identify this template within your app.",
        "required": false
      },
      "folder_name": {
        "type": "string",
        "description": "The folder name in which the template should be created.",
        "required": false
      },
      "document_urls": {
        "type": "array",
        "required": false,
        "description": "An Array of URLs with PDF files to open in the form builder. Optional when `template_id` is specified.",
        "example": "['https://www.irs.gov/pub/irs-pdf/fw9.pdf']"
      },
      "name": {
        "type": "string",
        "required": false,
        "description": "New template name when creating a template with document_urls specified.",
        "example": "Integration W-9 Test Form"
      },
      "extract_fields": {
        "type": "boolean",
        "required": false,
        "description": "Pass `false` to disable automatic PDF form fields extraction. PDF fields are automatically added by default."
      }
    }
  },
  "host": {
    "type": "string",
    "required": false,
    "description": "DocuSeal host domain name. Only use this attribute if you are using the on-premises DocuSeal installation or docuseal.eu Cloud.",
    "example": "yourdomain.com"
  },
  "custom-button": {
    "type": "object",
    "required": false,
    "description": "Custom button will be displayed on the top right corner of the form builder.",
    "properties": {
      "title": {
        "type": "string",
        "required": true,
        "description": "Custom button title."
      },
      "url": {
        "type": "string",
        "required": true,
        "description": "Custom button URL. Only absolute URLs are supported."
      }
    }
  },
  "only-defined-fields": {
    "type": "boolean",
    "required": false,
    "default": false,
    "description": "Allow to add fields only defined in the `:fields` prop."
  },
  "with-send-button": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Show the \"Recipients\" button."
  },
  "roles": {
    "type": "array",
    "required": false,
    "description": "Submitter role names to be used by default in the form."
  },
  "field-types": {
    "type": "array",
    "required": false,
    "description": "Field type names to be used in the form builder. All field types are used by default."
  },
  "draw-field-type": {
    "type": "string",
    "required": false,
    "default": "text",
    "description": "Field type to be used by default with the field drawing tool.",
    "example": "signature"
  },
  "fields": {
    "type": "array",
    "required": false,
    "description": "An array of default custom field properties with `name` to be added to the document.",
    "items": {
      "type": "object",
      "properties": {
        "name": {
          "type": "string",
          "required": true,
          "description": "Field name."
        },
        "type": {
          "type": "string",
          "required": false,
          "description": "Field type.",
          "enum": [
            "heading",
            "text",
            "signature",
            "initials",
            "date",
            "number",
            "image",
            "checkbox",
            "multiple",
            "file",
            "radio",
            "select",
            "cells",
            "stamp",
            "payment",
            "phone",
            "verification"
          ]
        },
        "role": {
          "type": "string",
          "required": false,
          "description": "Submitter role name for the field."
        },
        "default_value": {
          "type": "string",
          "required": false,
          "description": "Default value of the field."
        },
        "title": {
          "type": "string",
          "required": false,
          "description": "Field title displayed to the user instead of the name, shown on the signing form. Supports Markdown."
        },
        "description": {
          "type": "string",
          "required": false,
          "description": "Field description displayed on the signing form. Supports Markdown."
        },
        "width": {
          "type": "number",
          "required": false,
          "description": "Field width in pixels."
        },
        "height": {
          "type": "number",
          "required": false,
          "description": "Field height in pixels."
        },
        "format": {
          "type": "string",
          "required": false,
          "description": "Field format. Depends on the field type."
        },
        "options": {
          "type": "array",
          "required": false,
          "description": "Field options. Required for the select field type."
        },
        "validation": {
          "type": "object",
          "required": false,
          "description": "Field validation rules.",
          "properties": {
            "pattern": {
              "type": "string",
              "required": false,
              "description": "Field pattern.",
              "example": "^[0-9]{5}$"
            },
            "message": {
              "type": "string",
              "required": false,
              "description": "Validation error message."
            }
          }
        }
      }
    }
  },
  "submitters": {
    "type": "array",
    "required": false,
    "description": "An array of default submitters with `role` name to be added to the document.",
    "items": {
      "type": "object",
      "properties": {
        "email": {
          "type": "string",
          "required": false,
          "description": "Submitter email."
        },
        "role": {
          "type": "string",
          "required": true,
          "description": "Submitter role name."
        },
        "name": {
          "type": "string",
          "required": false,
          "description": "Submitter name."
        },
        "phone": {
          "type": "string",
          "required": false,
          "description": "Submitter phone number, formatted according to the E.164 standard."
        }
      }
    }
  },
  "required-fields": {
    "type": "array",
    "required": false,
    "description": "An array of default required custom field properties with `name` that should be added to the document.",
    "items": {
      "type": "object",
      "properties": {
        "name": {
          "type": "string",
          "required": true,
          "description": "Field name."
        },
        "type": {
          "type": "string",
          "required": false,
          "description": "Field type.",
          "enum": [
            "heading",
            "text",
            "signature",
            "initials",
            "date",
            "number",
            "image",
            "checkbox",
            "multiple",
            "file",
            "radio",
            "select",
            "cells",
            "stamp",
            "payment",
            "phone",
            "verification"
          ]
        },
        "role": {
          "type": "string",
          "required": false,
          "description": "Submitter role name for the field."
        },
        "default_value": {
          "type": "string",
          "required": false,
          "description": "Default value of the field."
        },
        "title": {
          "type": "string",
          "required": false,
          "description": "Field title displayed to the user instead of the name, shown on the signing form. Supports Markdown."
        },
        "description": {
          "type": "string",
          "required": false,
          "description": "Field description displayed on the signing form. Supports Markdown."
        },
        "width": {
          "type": "number",
          "required": false,
          "description": "Field width in pixels."
        },
        "height": {
          "type": "number",
          "required": false,
          "description": "Field height in pixels."
        },
        "format": {
          "type": "string",
          "required": false,
          "description": "Field format. Depends on the field type."
        },
        "options": {
          "type": "array",
          "required": false,
          "description": "Field options. Required for the select field type."
        },
        "validation": {
          "type": "object",
          "required": false,
          "description": "Field validation rules.",
          "properties": {
            "pattern": {
              "type": "string",
              "required": false,
              "description": "Field pattern.",
              "example": "^[0-9]{5}$"
            },
            "message": {
              "type": "string",
              "required": false,
              "description": "Validation error message."
            }
          }
        }
      }
    }
  },
  "email-message": {
    "type": "object",
    "required": false,
    "description": "Email subject and body for the signature request.",
    "properties": {
      "subject": {
        "type": "string",
        "required": true,
        "description": "Email subject for the signature request."
      },
      "body": {
        "type": "string",
        "required": true,
        "description": "Email body for the signature request."
      }
    }
  },
  "with-title": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Set `false` to remove document title from the builder."
  },
  "with-upload-button": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Show the \"Upload\" button."
  },
  "with-add-page-button": {
    "type": "boolean",
    "required": false,
    "default": false,
    "description": "Show the \"Add Blank Page\" button."
  },
  "with-sign-yourself-button": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Show the \"Sign Yourself\" button."
  },
  "with-documents-list": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Set `false` to now show the documents list on the left. Documents list is displayed by default."
  },
  "with-fields-list": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Set `false` to now show the fields list on the right. Fields list is displayed by default."
  },
  "with-field-placeholder": {
    "type": "boolean",
    "required": false,
    "default": false,
    "description": "Set `true` to display field name placeholders instead of the field type icons."
  },
  "autosave": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Set `false` to disable form changes autosaving."
  },
  "preview": {
    "type": "boolean",
    "required": false,
    "default": false,
    "description": "Show template in preview mode without ability to edit it."
  },
  "language": {
    "type": "string",
    "required": false,
    "default": "en",
    "description": "UI language, 'en', 'es', 'de', 'fr', 'pt', 'he', 'ar' languages are available."
  },
  "i18n": {
    "type": "object",
    "required": false,
    "default": "{}",
    "description": "Object that contains i18n keys to replace the default UI text with custom values. See <a href=\"https://github.com/docusealco/docuseal/blob/master/app/javascript/template_builder/i18n.js\" class=\"link\" target=\"_blank\" rel=\"nofollow\">template_builder/i18n.js</a> for available i18n keys."
  },
  "background-color": {
    "type": "string",
    "required": false,
    "description": "The form builder background color. Only HEX color codes are supported.",
    "example": "#ffffff"
  },
  "custom-css": {
    "type": "string",
    "required": false,
    "description": "Custom CSS styles to be applied to the form builder.",
    "example": "#sign_yourself_button { background-color: #FFA500; }"
  }
}
```

### Callback

```json
{
  "@load": {
    "type": "function",
    "required": false,
    "description": "Function to be called on loading the form builder template data.",
    "example": "onBuilderLoad"
  },
  "@upload": {
    "type": "function",
    "required": false,
    "description": "Function to be called on uploading a document to the template.",
    "example": "onBuilderUpload"
  },
  "@send": {
    "type": "function",
    "required": false,
    "description": "Function to be called on sending documents for signature to recipients.",
    "example": "onBuilderSend"
  },
  "@change": {
    "type": "function",
    "required": false,
    "description": "Function to be called when changes are made to the template form.",
    "example": "onBuilderChange"
  },
  "@save": {
    "type": "function",
    "required": false,
    "description": "Function to be called on saving changes of the template form.",
    "example": "onBuilderSave"
  }
}
```

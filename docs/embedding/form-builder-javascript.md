# JavaScript Form Builder

### Example Code

```javascript
<script src="https://docuseal.com/js/builder.js"></script>

<docuseal-builder
  data-token="<%= JWT.encode({
    user_email: '{{admin_user_email}}',
    integration_email: '{{signer_email}}',
    name: 'Integration W-9 Test Form',
    document_urls: ['https://www.irs.gov/pub/irs-pdf/fw9.pdf'],
  }, '{{api_key}}') %>">
</docuseal-builder>

```

### Attributes

```json
{
  "data-token": {
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
  "data-host": {
    "type": "string",
    "required": false,
    "description": "DocuSeal host domain name. Only use this attribute if you are using the on-premises DocuSeal installation or docuseal.eu Cloud.",
    "example": "yourdomain.com"
  },
  "data-roles": {
    "type": "string",
    "required": false,
    "description": "Comma separated submitter role names to be used by default in the form.",
    "example": "Company,Customer"
  },
  "data-fields": {
    "type": "string",
    "doc_type": "array",
    "required": false,
    "description": "A list of default custom fields with `name` to be added to the document. Should contain an array of field properties as a JSON encoded string.",
    "example": "[{ \"name\": \"FIELD_1\", \"type\": \"date\", \"role\": \"Customer\", \"default_value\": \"2021-01-01\" }]",
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
  "data-submitters": {
    "type": "string",
    "doc_type": "array",
    "required": false,
    "description": "A list of default submitters with `role` name to be added to the document. Should contain an array of field properties as a JSON encoded string.",
    "example": "[{ \"email\": \"example@company.com\", \"name\": \"John Doe\", \"phone\": \"+1234567890\", \"role\": \"Customer\" }]",
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
  "data-required-fields": {
    "type": "string",
    "doc_type": "array",
    "required": false,
    "description": "A list of required default custom fields with `name` that should be added to the document. Should contain an array of field properties as a JSON encoded string.",
    "example": "[{ \"name\": \"FIELD_1\", \"type\": \"date\", \"role\": \"Customer\", \"default_value\": \"2021-01-01\" }]",
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
  "data-field-types": {
    "type": "string",
    "required": false,
    "description": "Comma separated field type names to be used in the form builder. All field types are used by default.",
    "example": "text,date"
  },
  "data-draw-field-type": {
    "type": "string",
    "required": false,
    "default": "text",
    "description": "Field type to be used by default with the field drawing tool.",
    "example": "signature"
  },
  "data-custom-button-title": {
    "type": "string",
    "required": false,
    "description": "Custom button title. This button will be displayed on the top right corner of the form builder."
  },
  "data-custom-button-url": {
    "type": "string",
    "required": false,
    "description": "Custom button URL. Only absolute URLs are supported."
  },
  "data-with-title": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Set `false` to remove document title from the builder."
  },
  "email-subject": {
    "type": "string",
    "required": false,
    "description": "Email subject for the signature request. Required if `email-body` specified"
  },
  "email-body": {
    "type": "string",
    "required": false,
    "description": "Email body for the signature request. Required if `email-subject` specified"
  },
  "data-with-send-button": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Show the \"Recipients\" button."
  },
  "data-with-upload-button": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Show the \"Upload\" button."
  },
  "data-with-add-page-button": {
    "type": "boolean",
    "required": false,
    "default": false,
    "description": "Show the \"Add Blank Page\" button."
  },
  "data-with-sign-yourself-button": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Show the \"Sign Yourself\" button."
  },
  "data-with-documents-list": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Set `false` to now show the documents list on the left. Documents list is displayed by default."
  },
  "data-with-fields-list": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Set `false` to now show the fields list on the right. Fields list is displayed by default."
  },
  "data-with-field-placeholder": {
    "type": "boolean",
    "required": false,
    "default": false,
    "description": "Set `true` to display field name placeholders instead of the field type icons."
  },
  "data-preview": {
    "type": "boolean",
    "required": false,
    "default": false,
    "description": "Show template in preview mode without ability to edit it."
  },
  "data-only-defined-fields": {
    "type": "boolean",
    "required": false,
    "default": false,
    "description": "Allow to add fields only defined in the `data-fields` attribute."
  },
  "data-autosave": {
    "type": "boolean",
    "required": false,
    "default": true,
    "description": "Set `false` to disable form changes autosaving."
  },
  "data-i18n": {
    "type": "string",
    "required": false,
    "default": "{}",
    "description": "JSON encoded string that contains i18n keys to replace the default UI text with custom values. See <a href=\"https://github.com/docusealco/docuseal/blob/master/app/javascript/template_builder/i18n.js\" class=\"link\" target=\"_blank\" rel=\"nofollow\">template_builder/i18n.js</a> for available i18n keys."
  },
  "data-language": {
    "type": "string",
    "required": false,
    "default": "en",
    "description": "UI language, 'en', 'es', 'de', 'fr', 'pt', 'he', 'ar' languages are available."
  },
  "data-background-color": {
    "type": "string",
    "required": false,
    "description": "The form builder background color. Only HEX color codes are supported.",
    "example": "#ffffff"
  },
  "data-custom-css": {
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
  "load": {
    "type": "event",
    "required": false,
    "description": "Custom event to be triggered on loading the form builder template data.",
    "example": "document.querySelector('docuseal-builder').addEventListener('load', (e) => e.detail)"
  },
  "upload": {
    "type": "event",
    "required": false,
    "description": "Custom event to be triggered on uploading a document to the template.",
    "example": "document.querySelector('docuseal-builder').addEventListener('upload', (e) => e.detail)"
  },
  "send": {
    "type": "event",
    "required": false,
    "description": "Custom event to be triggered on sending documents for signature to recipients.",
    "example": "document.querySelector('docuseal-builder').addEventListener('send', (e) => e.detail)"
  },
  "change": {
    "type": "event",
    "required": false,
    "description": "Custom event to be triggered every time a change to the template is made.",
    "example": "document.querySelector('docuseal-builder').addEventListener('change', (e) => e.detail)"
  },
  "save": {
    "type": "event",
    "required": false,
    "description": "Custom event to be triggered on saving changes of the template form.",
    "example": "document.querySelector('docuseal-builder').addEventListener('save', (e) => e.detail)"
  }
}
```

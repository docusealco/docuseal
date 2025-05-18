### List all templates

The API endpoint provides the ability to retrieve a list of available document templates.

```shell
curl --request GET \
  --url https://api.docuseal.com/templates \
  --header 'X-Auth-Token: API_KEY'
```

```json
{
  "security": [
    {
      "AuthToken": []
    }
  ],
  "tags": [
    "Templates"
  ],
  "summary": "List all templates",
  "operationId": "getTemplates",
  "parameters": [
    {
      "name": "q",
      "in": "query",
      "required": false,
      "schema": {
        "type": "string"
      },
      "description": "Filter templates based on the name partial match."
    },
    {
      "name": "slug",
      "in": "query",
      "required": false,
      "schema": {
        "type": "string"
      },
      "description": "Filter templates by unique slug.",
      "example": "opaKWh8WWTAcVG"
    },
    {
      "name": "external_id",
      "in": "query",
      "required": false,
      "schema": {
        "type": "string"
      },
      "description": "The unique applications-specific identifier provided for the template via API or Embedded template form builder. It allows you to receive only templates with your specified external id."
    },
    {
      "name": "folder",
      "in": "query",
      "required": false,
      "schema": {
        "type": "string"
      },
      "description": "Filter templates by folder name."
    },
    {
      "name": "archived",
      "in": "query",
      "required": false,
      "schema": {
        "type": "boolean"
      },
      "description": "Get only archived templates instead of active ones."
    },
    {
      "name": "limit",
      "in": "query",
      "required": false,
      "schema": {
        "type": "integer"
      },
      "description": "The number of templates to return. Default value is 10. Maximum value is 100."
    },
    {
      "name": "after",
      "in": "query",
      "required": false,
      "schema": {
        "type": "integer"
      },
      "description": "The unique identifier of the template to start the list from. It allows you to receive only templates with id greater than the specified value. Pass ID value from the `pagination.next` response to load the next batch of templates."
    },
    {
      "name": "before",
      "in": "query",
      "required": false,
      "schema": {
        "type": "integer"
      },
      "description": "The unique identifier of the template to end the list with. It allows you to receive only templates with id less than the specified value."
    }
  ]
}
```

### Get a template

The API endpoint provides the functionality to retrieve information about a document template.

```shell
curl --request GET \
  --url https://api.docuseal.com/templates/1000001 \
  --header 'X-Auth-Token: API_KEY'
```

```json
{
  "security": [
    {
      "AuthToken": []
    }
  ],
  "tags": [
    "Templates"
  ],
  "summary": "Get a template",
  "operationId": "getTemplate",
  "parameters": [
    {
      "name": "id",
      "in": "path",
      "required": true,
      "schema": {
        "type": "integer"
      },
      "description": "The unique identifier of the document template.",
      "example": 1000001
    }
  ]
}
```

### Archive a template

The API endpoint allows you to archive a document template.

```shell
curl --request DELETE \
  --url https://api.docuseal.com/templates/1000001 \
  --header 'X-Auth-Token: API_KEY'
```

```json
{
  "security": [
    {
      "AuthToken": []
    }
  ],
  "tags": [
    "Templates"
  ],
  "summary": "Archive a template",
  "operationId": "archiveTemplate",
  "parameters": [
    {
      "name": "id",
      "in": "path",
      "required": true,
      "schema": {
        "type": "integer"
      },
      "description": "The unique identifier of the document template.",
      "example": 1000001
    }
  ]
}
```

### Update a template

The API endpoint provides the functionality to move a document template to a different folder and update the name of the template.

```shell
curl --request PUT \
  --url https://api.docuseal.com/templates/1000001 \
  --header 'X-Auth-Token: API_KEY' \
  --header 'content-type: application/json' \
  --data '{"name":"New Document Name","folder_name":"New Folder"}'
```

```json
{
  "security": [
    {
      "AuthToken": []
    }
  ],
  "tags": [
    "Templates"
  ],
  "summary": "Update a template",
  "operationId": "updateTemplate",
  "parameters": [
    {
      "name": "id",
      "in": "path",
      "required": true,
      "schema": {
        "type": "integer"
      },
      "description": "The unique identifier of the document template.",
      "example": 1000001
    }
  ],
  "requestBody": {
    "required": true,
    "content": {
      "application/json": {
        "schema": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string",
              "description": "The name of the template",
              "example": "New Document Name"
            },
            "folder_name": {
              "type": "string",
              "description": "The folder's name to which the template should be moved.",
              "example": "New Folder"
            },
            "roles": {
              "type": "array",
              "description": "An array of submitter role names to update the template with.",
              "items": {
                "type": "string"
              },
              "example": [
                "Agent",
                "Customer"
              ]
            },
            "archived": {
              "type": "boolean",
              "description": "Set `false` to unarchive template."
            }
          }
        }
      }
    }
  }
}
```

### List all submissions

The API endpoint provides the ability to retrieve a list of available submissions.

```shell
curl --request GET \
  --url https://api.docuseal.com/submissions \
  --header 'X-Auth-Token: API_KEY'
```

```json
{
  "security": [
    {
      "AuthToken": []
    }
  ],
  "tags": [
    "Submissions"
  ],
  "summary": "List all submissions",
  "operationId": "getSubmissions",
  "parameters": [
    {
      "name": "template_id",
      "in": "query",
      "required": false,
      "schema": {
        "type": "integer"
      },
      "description": "The template ID allows you to receive only the submissions created from that specific template."
    },
    {
      "name": "status",
      "in": "query",
      "required": false,
      "schema": {
        "type": "string",
        "enum": [
          "pending",
          "completed",
          "declined",
          "expired"
        ]
      },
      "description": "Filter submissions by status."
    },
    {
      "name": "q",
      "in": "query",
      "required": false,
      "schema": {
        "type": "string"
      },
      "description": "Filter submissions based on submitters name, email or phone partial match."
    },
    {
      "name": "slug",
      "in": "query",
      "required": false,
      "schema": {
        "type": "string"
      },
      "description": "Filter submissions by unique slug.",
      "example": "NtLDQM7eJX2ZMd"
    },
    {
      "name": "template_folder",
      "in": "query",
      "required": false,
      "schema": {
        "type": "string"
      },
      "description": "Filter submissions by template folder name."
    },
    {
      "name": "archived",
      "in": "query",
      "required": false,
      "schema": {
        "type": "boolean"
      },
      "description": "Returns only archived submissions when `true` and only active submissions when `false`."
    },
    {
      "name": "limit",
      "in": "query",
      "required": false,
      "schema": {
        "type": "integer"
      },
      "description": "The number of submissions to return. Default value is 10. Maximum value is 100."
    },
    {
      "name": "after",
      "in": "query",
      "required": false,
      "schema": {
        "type": "integer"
      },
      "description": "The unique identifier of the submission to start the list from. It allows you to receive only submissions with an ID greater than the specified value. Pass ID value from the `pagination.next` response to load the next batch of submissions."
    },
    {
      "name": "before",
      "in": "query",
      "required": false,
      "schema": {
        "type": "integer"
      },
      "description": "The unique identifier of the submission that marks the end of the list. It allows you to receive only submissions with an ID less than the specified value."
    }
  ]
}
```

### Create a submission

This API endpoint allows you to create signature requests (submissions) for a document template and send them to the specified submitters (signers).<br><b>Related Guides</b><br><a href="https://www.docuseal.com/guides/send-documents-for-signature-via-api" class="link">Send documents for signature via API</a><br><a href="https://www.docuseal.com/guides/pre-fill-pdf-document-form-fields-with-api" class="link">Pre-fill PDF document form fields with API</a>

```shell
curl --request POST \
  --url https://api.docuseal.com/submissions \
  --header 'X-Auth-Token: API_KEY' \
  --header 'content-type: application/json' \
  --data '{"template_id":1000001,"send_email":true,"submitters":[{"role":"First Party","email":"john.doe@example.com"}]}'
```

```json
{
  "security": [
    {
      "AuthToken": []
    }
  ],
  "tags": [
    "Submissions"
  ],
  "summary": "Create a submission",
  "operationId": "createSubmission",
  "parameters": [],
  "requestBody": {
    "required": true,
    "content": {
      "application/json": {
        "schema": {
          "type": "object",
          "required": [
            "template_id",
            "submitters"
          ],
          "properties": {
            "template_id": {
              "type": "integer",
              "description": "The unique identifier of the template. Document template forms can be created via the Web UI, <a href=\"https://www.docuseal.com/guides/use-embedded-text-field-tags-in-the-pdf-to-create-a-fillable-form\" class=\"link\">PDF and DOCX API</a>, or <a href=\"https://www.docuseal.com/guides/create-pdf-document-fillable-form-with-html-api\" class=\"link\">HTML API</a>.",
              "example": 1000001
            },
            "send_email": {
              "type": "boolean",
              "description": "Set `false` to disable signature request emails sending.",
              "default": true
            },
            "send_sms": {
              "type": "boolean",
              "description": "Set `true` to send signature request via phone number and SMS.",
              "default": false
            },
            "order": {
              "type": "string",
              "description": "Pass 'random' to send signature request emails to all parties right away. The order is 'preserved' by default so the second party will receive a signature request email only after the document is signed by the first party.",
              "default": "preserved",
              "enum": [
                "preserved",
                "random"
              ]
            },
            "completed_redirect_url": {
              "type": "string",
              "description": "Specify URL to redirect to after the submission completion."
            },
            "bcc_completed": {
              "type": "string",
              "description": "Specify BCC address to send signed documents to after the completion."
            },
            "reply_to": {
              "type": "string",
              "description": "Specify Reply-To address to use in the notification emails."
            },
            "expire_at": {
              "type": "string",
              "description": "Specify the expiration date and time after which the submission becomes unavailable for signature.",
              "example": "2024-09-01 12:00:00 UTC"
            },
            "message": {
              "type": "object",
              "properties": {
                "subject": {
                  "type": "string",
                  "description": "Custom signature request email subject."
                },
                "body": {
                  "type": "string",
                  "description": "Custom signature request email body. Can include the following variables: {{template.name}}, {{submitter.link}}, {{account.name}}."
                }
              }
            },
            "submitters": {
              "type": "array",
              "description": "The list of submitters for the submission.",
              "items": {
                "type": "object",
                "required": [
                  "email"
                ],
                "properties": {
                  "name": {
                    "type": "string",
                    "description": "The name of the submitter."
                  },
                  "role": {
                    "type": "string",
                    "description": "The role name or title of the submitter.",
                    "example": "First Party"
                  },
                  "email": {
                    "type": "string",
                    "description": "The email address of the submitter.",
                    "format": "email",
                    "example": "john.doe@example.com"
                  },
                  "phone": {
                    "type": "string",
                    "description": "The phone number of the submitter, formatted according to the E.164 standard.",
                    "example": "+1234567890"
                  },
                  "values": {
                    "type": "object",
                    "description": "An object with pre-filled values for the submission. Use field names for keys of the object. For more configurations see `fields` param."
                  },
                  "external_id": {
                    "type": "string",
                    "description": "Your application-specific unique string key to identify this submitter within your app."
                  },
                  "completed": {
                    "type": "boolean",
                    "description": "Pass `true` to mark submitter as completed and auto-signed via API."
                  },
                  "metadata": {
                    "type": "object",
                    "description": "Metadata object with additional submitter information.",
                    "example": "{ \"customField\": \"value\" }"
                  },
                  "send_email": {
                    "type": "boolean",
                    "description": "Set `false` to disable signature request emails sending only for this submitter.",
                    "default": true
                  },
                  "send_sms": {
                    "type": "boolean",
                    "description": "Set `true` to send signature request via phone number and SMS.",
                    "default": false
                  },
                  "reply_to": {
                    "type": "string",
                    "description": "Specify Reply-To address to use in the notification emails for this submitter."
                  },
                  "completed_redirect_url": {
                    "type": "string",
                    "description": "Submitter specific URL to redirect to after the submission completion."
                  },
                  "message": {
                    "type": "object",
                    "properties": {
                      "subject": {
                        "type": "string",
                        "description": "Custom signature request email subject for the submitter."
                      },
                      "body": {
                        "type": "string",
                        "description": "Custom signature request email body for the submitter. Can include the following variables: {{template.name}}, {{submitter.link}}, {{account.name}}."
                      }
                    }
                  },
                  "fields": {
                    "type": "array",
                    "description": "A list of configurations for template document form fields.",
                    "items": {
                      "type": "object",
                      "required": [
                        "name"
                      ],
                      "properties": {
                        "name": {
                          "type": "string",
                          "description": "Document template field name.",
                          "example": "First Name"
                        },
                        "default_value": {
                          "oneOf": [
                            {
                              "type": "string"
                            },
                            {
                              "type": "number"
                            },
                            {
                              "type": "boolean"
                            },
                            {
                              "type": "array",
                              "items": {
                                "oneOf": [
                                  {
                                    "type": "string"
                                  },
                                  {
                                    "type": "number"
                                  },
                                  {
                                    "type": "boolean"
                                  }
                                ]
                              }
                            }
                          ],
                          "description": "Default value of the field. Use base64 encoded file or a public URL to the image file to set default signature or image fields.",
                          "example": "Acme"
                        },
                        "readonly": {
                          "type": "boolean",
                          "description": "Set `true` to make it impossible for the submitter to edit predefined field value.",
                          "default": false
                        },
                        "required": {
                          "type": "boolean",
                          "description": "Set `true` to make the field required."
                        },
                        "title": {
                          "type": "string",
                          "description": "Field title displayed to the user instead of the name, shown on the signing form. Supports Markdown."
                        },
                        "description": {
                          "type": "string",
                          "description": "Field description displayed on the signing form. Supports Markdown."
                        },
                        "validation_pattern": {
                          "type": "string",
                          "description": "HTML field validation pattern string based on https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/pattern specification.",
                          "example": "[A-Z]{4}"
                        },
                        "invalid_message": {
                          "type": "string",
                          "description": "A custom message to display on pattern validation failure."
                        },
                        "preferences": {
                          "type": "object",
                          "properties": {
                            "font_size": {
                              "type": "integer",
                              "description": "Font size of the field value in pixels.",
                              "example": 12
                            },
                            "font_type": {
                              "type": "string",
                              "description": "Font type of the field value.",
                              "enum": [
                                "bold",
                                "italic",
                                "bold_italic"
                              ]
                            },
                            "font": {
                              "type": "string",
                              "description": "Font family of the field value.",
                              "enum": [
                                "Times",
                                "Helvetica",
                                "Courier"
                              ]
                            },
                            "color": {
                              "type": "string",
                              "description": "Font color of the field value.",
                              "enum": [
                                "black",
                                "white",
                                "blue"
                              ],
                              "default": "black"
                            },
                            "align": {
                              "type": "string",
                              "description": "Horizontal alignment of the field text value.",
                              "enum": [
                                "left",
                                "center",
                                "right"
                              ],
                              "default": "left"
                            },
                            "valign": {
                              "type": "string",
                              "description": "Vertical alignment of the field text value.",
                              "enum": [
                                "top",
                                "center",
                                "bottom"
                              ],
                              "default": "center"
                            },
                            "format": {
                              "type": "string",
                              "description": "The data format for different field types.<br>- Date field: accepts formats such as DD/MM/YYYY (default: MM/DD/YYYY).<br>- Signature field: accepts drawn, typed, drawn_or_typed (default), or upload.<br>- Number field: accepts currency formats such as usd, eur, gbp.",
                              "example": "DD/MM/YYYY"
                            },
                            "price": {
                              "type": "number",
                              "description": "Price value of the payment field. Only for payment fields.",
                              "example": 99.99
                            },
                            "currency": {
                              "type": "string",
                              "description": "Currency value of the payment field. Only for payment fields.",
                              "enum": [
                                "USD",
                                "EUR",
                                "GBP",
                                "CAD",
                                "AUD"
                              ],
                              "default": "USD"
                            },
                            "mask": {
                              "description": "Set `true` to make sensitive data masked on the document.",
                              "oneOf": [
                                {
                                  "type": "integer"
                                },
                                {
                                  "type": "boolean"
                                }
                              ],
                              "default": false
                            }
                          }
                        }
                      }
                    }
                  },
                  "roles": {
                    "type": "array",
                    "description": "A list of roles for the submitter. Use this param to merge multiple roles into one submitter.",
                    "items": {
                      "type": "string"
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
```

### Get a submission

The API endpoint provides the functionality to retrieve information about a submission.

```shell
curl --request GET \
  --url https://api.docuseal.com/submissions/1001 \
  --header 'X-Auth-Token: API_KEY'
```

```json
{
  "security": [
    {
      "AuthToken": []
    }
  ],
  "tags": [
    "Submissions"
  ],
  "summary": "Get a submission",
  "operationId": "getSubmission",
  "parameters": [
    {
      "name": "id",
      "in": "path",
      "required": true,
      "schema": {
        "type": "integer"
      },
      "description": "The unique identifier of the submission.",
      "example": 1001
    }
  ]
}
```

### Archive a submission

The API endpoint allows you to archive a submission.

```shell
curl --request DELETE \
  --url https://api.docuseal.com/submissions/1001 \
  --header 'X-Auth-Token: API_KEY'
```

```json
{
  "security": [
    {
      "AuthToken": []
    }
  ],
  "tags": [
    "Submissions"
  ],
  "summary": "Archive a submission",
  "operationId": "archiveSubmission",
  "parameters": [
    {
      "name": "id",
      "in": "path",
      "required": true,
      "schema": {
        "type": "integer"
      },
      "description": "The unique identifier of the submission.",
      "example": 1001
    }
  ]
}
```

### Get submission documents

This endpoint returns a list of partially filled documents for a submission. If the submission has been completed, the final signed documents are returned.

```shell
curl --request GET \
  --url https://api.docuseal.com/submissions/1001/documents \
  --header 'X-Auth-Token: API_KEY'
```

```json
{
  "security": [
    {
      "AuthToken": []
    }
  ],
  "tags": [
    "Submissions"
  ],
  "summary": "Get submission documents",
  "operationId": "getSubmissionDocuments",
  "parameters": [
    {
      "name": "id",
      "in": "path",
      "required": true,
      "schema": {
        "type": "integer"
      },
      "description": "The unique identifier of the submission.",
      "example": 1001
    }
  ]
}
```

### Create submissions from emails

This API endpoint allows you to create submissions for a document template and send them to the specified email addresses. This is a simplified version of the POST /submissions API to be used with Zapier or other automation tools.

```shell
curl --request POST \
  --url https://api.docuseal.com/submissions/emails \
  --header 'X-Auth-Token: API_KEY' \
  --header 'content-type: application/json' \
  --data '{"template_id":1000001,"emails":"hi@docuseal.com, example@docuseal.com"}'
```

```json
{
  "security": [
    {
      "AuthToken": []
    }
  ],
  "tags": [
    "Submissions"
  ],
  "summary": "Create submissions from emails",
  "operationId": "createSubmissionsFromEmails",
  "parameters": [],
  "requestBody": {
    "required": true,
    "content": {
      "application/json": {
        "schema": {
          "type": "object",
          "required": [
            "template_id",
            "emails"
          ],
          "properties": {
            "template_id": {
              "type": "integer",
              "description": "The unique identifier of the template.",
              "example": 1000001
            },
            "emails": {
              "type": "string",
              "description": "A comma-separated list of email addresses to send the submission to.",
              "example": "{{emails}}"
            },
            "send_email": {
              "type": "boolean",
              "description": "Set `false` to disable signature request emails sending.",
              "default": true
            },
            "message": {
              "type": "object",
              "properties": {
                "subject": {
                  "type": "string",
                  "description": "Custom signature request email subject."
                },
                "body": {
                  "type": "string",
                  "description": "Custom signature request email body. Can include the following variables: {{template.name}}, {{submitter.link}}, {{account.name}}."
                }
              }
            }
          }
        }
      }
    }
  }
}
```

### Get a submitter

The API endpoint provides functionality to retrieve information about a submitter, along with the submitter documents and field values.

```shell
curl --request GET \
  --url https://api.docuseal.com/submitters/500001 \
  --header 'X-Auth-Token: API_KEY'
```

```json
{
  "security": [
    {
      "AuthToken": []
    }
  ],
  "tags": [
    "Submitters"
  ],
  "summary": "Get a submitter",
  "operationId": "getSubmitter",
  "parameters": [
    {
      "name": "id",
      "in": "path",
      "required": true,
      "schema": {
        "type": "integer"
      },
      "description": "The unique identifier of the submitter.",
      "example": 500001
    }
  ]
}
```

### Update a submitter

The API endpoint allows you to update submitter details, pre-fill or update field values and re-send emails.<br><b>Related Guides</b><br><a href="https://www.docuseal.com/guides/pre-fill-pdf-document-form-fields-with-api#automatically_sign_documents_via_api" class="link">Automatically sign documents via API</a>

```shell
curl --request PUT \
  --url https://api.docuseal.com/submitters/500001 \
  --header 'X-Auth-Token: API_KEY' \
  --header 'content-type: application/json' \
  --data '{"email":"john.doe@example.com","fields":[{"name":"First Name","default_value":"Acme"}]}'
```

```json
{
  "security": [
    {
      "AuthToken": []
    }
  ],
  "tags": [
    "Submitters"
  ],
  "summary": "Update a submitter",
  "operationId": "updateSubmitter",
  "parameters": [
    {
      "name": "id",
      "in": "path",
      "required": true,
      "schema": {
        "type": "integer"
      },
      "description": "The unique identifier of the submitter.",
      "example": 500001
    }
  ],
  "requestBody": {
    "required": true,
    "content": {
      "application/json": {
        "schema": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string",
              "description": "The name of the submitter."
            },
            "email": {
              "type": "string",
              "description": "The email address of the submitter.",
              "format": "email",
              "example": "john.doe@example.com"
            },
            "phone": {
              "type": "string",
              "description": "The phone number of the submitter, formatted according to the E.164 standard.",
              "example": "+1234567890"
            },
            "values": {
              "type": "object",
              "description": "An object with pre-filled values for the submission. Use field names for keys of the object. For more configurations see `fields` param."
            },
            "external_id": {
              "type": "string",
              "description": "Your application-specific unique string key to identify this submitter within your app."
            },
            "send_email": {
              "type": "boolean",
              "description": "Set `true` to re-send signature request emails."
            },
            "send_sms": {
              "type": "boolean",
              "description": "Set `true` to re-send signature request via phone number SMS.",
              "default": false
            },
            "reply_to": {
              "type": "string",
              "description": "Specify Reply-To address to use in the notification emails."
            },
            "completed_redirect_url": {
              "type": "string",
              "description": "Submitter specific URL to redirect to after the submission completion."
            },
            "completed": {
              "type": "boolean",
              "description": "Pass `true` to mark submitter as completed and auto-signed via API."
            },
            "metadata": {
              "type": "object",
              "description": "Metadata object with additional submitter information.",
              "example": "{ \"customField\": \"value\" }"
            },
            "message": {
              "type": "object",
              "properties": {
                "subject": {
                  "type": "string",
                  "description": "Custom signature request email subject."
                },
                "body": {
                  "type": "string",
                  "description": "Custom signature request email body. Can include the following variables: {{template.name}}, {{submitter.link}}, {{account.name}}."
                }
              }
            },
            "fields": {
              "type": "array",
              "description": "A list of configurations for template document form fields.",
              "items": {
                "type": "object",
                "required": [
                  "name"
                ],
                "properties": {
                  "name": {
                    "type": "string",
                    "description": "Document template field name.",
                    "example": "First Name"
                  },
                  "default_value": {
                    "oneOf": [
                      {
                        "type": "string"
                      },
                      {
                        "type": "number"
                      },
                      {
                        "type": "boolean"
                      },
                      {
                        "type": "array",
                        "items": {
                          "oneOf": [
                            {
                              "type": "string"
                            },
                            {
                              "type": "number"
                            },
                            {
                              "type": "boolean"
                            }
                          ]
                        }
                      }
                    ],
                    "description": "Default value of the field. Use base64 encoded file or a public URL to the image file to set default signature or image fields.",
                    "example": "Acme"
                  },
                  "readonly": {
                    "type": "boolean",
                    "description": "Set `true` to make it impossible for the submitter to edit predefined field value.",
                    "default": false
                  },
                  "required": {
                    "type": "boolean",
                    "description": "Set `true` to make the field required."
                  },
                  "validation_pattern": {
                    "type": "string",
                    "description": "HTML field validation pattern string based on https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/pattern specification.",
                    "example": "[A-Z]{4}"
                  },
                  "invalid_message": {
                    "type": "string",
                    "description": "A custom message to display on pattern validation failure."
                  },
                  "preferences": {
                    "type": "object",
                    "properties": {
                      "font_size": {
                        "type": "integer",
                        "description": "Font size of the field value in pixels.",
                        "example": 12
                      },
                      "font_type": {
                        "type": "string",
                        "description": "Font type of the field value.",
                        "enum": [
                          "bold",
                          "italic",
                          "bold_italic"
                        ]
                      },
                      "font": {
                        "type": "string",
                        "description": "Font family of the field value.",
                        "enum": [
                          "Times",
                          "Helvetica",
                          "Courier"
                        ]
                      },
                      "color": {
                        "type": "string",
                        "description": "Font color of the field value.",
                        "enum": [
                          "black",
                          "white",
                          "blue"
                        ],
                        "default": "black"
                      },
                      "align": {
                        "type": "string",
                        "description": "Horizontal alignment of the field text value.",
                        "enum": [
                          "left",
                          "center",
                          "right"
                        ],
                        "default": "left"
                      },
                      "valign": {
                        "type": "string",
                        "description": "Vertical alignment of the field text value.",
                        "enum": [
                          "top",
                          "center",
                          "bottom"
                        ],
                        "default": "center"
                      },
                      "format": {
                        "type": "string",
                        "description": "The data format for different field types.<br>- Date field: accepts formats such as DD/MM/YYYY (default: MM/DD/YYYY).<br>- Signature field: accepts drawn, typed, drawn_or_typed (default), or upload.<br>- Number field: accepts currency formats such as usd, eur, gbp.",
                        "example": "DD/MM/YYYY"
                      },
                      "price": {
                        "type": "number",
                        "description": "Price value of the payment field. Only for payment fields.",
                        "example": 99.99
                      },
                      "currency": {
                        "type": "string",
                        "description": "Currency value of the payment field. Only for payment fields.",
                        "enum": [
                          "USD",
                          "EUR",
                          "GBP",
                          "CAD",
                          "AUD"
                        ],
                        "default": "USD"
                      },
                      "mask": {
                        "description": "Set `true` to make sensitive data masked on the document.",
                        "oneOf": [
                          {
                            "type": "integer"
                          },
                          {
                            "type": "boolean"
                          }
                        ],
                        "default": false
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
```

### List all submitters

The API endpoint provides the ability to retrieve a list of submitters.

```shell
curl --request GET \
  --url https://api.docuseal.com/submitters \
  --header 'X-Auth-Token: API_KEY'
```

```json
{
  "security": [
    {
      "AuthToken": []
    }
  ],
  "tags": [
    "Submitters"
  ],
  "summary": "List all submitters",
  "operationId": "getSubmitters",
  "parameters": [
    {
      "name": "submission_id",
      "in": "query",
      "required": false,
      "schema": {
        "type": "integer"
      },
      "description": "The submission ID allows you to receive only the submitters related to that specific submission."
    },
    {
      "name": "q",
      "in": "query",
      "required": false,
      "schema": {
        "type": "string"
      },
      "description": "Filter submitters on name, email or phone partial match."
    },
    {
      "name": "slug",
      "in": "query",
      "required": false,
      "schema": {
        "type": "string"
      },
      "description": "Filter submitters by unique slug.",
      "example": "zAyL9fH36Havvm"
    },
    {
      "name": "completed_after",
      "in": "query",
      "required": false,
      "schema": {
        "type": "string",
        "format": "date-time"
      },
      "example": "2024-03-05 9:32:20",
      "description": "The date and time string value to filter submitters that completed the submission after the specified date and time."
    },
    {
      "name": "completed_before",
      "in": "query",
      "required": false,
      "schema": {
        "type": "string",
        "format": "date-time"
      },
      "example": "2024-03-06 19:32:20",
      "description": "The date and time string value to filter submitters that completed the submission before the specified date and time."
    },
    {
      "name": "external_id",
      "in": "query",
      "required": false,
      "schema": {
        "type": "string"
      },
      "description": "The unique applications-specific identifier provided for a submitter when initializing a signature request. It allows you to receive only submitters with a specified external id."
    },
    {
      "name": "limit",
      "in": "query",
      "required": false,
      "schema": {
        "type": "integer"
      },
      "description": "The number of submitters to return. Default value is 10. Maximum value is 100."
    },
    {
      "name": "after",
      "in": "query",
      "required": false,
      "schema": {
        "type": "integer"
      },
      "description": "The unique identifier of the submitter to start the list from. It allows you to receive only submitters with id greater than the specified value. Pass ID value from the `pagination.next` response to load the next batch of submitters."
    },
    {
      "name": "before",
      "in": "query",
      "required": false,
      "schema": {
        "type": "integer"
      },
      "description": "The unique identifier of the submitter to end the list with. It allows you to receive only submitters with id less than the specified value."
    }
  ]
}
```

### Update template documents

The API endpoint allows you to add, remove or replace documents in the template with provided PDF/DOCX file or HTML content.

```shell
curl --request PUT \
  --url https://api.docuseal.com/templates/1000001/documents \
  --header 'X-Auth-Token: API_KEY' \
  --header 'content-type: application/json' \
  --data '{"documents":[{"file":"string"}]}'
```

```json
{
  "security": [
    {
      "AuthToken": []
    }
  ],
  "tags": [
    "Templates"
  ],
  "summary": "Update template documents",
  "operationId": "addDocumentToTemplate",
  "parameters": [
    {
      "name": "id",
      "in": "path",
      "required": true,
      "schema": {
        "type": "integer"
      },
      "description": "The unique identifier of the documents template.",
      "example": 1000001
    }
  ],
  "requestBody": {
    "required": true,
    "content": {
      "application/json": {
        "schema": {
          "type": "object",
          "properties": {
            "documents": {
              "type": "array",
              "description": "The list of documents to add or replace in the template.",
              "items": {
                "type": "object",
                "properties": {
                  "name": {
                    "type": "string",
                    "description": "Document name. Random uuid will be assigned when not specified.",
                    "example": "Test Template"
                  },
                  "file": {
                    "type": "string",
                    "format": "base64",
                    "description": "Base64-encoded content of the PDF or DOCX file or downloadable file URL. Leave it empty if you create a new document using HTML param."
                  },
                  "html": {
                    "type": "string",
                    "description": "HTML template with field tags. Leave it empty if you add a document via PDF or DOCX base64 encoded file param or URL."
                  },
                  "position": {
                    "type": "integer",
                    "description": "Position of the document. By default will be added as the last document in the template.",
                    "example": 0
                  },
                  "replace": {
                    "type": "boolean",
                    "default": false,
                    "description": "Set to `true` to replace existing document with a new file at `position`. Existing document fields will be transferred to the new document if it doesn't contain any fields."
                  },
                  "remove": {
                    "type": "boolean",
                    "default": false,
                    "description": "Set to `true` to remove existing document at given `position` or with given `name`."
                  }
                }
              }
            },
            "merge": {
              "type": "boolean",
              "default": false,
              "description": "Set to `true` to merge all existing and new documents into a single PDF document in the template."
            }
          }
        }
      }
    }
  }
}
```

### Clone a template

The API endpoint allows you to clone existing template into a new template.

```shell
curl --request POST \
  --url https://api.docuseal.com/templates/1000001/clone \
  --header 'X-Auth-Token: API_KEY' \
  --header 'content-type: application/json' \
  --data '{"name":"Cloned Template"}'
```

```json
{
  "security": [
    {
      "AuthToken": []
    }
  ],
  "tags": [
    "Templates"
  ],
  "summary": "Clone a template",
  "operationId": "cloneTemplate",
  "parameters": [
    {
      "name": "id",
      "in": "path",
      "required": true,
      "schema": {
        "type": "integer"
      },
      "description": "The unique identifier of the documents template.",
      "example": 1000001
    }
  ],
  "requestBody": {
    "required": true,
    "content": {
      "application/json": {
        "schema": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string",
              "description": "Template name. Existing name with (Clone) suffix will be used if not specified.",
              "example": "Cloned Template"
            },
            "folder_name": {
              "type": "string",
              "description": "The folder's name to which the template should be cloned."
            },
            "external_id": {
              "type": "string",
              "description": "Your application-specific unique string key to identify this template within your app."
            }
          }
        }
      }
    }
  }
}
```

### Create a template from HTML

The API endpoint provides the functionality to seamlessly generate a PDF document template by utilizing the provided HTML content while incorporating pre-defined fields.<br><b>Related Guides</b><br><a href="https://www.docuseal.com/guides/create-pdf-document-fillable-form-with-html-api" class="link">Create PDF document fillable form with HTML</a>

```shell
curl --request POST \
  --url https://api.docuseal.com/templates/html \
  --header 'X-Auth-Token: API_KEY' \
  --header 'content-type: application/json' \
  --data '{"html":"<p>Lorem Ipsum is simply dummy text of the\n<text-field\n  name=\"Industry\"\n  role=\"First Party\"\n  required=\"false\"\n  style=\"width: 80px; height: 16px; display: inline-block; margin-bottom: -4px\">\n</text-field>\nand typesetting industry</p>\n","name":"Test Template"}'
```

```json
{
  "security": [
    {
      "AuthToken": []
    }
  ],
  "tags": [
    "Templates"
  ],
  "summary": "Create a template from HTML",
  "operationId": "createTemplateFromHtml",
  "parameters": [],
  "requestBody": {
    "required": true,
    "content": {
      "application/json": {
        "schema": {
          "type": "object",
          "required": [
            "html"
          ],
          "properties": {
            "html": {
              "type": "string",
              "description": "HTML template with field tags.",
              "example": "<p>Lorem Ipsum is simply dummy text of the\n<text-field\n  name=\"Industry\"\n  role=\"First Party\"\n  required=\"false\"\n  style=\"width: 80px; height: 16px; display: inline-block; margin-bottom: -4px\">\n</text-field>\nand typesetting industry</p>\n"
            },
            "html_header": {
              "type": "string",
              "description": "HTML template of the header to be displayed on every page."
            },
            "html_footer": {
              "type": "string",
              "description": "HTML template of the footer to be displayed on every page."
            },
            "name": {
              "type": "string",
              "description": "Template name. Random uuid will be assigned when not specified.",
              "example": "Test Template"
            },
            "size": {
              "type": "string",
              "default": "Letter",
              "description": "Page size. Letter 8.5 x 11 will be assigned when not specified.",
              "enum": [
                "Letter",
                "Legal",
                "Tabloid",
                "Ledger",
                "A0",
                "A1",
                "A2",
                "A3",
                "A4",
                "A5",
                "A6"
              ],
              "example": "A4"
            },
            "external_id": {
              "type": "string",
              "description": "Your application-specific unique string key to identify this template within your app. Existing template with specified `external_id` will be updated with a new HTML.",
              "example": "714d974e-83d8-11ee-b962-0242ac120002"
            },
            "folder_name": {
              "type": "string",
              "description": "The folder's name to which the template should be created."
            },
            "documents": {
              "type": "array",
              "description": "The list of documents built from HTML. Can be used to create a template with multiple documents. Leave `documents` param empty when using a top-level `html` param for a template with a single document.",
              "items": {
                "type": "object",
                "required": [
                  "html"
                ],
                "properties": {
                  "html": {
                    "type": "string",
                    "description": "HTML template with field tags.",
                    "example": "<p>Lorem Ipsum is simply dummy text of the\n<text-field\n  name=\"Industry\"\n  role=\"First Party\"\n  required=\"false\"\n  style=\"width: 80px; height: 16px; display: inline-block; margin-bottom: -4px\">\n</text-field>\nand typesetting industry</p>\n"
                  },
                  "name": {
                    "type": "string",
                    "description": "Document name. Random uuid will be assigned when not specified.",
                    "example": "Test Document"
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
```

### Create a template from Word DOCX

The API endpoint provides the functionality to create a fillable document template for existing Microsoft Word document. Use <code>{{Field Name;role=Signer1;type=date}}</code> text tags to define fillable fields in the document. See <a href="https://www.docuseal.com/examples/fieldtags.docx" target="_blank" class="link font-bold" >https://www.docuseal.com/examples/fieldtags.docx</a> for more text tag formats. Or specify the exact pixel coordinates of the document fields using `fields` param.<br><b>Related Guides</b><br><a href="https://www.docuseal.com/guides/use-embedded-text-field-tags-in-the-pdf-to-create-a-fillable-form" class="link">Use embedded text field tags to create a fillable form</a>


```shell
curl --request POST \
  --url https://api.docuseal.com/templates/docx \
  --header 'X-Auth-Token: API_KEY' \
  --header 'content-type: application/json' \
  --data '{"name":"Test DOCX","documents":[{"name":"string","file":"base64"}]}'
```

```json
{
  "security": [
    {
      "AuthToken": []
    }
  ],
  "tags": [
    "Templates"
  ],
  "summary": "Create a template from Word DOCX",
  "operationId": "createTemplateFromDocx",
  "parameters": [],
  "requestBody": {
    "required": true,
    "content": {
      "application/json": {
        "schema": {
          "type": "object",
          "required": [
            "documents"
          ],
          "properties": {
            "name": {
              "type": "string",
              "description": "Name of the template",
              "example": "Test DOCX"
            },
            "external_id": {
              "type": "string",
              "description": "Your application-specific unique string key to identify this template within your app. Existing template with specified `external_id` will be updated with a new document.",
              "example": "unique-key"
            },
            "folder_name": {
              "type": "string",
              "description": "The folder's name to which the template should be created."
            },
            "documents": {
              "type": "array",
              "items": {
                "type": "object",
                "required": [
                  "name",
                  "file"
                ],
                "properties": {
                  "name": {
                    "type": "string",
                    "description": "Name of the document."
                  },
                  "file": {
                    "type": "string",
                    "example": "base64",
                    "format": "base64",
                    "description": "Base64-encoded content of the DOCX file or downloadable file URL"
                  },
                  "fields": {
                    "description": "Fields are optional if you use {{...}} text tags to define fields in the document.",
                    "type": "array",
                    "items": {
                      "type": "object",
                      "properties": {
                        "name": {
                          "type": "string",
                          "description": "Name of the field."
                        },
                        "type": {
                          "type": "string",
                          "description": "Type of the field (e.g., text, signature, date, initials).",
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
                          "description": "Role name of the signer."
                        },
                        "required": {
                          "type": "boolean",
                          "description": "Indicates if the field is required."
                        },
                        "title": {
                          "type": "string",
                          "description": "Field title displayed to the user instead of the name, shown on the signing form. Supports Markdown."
                        },
                        "description": {
                          "type": "string",
                          "description": "Field description displayed on the signing form. Supports Markdown."
                        },
                        "areas": {
                          "type": "array",
                          "items": {
                            "type": "object",
                            "properties": {
                              "x": {
                                "type": "number",
                                "description": "X-coordinate of the field area."
                              },
                              "y": {
                                "type": "number",
                                "description": "Y-coordinate of the field area."
                              },
                              "w": {
                                "type": "number",
                                "description": "Width of the field area."
                              },
                              "h": {
                                "type": "number",
                                "description": "Height of the field area."
                              },
                              "page": {
                                "type": "integer",
                                "description": "Page number of the field area. Starts from 1."
                              },
                              "option": {
                                "type": "string",
                                "description": "Option string value for 'radio' and 'multiple' select field types."
                              }
                            }
                          }
                        },
                        "options": {
                          "type": "array",
                          "description": "An array of option values for 'select' field type.",
                          "items": {
                            "type": "string"
                          },
                          "example": [
                            "Option A",
                            "Option B"
                          ]
                        },
                        "preferences": {
                          "type": "object",
                          "properties": {
                            "font_size": {
                              "type": "integer",
                              "description": "Font size of the field value in pixels.",
                              "example": 12
                            },
                            "font_type": {
                              "type": "string",
                              "description": "Font type of the field value.",
                              "enum": [
                                "bold",
                                "italic",
                                "bold_italic"
                              ]
                            },
                            "font": {
                              "type": "string",
                              "description": "Font family of the field value.",
                              "enum": [
                                "Times",
                                "Helvetica",
                                "Courier"
                              ]
                            },
                            "color": {
                              "type": "string",
                              "description": "Font color of the field value.",
                              "enum": [
                                "black",
                                "white",
                                "blue"
                              ],
                              "default": "black"
                            },
                            "align": {
                              "type": "string",
                              "description": "Horizontal alignment of the field text value.",
                              "enum": [
                                "left",
                                "center",
                                "right"
                              ],
                              "default": "left"
                            },
                            "valign": {
                              "type": "string",
                              "description": "Vertical alignment of the field text value.",
                              "enum": [
                                "top",
                                "center",
                                "bottom"
                              ],
                              "default": "center"
                            },
                            "format": {
                              "type": "string",
                              "description": "The data format for different field types.<br>- Date field: accepts formats such as DD/MM/YYYY (default: MM/DD/YYYY).<br>- Signature field: accepts drawn, typed, drawn_or_typed (default), or upload.<br>- Number field: accepts currency formats such as usd, eur, gbp.",
                              "example": "DD/MM/YYYY"
                            },
                            "price": {
                              "type": "number",
                              "description": "Price value of the payment field. Only for payment fields.",
                              "example": 99.99
                            },
                            "currency": {
                              "type": "string",
                              "description": "Currency value of the payment field. Only for payment fields.",
                              "enum": [
                                "USD",
                                "EUR",
                                "GBP",
                                "CAD",
                                "AUD"
                              ],
                              "default": "USD"
                            },
                            "mask": {
                              "description": "Set `true` to make sensitive data masked on the document.",
                              "oneOf": [
                                {
                                  "type": "integer"
                                },
                                {
                                  "type": "boolean"
                                }
                              ],
                              "default": false
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
```

### Create a template from existing PDF

The API endpoint provides the functionality to create a fillable document template for existing PDF file. Use <code>{{Field Name;role=Signer1;type=date}}</code> text tags to define fillable fields in the document. See <a href="https://www.docuseal.com/examples/fieldtags.pdf" target="_blank" class="link font-bold">https://www.docuseal.com/examples/fieldtags.pdf</a> for more text tag formats. Or specify the exact pixel coordinates of the document fields using `fields` param.<br><b>Related Guides</b><br><a href="https://www.docuseal.com/guides/use-embedded-text-field-tags-in-the-pdf-to-create-a-fillable-form" class="link">Use embedded text field tags to create a fillable form</a>


```shell
curl --request POST \
  --url https://api.docuseal.com/templates/pdf \
  --header 'X-Auth-Token: API_KEY' \
  --header 'content-type: application/json' \
  --data '{"name":"Test PDF","documents":[{"name":"string","file":"base64","fields":[{"name":"string","areas":[{"x":0,"y":0,"w":0,"h":0,"page":1}]}]}]}'
```

```json
{
  "security": [
    {
      "AuthToken": []
    }
  ],
  "tags": [
    "Templates"
  ],
  "summary": "Create a template from existing PDF",
  "operationId": "createTemplateFromPdf",
  "parameters": [],
  "requestBody": {
    "required": true,
    "content": {
      "application/json": {
        "schema": {
          "type": "object",
          "required": [
            "documents"
          ],
          "properties": {
            "name": {
              "type": "string",
              "description": "Name of the template",
              "example": "Test PDF"
            },
            "folder_name": {
              "type": "string",
              "description": "The folder's name to which the template should be created."
            },
            "external_id": {
              "type": "string",
              "description": "Your application-specific unique string key to identify this template within your app. Existing template with specified `external_id` will be updated with a new PDF.",
              "example": "unique-key"
            },
            "documents": {
              "type": "array",
              "items": {
                "type": "object",
                "required": [
                  "name",
                  "file"
                ],
                "properties": {
                  "name": {
                    "type": "string",
                    "description": "Name of the document."
                  },
                  "file": {
                    "example": "base64",
                    "type": "string",
                    "format": "base64",
                    "description": "Base64-encoded content of the PDF file or downloadable file URL."
                  },
                  "fields": {
                    "type": "array",
                    "description": "Fields are optional if you use {{...}} text tags to define fields in the document.",
                    "items": {
                      "type": "object",
                      "properties": {
                        "name": {
                          "type": "string",
                          "description": "Name of the field."
                        },
                        "type": {
                          "type": "string",
                          "description": "Type of the field (e.g., text, signature, date, initials).",
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
                          "description": "Role name of the signer."
                        },
                        "required": {
                          "type": "boolean",
                          "description": "Indicates if the field is required."
                        },
                        "title": {
                          "type": "string",
                          "description": "Field title displayed to the user instead of the name, shown on the signing form. Supports Markdown."
                        },
                        "description": {
                          "type": "string",
                          "description": "Field description displayed on the signing form. Supports Markdown."
                        },
                        "areas": {
                          "type": "array",
                          "items": {
                            "type": "object",
                            "required": [
                              "x",
                              "y",
                              "w",
                              "h",
                              "page"
                            ],
                            "properties": {
                              "x": {
                                "type": "number",
                                "description": "X-coordinate of the field area."
                              },
                              "y": {
                                "type": "number",
                                "description": "Y-coordinate of the field area."
                              },
                              "w": {
                                "type": "number",
                                "description": "Width of the field area."
                              },
                              "h": {
                                "type": "number",
                                "description": "Height of the field area."
                              },
                              "page": {
                                "type": "integer",
                                "description": "Page number of the field area. Starts from 1.",
                                "example": 1
                              },
                              "option": {
                                "type": "string",
                                "description": "Option string value for 'radio' and 'multiple' select field types."
                              }
                            }
                          }
                        },
                        "options": {
                          "type": "array",
                          "description": "An array of option values for 'select' field type.",
                          "items": {
                            "type": "string"
                          },
                          "example": [
                            "Option A",
                            "Option B"
                          ]
                        },
                        "preferences": {
                          "type": "object",
                          "properties": {
                            "font_size": {
                              "type": "integer",
                              "description": "Font size of the field value in pixels.",
                              "example": 12
                            },
                            "font_type": {
                              "type": "string",
                              "description": "Font type of the field value.",
                              "enum": [
                                "bold",
                                "italic",
                                "bold_italic"
                              ]
                            },
                            "font": {
                              "type": "string",
                              "description": "Font family of the field value.",
                              "enum": [
                                "Times",
                                "Helvetica",
                                "Courier"
                              ]
                            },
                            "color": {
                              "type": "string",
                              "description": "Font color of the field value.",
                              "enum": [
                                "black",
                                "white",
                                "blue"
                              ],
                              "default": "black"
                            },
                            "align": {
                              "type": "string",
                              "description": "Horizontal alignment of the field text value.",
                              "enum": [
                                "left",
                                "center",
                                "right"
                              ],
                              "default": "left"
                            },
                            "valign": {
                              "type": "string",
                              "description": "Vertical alignment of the field text value.",
                              "enum": [
                                "top",
                                "center",
                                "bottom"
                              ],
                              "default": "center"
                            },
                            "format": {
                              "type": "string",
                              "description": "The data format for different field types.<br>- Date field: accepts formats such as DD/MM/YYYY (default: MM/DD/YYYY).<br>- Signature field: accepts drawn, typed, drawn_or_typed (default), or upload.<br>- Number field: accepts currency formats such as usd, eur, gbp.",
                              "example": "DD/MM/YYYY"
                            },
                            "price": {
                              "type": "number",
                              "description": "Price value of the payment field. Only for payment fields.",
                              "example": 99.99
                            },
                            "currency": {
                              "type": "string",
                              "description": "Currency value of the payment field. Only for payment fields.",
                              "enum": [
                                "USD",
                                "EUR",
                                "GBP",
                                "CAD",
                                "AUD"
                              ],
                              "default": "USD"
                            },
                            "mask": {
                              "description": "Set `true` to make sensitive data masked on the document.",
                              "oneOf": [
                                {
                                  "type": "integer"
                                },
                                {
                                  "type": "boolean"
                                }
                              ],
                              "default": false
                            }
                          }
                        }
                      }
                    }
                  },
                  "flatten": {
                    "type": "boolean",
                    "description": "Remove PDF form fields from the document.",
                    "default": false
                  },
                  "remove_tags": {
                    "type": "boolean",
                    "description": "Pass `false` to disable the removal of {{text}} tags from the PDF. This can be used along with transparent text tags for faster and more robust PDF processing.",
                    "default": true
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
```

### Merge templates

The API endpoint allows you to merge multiple templates with documents and fields into a new combined template.

```shell
curl --request POST \
  --url https://api.docuseal.com/templates/merge \
  --header 'X-Auth-Token: API_KEY' \
  --header 'content-type: application/json' \
  --data '{"template_ids":[321,432],"name":"Merged Template"}'
```

```json
{
  "security": [
    {
      "AuthToken": []
    }
  ],
  "tags": [
    "Templates"
  ],
  "summary": "Merge templates",
  "operationId": "mergeTemplate",
  "parameters": [],
  "requestBody": {
    "required": true,
    "content": {
      "application/json": {
        "schema": {
          "type": "object",
          "required": [
            "template_ids"
          ],
          "properties": {
            "template_ids": {
              "type": "array",
              "description": "An array of template ids to merge into a new template.",
              "items": {
                "type": "integer"
              },
              "example": [
                321,
                432
              ]
            },
            "name": {
              "type": "string",
              "description": "Template name. Existing name with (Merged) suffix will be used if not specified.",
              "example": "Merged Template"
            },
            "folder_name": {
              "type": "string",
              "description": "The name of the folder in which the merged template should be placed."
            },
            "external_id": {
              "type": "string",
              "description": "Your application-specific unique string key to identify this template within your app."
            },
            "roles": {
              "type": "array",
              "description": "An array of submitter role names to be used in the merged template.",
              "items": {
                "type": "string"
              },
              "example": [
                "Agent",
                "Customer"
              ]
            }
          }
        }
      }
    }
  }
}
```


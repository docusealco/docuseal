# Template Webhook

Get template creation and update notifications using these events:

- **'template.created'** is triggered when the template is created.
- **'template.updated'** is triggered when the template is updated.
- **'template.archived'** is triggered when the template is archived.



```json
{
  "event_type": {
    "type": "string",
    "description": "The event type.",
    "enum": [
      "template.created",
      "template.updated",
      "template.archived"
    ]
  },
  "timestamp": {
    "type": "string",
    "description": "The event timestamp.",
    "examples": [
      "2023-09-24T11:20:42Z"
    ],
    "format": "date-time"
  },
  "data": {
    "type": "object",
    "description": "Submitted data object.",
    "properties": {
      "id": {
        "type": "number",
        "description": "The template's unique identifier."
      },
      "slug": {
        "type": "string",
        "description": "The template's unique slug."
      },
      "name": {
        "type": "string",
        "description": "The template's name."
      },
      "schema": {
        "type": "array",
        "description": "The template document files.",
        "items": {
          "type": "object",
          "properties": {
            "attachment_uuid": {
              "type": "string",
              "description": "The attachment UUID."
            },
            "name": {
              "type": "string",
              "description": "The attachment name."
            }
          }
        }
      },
      "fields": {
        "type": "array",
        "description": "The template fields.",
        "items": {
          "type": "object",
          "properties": {
            "uuid": {
              "type": "string",
              "description": "The field UUID."
            },
            "submitter_uuid": {
              "type": "string",
              "description": "The submitter role UUID."
            },
            "name": {
              "type": "string",
              "description": "The field name."
            },
            "type": {
              "type": "string",
              "description": "The field type.",
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
                "verification",
                "kba",
                "strikethrough"
              ]
            },
            "required": {
              "type": "boolean",
              "description": "The flag indicating whether the field is required."
            },
            "preferences": {
              "type": "object",
              "description": "The field preferences."
            },
            "areas": {
              "type": "array",
              "description": "List of areas where the field is located in the document.",
              "items": {
                "type": "object",
                "properties": {
                  "x": {
                    "type": "number",
                    "description": "X coordinate of the area where the field is located in the document."
                  },
                  "y": {
                    "type": "number",
                    "description": "Y coordinate of the area where the field is located in the document."
                  },
                  "w": {
                    "type": "number",
                    "description": "Width of the area where the field is located in the document."
                  },
                  "h": {
                    "type": "number",
                    "description": "Height of the area where the field is located in the document."
                  },
                  "attachment_uuid": {
                    "type": "string",
                    "description": "Unique identifier of the attached document where the field is located."
                  },
                  "page": {
                    "type": "integer",
                    "description": "Page number of the attached document where the field is located."
                  }
                }
              }
            }
          }
        }
      },
      "submitters": {
        "type": "array",
        "description": "List of submitter roles defined in the template.",
        "items": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string",
              "description": "Submitter name."
            },
            "uuid": {
              "type": "string",
              "description": "Unique identifier of the submitter."
            }
          }
        }
      },
      "author_id": {
        "type": "integer",
        "description": "Unique identifier of the author of the template."
      },
      "archived_at": {
        "type": [
          "string",
          "null"
        ],
        "description": "Date and time when the template was archived."
      },
      "created_at": {
        "type": "string",
        "description": "Date and time when the template was created."
      },
      "updated_at": {
        "type": "string",
        "description": "Date and time when the template was updated."
      },
      "source": {
        "type": "string",
        "description": "Source of the template.",
        "enum": [
          "native",
          "api",
          "embed"
        ]
      },
      "external_id": {
        "type": [
          "string",
          "null"
        ],
        "description": "Identifier of the template in the external system."
      },
      "folder_id": {
        "type": "integer",
        "description": "Unique identifier of the folder where the template is placed."
      },
      "folder_name": {
        "type": "string",
        "description": "Folder name where the template is placed."
      },
      "preferences": {
        "type": "object",
        "description": "Template preferences object."
      },
      "shared_link": {
        "type": "boolean",
        "description": "Flag indicating whether the shared link is enabled for the template."
      },
      "author": {
        "type": "object",
        "description": "Author of the template.",
        "properties": {
          "id": {
            "type": "integer",
            "description": "Unique identifier of the author."
          },
          "first_name": {
            "type": "string",
            "description": "First name of the author."
          },
          "last_name": {
            "type": "string",
            "description": "Last name of the author."
          },
          "email": {
            "type": "string",
            "description": "Author email."
          }
        }
      },
      "documents": {
        "type": "array",
        "description": "List of documents attached to the template.",
        "items": {
          "type": "object",
          "properties": {
            "id": {
              "type": "integer",
              "description": "Unique identifier of the document."
            },
            "uuid": {
              "type": "string",
              "description": "Unique identifier of the document."
            },
            "url": {
              "type": "string",
              "description": "URL of the document."
            },
            "preview_image_url": {
              "type": "string",
              "description": "Document preview image URL."
            },
            "filename": {
              "type": "string",
              "description": "Document filename."
            }
          }
        }
      }
    }
  }
}
```
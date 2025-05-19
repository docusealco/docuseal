# Form Webhook

During the form filling and signing process, 3 types of events may occur and are dispatched at different stages:

- **'form.viewed'** event is triggered when the submitter first opens the form.
- **'form.started'** event is triggered when the submitter initiates filling out the form.
- **'form.completed'** event is triggered upon successful form completion and signing by one of the parties.
- **'form.declined'** event is triggered when a signer declines the submission.

 It's important to note that each of these events contain information available at the time of dispatch, so some data may be missing or incomplete depending on the specific event. Failed webhook requests (4xx, 5xx) are automatically retried multiple times within 48 hours (every 2^attempt minutes) for all production accounts.  
**Related Guides**  
[Download Signed Documents](https://www.docuseal.com/guides/download-signed-documents)

```json
{
  "event_type": {
    "type": "string",
    "description": "The event type.",
    "enum": [
      "form.viewed",
      "form.started",
      "form.completed"
    ]
  },
  "timestamp": {
    "type": "string",
    "description": "The event timestamp.",
    "example": "2023-09-24T11:20:42Z",
    "format": "date-time"
  },
  "data": {
    "type": "object",
    "description": "Submitted data object.",
    "properties": {
      "id": {
        "type": "number",
        "description": "The submitter's unique identifier."
      },
      "submission_id": {
        "type": "number",
        "description": "The unique submission identifier."
      },
      "email": {
        "type": "string",
        "description": "The submitter's email address",
        "format": "email",
        "example": "john.doe@example.com"
      },
      "ua": {
        "type": "string",
        "description": "The user agent string that provides information about the submitter's web browser.",
        "example": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36"
      },
      "ip": {
        "type": "string",
        "description": "The submitter's IP address."
      },
      "name": {
        "type": "string",
        "description": "The submitter's name."
      },
      "phone": {
        "type": "string",
        "description": "The submitter's phone number, formatted according to the E.164 standard.",
        "example": "+1234567890"
      },
      "role": {
        "type": "string",
        "description": "The submitter's role name or title.",
        "example": "First Party"
      },
      "external_id": {
        "type": "string",
        "description": "Your application-specific unique string key to identify submitter within your app."
      },
      "application_key": {
        "type": "string",
        "description": "Your application-specific unique string key to identify submitter within your app. Backward compatibility with the previous version of the API. Use external_id instead."
      },
      "decline_reason": {
        "type": "string",
        "description": "Submitter provided decline message."
      },
      "sent_at": {
        "type": "string",
        "format": "date-time"
      },
      "status": {
        "type": "string",
        "description": "The submitter status.",
        "enum": [
          "completed",
          "declined",
          "opened",
          "sent",
          "awaiting"
        ]
      },
      "opened_at": {
        "type": "string",
        "format": "date-time"
      },
      "completed_at": {
        "type": "string",
        "format": "date-time"
      },
      "declined_at": {
        "type": "string",
        "format": "date-time"
      },
      "created_at": {
        "type": "string",
        "format": "date-time"
      },
      "updated_at": {
        "type": "string",
        "format": "date-time"
      },
      "submission": {
        "type": "object",
        "description": "The submission details.",
        "properties": {
          "id": {
            "type": "number",
            "description": "The submission's unique identifier."
          },
          "audit_log_url": {
            "type": "string",
            "description": "The audit log PDF URL. Available only if the submission was completed by all submitters."
          },
          "combined_document_url": {
            "type": "string",
            "description": "The URL of the combined documents with audit log. Combined documents can be enabled via <a href=\"https://docuseal.com/settings/account\" target=\"_blank\" class=\"link\">/settings/accounts</a>."
          },
          "status": {
            "type": "string",
            "description": "The submission status.",
            "enum": [
              "completed",
              "declined",
              "expired",
              "pending"
            ]
          },
          "url": {
            "type": "string",
            "description": "The submission URL."
          },
          "created_at": {
            "type": "string",
            "description": "The submission creation date.",
            "format": "date-time"
          }
        }
      },
      "template": {
        "type": "object",
        "description": "Base template details.",
        "properties": {
          "id": {
            "type": "number",
            "description": "The template's unique identifier."
          },
          "name": {
            "type": "string",
            "description": "The template's name."
          },
          "external_id": {
            "type": "string",
            "description": "Your application-specific unique string key to identify template within your app."
          },
          "created_at": {
            "type": "string",
            "format": "date-time"
          },
          "updated_at": {
            "type": "string",
            "format": "date-time"
          },
          "folder_name": {
            "type": "string",
            "description": "Template folder name."
          }
        }
      },
      "preferences": {
        "type": "object",
        "properties": {
          "send_email": {
            "type": "boolean",
            "description": "The flag indicating whether the submitter has opted to receive an email."
          },
          "send_sms": {
            "type": "boolean",
            "description": "The flag indicating whether the submitter has opted to receive an SMS."
          }
        }
      },
      "values": {
        "type": "array",
        "description": "List of the filled values passed by the submitter.",
        "items": {
          "type": "object",
          "properties": {
            "field": {
              "type": "string",
              "description": "The field name."
            },
            "values": {
              "type": "string",
              "description": "The field value."
            }
          }
        }
      },
      "metadata": {
        "type": "object",
        "description": "Metadata object with additional submitter information."
      },
      "audit_log_url": {
        "type": "string",
        "description": "The audit log PDF URL. Available only if the submission was completed by all submitters."
      },
      "submission_url": {
        "type": "string",
        "description": "The submission URL."
      },
      "documents": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string",
              "description": "The document file name."
            },
            "url": {
              "type": "string",
              "description": "The document file URL."
            }
          }
        }
      }
    }
  }
}
```
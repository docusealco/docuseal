# Submission Webhook

Get submission creation, completion, expiration, and archiving notifications using these events:

- **'submission.created'** event is triggered when the submission is created.
- **'submission.completed'** event is triggered when the submission is completed by all signing parties.
- **'submission.expired'** event is triggered when the submission expires.
- **'submission.archived'** event is triggered when the submission is archived.



```json
{
  "event_type": {
    "type": "string",
    "description": "The event type.",
    "enum": [
      "submission.created",
      "submission.archived"
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
        "description": "The submission's unique identifier."
      },
      "archived_at": {
        "type": "string",
        "description": "The submission archive date."
      },
      "created_at": {
        "type": "string",
        "description": "The submission creation date."
      },
      "updated_at": {
        "type": "string",
        "description": "The submission update date."
      },
      "source": {
        "type": "string",
        "description": "The submission source.",
        "enum": [
          "invite",
          "bulk",
          "api",
          "embed",
          "link"
        ]
      },
      "submitters_order": {
        "type": "string",
        "description": "The submitters order.",
        "enum": [
          "random",
          "preserved"
        ]
      },
      "audit_log_url": {
        "type": "string",
        "description": "Audit log file URL."
      },
      "submitters": {
        "type": "array",
        "description": "The list of submitters for the submission.",
        "items": {
          "type": "object",
          "properties": {
            "id": {
              "type": "number",
              "description": "The submitter's unique identifier."
            },
            "submission_id": {
              "type": "number",
              "description": "The unique submission identifier."
            },
            "uuid": {
              "type": "string",
              "description": "The submitter UUID."
            },
            "email": {
              "type": "string",
              "description": "The email address of the submitter.",
              "format": "email",
              "example": "john.doe@example.com"
            },
            "slug": {
              "type": "string",
              "description": "The unique slug of the document template."
            },
            "sent_at": {
              "type": "string",
              "description": "The date and time when the signing request was sent to the submitter."
            },
            "opened_at": {
              "type": "string",
              "description": "The date and time when the submitter opened the signing form."
            },
            "completed_at": {
              "type": "string",
              "description": "The date and time when the submitter completed the signing form."
            },
            "declined_at": {
              "type": "string",
              "description": "The date and time when the submitter declined the signing form."
            },
            "created_at": {
              "type": "string",
              "description": "The date and time when the submitter was created."
            },
            "updated_at": {
              "type": "string",
              "description": "The date and time when the submitter was last updated."
            },
            "name": {
              "type": "string",
              "description": "The name of the submitter."
            },
            "phone": {
              "type": "string",
              "description": "The phone number of the submitter, formatted according to the E.164 standard.",
              "example": "+1234567890"
            },
            "role": {
              "type": "string",
              "description": "The role name or title of the submitter.",
              "example": "First Party"
            },
            "external_id": {
              "type": "string",
              "description": "Your application-specific unique string key to identify this submitter within your app."
            },
            "metadata": {
              "type": "object",
              "description": "Metadata object with additional submitter information.",
              "example": "{ 'customField': 'value' }"
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
            "application_key": {
              "type": "string",
              "description": "Your application-specific unique string key to identify this submitter within your app."
            },
            "values": {
              "type": "object",
              "description": "An object with pre-filled values for the submission. Use field names for keys of the object. For more configurations see `fields` param."
            },
            "documents": {
              "type": "array",
              "description": "The list of documents for the submission.",
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
            },
            "preferences": {
              "type": "object",
              "description": "The submitter preferences."
            }
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
          "folder_name": {
            "type": "string",
            "description": "The folder name."
          },
          "created_at": {
            "type": "string",
            "description": "The date and time when the template was created."
          },
          "updated_at": {
            "type": "string",
            "description": "The date and time when the template was last updated."
          }
        }
      },
      "created_by_user": {
        "type": "object",
        "properties": {
          "id": {
            "type": "integer",
            "description": "Unique identifier of the user who created the submission."
          },
          "first_name": {
            "type": "string",
            "description": "The first name of the user who created the submission."
          },
          "last_name": {
            "type": "string",
            "description": "The last name of the user who created the submission."
          },
          "email": {
            "type": "string",
            "description": "The email address of the user who created the submission."
          }
        }
      },
      "submission_events": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "id": {
              "type": "integer",
              "description": "Submission event unique ID number."
            },
            "submitter_id": {
              "type": "integer",
              "description": "Unique identifier of the submitter that triggered the event."
            },
            "event_type": {
              "type": "string",
              "description": "Event type.",
              "enum": [
                "send_email",
                "bounce_email",
                "complaint_email",
                "send_reminder_email",
                "send_sms",
                "send_2fa_sms",
                "open_email",
                "click_email",
                "click_sms",
                "phone_verified",
                "start_form",
                "start_verification",
                "complete_verification",
                "view_form",
                "invite_party",
                "complete_form",
                "decline_form",
                "api_complete_form"
              ]
            },
            "event_timestamp": {
              "type": "string",
              "description": "Date and time when the event was triggered."
            }
          }
        }
      },
      "documents": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string",
              "description": "Document name."
            },
            "url": {
              "type": "string",
              "description": "Document URL."
            }
          }
        }
      },
      "status": {
        "type": "string",
        "description": "The status of the submission.",
        "enum": [
          "completed",
          "declined",
          "expired",
          "pending"
        ]
      },
      "completed_at": {
        "type": "string",
        "description": "The date and time when the submission was fully completed."
      }
    }
  }
}
```
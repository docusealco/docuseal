# DocuSeal API Reference — Extended Endpoints

This documents the additional API endpoints implemented in this fork beyond the base DocuSeal OSS API.

Authentication: All endpoints require an `X-Auth-Token` header with a valid API token.

Base URL: `http://your-host/api`

---

## POST /api/templates/pdf

Create a fillable document template from one or more PDF files.

PDF files may contain embedded text field tags using the `{{Field Name;role=Signer1;type=date}}` syntax. Fields are automatically extracted from these tags. Alternatively (or additionally), you can specify explicit field positions using the `fields` parameter with pixel-fraction coordinates.

If a template with the given `external_id` already exists, it will be updated with the new documents.

### Request

```
POST /api/templates/pdf
Content-Type: application/json
X-Auth-Token: YOUR_API_KEY
```

### Request Body

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | String | No | Template name. Defaults to the first document's name. |
| `external_id` | String | No | Your application-specific unique key. If a template with this ID exists, it will be updated instead of creating a new one. |
| `folder_name` | String | No | Name of the folder to place the template in. Created automatically if it doesn't exist. |
| `documents` | Array | **Yes** | Array of PDF document objects. |

#### `documents[]` object

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | String | **Yes** | Name of the document. |
| `file` | String | **Yes** | Base64-encoded PDF content, OR a publicly accessible URL to download the PDF from. |
| `fields` | Array | No | Explicit field definitions with coordinates. Optional if you use `{{...}}` text tags in the PDF. |

#### `documents[].fields[]` object

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | String | No | Field name displayed in the signing form. |
| `type` | String | No | Field type. Default: `text`. See field types below. |
| `role` | String | No | Role name of the signer who fills this field. Default: `First Party`. |
| `required` | Boolean | No | Whether the field is required. Default: `true`. |
| `areas` | Array | No | Positioning coordinates on the document page. |

**Field types:** `text`, `signature`, `initials`, `date`, `number`, `image`, `checkbox`, `multiple`, `file`, `radio`, `select`, `cells`, `stamp`, `payment`, `phone`

#### `documents[].fields[].areas[]` object

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `x` | Number | **Yes** | X-coordinate as a fraction of page width (0.0 to 1.0). |
| `y` | Number | **Yes** | Y-coordinate as a fraction of page height (0.0 to 1.0). |
| `w` | Number | **Yes** | Width as a fraction of page width (0.0 to 1.0). |
| `h` | Number | **Yes** | Height as a fraction of page height (0.0 to 1.0). |
| `page` | Integer | **Yes** | Page number, **starting from 1**. |

### Example Request

```bash
curl -X POST https://your-host/api/templates/pdf \
  -H "X-Auth-Token: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Rental Agreement",
    "external_id": "rental-v2",
    "folder_name": "Contracts",
    "documents": [
      {
        "name": "rental-agreement",
        "file": "JVBERi0xLjQK...",
        "fields": [
          {
            "name": "Tenant Name",
            "type": "text",
            "role": "Tenant",
            "required": true,
            "areas": [{"x": 0.1, "y": 0.3, "w": 0.35, "h": 0.03, "page": 1}]
          },
          {
            "name": "Tenant Signature",
            "type": "signature",
            "role": "Tenant",
            "areas": [{"x": 0.1, "y": 0.85, "w": 0.3, "h": 0.06, "page": 2}]
          },
          {
            "name": "Landlord Signature",
            "type": "signature",
            "role": "Landlord",
            "areas": [{"x": 0.55, "y": 0.85, "w": 0.3, "h": 0.06, "page": 2}]
          }
        ]
      }
    ]
  }'
```

### Example with URL

```bash
curl -X POST https://your-host/api/templates/pdf \
  -H "X-Auth-Token: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "NDA Template",
    "documents": [
      {
        "name": "nda",
        "file": "https://example.com/documents/nda-template.pdf"
      }
    ]
  }'
```

### Example with Text Tags (no explicit fields)

If your PDF contains text like `{{Full Name;type=text;role=Employee}}` and `{{Signature;type=signature;role=Employee}}`, fields are extracted automatically:

```bash
curl -X POST https://your-host/api/templates/pdf \
  -H "X-Auth-Token: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Employment Contract",
    "external_id": "emp-contract-v1",
    "documents": [
      {
        "name": "contract",
        "file": "https://example.com/tagged-contract.pdf"
      }
    ]
  }'
```

### Response

Returns the full template object:

```json
{
  "id": 42,
  "slug": "ZQpF222rFBv71q",
  "name": "Rental Agreement",
  "schema": [
    {
      "name": "rental-agreement",
      "attachment_uuid": "09a8bc73-a7a9-4fd9-8173-95752bdf0af5"
    }
  ],
  "fields": [
    {
      "uuid": "a06c49f6-4b20-4442-ac7f-c1040d2cf1ac",
      "submitter_uuid": "93ba628c-5913-4456-a1e9-1a81ad7444b3",
      "name": "Tenant Name",
      "type": "text",
      "required": true,
      "areas": [
        {
          "attachment_uuid": "09a8bc73-a7a9-4fd9-8173-95752bdf0af5",
          "x": 0.1,
          "y": 0.3,
          "w": 0.35,
          "h": 0.03,
          "page": 0
        }
      ]
    }
  ],
  "submitters": [
    {
      "name": "Tenant",
      "uuid": "93ba628c-5913-4456-a1e9-1a81ad7444b3"
    },
    {
      "name": "Landlord",
      "uuid": "b7de5f12-3c89-4a67-b890-1234567890ab"
    }
  ],
  "author_id": 1,
  "author": {
    "id": 1,
    "first_name": "John",
    "last_name": "Doe",
    "email": "admin@example.com"
  },
  "source": "api",
  "external_id": "rental-v2",
  "folder_id": 5,
  "folder_name": "Contracts",
  "archived_at": null,
  "created_at": "2026-05-07T10:30:00.000Z",
  "updated_at": "2026-05-07T10:30:00.000Z",
  "documents": [
    {
      "id": 101,
      "uuid": "09a8bc73-a7a9-4fd9-8173-95752bdf0af5",
      "url": "https://your-host/blobs/proxy/abc123/rental-agreement.pdf",
      "preview_image_url": "https://your-host/blobs/proxy/def456/0.png",
      "filename": "rental-agreement.pdf"
    }
  ]
}
```

### Notes

- Page numbers in the request are **1-indexed** (page 1 = first page). In the response, they are **0-indexed** (page 0 = first page). This matches the DocuSeal Pro API behavior.
- When `external_id` is provided and a template with that ID exists, the template is updated (upsert behavior). The webhook event will be `template.updated` instead of `template.created`.
- Fields extracted from PDF text tags use the syntax: `{{Field Name;role=RoleName;type=fieldtype;required=false}}`. Attributes are separated by semicolons.
- Both base64 content and HTTP(S) URLs are supported for the `file` parameter.

### Errors

| Status | Condition |
|--------|-----------|
| 401 | Missing or invalid `X-Auth-Token` |
| 403 | Token valid but user lacks permission to create templates |
| 422 | Invalid parameters (missing documents, invalid JSON) |

---

## PUT /api/templates/{id}/documents

Add, replace, or remove documents in an existing template.

### Request

```
PUT /api/templates/{id}/documents
Content-Type: application/json
X-Auth-Token: YOUR_API_KEY
```

### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | Integer | **Yes** | The template ID. |

### Request Body

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `documents` | Array | **Yes** | Array of document operation objects. |

#### `documents[]` object

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | String | No | Document name. |
| `file` | String | No | Base64-encoded PDF content or URL. Required unless `remove` is true. |
| `position` | Integer | No | Zero-indexed position in the template's document list. For add: where to insert (default: append). For replace/remove: which document to target. |
| `replace` | Boolean | No | Set to `true` to replace the document at `position` with the new file. Existing field positions are transferred to the new document if the new document has no auto-detected fields. Default: `false`. |
| `remove` | Boolean | No | Set to `true` to remove the document at `position` or matching `name`. Default: `false`. |

### Operations

#### Add a document (default)

Adds a new document to the template at the specified position (or appends to the end).

```json
{
  "documents": [
    {
      "name": "Appendix A",
      "file": "JVBERi0xLjQK...",
      "position": 1
    }
  ]
}
```

#### Replace a document

Replaces the document at `position` with a new file. If the new document doesn't contain any auto-detected fields, existing fields are remapped to the new document (preserving their coordinates).

```json
{
  "documents": [
    {
      "file": "JVBERi0xLjQK...",
      "position": 0,
      "replace": true
    }
  ]
}
```

#### Remove a document

Removes the document at `position` or matching `name`. All fields associated with the removed document are also deleted.

```json
{
  "documents": [
    {
      "position": 2,
      "remove": true
    }
  ]
}
```

Or by name:

```json
{
  "documents": [
    {
      "name": "Appendix A",
      "remove": true
    }
  ]
}
```

#### Multiple operations in one request

You can combine add, replace, and remove operations:

```json
{
  "documents": [
    {"position": 2, "remove": true},
    {"name": "New Main Document", "file": "JVBERi0...", "position": 0, "replace": true},
    {"name": "Addendum", "file": "https://example.com/addendum.pdf"}
  ]
}
```

Operations are processed in array order.

### Example Request

```bash
curl -X PUT https://your-host/api/templates/42/documents \
  -H "X-Auth-Token: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "documents": [
      {
        "name": "Updated Contract",
        "file": "https://example.com/contract-v2.pdf",
        "position": 0,
        "replace": true
      }
    ]
  }'
```

### Response

Returns the full updated template object (same format as POST /api/templates/pdf response above).

```json
{
  "id": 42,
  "slug": "ZQpF222rFBv71q",
  "name": "Rental Agreement",
  "schema": [...],
  "fields": [...],
  "submitters": [...],
  "author_id": 1,
  "author": {...},
  "documents": [
    {
      "id": 205,
      "uuid": "new-document-uuid",
      "url": "https://your-host/blobs/proxy/xyz/Updated%20Contract.pdf",
      "preview_image_url": "https://your-host/blobs/proxy/abc/0.png",
      "filename": "Updated Contract.pdf"
    }
  ],
  ...
}
```

### Notes

- Position is **0-indexed** (position 0 = first document).
- When replacing a document, existing field coordinates are preserved if the new document has no auto-detected fields. This is useful when replacing a template PDF with an updated version that has the same layout.
- When removing a document, all fields whose `areas` reference that document's `attachment_uuid` are also removed.
- Operations are processed sequentially in array order. Be aware that positions may shift after add/remove operations earlier in the array.

### Errors

| Status | Condition |
|--------|-----------|
| 401 | Missing or invalid `X-Auth-Token` |
| 403 | Token valid but user lacks permission to update this template |
| 404 | Template with given ID not found |
| 422 | Invalid parameters |

---

## Text Field Tag Syntax

When creating templates from PDF files, you can embed field tags directly in the document text. The tag format is:

```
{{Field Name;attribute=value;attribute=value}}
```

### Supported Attributes

| Attribute | Values | Description |
|-----------|--------|-------------|
| `type` | text, signature, date, initials, number, image, checkbox, radio, select, file, stamp, phone | Field type. Default: text |
| `role` | Any string | Signer role name for multi-party documents |
| `required` | true, false | Whether the field is required. Default: true |
| `readonly` | true, false | Whether the field is read-only |
| `default` | Any string | Pre-filled default value |

### Examples

```
{{Full Name;role=Employee;type=text}}
{{Signature;role=Employee;type=signature}}
{{Date of Birth;type=date;required=false}}
{{Photo ID;role=Applicant;type=image}}
{{Accept Terms;type=checkbox}}
{{Department;type=select;options=Engineering,Sales,Marketing}}
{{Rating;type=radio;option=Excellent}}
{{Rating;type=radio;option=Good}}
{{Rating;type=radio;option=Fair}}
```

See https://www.docuseal.com/examples/fieldtags.pdf for a complete reference of all tag formats.

---

## Webhook Events

Both endpoints trigger webhook events when configured:

| Endpoint | Event |
|----------|-------|
| POST /api/templates/pdf (new template) | `template.created` |
| POST /api/templates/pdf (upsert existing) | `template.updated` |
| PUT /api/templates/:id/documents | `template.updated` |

Configure webhooks in Settings > Webhooks.

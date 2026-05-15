# DocuSeal like-a-Pro (Community Edition)

> Fork of [DocuSeal](https://github.com/docusealco/docuseal) with select Pro features "unlocked" (read: vibe-coded) as open source.

This fork adds features that are not part of the opensource version of DocuSeal, making them available for self-hosted deployments under the same AGPL-3.0 license.

Disclaimer:

I never had any access to the Pro Version and I have no idea how DocuSeal LLC implemented these features. I don't even think that "white-room copy" would be the right description here.
I did not review, copy, or use any copyright-protected source code from DocuSeal LLC. The changes in this repo are "designed" based on the official API documentation and feature spotlights on the website or what I thought these features should look like.
The plan of this repo is not to challenge Docuseal's position; I just needed some features that I thought were simple enough to vibe code and play around with. I would not recommend using this fork for a production environment, and I can't guarantee maintenance at all.
If you need a professional, reliable solution, stick with the upstream project or buy a subscription with Docuseal! 
Support companies that are providing open-source solutions!


## vibe-coded "Pro" Features

| Feature | Status | Description |
|---------|--------|-------------|
| Company logo / white-label | Done | Upload your logo in Settings > Personalization. Displayed in signing forms and emails. |
| Automated reminders | Done | Scheduled follow-up emails with customizable templates, reminder queue visibility, and skip controls. |
| Template creation via API | Done | `POST /api/templates/pdf` and `PUT /api/templates/:id/documents` — create and manage templates programmatically with field coordinates or embedded text tags. |
| Professional email design | Done | Table-based responsive email layout with company branding, styled CTA buttons, and proper footer. |
| Teams & user roles | Done | Multi-team support with admin/editor roles. Editors see only their team's documents. Admins can move folders between teams. |

See [`docs/API.md`](docs/API.md) for full API reference on the new endpoints.

## Teams & Roles

This fork implements team-based access control with two roles:

| Role | Access |
|------|--------|
| **Admin** | Full access to all teams, users, settings, and resources in the account |
| **Editor** | Full access to templates, submissions, and documents within their team only. Can manage personalization, API keys, and webhooks. Cannot manage users, teams, or account settings. |

**Key features:**
- Create multiple teams per account (Settings > Teams)
- Assign users to teams with role selection
- Editors are scoped to their team — they only see templates, submissions, and folders belonging to their team
- Admins can move entire folders (with all templates and submissions) to another team via the folder edit modal
- API tokens respect the user's role and team membership
- Migrations handle both greenfield installs and existing deployments (auto-creates a "Default" team and backfills)

## Automated Reminders

Reminder emails are sent to pending signers on a configurable schedule.

**Configuration:**
- Set reminder interval (e.g., every 2 days) in Settings > Notifications
- Customize reminder email subject and body at account level (Settings > Personalization) or per-template
- Supports the same template variables as invitation emails (submitter name, template name, link, etc.)

**Visibility & Controls:**
- Submission page shows the next scheduled reminder time per submitter (with timezone tooltip)
- Settings > Notifications includes a pending reminders queue table showing all upcoming reminders
- Skip button lets you advance past a pending reminder without sending it (fires a `skip_reminder_email` event)

**Reliability:**
- Deduplication guard prevents the same reminder from being sent twice within 1 minute
- Job scheduling handles container restarts gracefully (clears stale scheduled jobs before re-registering)

## Paperless-ngx Integration

Automatically upload completed, fully-signed documents to a [paperless-ngx](https://docs.paperless-ngx.com/) instance for archival and full-text search.

**How it works:**
- When all parties have signed a submission, the combined result PDF and audit trail are uploaded to paperless-ngx via its REST API.
- If the combined PDF feature is not enabled, individual per-submitter result PDFs are uploaded instead.
- Documents are titled `"Template Name - Signer 1, Signer 2"` with the signing completion date.
- Uploads run as a background job with exponential retry (up to 10 attempts) — they never block the signing flow.

**Configuration (env vars only — no GUI):**

| Variable | Description |
|----------|-------------|
| `PAPERLESS_NGX_URL` | Base URL of your paperless-ngx instance (e.g., `http://paperless:8000`) |
| `PAPERLESS_NGX_TOKEN` | API token for authentication ([how to get one](https://docs.paperless-ngx.com/api/#authorization)) |

The feature is inactive unless both variables are set.

## What's NOT included

These Pro features remain unavailable in this fork (they require significant UI/infrastructure work):

- SMS invitation and verification
- Conditional fields and formulas
- Bulk send with CSV/XLSX import
- SSO / SAML
- Template creation with HTML or DOCX API
- Embedded form builder components

## Deploy

Pre-built images are published to GitHub Container Registry on every release tag.

```
ghcr.io/s256/docuseal-with-some-pro-features:latest
ghcr.io/s256/docuseal-with-some-pro-features:2.5.3-fork.2
```

Images are signed with [cosign](https://github.com/sigstore/cosign) and include an SBOM and build provenance attestation.

#### Docker Compose (recommended)

```sh
curl -O https://raw.githubusercontent.com/s256/docuseal-with-some-pro-features/master/docker-compose.yml
docker compose up
```

This starts the app with PostgreSQL. Available at `http://localhost:3000`.

Data is persisted in `./docuseal` (uploads, active storage) and `./pg_data` (database).

#### With SSL (reverse proxy)

Uncomment the Caddy service in `docker-compose.yml` and set your domain:

```sh
HOST=your-domain.com docker compose up
```

Caddy auto-provisions TLS certificates via Let's Encrypt.

#### Docker (standalone)

```sh
docker run --name docuseal \
  -p 3000:3000 \
  -v ./docuseal:/data/docuseal \
  -e DATABASE_URL=postgresql://user:pass@host:5432/docuseal \
  ghcr.io/s256/docuseal-with-some-pro-features:latest
```

Without `DATABASE_URL`, the app falls back to SQLite (stored in `/data/docuseal`).

#### Build from source

```sh
git clone https://github.com/s256/docuseal-with-some-pro-features.git
cd docuseal-with-some-pro-features
docker build -t docuseal .
docker compose up  # edit docker-compose.yml to use `build: .` instead of `image:`
```

#### Environment variables

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string. Omit for SQLite. |
| `SECRET_KEY_BASE` | Rails secret key (auto-generated if not set). |
| `APP_URL` | Public-facing URL for links in emails. |
| `FORCE_SSL` | Set to your domain to enforce HTTPS redirects. |
| `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD` | SMTP for outgoing emails (invitations, reminders). |

See the [environment reference](https://www.docuseal.com/docs/hosting#docker) in the upstream docs for the full list.

## Upstream Features

All features from the base DocuSeal OSS are included:

- PDF form fields builder (WYSIWYG)
- 12 field types (Signature, Date, File, Checkbox, etc.)
- Multiple submitters per document
- Automated emails via SMTP
- File storage on disk or S3/GCS/Azure
- Automatic PDF eSignature and verification
- Users management
- Mobile-optimized
- UI in 7 languages, signing in 14 languages
- API and Webhooks
- Easy deployment

## License

Distributed under the AGPLv3 License with Section 7(b) Additional Terms. See [LICENSE](LICENSE) and [LICENSE_ADDITIONAL_TERMS](LICENSE_ADDITIONAL_TERMS) for more information.

Original work © 2023-2026 DocuSeal LLC. Modifications in this fork are released under the same license.

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
| Automated reminders | Done | Configure reminder intervals per-account. Pending signers receive scheduled follow-up emails. |
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

## What's NOT included

These Pro features remain unavailable in this fork (they require significant UI/infrastructure work):

- SMS invitation and verification
- Conditional fields and formulas
- Bulk send with CSV/XLSX import
- SSO / SAML
- Template creation with HTML or DOCX API
- Embedded form builder components

## Deploy

#### Docker Compose (recommended)

```sh
git clone https://github.com/s256/docuseal-with-some-pro-features.git
cd docuseal
docker compose up --build
```

The app will be available at `http://localhost:3000`.

To run behind a reverse proxy with SSL, uncomment the Caddy service in `docker-compose.yml` and set your domain:

```sh
HOST=your-domain.com docker compose up --build
```

#### Docker (standalone)

```sh
docker build -t docuseal .
docker run --name docuseal -p 3000:3000 -v ./docuseal:/data/docuseal docuseal
```

Uses PostgreSQL by default (see `docker-compose.yml`). For SQLite, use the upstream image or omit `DATABASE_URL`.

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

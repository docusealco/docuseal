# Changelog

All notable changes to WaboSign are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] — 2026-05-18

### Added
- Per-account product-name branding. Account admins can replace "WaboSign" in the UI, emails, audit-trail PDFs, signing-form headers, page titles, PWA manifest, social-share `og:title`, and authenticator-app issuer with their own product name. Configurable from `/settings/personalization` above the logo upload. Leave blank to fall back to the default.

### Changed
- Resolution flows through a new `Wabosign.branded_product_name(account = nil)` helper. When no account is in scope (landing page, PWA manifest, OAuth chrome), the deployment's oldest non-archived account's brand is used.

[1.1.0]: https://github.com/wabolabs/wabosign/releases/tag/1.1.0

## [1.0.0] — 2026-05-17

First WaboSign release. Forked from [DocuSeal](https://github.com/docusealco/docuseal) 2.5.3.

### Added
- Google Workspace SSO via `omniauth-google-oauth2`, configurable from `/settings/sso` with ENV + DB fallback. See [GOOGLE_SSO.md](GOOGLE_SSO.md).
- SMS invitations via BulkVS, configurable from `/settings/sms`. See [SMS.md](SMS.md).
- Custom account logo upload with server-side SVG sanitization. The logo renders on the sign-in page, signing flow, dashboard navbar, share-link QR page, and audit-trail PDFs.
- Editor and Viewer user roles alongside Admin. Editors get CRUD on templates and submissions; Viewers get read-only access. Self-service profile management is preserved for every role.
- OCI image labels (`org.opencontainers.image.*`) and multi-arch (linux/amd64 + linux/arm64) Docker builds wired via `.github/workflows/docker.yml`.
- [CHANGELOG.md](CHANGELOG.md) and a Releases section in [README.md](README.md).

### Changed
- Removed the upstream "Pro" feature paywall — multi-account, SSO, SMS, audit trail, and timestamping all work out of the box on a self-hosted deployment.
- Rebranded all UI surfaces, emails, and asset paths from DocuSeal to WaboSign while preserving AGPL §7(b) upstream attribution in [NOTICE](NOTICE), [REBRANDING.md](REBRANDING.md), [LICENSE_ADDITIONAL_TERMS](LICENSE_ADDITIONAL_TERMS), and the in-app "Powered by" footer.
- Default container image is now `ghcr.io/wabolabs/wabosign` (public).
- Security contact in [SECURITY.md](SECURITY.md) now routes to `wabosign@wabo.cc`.

### Removed
- Developer Newsletter step from the initial-setup flow (was a DocuSeal mailing-list signup).
- Console-redirect endpoints (`/upgrade`, `/manage`, `/console_redirect`) and the enquiries form — only made sense for DocuSeal's hosted multitenant SaaS.
- Upstream API-docs language stubs at `docs/api/` (10 files referencing `api.docuseal.com`). The OpenAPI spec at `docs/openapi.json` and the embedding/webhook guides remain (URLs rewritten to `sign.wabo.cc`).
- The "Upgrade to Pro" fallback markup served by the embed-script controller — replaced with a neutral "embed assets not loaded" message.

### Security
- Account-logo SVG uploads are sanitized via Nokogiri before storage (strips `<script>`, `<foreignObject>`, `on*` attributes, and external `href` / `xlink:href` values).

[1.0.0]: https://github.com/wabolabs/wabosign/releases/tag/1.0.0

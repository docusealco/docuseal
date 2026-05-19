# Changelog

All notable changes to WaboSign are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] — 2026-05-19

Adds three new SMS providers alongside the existing BulkVS integration.

### Added
- [Twilio](lib/sms/providers/twilio.rb) — form-encoded POST to the Messages API; Basic Auth with `SID:Token`; treats a `201` response carrying an `error_code` as a failure.
- [VoIP.ms](lib/sms/providers/voipms.rb) — query-string-auth GET to `sendSMS`; treats `status != "success"` as a failure even on HTTP 200; enforces the API's 160-byte hard cap before dispatch.
- [SignalWire](lib/sms/providers/signalwire.rb) — Twilio-shaped client targeting the per-account Space URL host; strips `https://` and any trailing `/` from the user-supplied space URL.
- [/settings/sms](app/views/sms_settings/index.html.erb) — dynamic provider select driven by `Sms::SUPPORTED_PROVIDERS`, per-provider field blocks toggled by a nonce'd inline script (the app's CSP requires nonces on inline JS).
- [SMS.md](SMS.md) — per-provider "Configuring …" sections, wire-format quick-reference table, updated extension and status-code map sections.

### Changed
- [lib/sms.rb](lib/sms.rb) dispatches via per-provider classes and delegates the "is this configured" check to each provider — replaces the BulkVS-only hardcoded gate in `enabled_for?`.
- [app/controllers/sms_settings_controller.rb](app/controllers/sms_settings_controller.rb) extends the preserve-secret-on-blank-edit pattern (used for BulkVS) to all four providers' password/token fields via a `SECRET_KEYS` array.
- Existing BulkVS configs keep working unchanged — credentials remain in their existing keys; the `provider` key defaults to `bulkvs` when absent.

### Notes
- Released image: `ghcr.io/wabolabs/wabosign:1.3.0` (also tagged `:latest`).
- This release is a fast-follow on 1.2.0 — same upstream-sync state, plus the SMS providers.

[1.3.0]: https://github.com/wabolabs/wabosign/releases/tag/1.3.0

## [1.2.0] — 2026-05-19

Synced with upstream [DocuSeal 3.0.0](https://github.com/docusealco/docuseal/releases/tag/3.0.0) and added scripted-sweep tooling so future upstream merges are reproducible.

### Added
- [bin/rebrand-sync](bin/rebrand-sync) — idempotent Ruby script that performs the DocuSeal → WaboSign rename sweep across the working tree. Sentinel-protects AGPL §7(b) attribution phrases, the `<docuseal-form>` / `<docuseal-builder>` SDK custom elements, the `@docuseal/*` npm packages, and the `github.com/docusealco/{fields-detection,pdfium-binaries,turbo}` binary URLs. Pulls `PRODUCT_NAME` / `AATL_CERT_NAME` from [lib/wabosign.rb](lib/wabosign.rb) so a future brand change only touches one file.
- [bin/rebrand-check](bin/rebrand-check) — CI gate that fails on accidental DocuSeal survivors. Wired in as the new `Rebrand check` job in [.github/workflows/ci.yml](.github/workflows/ci.yml).
- "Sync workflow" section in [REBRANDING.md](REBRANDING.md) documenting the per-sync workflow.
- Upstream resend-emails feature: `app/controllers/submissions_resend_email_controller.rb` plus a new `resources :resend_email` route. English UI strings fall back to the key name until 14-language i18n is added.

### Changed
- Synced with upstream DocuSeal 3.0.0 (15 upstream commits, merge-base `528a1216`):
  - PDF image optimization, signing-form completion-button refactor.
  - Vue area-box clamping; percent format support; validation message improvements.
  - Defensive blank-check for `X-Wabosign-Signature` — caller-supplied signature headers are no longer overridden ([upstream a7891f89](https://github.com/docusealco/docuseal/commit/a7891f89)).
  - Belt-and-suspenders `authorize!(:update, @submitter)` on `submitters_send_email#create` ([upstream e52830c9](https://github.com/docusealco/docuseal/commit/e52830c9)).
- `git rerere` enabled (`rerere.enabled = true`, `rerere.autoupdate = true`) so semantic conflict resolutions are cached across syncs.
- [.gitattributes](.gitattributes) marks `Gemfile.lock` and `yarn.lock` as `-merge` (regenerate post-merge rather than diff).
- Webhook `User-Agent` continues to be `'WaboSign Webhook'` (upstream renamed theirs to `'WaboSign.com Webhook'`; the fork's name is preserved).
- `lib/docuseal.rb` upstream → `lib/wabosign.rb` rename is now performed by the script rather than by hand.

### Fixed
- [public/service-worker.js](public/service-worker.js) — the install/activate listeners now log `'WaboSign App installed/activated'` (latent rebrand survivor from 1.0.0).
- [.dockerignore](.dockerignore) and [.gitignore](.gitignore) — runtime data-dir entries now point at `/wabosign` instead of the stale `/docuseal`.

### Notes
- AGPL §7(b) "based on DocuSeal" attribution intact in [_powered_by](app/views/shared/_powered_by.html.erb), [_email_attribution](app/views/shared/_email_attribution.html.erb), [completed.vue](app/javascript/submission_form/completed.vue), [NOTICE](NOTICE), [LICENSE_ADDITIONAL_TERMS](LICENSE_ADDITIONAL_TERMS), and [README.md](README.md).
- Released image: `ghcr.io/wabolabs/wabosign:1.2.0` (also tagged `:latest`).
- Sync reference tag: `wabosign-synced-with-3.0.0` marks the merged tree as a known-good base for the next upstream pull.

[1.2.0]: https://github.com/wabolabs/wabosign/releases/tag/1.2.0

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

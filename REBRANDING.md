# Rebranding Summary: DocuSeal → WaboSign

This document records the changes made when forking DocuSeal into WaboSign. It exists for transparency, to fulfil AGPLv3 §7(b) disclosure expectations, and as a reference for future maintainers tracing why a particular file was touched.

Scope: ~183 files modified. Decisions were made in a planning conversation before changes were applied; the final plan lives at [.claude/plans/this-agpl-project-has-toasty-cake.md](.claude/plans/this-agpl-project-has-toasty-cake.md) on the developer's machine.

## Brand & identity

- Ruby module `Docuseal` → `Wabosign` ([lib/wabosign.rb](lib/wabosign.rb)); Rails app module `DocuSeal` → `WaboSign` ([config/application.rb](config/application.rb))
- All hardcoded `DocuSeal` strings in views, mailers, controllers, libs, JS/Vue replaced with `Wabosign.product_name` (or equivalents)
- [config/locales/i18n.yml](config/locales/i18n.yml): 168 user-facing strings sweep-replaced across all 14 languages
- New favicons, apple-touch-icons, and logo SVG (a neutral "W" mark) generated via Inkscape
- daisyUI theme renamed `docuseal` → `wabosign` in [tailwind.config.js](tailwind.config.js)
- Discord, Twitter, ChatGPT URLs removed entirely
- New brand constants in [lib/wabosign.rb](lib/wabosign.rb):
  - `PRODUCT_URL = 'https://sign.wabo.cc'`
  - `GITHUB_URL = 'https://github.com/wabolabs/wabosign'`
  - `SUPPORT_EMAIL = 'wabosign@wabo.cc'`

## AGPL §7(b) attribution

- `Wabosign::UPSTREAM_NAME = 'DocuSeal'` and `Wabosign::UPSTREAM_URL` constants added
- [app/views/shared/_powered_by.html.erb](app/views/shared/_powered_by.html.erb) and [app/views/shared/_email_attribution.html.erb](app/views/shared/_email_attribution.html.erb) now render a "based on DocuSeal (AGPLv3)" credit alongside the WaboSign brand
- [app/javascript/submission_form/completed.vue](app/javascript/submission_form/completed.vue) carries the same credit on the post-signing completion screen
- New `based_on` i18n key added to all 14 language sections
- [README.md](README.md) and [LICENSE_ADDITIONAL_TERMS](LICENSE_ADDITIONAL_TERMS) rewritten
- New [NOTICE](NOTICE) file added crediting DocuSeal LLC and listing modifications

## Freemium gates removed

- Pro-upsell placeholders rewritten or neutralised for SMS, SSO, and logo personalisation (these features are not bundled in the upstream OSS edition; the placeholders now explain that rather than advertising a paid tier)
- Bulk-send and reminder placeholders rewritten as neutral info; reminder-duration multitenant gate stripped in [app/views/notifications_settings/_reminder_form.html.erb](app/views/notifications_settings/_reminder_form.html.erb)
- "Plans" / "Console" / "Upgrade" links removed from [app/views/shared/_settings_nav.html.erb](app/views/shared/_settings_nav.html.erb) and [app/views/shared/_navbar_buttons.html.erb](app/views/shared/_navbar_buttons.html.erb)
- Multitenant gates on Decline / Delegate / Personalization toggles, reply-to, BCC, and send-on-completion stripped in [app/views/accounts/show.html.erb](app/views/accounts/show.html.erb) and [app/views/personalization_settings/_documents_copy_email_form.html.erb](app/views/personalization_settings/_documents_copy_email_form.html.erb)
- Routes: `timestamp_server` and `detect_fields` no longer gated by `multitenant?` in [config/routes.rb](config/routes.rb)
- Pricing/upsell links removed from [app/javascript/template_builder/conditions_modal.vue](app/javascript/template_builder/conditions_modal.vue), [formula_modal.vue](app/javascript/template_builder/formula_modal.vue), [fields.vue](app/javascript/template_builder/fields.vue), and [payment_settings.vue](app/javascript/template_builder/payment_settings.vue)
- `ENTERPRISE_PATHS` 404-with-upsell-message removed from [app/controllers/errors_controller.rb](app/controllers/errors_controller.rb)

## Migrations & infrastructure

- New migration [db/migrate/20260515183000_rename_docuseal_aatl_cert.rb](db/migrate/20260515183000_rename_docuseal_aatl_cert.rb) updates the AATL cert `name` field inside encrypted JSON value blobs from `docuseal_aatl` → `wabosign_aatl`
- `AATL_CERT_NAME` constant updated accordingly
- [Dockerfile](Dockerfile): user, group, home directory, and workdir renamed `docuseal` → `wabosign`
- [docker-compose.yml](docker-compose.yml): image, volume, and Postgres DB name → `ghcr.io/wabolabs/wabosign` / `wabosign`
- [config/database.yml](config/database.yml): dev/test DB names → `wabosign_dev` / `wabosign_test`
- [.github/workflows/ci.yml](.github/workflows/ci.yml) and [.github/workflows/docker.yml](.github/workflows/docker.yml): image name and test DB renamed
- `docuseal.env` config file path → `wabosign.env` in [config/dotenv.rb](config/dotenv.rb)
- DOM IDs and localStorage keys renamed `docuseal_*` → `wabosign_*` across [app/javascript/template_builder/](app/javascript/template_builder/)
- Webhook `USER_AGENT` and corresponding spec assertions updated

## Intentionally preserved upstream references

Per AGPL §7(b) and downstream SDK compatibility, the following references remain. All are documented in [NOTICE](NOTICE).

- `<docuseal-form>` and `<docuseal-builder>` custom HTML elements, plus the `@docuseal/{react,vue,angular}` npm packages referenced in [app/views/templates/_embedding.html.erb](app/views/templates/_embedding.html.erb) and registered in [app/controllers/embed_scripts_controller.rb](app/controllers/embed_scripts_controller.rb). Renaming these would break embeddings published against the upstream SDKs.
- Upstream binary URLs in [Dockerfile](Dockerfile) and CI: `github.com/docusealco/fields-detection` (ONNX model) and `github.com/docusealco/pdfium-binaries`.
- DocuSeal LLC copyright notice on the JavaScript calculator port at [app/javascript/submission_form/calculator.js](app/javascript/submission_form/calculator.js).

## Verification status

- Ruby syntax-checked all edited `.rb` files (lib, controllers, mailers, migration)
- ERB-compiled the edited view partials
- YAML-parsed `config/locales/i18n.yml` and `docker-compose.yml`
- JSON-parsed `docs/openapi.json`
- Webhook spec assertions updated to match new `WaboSign Webhook` user-agent

Full Rails boot requires Ruby 4.0.1, which was not available on the dev machine that performed the rebrand. Recommend running `docker compose up --build` to verify boot end-to-end before publishing.

## Sync workflow

Upstream lives at `docusealco/docuseal`. Each upstream release is brought in by re-running a deterministic rebrand sweep on the upstream tree, then merging into `master`. The strategy details are in [.claude/plans/come-up-with-a-foamy-flask.md](.claude/plans/come-up-with-a-foamy-flask.md); the short version follows.

### Tooling

- [bin/rebrand-sync](bin/rebrand-sync) — Ruby script that performs the DocuSeal → WaboSign rename sweep across the working tree. Idempotent. Honors a deny-list (see §"Intentionally preserved upstream references" above) and sentinel-protects AGPL §7(b) attribution phrases, SDK custom-element names (`docuseal-form`, `docuseal-builder`), `@docuseal/*` npm packages, and the `github.com/docusealco/{fields-detection,pdfium-binaries,turbo}` binary URLs.
- [bin/rebrand-check](bin/rebrand-check) — fails (exit 1) if any unintended DocuSeal reference survives. Wired into [.github/workflows/ci.yml](.github/workflows/ci.yml) as the `Rebrand check` job.
- `git config rerere.enabled true && git config rerere.autoupdate true` — once-per-checkout setup; remembers semantic conflict resolutions so the same call is not re-made each release.
- [.gitattributes](.gitattributes) marks `Gemfile.lock` and `yarn.lock` as `-merge` (regenerate after merge rather than diffing).

### Per-sync steps

```sh
git fetch upstream --tags
git checkout -b sync/upstream-<tag> <tag>      # e.g. 3.0.0
bin/rebrand-sync
git add -A && git commit -m "Apply WaboSign rebrand sweep to upstream <tag>"

git checkout master
git merge --no-ff sync/upstream-<tag>
# Resolve conflicts. Rerere caches recurring resolutions.

# Restore WaboSign brand assets that the merge may have overwritten:
git checkout ORIG_HEAD -- public/favicon.svg public/favicon.ico \
  public/favicon-16x16.png public/favicon-32x32.png \
  public/favicon-96x96.png public/logo.svg

bin/rebrand-sync                                # catch upstream-only new files
bin/rebrand-check                               # CI gate

bundle install
yarn install

# Verify (see "Verification" in the plan), then:
git tag wabosign-synced-with-<tag>
```

Or use the automated script:
```sh
bin/sync-upstream <tag>
```

### Adding new preserved tokens

When upstream introduces a new SDK identifier, binary URL, or attribution surface that must survive the sweep, edit `PRESERVE` in [bin/rebrand-sync](bin/rebrand-sync) and `ALLOW_PATTERNS` in [bin/rebrand-check](bin/rebrand-check) together. The two must stay in sync — `rebrand-sync` decides what the sweep ignores, `rebrand-check` decides what CI tolerates.

## Post-Merge Verification Checklist

Run through these checks after every upstream merge. The earlier failures are caught by `bin/rebrand-check`; the later ones require manual inspection or `rspec`.

### Automatic (`bin/rebrand-check`)
- Rebrand check passes (no unintended DocuSeal references)
- RSpec suite passes (360+ examples, 0 failures)

### Footer / Attribution
- [ ] `app/views/shared/_powered_by.html.erb` links both WaboSign *and* DocuSeal (upstream AGPL credit)
- [ ] `app/views/shared/_email_attribution.html.erb` uses WaboSign product name, not DocuSeal
- [ ] `app/javascript/submission_form/completed.vue` still has the hardcoded DocuSeal upstream credit

### Logo / Branding
- [ ] `app/views/shared/_logo.html.erb` shows the WaboSign "W" mark (not the DocuSeal abstract shape)
- [ ] `public/favicon.svg`, `public/logo.svg` show the WaboSign "W" mark
- [ ] `app/views/shared/_account_logo.html.erb` renders attached logo or falls back to the W mark

### Console / Plans / Pro / Upgrade
- [ ] `app/controllers/console_redirect_controller.rb` does not exist
- [ ] `config/routes.rb` has no `console_redirect`, `upgrade`, or `manage` routes
- [ ] `app/controllers/sessions_controller.rb` has no `console_redirect_index_path` call
- [ ] `lib/wabosign.rb` has no `CONSOLE_URL`, `CLOUD_URL`, or `CDN_URL` constants
- [ ] `app/views/shared/_settings_nav.html.erb` has no "Plans" link or "Pro" badge
- [ ] `app/views/shared/_navbar.html.erb` has no "Console" link in dropdown
- [ ] `app/views/shared/_navbar_buttons.html.erb` has no "Upgrade" button
- [ ] No view file contains `unlock_with_docuseal_pro`, `activate_with_docuseal_pro`, or `console_redirect_index_path`

### Feature Gates (all freely available)
- [ ] `app/views/sms_settings/index.html.erb` shows provider form (BulkVS/Twilio/VoIP.ms/SignalWire) — not a placeholder
- [ ] `app/views/personalization_settings/_logo_placeholder.html.erb` shows upload form — not a Pro upsell
- [ ] `app/views/notifications_settings/_reminder_placeholder.html.erb` is empty (reminder form renders freely)
- [ ] `app/views/submissions/_bulk_send_placeholder.html.erb` is empty (bulk send freely available)
- [ ] `app/views/submissions/_send_sms_button.html.erb` is a functional button (not Pro-gated tooltip)
- [ ] `app/views/users/_role_select.html.erb` has no disabled options or Pro upsell link
- [ ] `app/views/accounts/show.html.erb` has no console-redirect Pro gates on Decline/Delegate toggles

### Google SSO
- [ ] `app/views/sso_settings/index.html.erb` shows the Google SSO config form (client_id, client_secret, allowed_domains)
- [ ] `app/views/devise/sessions/_omniauthable.html.erb` has the "Sign in with Google" button
- [ ] `app/views/sso_settings/_placeholder.html.erb` does not exist (was replaced by the real form)
- [ ] OmniAuth routes for `auth/google_oauth2` are present in `config/routes.rb`

### E-Signature Settings
- [ ] `app/views/esign_settings/_default_signature_row.html.erb` does not exist
- [ ] `config/locales/i18n.yml` has no `wabosign_trusted_signature` or `sign_documents_with_trusted_certificate_*` keys

### Social / Extras
- [ ] `app/views/shared/_github.html.erb` does not exist (no hardcoded star count)
- [ ] `app/views/shared/_navbar.html.erb` does not render `shared/github` or `shared/github_button`
- [ ] `app/views/shared/_settings_nav.html.erb` has no Discord or AI Assistant links in support channels
- [ ] `config/locales/i18n.yml` has no `discord_community` or `ai_assistant` keys

### SMS (independently developed)
- [ ] `app/views/sms_settings/index.html.erb` is the full provider form (not placeholder)
- [ ] `lib/sms.rb` exists with all 4 providers (BulkVS, Twilio, VoIP.ms, SignalWire)
- [ ] `lib/sms/providers/` directory exists with all 4 provider implementations
- [ ] `app/controllers/sms_settings_controller.rb` handles `test_message` action
- [ ] `app/models/encrypted_config.rb` has `SMS_CONFIGS_KEY = 'sms_configs'` constant
- [ ] `config/routes.rb` has the SMS routes with `test_message` collection route

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
- [app/views/shared/_powered_by.html.erb](app/views/shared/_powered_by.html.erb) renders "WaboSign, a fork of DocuSeal" in the footer; [app/views/shared/_email_attribution.html.erb](app/views/shared/_email_attribution.html.erb) states the fork relationship in the email footer
- [app/javascript/submission_form/completed.vue](app/javascript/submission_form/completed.vue) carries the same credit on the post-signing completion screen
- i18n keys `fork_of` and `product_name_is_a_fork_of_upstream_html` carry the credit text (English; other locales fall back via `config.i18n.fallbacks`). `bin/fork-check` asserts these surfaces keep the credit
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
- [bin/rebrand-check](bin/rebrand-check) — fails (exit 1) if any unintended DocuSeal *text* reference survives. Wired into CI as the `Rebrand check` job.
- [bin/fork-check](bin/fork-check) — fails (exit 1) if any **fork invariant** is broken: re-introduced Pro gate, deleted fork code, overwritten brand asset, lost attribution, dangling partial render, or PRESERVE↔ALLOW_PATTERNS drift. Driven by the declarative manifest [config/fork_invariants.yml](config/fork_invariants.yml). Wired into CI as the `Fork invariants` job. This is the executable form of the old manual post-merge checklist.
- [config/fork_invariants.yml](config/fork_invariants.yml) — the data behind `bin/fork-check`. Extend **this file** (not the script) when upstream adds a new gate; every entry carries a `why:`.
- [config/brand_assets.sha256](config/brand_assets.sha256) — checksum baseline of the WaboSign "W" mark assets. The single source of truth for "what is a brand asset": `bin/fork-check` verifies it, `bin/sync-upstream` restores from it, and [.gitattributes](.gitattributes) `-merge` should mirror it.
- `git config rerere.enabled true && git config rerere.autoupdate true` — once-per-checkout setup; remembers semantic conflict resolutions so the same call is not re-made each release.
- [.gitattributes](.gitattributes) marks the brand binary assets as `-merge` (always keep ours; never blend an upstream version during a merge).

### Runbook (for a human or AI agent)

The whole sync — fetch, branch from the tag, sweep, merge, restore brand assets,
re-sweep, and run both gates — is automated:

```sh
bin/sync-upstream <tag>          # e.g. bin/sync-upstream 3.0.2
# RUN_TESTS=1 bin/sync-upstream <tag>   # also run rspec before declaring done
```

When it stops, decide based on which gate failed:

1. **Merge conflict** — resolve it. `rerere` caches recurring resolutions.
2. **`rebrand-check` failed** — un-rebranded DocuSeal text survived. If a token
   must be preserved, add it to `PRESERVE` (bin/rebrand-sync) **and**
   `ALLOW_PATTERNS` (bin/rebrand-check) together (see below).
3. **`fork-check` failed** — a fork invariant broke. Each violation names the
   file + the `why:` from the manifest:
   - re-introduced gate → remove it;
   - brand asset overwritten → `git checkout ORIG_HEAD -- <path>`;
   - genuinely new upstream feature/gate → add a scoped invariant to
     [config/fork_invariants.yml](config/fork_invariants.yml).
4. Re-run `bin/fork-check` (and `bin/rebrand-check`) until both print `ok`.
5. `bundle install && yarn install`, then **tag + push only when both gates and
   `rspec` are green**: `git tag wabosign-synced-with-<tag> && git push origin master --tags`.

The equivalent manual steps (if you are not using the script) are: branch from
the tag, `bin/rebrand-sync`, commit, `git merge --no-ff` into master, restore
the brand assets listed in `config/brand_assets.sha256` from `ORIG_HEAD`,
`bin/rebrand-sync` again, then `bin/rebrand-check && bin/fork-check`.

### Adding new preserved tokens

When upstream introduces a new SDK identifier, binary URL, or attribution surface that must survive the sweep, edit `PRESERVE` in [bin/rebrand-sync](bin/rebrand-sync) and `ALLOW_PATTERNS` in [bin/rebrand-check](bin/rebrand-check) together. The two must stay in sync — `rebrand-sync` decides what the sweep ignores, `rebrand-check` decides what CI tolerates. **This pairing is now CI-enforced:** `bin/fork-check` fails if a `PRESERVE` token containing "docuseal" has no matching `ALLOW_PATTERN`.

### Adding a new fork invariant

When upstream re-introduces a gate, deletes fork code, or adds a brand asset, encode the rule in [config/fork_invariants.yml](config/fork_invariants.yml) — not in `bin/fork-check`. Use a path-scoped `must_not_contain` for re-added gates (never ban a token tree-wide unless it is genuinely unique to the gate — `Wabosign.multitenant?` is legitimate in ~19 views), `must_exist`/`must_not_exist` for files, and add new brand files to `config/brand_assets.sha256` (and the `.gitattributes` `-merge` list). Always include a `why:` — it is the institutional memory the next sync will need.

## Post-Merge Verification

Most of what used to be a 21-item manual checklist is now executed by CI. After a
sync, the gates below must be green; only a short residue needs a human eye.

### Automated (CI — must pass)

- **`bin/rebrand-check`** — no unintended DocuSeal *text* survived the sweep.
- **`bin/fork-check`** — every fork invariant holds. The assertions (and the
  rationale for each) live in [config/fork_invariants.yml](config/fork_invariants.yml):
  attribution surfaces present; renamed identifiers + SDK tokens present; brand
  assets match [config/brand_assets.sha256](config/brand_assets.sha256); no
  re-introduced Pro gates (`ENTERPRISE_PATHS`, `console_redirect_index_path`, the
  reminder `multitenant?` gate, …); placeholders / `console_redirect_controller` /
  `lib/docuseal.rb` absent; SMS stack + `lib/ability.rb` present; no dead paywall
  i18n keys; no dangling partial renders; PRESERVE↔ALLOW_PATTERNS in sync.
- **`rspec`** — suite passes (also catches Zeitwerk module conflicts at boot).

When upstream changes something the manifest does not yet know about, **extend
the manifest** (see "Adding a new fork invariant" above) rather than re-checking
by hand. That way the next sync inherits the protection.

### Human-judgment residue (not automatable)

- [ ] The rendered WaboSign "W" mark *looks* right (checksum proves the file is
      unchanged; a human confirms it is the intended asset, e.g. after a
      deliberate brand update + baseline regen).
- [ ] Upstream did not introduce a genuinely **new** feature or freemium gate
      that needs a fork-policy decision (free it, and add an invariant) — skim
      the merge diff for new `multitenant?` / Pro / Console / placeholder code.
- [ ] New upstream **UI strings** read correctly after the sweep (the rename is
      mechanical; some phrasings need a human's rebranding nuance).

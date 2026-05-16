# SMS

WaboSign sends signing-invitation SMS via configurable providers. v1 ships [BulkVS](https://www.bulkvs.com) only; the architecture leaves room for additional providers behind the same `Sms.send_message` interface.

## What you get

- A self-serve `/settings/sms` page where admins paste their BulkVS Basic Auth header and From number.
- A **Send test** card on the same page for verifying the config with a one-off SMS to any phone number.
- Per-submitter **Send SMS** button on the submission detail page (`/submissions/:id`).
- "Send SMS on save" toggle in the submitter edit dialog — already wired into `SubmittersController#maybe_resend_email_sms`, now actually fires the job.
- Per-account body template override at `/settings/personalization` → "Signature request SMS". Supports `{account.name}`, `{submitter.link}`, `{submitter.name}`, `{submitter.first_name}`, `{submission.name}`, `{sender.name}` and the rest of the existing `ReplaceEmailVariables` vocabulary.
- Sidekiq job (`SendSubmitterInvitationSmsJob`, retry: 5) so a failed BulkVS request retries on its own.

## Configuring BulkVS

In the [BulkVS portal](https://portal.bulkvs.com/), open the **API** tab and copy the pre-encoded **Basic Auth Header** value (it's a single base64 string like `dXNlcjp0b2tlbg==`; do NOT include the literal `Basic ` prefix).

In WaboSign:
1. Sign in as an admin → **Settings** → **SMS**.
2. Toggle **Enable SMS** on.
3. Paste the BulkVS Basic Auth token.
4. Set **From Number** in E.164 (digits-only with country code, e.g. `15551234567`).
5. *(Optional)* set the **Delivery Status Webhook** to a URL BulkVS will POST status events to. WaboSign does not yet process these inbound events — the field is stored on the config and forwarded to BulkVS so the receipts flow somewhere of your choosing.
6. Save.
7. Use the **Send test** card to verify with a number you own. Errors from BulkVS (bad credentials, malformed number, etc.) come back as `Sms::ProviderError` and are shown inline.

## How sending happens

```
User clicks "Send SMS" on /submissions/:id
   → SubmittersSendSmsController#create
      → SendSubmitterInvitationSmsJob.perform_async    (Sidekiq, retry: 5)
         → Sms.send_message(account:, to:, text:)
            → Sms::Providers::Bulkvs#deliver
               → HTTPS POST to https://portal.bulkvs.com/api/v1.0/messageSend
            → returns BulkVS JSON
         → SubmissionEvent.create!(event_type: 'send_sms')
         → Submitter.sent_at ||= Time.current
```

The "send SMS on save" toggle in the submitter edit dialog takes the same code path via [SubmittersController#maybe_resend_email_sms](app/controllers/submitters_controller.rb).

Body substitution runs through the existing [`ReplaceEmailVariables`](lib/replace_email_variables.rb) module. The account-level template at `submitter_invitation_sms` overrides the i18n default `submitter_invitation_sms_body_sign` when set.

## Adding another provider

Two-step extension:

1. **Implement the provider class** at `lib/sms/providers/<name>.rb`. The interface is `#new(config)` + `#deliver(to:, text:, webhook: nil)`. Raise `Sms::ProviderError` on non-2xx responses. See [`lib/sms/providers/bulkvs.rb`](lib/sms/providers/bulkvs.rb) for shape.

2. **Register the provider** in three places:
   - `Sms::SUPPORTED_PROVIDERS` in [`lib/sms.rb`](lib/sms.rb).
   - The `case provider` switch in `Sms.send_message`.
   - The `<select>` of provider options in [`app/views/sms_settings/index.html.erb`](app/views/sms_settings/index.html.erb).

Per-provider config fields (e.g. Twilio's account SID + auth token) can ride on the same `sms_configs` EncryptedConfig hash — pick names that don't collide with BulkVS's keys, and have the view render the right field for the selected provider. The Sidekiq job and per-submitter controller are provider-agnostic and don't need to change.

## Code map

| File | Role |
|---|---|
| [lib/sms.rb](lib/sms.rb) | Top-level `Sms` module: `enabled_for?(account)`, `configuration_for(account)`, `send_message`, `normalize_phone`. Error types: `Sms::Error`, `Sms::NotConfiguredError`, `Sms::ProviderError`, `Sms::InvalidNumberError`. |
| [lib/sms/providers/bulkvs.rb](lib/sms/providers/bulkvs.rb) | BulkVS HTTPS client. Constructs the Basic Auth + JSON body, raises `Sms::ProviderError` with the upstream error message on non-2xx. |
| [app/jobs/send_submitter_invitation_sms_job.rb](app/jobs/send_submitter_invitation_sms_job.rb) | Sidekiq job. Skips if submitter has no phone, is completed, archived, or the account has no SMS config. |
| [app/controllers/sms_settings_controller.rb](app/controllers/sms_settings_controller.rb) | `index` / `create` / `test_message`. Preserves the saved Basic Auth token when the field is left blank on edit. |
| [app/controllers/submitters_send_sms_controller.rb](app/controllers/submitters_send_sms_controller.rb) | `create` action behind the per-submitter Send SMS button. Mirrors `SubmittersSendEmailController`. |
| [app/views/sms_settings/index.html.erb](app/views/sms_settings/index.html.erb) | Settings form + test-send card. |
| [app/views/submissions/_send_sms_button.html.erb](app/views/submissions/_send_sms_button.html.erb) | Per-submitter Send SMS button. Disabled with a tooltip when the provider is unconfigured or the submitter has no phone. |
| [app/views/submissions/_send_sms.html.erb](app/views/submissions/_send_sms.html.erb) | "Send SMS on save" toggle rendered inside the submitter edit dialog. |
| [app/views/personalization_settings/_signature_request_sms_form.html.erb](app/views/personalization_settings/_signature_request_sms_form.html.erb) | Per-account SMS body override form. |
| [app/models/encrypted_config.rb](app/models/encrypted_config.rb) | `SMS_CONFIGS_KEY = 'sms_configs'` added to `CONFIG_KEYS`. |
| [app/models/account_config.rb](app/models/account_config.rb) | `SUBMITTER_INVITATION_SMS_KEY = 'submitter_invitation_sms'`. |
| [config/routes.rb](config/routes.rb) | `resources :sms` with `index`, `create`, and `post :test_message` on the collection; submitters nested `resources :send_sms`. |

## BulkVS API reference

- Endpoint: `POST https://portal.bulkvs.com/api/v1.0/messageSend`
- Auth: `Authorization: Basic <pre-encoded token from the BulkVS portal>`
- Content-Type: `application/json`
- Body:
  ```json
  {
    "From": "15551234567",
    "To": ["15555550100"],
    "Message": "Hello from WaboSign",
    "delivery_status_webhook_url": "https://your-app.example/webhooks/sms"
  }
  ```
- Response: 2xx JSON on success; non-2xx with `Description` / `Status` / `error` keys on failure.
- Docs: <https://portal.bulkvs.com/api/v1.0/documentation> (login required for the Swagger UI).

## Verified during commit `1872a099`

- `/settings/sms` returns 200; all six form fields render.
- `/settings/personalization` renders the SMS body editor with the full variable list.
- With a bogus saved token, `Sms.send_message` opens an HTTPS connection to BulkVS, receives a **real 401**, and surfaces it as `Sms::ProviderError("BulkVS rejected request (HTTP 401): …")`. Proves the transport + auth header + JSON body shape are correct end-to-end; only the test token is wrong.
- Route helpers resolve: `settings_sms_path` (no `_index_` because "sms" is uncountable in Rails inflection), `test_message_settings_sms_path`, `submitter_send_sms_path`.

## Out of scope for v1

- **No inbound delivery webhook handler.** The URL is stored and forwarded to BulkVS, but WaboSign does not yet consume the resulting POSTs. Add a controller at e.g. `app/controllers/webhooks/sms_delivery_controller.rb` if you want delivery confirmations in the audit trail or `SubmissionEvent` log.
- **No other SMS providers.** `Sms::SUPPORTED_PROVIDERS = %w[bulkvs]` is the gate; see "Adding another provider" above.
- **Phone validation is minimal** — `Sms.normalize_phone` strips non-digits and rejects strings shorter than 8 digits. Malformed E.164 is caught by BulkVS and surfaces as `Sms::ProviderError` with the upstream message.
- **No rate-limiting / per-account quota.** Relies on BulkVS's own controls.

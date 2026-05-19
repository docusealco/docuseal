# SMS

WaboSign sends signing-invitation SMS via configurable providers. Supported providers: [BulkVS](https://www.bulkvs.com), [Twilio](https://www.twilio.com), [VoIP.ms](https://voip.ms), and [SignalWire](https://signalwire.com). All providers share the same `Sms.send_message` interface; per-account credentials live in the encrypted `sms_configs` blob and are namespaced by provider.

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
2. Toggle **Enable SMS** on; choose **BulkVS** from the provider dropdown.
3. Paste the BulkVS Basic Auth token.
4. Set **From Number** in E.164 (digits-only with country code, e.g. `15551234567`).
5. *(Optional)* set the **Delivery Status Webhook** to a URL BulkVS will POST status events to. WaboSign does not yet process these inbound events — the field is stored on the config and forwarded to BulkVS so the receipts flow somewhere of your choosing.
6. Save.
7. Use the **Send test** card to verify with a number you own. Errors from BulkVS (bad credentials, malformed number, etc.) come back as `Sms::ProviderError` and are shown inline.

## Configuring Twilio

In the [Twilio Console](https://console.twilio.com/), open **Account Info** and copy the **Account SID** and **Auth Token** (click *show* to reveal). Buy an SMS-capable number under **Phone Numbers → Manage**. For US long-code delivery you must complete **A2P 10DLC** brand + campaign registration before messages will deliver.

In WaboSign:
1. **Settings** → **SMS**; pick **Twilio** from the provider dropdown.
2. Paste the Account SID, Auth Token, and Twilio number (full E.164 with leading `+`, e.g. `+15551234567`).
3. Save, then use **Send test**. Twilio returns a message SID on success; a non-null `error_code` is reported as `Sms::ProviderError`.

## Configuring VoIP.ms

Set up at the [API portal](https://voip.ms/m/api.php):
1. Set a dedicated **API password** (distinct from your portal login password).
2. Toggle **Enable API** on.
3. Add the WaboSign server's egress IP to the **API IP whitelist**. Without this every call returns `ip_not_authorized` or `invalid_credentials`.
4. Under **Manage DIDs**, enable the **SMS** feature on the DID you plan to send from.

In WaboSign:
1. **Settings** → **SMS**; pick **VoIP.ms** from the provider dropdown.
2. Fill in your portal-login email (API Username), the API password from step 1 above, and the SMS-enabled DID (digits only, no `+`).
3. Save, then **Send test**.

Caveats:
- The API hard-caps each call at **160 bytes**, with no segmentation. WaboSign rejects longer bodies up front (`Sms::ProviderError`) rather than truncating.
- VoIP.ms returns HTTP 200 on every error, with `status` indicating the failure code; common codes (`invalid_credentials`, `limit_reached`, `sms_toolong`, `ip_not_authorized`) surface verbatim in the error message.
- Default account quota is 100 SMS/day — contact VoIP.ms support to raise it.

## Configuring SignalWire

Open your [SignalWire dashboard](https://signalwire.com/), click the **API** tab in the sidebar, and copy:
- **Your Space URL** (e.g. `acme.signalwire.com`).
- **Your Project ID** (UUID).
- **Your API Token** (`PT…`). Make sure the token has the **Messaging** scope enabled.

Buy an SMS-capable number under **Phone Numbers**. For US long-code delivery you must attach the number to an approved **10DLC / TCR** campaign.

In WaboSign:
1. **Settings** → **SMS**; pick **SignalWire** from the provider dropdown.
2. Enter the Space URL (omit `https://`), Project ID, API Token, and From Number (E.164 with leading `+`).
3. Save, then **Send test**.

A 401 with no obvious credential mistake usually means the API Token lacks the Messaging scope — the upstream message is surfaced verbatim, so check the flash text.

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

Three-step extension:

1. **Implement the provider class** at `lib/sms/providers/<name>.rb`. The interface is `self.configured?(config)` + `#new(config)` + `#deliver(to:, text:, webhook: nil)`. Raise `Sms::ProviderError` on non-2xx responses (or on logical failures hidden behind a 200, as VoIP.ms does). See [`lib/sms/providers/bulkvs.rb`](lib/sms/providers/bulkvs.rb), [`twilio.rb`](lib/sms/providers/twilio.rb), [`voipms.rb`](lib/sms/providers/voipms.rb), and [`signalwire.rb`](lib/sms/providers/signalwire.rb) for shape.

2. **Register the provider** in three places:
   - Append to `Sms::SUPPORTED_PROVIDERS` in [`lib/sms.rb`](lib/sms.rb).
   - Add a branch to `Sms.provider_class` in the same file.
   - Add a `data-provider-block="..."` section to [`app/views/sms_settings/index.html.erb`](app/views/sms_settings/index.html.erb) with the credential fields, and add the human-readable label to the `provider_labels` hash at the top of the template.

3. **If the new provider has a secret field** that should be preserved on blank-edits (the way BulkVS's Basic Auth token is), add its config key to `SmsSettingsController::SECRET_KEYS`.

Per-provider config fields all ride on the same `sms_configs` EncryptedConfig hash; prefix new keys with the provider name (e.g. `twilio_auth_token`) to avoid collisions. The Sidekiq job and per-submitter controller are provider-agnostic and don't need to change.

## Code map

| File | Role |
|---|---|
| [lib/sms.rb](lib/sms.rb) | Top-level `Sms` module: `enabled_for?(account)`, `configuration_for(account)`, `send_message`, `normalize_phone`, `provider_class`. Error types: `Sms::Error`, `Sms::NotConfiguredError`, `Sms::ProviderError`, `Sms::InvalidNumberError`. |
| [lib/sms/providers/bulkvs.rb](lib/sms/providers/bulkvs.rb) | BulkVS HTTPS client. Constructs Basic Auth + JSON body, raises `Sms::ProviderError` with the upstream error message on non-2xx. |
| [lib/sms/providers/twilio.rb](lib/sms/providers/twilio.rb) | Twilio Messages API client (form-encoded body, Basic Auth with SID:Token, 201 on success). |
| [lib/sms/providers/voipms.rb](lib/sms/providers/voipms.rb) | VoIP.ms REST/JSON `sendSMS` client (GET with query-string auth, treats `status != "success"` as failure even on HTTP 200, enforces 160-byte cap up front). |
| [lib/sms/providers/signalwire.rb](lib/sms/providers/signalwire.rb) | SignalWire Compatibility API client (Twilio-shaped form body, per-account Space URL host, requires Messaging-scoped API Token). |
| [app/jobs/send_submitter_invitation_sms_job.rb](app/jobs/send_submitter_invitation_sms_job.rb) | Sidekiq job. Skips if submitter has no phone, is completed, archived, or the account has no SMS config. |
| [app/controllers/sms_settings_controller.rb](app/controllers/sms_settings_controller.rb) | `index` / `create` / `test_message`. `SECRET_KEYS` lists the password-field config keys that should be preserved on blank-edits. |
| [app/controllers/submitters_send_sms_controller.rb](app/controllers/submitters_send_sms_controller.rb) | `create` action behind the per-submitter Send SMS button. Mirrors `SubmittersSendEmailController`. |
| [app/views/sms_settings/index.html.erb](app/views/sms_settings/index.html.erb) | Settings form + test-send card. |
| [app/views/submissions/_send_sms_button.html.erb](app/views/submissions/_send_sms_button.html.erb) | Per-submitter Send SMS button. Disabled with a tooltip when the provider is unconfigured or the submitter has no phone. |
| [app/views/submissions/_send_sms.html.erb](app/views/submissions/_send_sms.html.erb) | "Send SMS on save" toggle rendered inside the submitter edit dialog. |
| [app/views/personalization_settings/_signature_request_sms_form.html.erb](app/views/personalization_settings/_signature_request_sms_form.html.erb) | Per-account SMS body override form. |
| [app/models/encrypted_config.rb](app/models/encrypted_config.rb) | `SMS_CONFIGS_KEY = 'sms_configs'` added to `CONFIG_KEYS`. |
| [app/models/account_config.rb](app/models/account_config.rb) | `SUBMITTER_INVITATION_SMS_KEY = 'submitter_invitation_sms'`. |
| [config/routes.rb](config/routes.rb) | `resources :sms` with `index`, `create`, and `post :test_message` on the collection; submitters nested `resources :send_sms`. |

## Provider wire-format quick reference

| Provider | Endpoint | Body encoding | Phone format | Success signal |
|---|---|---|---|---|
| BulkVS | POST `https://portal.bulkvs.com/api/v1.0/messageSend` | JSON | digits, no `+` | HTTP 2xx |
| Twilio | POST `https://api.twilio.com/2010-04-01/Accounts/<SID>/Messages.json` | `application/x-www-form-urlencoded` | digits **with** `+` | HTTP 201 **and** `error_code` is null |
| VoIP.ms | GET `https://voip.ms/api/v1/rest.php?method=sendSMS&…` | query string | digits, no `+` | HTTP 200 **and** `status == "success"` |
| SignalWire | POST `https://<space>/api/laml/2010-04-01/Accounts/<ProjectID>/Messages` | `application/x-www-form-urlencoded` | digits **with** `+` | HTTP 201 **and** `error_code` is null |

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

## Out of scope

- **No inbound delivery-status webhook handler.** BulkVS / Twilio / SignalWire can be told where to POST receipts (`delivery_status_webhook_url` / `StatusCallback`), but WaboSign does not yet consume those POSTs. Add a controller at e.g. `app/controllers/webhooks/sms_delivery_controller.rb` if you want delivery confirmations in the audit trail or `SubmissionEvent` log.
- **No MMS.** Outbound is text-only across all providers.
- **No client-side message segmentation.** BulkVS / Twilio / SignalWire auto-segment on their end and bill per segment; VoIP.ms refuses bodies over 160 bytes outright — WaboSign raises `Sms::ProviderError` up front for that provider instead of attempting to split.
- **Phone validation is minimal** — `Sms.normalize_phone` strips non-digits and rejects strings shorter than 8 digits. Each provider prepends `+` if its wire format requires it. Malformed numbers surface as `Sms::ProviderError` with the upstream message.
- **No rate-limiting / per-account quota.** Relies on each provider's own controls.

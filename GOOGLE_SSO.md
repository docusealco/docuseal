# Google SSO

WaboSign supports "Sign in with Google" as an additive authentication path. Once you set the environment variables below, a Google button appears on the sign-in page alongside the existing email-and-password form. Password sign-in keeps working — SSO does not replace it.

This document covers operator setup, runtime behaviour, verification, and troubleshooting.

---

## What you get

- "Sign in with Google" button on `/users/sign_in` whenever the env vars are set.
- Domain-restricted access: only Google accounts whose Workspace `hd` (hosted-domain) claim matches your allowlist can sign in.
- Just-in-time (JIT) user provisioning: a first-time Google sign-in from an allowed domain creates a WaboSign user in the default account.
- 2FA bypass: a user who signed in via Google is not prompted for the WaboSign OTP — Google's MFA is trusted.
- Password sign-in continues to work for any user that has a password (additive, not replaced).

What you *don't* get out of the box:

- No admin UI for credentials — configuration is via env vars only.
- No SAML/Okta/Entra/Keycloak — Google-only. (See the SSO settings page for hints on adding SAML if you need it later.)
- No role mapping from Google Workspace groups — every JIT-created user is `role: 'admin'` (the only role WaboSign ships with).
- No automatic deprovisioning when a user is removed from your Workspace — manage WaboSign accounts via the existing Users settings page.

---

## Prerequisites

1. A Google Cloud project with the "Google Identity" / OAuth consent screen configured.
2. An "OAuth client ID" of type **Web application** with:
   - **Authorized redirect URI**: `https://<your-host>/users/auth/google_oauth2/callback`
   - Authorized JavaScript origins are not required.
3. A Google Workspace domain whose users should be allowed to sign in (for personal Gmail accounts, see "Open access" below).

Create the OAuth client at <https://console.cloud.google.com/apis/credentials> → **Create credentials → OAuth client ID**. Copy the client ID and client secret to your environment.

---

## Configuration

Two ways to configure, in priority order:

### 1. Environment variables (priority — recommended for production)

Set these on the WaboSign process (in `wabosign.env`, the docker-compose `environment:` block, or your hosting provider's secret store):

| Variable | Required | Example | Notes |
|---|---|---|---|
| `GOOGLE_CLIENT_ID` | yes | `1234.apps.googleusercontent.com` | From the Google Cloud OAuth client. |
| `GOOGLE_CLIENT_SECRET` | yes | `GOCSPX-…` | From the Google Cloud OAuth client. |
| `GOOGLE_ALLOWED_DOMAINS` | recommended | `wabo.cc,partner.example` | Comma-separated. Only Google accounts whose `hd` claim is in this list can sign in. Empty = any Google account allowed. |
| `GOOGLE_DEFAULT_ACCOUNT_ID` | no | `1` | The WaboSign `Account` JIT-provisioned users are attached to. Defaults to the oldest account (or the account that owns the UI-saved config, if no env override). Useful only if you run multiple `Account` records on one deployment. |

ENV-driven values take effect at the next request — no restart needed. ENV always wins over the UI form below.

### 2. Web UI (fallback — for ENV-free deployments)

Sign in as an admin, go to **Settings → Google SSO** (`/settings/sso`), and fill in:

- **Enable Google SSO** — toggle. Required for the button to appear on the sign-in page.
- **Client ID** — from your Google Cloud OAuth client.
- **Client Secret** — same. Stored encrypted via Rails `encrypts :value` on `EncryptedConfig`. Leave the field blank when editing later to keep the saved secret unchanged.
- **Allowed Workspace Domains** — comma-separated. Same semantics as `GOOGLE_ALLOWED_DOMAINS`.

The UI-saved config is read on every sign-in via an OmniAuth `setup` proc, so changes take effect on the next click of "Sign in with Google" — no restart needed. The Client Secret is stored encrypted in the `encrypted_configs` table under the `google_sso_configs` key.

The OAuth redirect URI to register in [Google Cloud Console](https://console.cloud.google.com/apis/credentials) is shown on the settings page; it follows the pattern `https://<your-host>/auth/google_oauth2/callback`.

If ENV is also set, the settings page shows a banner indicating that ENV takes precedence; the form is still editable, but the saved values are unused until you unset the env vars (and restart).

---

## Runtime behaviour

### Sign-in flow

1. User clicks **Sign in with Google** on `/users/sign_in`.
2. They are redirected to Google's consent screen. If `GOOGLE_ALLOWED_DOMAINS` is non-empty, the `hd` parameter is passed so Google restricts the account chooser at its end too (defense-in-depth).
3. Google redirects back to `/users/auth/google_oauth2/callback`. [Users::OmniauthCallbacksController#google_oauth2](app/controllers/users/omniauth_callbacks_controller.rb) handles the response:
   - The `hd` claim is checked against `GOOGLE_ALLOWED_DOMAINS`. Mismatch → redirect to sign-in with the "not permitted" flash.
   - The `email` claim is looked up case-insensitively in the `users` table.
4. If a matching user exists:
   - If their `provider`/`uid` are unset, they get linked to this Google identity and signed in.
   - If they already have a different `uid` linked, sign-in is rejected (defends against account takeover by email collision).
5. If no matching user exists, a new one is JIT-provisioned in the default account, with `role: 'admin'`, the user's Google first/last name, a random unused password, and `confirmed_at: now`.
6. `session[:bypass_otp_for_sso]` is set so the post-login MFA-setup redirect in [DashboardController#maybe_redirect_mfa_setup](app/controllers/dashboard_controller.rb) is skipped.

### 2FA interaction

Users who signed in via Google never see the WaboSign OTP prompt — regardless of whether their account has `otp_required_for_login: true`. The reasoning: Google enforces its own MFA, and a second OTP step would be redundant.

Password users are unaffected — they still see the OTP prompt if they have 2FA enabled.

If you ever sign out and back in via password, the bypass flag is cleared and the normal OTP path applies.

### Open access (no allowlist)

Leaving `GOOGLE_ALLOWED_DOMAINS` empty *enables sign-in for any Google account, including personal Gmail*. A `Rails.logger.warn` is emitted at boot:

```
[Wabosign] Google SSO is enabled but GOOGLE_ALLOWED_DOMAINS is empty — any Google account will be permitted to sign in.
```

Use this only for demo or single-user deployments. For business deployments, **always** set an allowlist.

---

## Verification

After deploying:

1. **Status page** — open <https://your-host/settings/sso> as an admin. You should see a green banner: *"Google SSO is enabled. Allowed Workspace domain: `wabo.cc`."* If you see *"Google SSO is not configured"*, your env vars didn't reach the process — check your secret loader.

2. **Happy path** — open <https://your-host/users/sign_in> in a private window. Click **Sign in with Google**. Use a Google account whose domain is on the allowlist. You should land on the WaboSign dashboard signed in. If the user didn't already exist in WaboSign, they were just JIT-created in the default account.

3. **Domain rejection** — repeat with a Google account whose domain is *not* on the allowlist (e.g. a personal `@gmail.com`). You should be redirected back to `/users/sign_in` with the flash: *"Google sign-in failed: this Google account is not permitted to sign in."*

4. **Password still works** — sign in as a different user with email + password. The flow should be unchanged from before SSO was enabled (still OTP-gated if that user has 2FA on).

5. **2FA bypass** — turn on WaboSign 2FA for the SSO user via Settings → Profile → Two-Factor Authentication. Sign out. Sign back in via Google. Confirm you go straight to the dashboard without an OTP prompt.

6. **Spec suite** — `bin/rspec spec/requests/users/omniauth_callbacks_spec.rb` runs five cases: happy path, link existing user, domain rejection, identity collision, 2FA bypass. All should pass.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| No Google button on sign-in page | `GOOGLE_CLIENT_ID` or `GOOGLE_CLIENT_SECRET` is unset, or the app hasn't been restarted since you set them. | Check `bin/rails runner 'puts Wabosign.google_sso_enabled?'` — should print `true`. Restart if needed. |
| `redirect_uri_mismatch` error from Google | The redirect URI registered in Google Cloud Console doesn't match the one WaboSign sends. | Ensure the **Authorized redirect URI** in Google Cloud is exactly `https://<your-host>/users/auth/google_oauth2/callback` (matching scheme, host, no trailing slash). Update `ENV['HOST']` / `APP_URL` on the WaboSign side if needed. |
| "Google sign-in failed: this Google account is not permitted" for a user whose domain *is* on the allowlist | The Google account is a personal Gmail (no `hd` claim) rather than a Workspace account, or the `hd` claim differs from your allowlist entry (e.g. `googlemail.com` vs `gmail.com`). | Confirm the user is signing in with their Workspace identity. Check the Rails logs around the failure for the actual `hd` value. |
| Identity collision rejection (existing email with different Google uid) | Someone else's Google account already linked to that email, then the user changed their primary Google identity. | Manually unset `provider`/`uid` on that user row via `bin/rails console`: `User.find_by(email: '...').update_columns(provider: nil, uid: nil)`. The next sign-in will re-link. |
| User keeps being prompted for MFA setup after Google sign-in | `FORCE_MFA` is enabled for the account, and the code path missed the bypass. | Confirm `User#signed_in_via_sso?` returns true for that user (run in `rails console`). If it returns false, check that the user has `provider: 'google_oauth2'` and a non-blank `uid` — both are set on first SSO sign-in. |
| Sign-in works but the user lands in an empty/wrong account | More than one `Account` exists in your deployment and the user got assigned to the wrong one by JIT provisioning. | Set `GOOGLE_DEFAULT_ACCOUNT_ID` to pin the target account, or move the user via the Users settings page. |
| Boot log: "any Google account will be permitted to sign in" | Allowlist is empty. | Set `GOOGLE_ALLOWED_DOMAINS` to your Workspace domain(s) and restart. |

---

## Security notes

- **Domain allowlist enforced server-side.** Google's `hd` parameter on the request is a UX hint — Google may still let unrelated accounts through the consent screen. WaboSign re-checks the `hd` claim in the OAuth response before issuing a session, so a misconfigured Google Cloud consent screen cannot bypass the allowlist.

- **Identity collision protection.** If a row in `users` already has `provider`/`uid` set, sign-in via a *different* Google uid for the same email is rejected. This blocks "I changed my Workspace identity but kept the email alias" attacks.

- **Password sign-in is not weakened.** Adding Google SSO does not remove or alter the password flow. Users who never click the Google button can keep using passwords + OTP exactly as before. An attacker who compromises your Google Cloud project can sign in as any allowlisted email — they cannot sign in as users on disallowed domains, nor as users who have no password yet (those don't exist after JIT — every JIT-created user has a random unused password, which is fine because it's not recoverable).

- **The unused password.** JIT-created users have `password = SecureRandom.hex(32)`. It is never displayed and never resetable through the standard flow (the user has no way to know it). To grant a JIT-only user a real password, use the Devise "forgot password" flow or set one via `bin/rails console`.

- **No domain-wide pre-revocation.** Removing a user from your Google Workspace does not delete or disable their WaboSign user. Use the Users settings page to archive them, or write a periodic task that scans against Google's Admin SDK.

---

## Code map

| File | Role |
|---|---|
| [Gemfile](Gemfile) | Adds `omniauth`, `omniauth-google-oauth2`, `omniauth-rails_csrf_protection`. |
| [lib/wabosign.rb](lib/wabosign.rb) | `GOOGLE_*` constants, `google_sso_enabled?`, `google_domain_allowed?`, boot warning. |
| [config/initializers/devise.rb](config/initializers/devise.rb) | Registers `:google_oauth2` Devise OmniAuth strategy when enabled. |
| [app/models/user.rb](app/models/user.rb) | Conditional `:omniauthable`, `from_google_omniauth`, `default_sso_account`, `signed_in_via_sso?`. |
| [config/routes.rb](config/routes.rb) | `devise_for` extended with `omniauth_callbacks`. |
| [app/controllers/users/omniauth_callbacks_controller.rb](app/controllers/users/omniauth_callbacks_controller.rb) | Handles `/users/auth/google_oauth2/callback`. |
| [app/controllers/sessions_controller.rb](app/controllers/sessions_controller.rb) | Clears `session[:bypass_otp_for_sso]` on sign-out. |
| [app/controllers/dashboard_controller.rb](app/controllers/dashboard_controller.rb) | Honours the SSO bypass flag to skip the FORCE_MFA redirect. |
| [app/views/devise/sessions/_omniauthable.html.erb](app/views/devise/sessions/_omniauthable.html.erb) | The Google button on the sign-in page. |
| [app/views/sso_settings/_placeholder.html.erb](app/views/sso_settings/_placeholder.html.erb) | Status panel at `/settings/sso`. |
| `db/migrate/20260515200000_add_omniauth_to_users.rb` | Adds `provider`, `uid`, partial unique index. |
| `public/google_g.svg` | Google "G" mark used by the button. |
| `spec/requests/users/omniauth_callbacks_spec.rb` | Request specs (happy path, link, reject, collision, 2FA bypass). |

---

## Future work

- **Other IdPs.** To support Okta / Entra / Keycloak, swap `omniauth-google-oauth2` for `omniauth_openid_connect` (generic OIDC) and add per-IdP env vars. The User model JIT logic stays the same shape.
- **Admin UI for credentials.** Move from env vars to an encrypted `EncryptedConfig` record so non-developers can rotate credentials. The existing [SsoSettingsController](app/controllers/sso_settings_controller.rb) already loads a `saml_configs` key — extend with `google_oauth_configs` and a form.
- **Role mapping.** When you add `:editor` / `:viewer` roles, derive them from Google Workspace group claims rather than defaulting every JIT user to `:admin`.
- **Workspace-wide deprovisioning.** Periodic Sidekiq job that uses the Google Admin SDK to check whether each Google-linked WaboSign user still exists in your Workspace, and archives ones that don't.

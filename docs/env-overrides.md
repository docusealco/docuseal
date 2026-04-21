# Environment Variable Config Overrides

Any `account_config` value can be locked via an environment variable using the
`DOCUSEAL_CONFIG_<UPCASE_KEY>` pattern. When set, the value takes precedence
over the database and the corresponding UI toggle is rendered as disabled with
a tooltip "Locked by environment variable".

## Value parsing rules

| Raw ENV value                      | Parsed as                 |
|------------------------------------|---------------------------|
| `true`, `1`, `yes`, `on`           | boolean `true`            |
| `false`, `0`, `no`, `off`          | boolean `false`           |
| Valid JSON (object / array / num)  | parsed JSON               |
| Anything else                      | raw string                |

Comparison is case-insensitive for booleans.

## Examples

```bash
# Boolean toggle
DOCUSEAL_CONFIG_ALLOW_TYPED_SIGNATURE=true

# JSON object
DOCUSEAL_CONFIG_POLICY_LINKS='{"privacy":"https://example.com/privacy"}'

# Plain string
DOCUSEAL_CONFIG_DOCUMENT_FILENAME_FORMAT="{{template.name}}-{{submitter.name}}"
```

## Supported keys (non-exhaustive)

All keys declared as constants in `app/models/account_config.rb` are supported.
A few common ones:

| ENV variable                                           | Account config key               |
|--------------------------------------------------------|----------------------------------|
| `DOCUSEAL_CONFIG_ALLOW_TYPED_SIGNATURE`                | `allow_typed_signature`          |
| `DOCUSEAL_CONFIG_ALLOW_TO_DECLINE`                     | `allow_to_decline`               |
| `DOCUSEAL_CONFIG_ENFORCE_SIGNING_ORDER`                | `enforce_signing_order`          |
| `DOCUSEAL_CONFIG_FORCE_MFA`                            | `force_mfa`                      |
| `DOCUSEAL_CONFIG_EMAIL_FOOTER_MESSAGE`                 | `email_footer_message`           |
| `DOCUSEAL_CONFIG_SHOW_CONSOLE_LINK`                    | `show_console_link`              |
| `DOCUSEAL_CONFIG_SHOW_API_LINK`                        | `show_api_link`                  |
| `DOCUSEAL_CONFIG_SHOW_TEST_MODE`                       | `show_test_mode`                 |

## How it works

- `AccountConfig.locked_by_env?(key)` returns `true` when the matching env var
  is set (non-blank).
- `AccountConfig.env_override_cast(key)` parses the value per the rules above.
- On `Account` create (`after_create_commit`), all env overrides are upserted
  into `account_configs`.
- On boot (`config/initializers/account_config_env_overrides.rb`), overrides
  are applied to all existing accounts so the DB stays in sync with the env.
- Views should check `AccountConfig.locked_by_env?(key)` to render form fields
  as disabled with an appropriate tooltip when an override is active.

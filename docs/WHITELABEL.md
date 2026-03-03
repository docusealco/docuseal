# White-Label Developer Reference (Internal)

> **This file is for Intebec developers only.**
> Do NOT add config schema details, API contracts, or example YAML here.
> The private config template is managed in the Intebec Dashboard, not in this repo.

## Usage in Code

### In ERB views

```erb
<%= wl.brand_name %>
<%= wl.logo_path %>
<%= wl.support_email %>
<%= wl.page_title(signed_in: true) %>
```

### In Ruby (controllers, mailers, lib)

```ruby
Whitelabel.brand_name
Whitelabel.website_url
Whitelabel.email_from
Whitelabel.sign_reason("John")
Whitelabel.theme(:primary)
```

## Upstream Merge Strategy

This system is designed to minimise merge conflicts with the upstream DocuSeal repo:

1. **New files** (no conflicts): `lib/whitelabel.rb`, `config/initializers/whitelabel.rb`, `app/helpers/whitelabel_helper.rb`, `config/locales/whitelabel.yml`
2. **Patched files** (potential conflicts, but isolated changes):
   - `lib/docuseal.rb` — only added a comment block; the `product_name` method is overridden at runtime
   - View templates — changes are surgical (replacing one hardcoded string with a `Whitelabel.xxx` call)
3. **Untouched internal identifiers**: `data-theme="docuseal"`, `Docuseal` module name, `#docuseal_modal_container`, `docuseal_clipboard` localStorage keys — all kept as-is for compatibility

### When Upstream Adds New Branded Content

1. Check if new views/lib files have hardcoded "DocuSeal" text
2. Replace with `Whitelabel.brand_name` or `wl.brand_name`
3. If it's an i18n key, add the override to `config/locales/whitelabel.yml`

## File Reference

| File                                | Purpose                      | Upstream risk           |
| ----------------------------------- | ---------------------------- | ----------------------- |
| `lib/whitelabel.rb`                 | Config loader + licence gate | New file — zero risk    |
| `config/initializers/whitelabel.rb` | Boot-time patching           | New file — zero risk    |
| `app/helpers/whitelabel_helper.rb`  | View helper                  | New file — zero risk    |
| `config/locales/whitelabel.yml`     | i18n overrides               | New file — zero risk    |
| `public/intebec.css`                | Theme CSS                    | Custom file — zero risk |
| `lib/docuseal.rb`                   | Added comment                | Low risk — comment only |

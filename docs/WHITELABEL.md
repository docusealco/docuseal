# White-Label Configuration Guide

## Overview

This fork of DocuSeal uses a **centralised white-label configuration system** that lets you rebrand the entire application for any client by editing a single YAML file. No need to create a separate repo for each client.

## Architecture

```
config/whitelabel.yml          ← Single source of truth (brand, URLs, theme, PDF, features)
lib/whitelabel.rb              ← Ruby module that loads + exposes the config
config/initializers/whitelabel.rb  ← Patches Docuseal module at boot so existing code uses new values
app/helpers/whitelabel_helper.rb   ← View helper (use `wl.xxx` in any ERB template)
config/locales/whitelabel.yml  ← Locale overrides for branded i18n keys (EN + FR)
public/intebec.css             ← CSS theme overrides (DaisyUI custom properties)
```

## How to Rebrand for a New Client

### 1. Edit `config/whitelabel.yml`

Change the values under each section:

| Section    | What it controls                               |
| ---------- | ---------------------------------------------- |
| `brand`    | Name, tagline, description, page titles        |
| `urls`     | Website, support email, privacy/terms, socials |
| `email`    | From address, email attribution                |
| `assets`   | Logo, favicons, preview image                  |
| `theme`    | DaisyUI colour palette (HSL values)            |
| `pdf`      | Signing reason, audit trail footer, cert name  |
| `pwa`      | PWA manifest name, colours                     |
| `webhooks` | User-Agent string                              |
| `features` | Toggle GitHub button, AI link, powered-by text |

### 2. Replace Asset Files

Put your client's files in `/public`:

- `logo.svg` — navbar + form logo
- `favicon.ico`, `favicon-16x16.png`, `favicon-32x32.png`, `favicon-96x96.png`
- `favicon.svg` — SVG favicon
- `apple-icon-180x180.png` — iOS home screen icon
- `preview.png` — Open Graph social preview

### 3. Update Theme Colours

Two options:

**Option A** — Edit `theme:` in `config/whitelabel.yml` (DaisyUI tokens, HSL format):

```yaml
theme:
  primary: "216 77% 52%"
  secondary: "220 12% 45%"
  accent: "160 50% 40%"
```

**Option B** — Edit `public/intebec.css` for fine-grained CSS overrides.

### 4. Update Locale Overrides

Edit `config/locales/whitelabel.yml` to change branded text in both English and French. This file **overrides** the base `config/locales/i18n.yml` — Rails merges them automatically.

### 5. Restart

After editing, restart the app:

```bash
docker compose down && docker compose up -d --build
```

Or in a Rails console:

```ruby
Whitelabel.reload!
```

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
Whitelabel.brand_name      # => "Intébec"
Whitelabel.website_url     # => "https://intebec.ca"
Whitelabel.email_from      # => "Intébec <info@intebec.ca>"
Whitelabel.sign_reason("John") # => "Signed by John with Intébec"
Whitelabel.theme(:primary) # => "216 77% 52%"
```

### In JavaScript

Brand values are available via `<meta>` tags in the page head:

```javascript
document.querySelector('meta[name="brand-name"]').content; // "Intébec"
document.querySelector('meta[name="brand-website-url"]').content; // "https://intebec.ca"
```

## Upstream Merge Strategy

This system is designed to minimise merge conflicts with the upstream DocuSeal repo:

1. **New files** (no conflicts): `config/whitelabel.yml`, `lib/whitelabel.rb`, `config/initializers/whitelabel.rb`, `app/helpers/whitelabel_helper.rb`, `config/locales/whitelabel.yml`
2. **Patched files** (potential conflicts, but isolated changes):
   - `lib/docuseal.rb` — only added a comment block; the `product_name` method is overridden at runtime
   - View templates — changes are surgical (replacing one hardcoded string with a `Whitelabel.xxx` call)
3. **Untouched internal identifiers**: `data-theme="docuseal"`, `Docuseal` module name, `#docuseal_modal_container`, `docuseal_clipboard` localStorage keys — all kept as-is for compatibility

### When Upstream Adds New Branded Content

1. Check if new views/lib files have hardcoded "DocuSeal" text
2. Replace with `Whitelabel.brand_name` or `wl.brand_name`
3. If it's an i18n key, add the override to `config/locales/whitelabel.yml`

## Feature Flags

Toggle upstream features without removing code:

```yaml
features:
  show_github_button: false # Hide "Star on GitHub"
  show_powered_by: true # Show/hide "Powered by" on signing pages
  show_ai_link: false # Hide "Ask AI" in user menu
  show_discord_link: false # Hide Discord link
```

## File Reference

| File                                     | Purpose            | Upstream risk           |
| ---------------------------------------- | ------------------ | ----------------------- |
| `config/whitelabel.yml`                  | All brand config   | New file — zero risk    |
| `lib/whitelabel.rb`                      | Config loader      | New file — zero risk    |
| `config/initializers/whitelabel.rb`      | Boot-time patching | New file — zero risk    |
| `app/helpers/whitelabel_helper.rb`       | View helper        | New file — zero risk    |
| `config/locales/whitelabel.yml`          | i18n overrides     | New file — zero risk    |
| `public/intebec.css`                     | Theme CSS          | Custom file — zero risk |
| `lib/docuseal.rb`                        | Added comment      | Low risk — comment only |
| `app/views/shared/_logo.html.erb`        | Dynamic logo path  | Low risk                |
| `app/views/shared/_meta.html.erb`        | Dynamic meta tags  | Low risk                |
| `app/views/shared/_title.html.erb`       | Dynamic brand name | Low risk                |
| `app/views/layouts/application.html.erb` | Added meta tags    | Low risk                |
| `app/views/layouts/form.html.erb`        | Added meta tags    | Low risk                |

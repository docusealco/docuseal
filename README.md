<h1 align="center" style="border-bottom: none">
  <div>
    <a href="https://sign.wabo.cc">
      <img alt="WaboSign" src="public/favicon.svg" width="80" />
      <br>
    </a>
    WaboSign
  </div>
</h1>
<h3 align="center">
  Self-hosted document filling and signing
</h3>

<p>
WaboSign is a self-hosted, open-source platform for secure digital document signing and processing. Create PDF forms, fill them in online from any device, and collect signatures with an easy-to-use, mobile-optimized web tool.
</p>

WaboSign is a fork of [DocuSeal](https://github.com/docusealco/docuseal) under AGPLv3, with the upstream's "Pro" feature paywall removed so that every shipped capability is available out of the box on a self-hosted deployment.

## Features

- PDF form fields builder (WYSIWYG)
- 12 field types (Signature, Date, File, Checkbox, Phone, Verification, etc.)
- Multiple submitters per document
- Automated emails via SMTP
- File storage on disk or AWS S3, Google Storage, Azure Blob
- Automatic PDF eSignature
- PDF signature verification
- User management and roles
- Mobile-optimized signing flow
- 14 UI languages
- API + Webhooks for integrations
- SMS invitations via [BulkVS](SMS.md)
- Bulk send via CSV / XLSX import
- Google Workspace SSO ([setup guide](GOOGLE_SSO.md))
- Conditional fields and formulas
- Custom branding (logo, colors, reply-to)
- Easy Docker deployment

## Docker

```sh
docker run --name wabosign -p 3000:3000 -v .:/data ghcr.io/wabolabs/wabosign:latest
```

By default the container uses SQLite for data. Point at PostgreSQL or MySQL by setting `DATABASE_URL`.

### Docker Compose

```sh
sudo HOST=sign.example.com docker compose up
```

Make sure your DNS points at the server so Caddy can issue an SSL cert automatically.

## Authentication

WaboSign ships with email + password (Devise) and TOTP two-factor auth out of the box. Google Workspace SSO can be enabled by setting three environment variables — see [GOOGLE_SSO.md](GOOGLE_SSO.md) for the full operator guide.

## License

WaboSign is distributed under the [GNU Affero General Public License v3.0](LICENSE), with the §7(b) [Additional Terms](LICENSE_ADDITIONAL_TERMS) preserved from upstream.

WaboSign is a fork of [DocuSeal](https://github.com/docusealco/docuseal) © 2023–2026 DocuSeal LLC. The upstream attribution required by §7(b) is preserved in interactive UIs and in the [NOTICE](NOTICE) file. Modifications © 2026 the WaboSign authors.

## Acknowledgements

This software builds on the substantial work of the [DocuSeal](https://github.com/docusealco/docuseal) team. Their open-source release made this fork possible. WaboSign retains the embedding SDK contract (`<docuseal-form>`, `@docuseal/react`, `@docuseal/vue`, `@docuseal/angular`) so existing DocuSeal embedding code continues to work.

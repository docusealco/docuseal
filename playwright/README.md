# DocuSeal Playwright Tests

End-to-end tests for DocuSeal fork features.

## Setup

```bash
cd playwright
npm install
npm run install:browsers
```

## Running

```bash
# Against local dev server (http://localhost:3000)
npm test

# Against UAT
PLAYWRIGHT_BASE_URL=https://docuseal-uat.example.com npm test

# Headed / debug UI
npm run test:headed
npm run test:ui
```

## Env vars

- `PLAYWRIGHT_BASE_URL` — explicit target URL (overrides everything)
- `DOCUSEAL_UAT_URL` — default UAT URL when `PLAYWRIGHT_BASE_URL` absent
- `DOCUSEAL_ADMIN_EMAIL` / `DOCUSEAL_ADMIN_PASSWORD` — credentials for login helpers

## Layout

One spec per feature (mirrors `PLAN.md` version numbering):

- `v0.4.0-version-display.spec.ts`
- `v0.1.0-config-overrides.spec.ts`
- ...

# Gold Leaf DocuSeal — deployment notes

DocuSeal as a fourth user-facing service in the eDMS stack at **https://sign.zabbu.co**. Forked from `docusealco/docuseal` and tracked on the `goldleaf-custom` branch so monthly upstream merges (`git merge upstream/master`) stay clean.

## What this fork adds

Only deployment scaffolding — no Rails source-code changes in Phase 1:

- `docker-compose.prod.yml` — production stack (app + Postgres) routed via the shared nginx-proxy.
- `.env.example` — documented secrets template.
- `.github/workflows/deploy.yml` — CI/CD: build the upstream `Dockerfile`, push `servedigital/docuseal:latest`, SSH-deploy to `/opt/zabbu-sign/`.

Branding (app name, logo) is applied through DocuSeal's own admin UI after the first boot.

## Architecture

```
Internet → nginx-proxy + acme-companion (/opt/goldleaf-dms/)
            │   proxy network (external)
            ▼
          docuseal:3000  (servedigital/docuseal:latest)
            │   docuseal-internal network (internal-only)
            ▼
          docuseal-db (postgres:18)

Outbound mail:
          docuseal --SMTP:25--> invoice-reminder --REST--> Mailgun
                  (proxy network, no TLS, no auth)
```

DocuSeal's bundled Caddy is **not used** — nginx-proxy handles SSL for every other service in this droplet, and we want one termination point.

## Email

DigitalOcean blocks outbound SMTP, so DocuSeal points at the existing `invoice-reminder` container (extended with an SMTP→Mailgun relay) instead of contacting an SMTP server directly. Required reading: `edms-invoice-reminder-service/README.md` → "Internal SMTP relay".

DocuSeal env vars used:

| Var | Value | Source |
|---|---|---|
| `SMTP_ADDRESS` | `invoice-reminder` | container DNS on `proxy` network |
| `SMTP_PORT` | `25` | the relay's listen port |
| `SMTP_DOMAIN` | `zabbu.co` | EHLO domain |
| `SMTP_ENABLE_STARTTLS` | `false` | local network, no need |
| `SMTP_ENABLE_SSL` / `SMTP_ENABLE_TLS` | `false` | same |
| `SMTP_USERNAME` / `SMTP_PASSWORD` | (unset) | relay accepts unauthenticated mail |

DocuSeal's default From header is `DocuSeal <info@docuseal.com>`. Mailgun rejects mail whose From domain isn't on a verified domain, so **after first boot** set the per-account "Send from Email" in DocuSeal's admin UI (Account settings → Send from Email) to a verified Mailgun address (e.g. `sign@mg.servedigital.io`). The relay also rewrites unmatched From addresses to `MAILGUN_FROM` as a safety net, but explicit configuration is cleaner.

## First-time VPS setup (one-shot)

```bash
ssh zabbu@46.101.144.7
sudo mkdir -p /opt/zabbu-sign
sudo chown zabbu:zabbu /opt/zabbu-sign
cd /opt/zabbu-sign
```

Copy the compose file from your laptop:

```bash
scp docker-compose.prod.yml zabbu@46.101.144.7:/opt/zabbu-sign/docker-compose.yml
```

Create `/opt/zabbu-sign/.env`:

```bash
cat > /opt/zabbu-sign/.env <<EOF
POSTGRES_PASSWORD=$(openssl rand -hex 24)
SECRET_KEY_BASE=$(openssl rand -hex 64)
EOF
chmod 600 /opt/zabbu-sign/.env
```

Bump the upload size in nginx-proxy (default 1 MB will 413 every contract):

```bash
echo 'client_max_body_size 100m;' \
  | sudo tee /opt/goldleaf-dms/nginx-custom/sign.zabbu.co_location
cd /opt/goldleaf-dms && docker compose restart nginx-proxy
```

Toggle the SMTP relay on the reminder service (must be done before DocuSeal starts):

```bash
ssh zabbu@46.101.144.7 'cd /opt/invoice-reminder && \
  grep -q ^SMTP_RELAY_ENABLED .env || cat >> .env <<EOF

SMTP_RELAY_ENABLED=true
SMTP_RELAY_PORT=25
SMTP_RELAY_ALLOWED_FROM_DOMAINS=mg.servedigital.io,vms-api.servedigital.io,zabbu.co
EOF
docker compose -f docker-compose.prod.yml up -d --no-deps invoice-reminder'
```

First boot of DocuSeal (after the CI/CD build has pushed `servedigital/docuseal:latest`):

```bash
cd /opt/zabbu-sign
docker compose pull
docker compose up -d
docker compose logs -f docuseal      # watch Rails migrations run
```

acme-companion will issue the Let's Encrypt cert automatically once DocuSeal is healthy (DNS for `sign.zabbu.co → 46.101.144.7` is already in place).

## First-time browser setup

1. Open `https://sign.zabbu.co`. Create the superadmin account.
2. Account settings → upload `goldleaf_logo.png`, set the app name to "Gold Leaf Sign".
3. Account settings → "Send from Email" → enter a verified Mailgun address (e.g. `sign@mg.servedigital.io`).
4. Send a one-off signing request to a personal address and confirm:
   - it arrives in the inbox
   - the signing link points at `https://sign.zabbu.co/...`
   - clicking through, signing, and returning to the dashboard works

## Upstream sync (run monthly)

```bash
cd /home/oquidave/servedigital/eDMS/docuseal
git fetch upstream
git checkout goldleaf-custom
git merge upstream/master
# resolve conflicts (rare — we only added top-level deploy files)
git push origin goldleaf-custom
```

The push triggers CI; the new image is on DockerHub within ~10 min.

## Troubleshooting

**Cert never issues.** `docker compose -f /opt/goldleaf-dms/docker-compose.yml logs acme-companion | grep sign.zabbu.co`. Most common cause: container isn't healthy yet, so acme-companion hasn't tried.

**413 Request Entity Too Large.** The nginx-proxy snippet `/opt/goldleaf-dms/nginx-custom/sign.zabbu.co_location` is missing or nginx-proxy wasn't restarted after adding it.

**Email never arrives.** Check the relay logs first: `docker compose -f /opt/invoice-reminder/docker-compose.prod.yml logs --tail=100 invoice-reminder | grep smtp-relay`. You should see `forwarded ... mailgun_id=...`. If not, the SMTP_ADDRESS in DocuSeal's env is wrong, or `SMTP_RELAY_ENABLED` is still `false`.

**Mailgun returns 401/403/422.** The From: domain isn't verified. Either set DocuSeal's "Send from Email" to a verified address, or add the domain to `SMTP_RELAY_ALLOWED_FROM_DOMAINS` in the reminder service's `.env`.

## Backups

`./data` (uploaded PDFs + signed PDFs) and `./pgdata` (Postgres) live on the droplet's local SSD. Roll them into the daily DO Spaces backup task when it ships:

```bash
# Add to /opt/goldleaf-dms/backups/backup.sh (when that script exists)
docker exec docuseal-db pg_dump -U docuseal docuseal > /opt/zabbu-sign/pgdata-backup.sql
tar -czf docuseal-$(date +%F).tar.gz \
  /opt/zabbu-sign/data /opt/zabbu-sign/pgdata-backup.sql
# then s3cmd put → DO Spaces
```

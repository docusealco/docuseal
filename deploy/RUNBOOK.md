# DocuSeal VPS Deploy Runbook (KVM1 → e-sign.360dmmc.com)

## Prerequisites (from Lohith)
- SSH access to KVM1 (sudo-capable user)
- DNS A-record: `e-sign.360dmmc.com` → KVM1 public IPv4
- Firewall: 80/tcp, 443/tcp inbound (world); 22/tcp inbound (admin); 587/tcp outbound to `smtp.office365.com`
- Ubuntu 22.04, ≥2 GB RAM, ≥20 GB disk

## 1. Install Docker (if absent)
```sh
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
# log out/in for group change to take effect
```

## 2. Clone repo
```sh
sudo mkdir -p /opt/docuseal && sudo chown $USER:$USER /opt/docuseal
git clone https://github.com/Dhia-mastouri/360-e-sign.git /opt/docuseal
cd /opt/docuseal
```

## 3. Configure environment
```sh
cp deploy/.env.example deploy/.env
# Generate secrets:
echo "SECRET_KEY_BASE=$(openssl rand -hex 64)"  >> deploy/.env  # then dedupe
echo "POSTGRES_PASSWORD=$(openssl rand -hex 24)" >> deploy/.env
# Edit deploy/.env: set HOST, SMTP_USERNAME, SMTP_PASSWORD, DATABASE_URL (use the same POSTGRES_PASSWORD)
chmod 600 deploy/.env
```

## 4. Verify DNS before bringing Caddy up
```sh
dig +short e-sign.360dmmc.com
# Must return KVM1 public IP. If not, wait or fix with Lohith before next step.
```

## 5. Bring stack up
```sh
docker compose --env-file deploy/.env \
  -f docker-compose.yml -f deploy/docker-compose.prod.yml \
  up -d
docker compose logs -f app
# Wait for "Listening on http://0.0.0.0:3000"
```

Caddy will obtain a Let's Encrypt cert automatically on first request (~30 s).

## 6. First-run admin setup
- Open `https://e-sign.360dmmc.com`
- Complete admin onboarding (email, password, company)
- Settings → Email → SMTP: confirm Exchange creds, send a test mail to yourself

## 7. Schedule backups
```sh
chmod +x deploy/backup.sh deploy/restore.sh
sudo crontab -e
# Add: 0 2 * * * /opt/docuseal/deploy/backup.sh >> /var/log/docuseal-backup.log 2>&1
```

## 8. Smoke test
- Upload AI-generated service-agreement PDF as a template
- Drop Signature + Date + Name fields
- Send to a real recipient
- Verify completed PDF + audit log download

## Upstream sync
```sh
git fetch upstream
git checkout dev
git merge upstream/master   # or upstream/main
# Resolve conflicts in deploy/ should never happen; they will only ever appear
# in upstream-tracked files. If they do, resolve in favor of upstream and
# re-apply our 360DMMC overlay separately.
docker compose pull && docker compose up -d
```

## Rollback
```sh
docker compose down
./deploy/restore.sh /opt/docuseal/backups/<timestamp>
docker compose --env-file deploy/.env -f docker-compose.yml -f deploy/docker-compose.prod.yml up -d
```

## Health checks
- `curl -I https://e-sign.360dmmc.com` → expect `200` or `302`
- `docker compose ps` → all services `Up`
- `docker compose logs --tail 50 app` → no `ERROR` lines

## HIPAA pre-flight (before real PHI)
- [ ] Microsoft 365 BAA signed (covers Exchange SMTP)
- [ ] Postgres volume on encrypted disk (`cryptsetup` or cloud-provider encrypted disk)
- [ ] Off-site backup target (encrypted) configured in `deploy/backup.sh`
- [ ] Audit log retention policy documented
- [ ] Access list reviewed (who has KVM1 sudo, who has DocuSeal admin)

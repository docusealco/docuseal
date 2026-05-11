#!/usr/bin/env bash
# One-shot DocuSeal bootstrap for KVM1.
# Run as a sudo-capable user. Idempotent: safe to re-run.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Dhia-mastouri/360-e-sign/dev/deploy/bootstrap.sh | bash -s -- [proxy|caddy]
#
# Modes:
#   caddy  - DocuSeal manages SSL via bundled Caddy. Requires ports 80+443 free.
#   proxy  - DocuSeal binds to 127.0.0.1:3000, an existing reverse proxy fronts it.
#
# After running, edit /opt/docuseal/deploy/.env and fill SMTP_USERNAME, SMTP_PASSWORD,
# then run: cd /opt/docuseal && docker compose --env-file deploy/.env -f docker-compose.yml -f deploy/docker-compose.<mode>.yml up -d

set -euo pipefail

MODE="${1:-caddy}"
case "$MODE" in
  caddy) OVERLAY="docker-compose.prod.yml" ;;
  proxy) OVERLAY="docker-compose.behind-proxy.yml" ;;
  *) echo "usage: $0 [caddy|proxy]"; exit 1 ;;
esac

REPO_URL="https://github.com/Dhia-mastouri/360-e-sign.git"
INSTALL_DIR="/opt/docuseal"
BRANCH="dev"
HOST_DEFAULT="e-sign.360dmmc.com"

echo "==> mode: $MODE (overlay: $OVERLAY)"

if ! command -v docker >/dev/null 2>&1; then
  echo "==> installing Docker"
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
  echo "    Docker installed. Log out and back in for group membership, then re-run."
  exit 0
fi

if [ ! -d "$INSTALL_DIR" ]; then
  echo "==> cloning repo to $INSTALL_DIR"
  sudo mkdir -p "$INSTALL_DIR"
  sudo chown "$USER:$USER" "$INSTALL_DIR"
  git clone -b "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
else
  echo "==> repo exists, pulling latest"
  git -C "$INSTALL_DIR" fetch origin "$BRANCH"
  git -C "$INSTALL_DIR" checkout "$BRANCH"
  git -C "$INSTALL_DIR" pull --ff-only origin "$BRANCH"
fi

cd "$INSTALL_DIR"

mkdir -p /opt/docuseal/data /opt/docuseal/pg_data /opt/docuseal/caddy /opt/docuseal/backups

if [ ! -f deploy/.env ]; then
  echo "==> generating deploy/.env from template"
  cp deploy/.env.example deploy/.env
  PG_PASS=$(openssl rand -hex 24)
  SECRET=$(openssl rand -hex 64)
  sed -i "s|^SECRET_KEY_BASE=.*|SECRET_KEY_BASE=$SECRET|" deploy/.env
  sed -i "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$PG_PASS|" deploy/.env
  sed -i "s|REPLACE_ME|$PG_PASS|" deploy/.env
  sed -i "s|^HOST=.*|HOST=$HOST_DEFAULT|" deploy/.env
  chmod 600 deploy/.env
  echo "    .env generated. EDIT IT NOW to set SMTP_USERNAME / SMTP_PASSWORD before continuing."
  echo "    Edit:  nano $INSTALL_DIR/deploy/.env"
  exit 0
fi

if grep -q "^SMTP_USERNAME=$" deploy/.env || grep -q "^SMTP_PASSWORD=$" deploy/.env; then
  echo "!! SMTP_USERNAME and/or SMTP_PASSWORD are still empty in deploy/.env."
  echo "   Edit deploy/.env and re-run."
  exit 1
fi

echo "==> bringing stack up"
docker compose --env-file deploy/.env -f docker-compose.yml -f "deploy/$OVERLAY" pull
docker compose --env-file deploy/.env -f docker-compose.yml -f "deploy/$OVERLAY" up -d

echo "==> waiting for app to be ready"
for i in $(seq 1 60); do
  if docker compose logs app 2>/dev/null | grep -q "Listening on http://0.0.0.0:3000"; then
    echo "    app ready"
    break
  fi
  sleep 2
done

echo "==> done"
docker compose ps

cat <<EOF

Next steps:
  1. Open https://$(grep ^HOST= deploy/.env | cut -d= -f2)
  2. Complete admin onboarding (email + password + company)
  3. Settings -> Email -> SMTP: confirm Exchange creds, send test mail
  4. Generate an API token (Settings -> API)
  5. Run health check: deploy/health_check.sh
  6. Schedule backups:
       sudo crontab -l 2>/dev/null | { cat; echo '0 2 * * * $INSTALL_DIR/deploy/backup.sh >> /var/log/docuseal-backup.log 2>&1'; } | sudo crontab -
EOF

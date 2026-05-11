#!/usr/bin/env bash
# Daily backup of Postgres + attachments. Run from /opt/docuseal repo root.
# Suggested cron: 0 2 * * * /opt/docuseal/deploy/backup.sh >> /var/log/docuseal-backup.log 2>&1

set -euo pipefail

BACKUP_ROOT="${BACKUP_ROOT:-/opt/docuseal/backups}"
RETAIN_DAYS="${RETAIN_DAYS:-14}"
STAMP=$(date -u +%Y%m%d-%H%M%S)
DEST="$BACKUP_ROOT/$STAMP"

mkdir -p "$DEST"

docker compose exec -T postgres \
  pg_dump -U "${POSTGRES_USER:-docuseal}" -d "${POSTGRES_DB:-docuseal}" -Fc \
  > "$DEST/postgres.dump"

tar czf "$DEST/attachments.tgz" -C /opt/docuseal data 2>/dev/null || true

find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +"$RETAIN_DAYS" -exec rm -rf {} +

echo "[$(date -u +%FT%TZ)] backup ok -> $DEST ($(du -sh "$DEST" | cut -f1))"

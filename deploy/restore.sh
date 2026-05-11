#!/usr/bin/env bash
# Restore a backup directory produced by backup.sh.
# Usage: ./deploy/restore.sh /opt/docuseal/backups/YYYYMMDD-HHMMSS

set -euo pipefail

SRC="${1:?usage: restore.sh <backup-dir>}"
[ -f "$SRC/postgres.dump" ] || { echo "missing $SRC/postgres.dump"; exit 1; }

read -r -p "Restore $SRC into running stack? Postgres data will be REPLACED. [yes/N] " ok
[ "$ok" = "yes" ] || exit 1

docker compose exec -T postgres \
  psql -U "${POSTGRES_USER:-docuseal}" -d postgres -c \
  "DROP DATABASE IF EXISTS ${POSTGRES_DB:-docuseal}; CREATE DATABASE ${POSTGRES_DB:-docuseal};"

docker compose exec -T postgres \
  pg_restore -U "${POSTGRES_USER:-docuseal}" -d "${POSTGRES_DB:-docuseal}" --clean --if-exists \
  < "$SRC/postgres.dump"

if [ -f "$SRC/attachments.tgz" ]; then
  tar xzf "$SRC/attachments.tgz" -C /opt/docuseal
fi

docker compose restart app
echo "restore complete from $SRC"

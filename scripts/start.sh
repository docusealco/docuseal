#!/bin/sh
set -e
DB=/data/docuseal/db.sqlite3
mkdir -p /data/docuseal
if [ ! -f "$DB" ]; then
  echo "[start.sh] DB missing — restoring from R2 via litestream..."
  litestream restore -if-replica-exists -config /etc/litestream.yml "$DB" || echo "[start.sh] WARN: restore failed; starting empty."
fi
exec litestream replicate -config /etc/litestream.yml -exec "/app/bin/bundle exec puma -C /app/config/puma.rb --dir /app"

#!/bin/sh
set -eu
secret_file=/run/secrets/docuseal_secret_key_base
[ -s "$secret_file" ] || { echo "Application secret is missing" >&2; exit 1; }
SECRET_KEY_BASE=$(cat "$secret_file")
export SECRET_KEY_BASE
exec /app/bin/bundle exec puma -C /app/config/puma.rb --dir /app

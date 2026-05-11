#!/usr/bin/env bash
# Post-deploy smoke check. Returns non-zero if anything looks wrong.
# Usage: deploy/health_check.sh [host]

set -uo pipefail

HOST="${1:-$(grep ^HOST= deploy/.env 2>/dev/null | cut -d= -f2)}"
HOST="${HOST:-e-sign.360dmmc.com}"
FAIL=0

check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  ✓ $label"
  else
    echo "  ✗ $label"
    FAIL=1
  fi
}

echo "== containers =="
check "app running"      bash -c "docker compose ps app | grep -q ' Up'"
check "postgres healthy" bash -c "docker compose ps postgres | grep -q 'healthy'"

echo "== database =="
check "pg_isready" docker compose exec -T postgres pg_isready -U "${POSTGRES_USER:-docuseal}"

echo "== app =="
check "puma listening on 3000" docker compose exec -T app bash -c "ss -tln 2>/dev/null | grep -q ':3000' || netstat -tln 2>/dev/null | grep -q ':3000'"

echo "== HTTP =="
code=$(curl -sk -o /dev/null -w "%{http_code}" "https://$HOST/" --max-time 10 || echo "000")
if [ "$code" = "200" ] || [ "$code" = "302" ] || [ "$code" = "301" ]; then
  echo "  ✓ https://$HOST/ -> $code"
else
  echo "  ✗ https://$HOST/ -> $code"
  FAIL=1
fi

echo "== TLS =="
if echo | openssl s_client -connect "$HOST:443" -servername "$HOST" -verify_return_error 2>/dev/null | grep -q "Verify return code: 0"; then
  echo "  ✓ TLS cert valid"
else
  echo "  ✗ TLS cert invalid or unreachable"
  FAIL=1
fi

if [ "${DOCUSEAL_API_KEY:-}" != "" ]; then
  echo "== API =="
  api_code=$(curl -sk -o /dev/null -w "%{http_code}" \
    -H "X-Auth-Token: $DOCUSEAL_API_KEY" \
    "https://$HOST/api/templates?limit=1" --max-time 10 || echo "000")
  if [ "$api_code" = "200" ]; then
    echo "  ✓ API token valid"
  else
    echo "  ✗ API check returned $api_code"
    FAIL=1
  fi
else
  echo "  - skipped API check (set DOCUSEAL_API_KEY to enable)"
fi

echo
[ $FAIL -eq 0 ] && echo "ALL OK" || echo "FAILURES PRESENT"
exit $FAIL

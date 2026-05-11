#!/usr/bin/env bash
# Validate upload_template.py + send_batch.py against the LOCAL docker stack.
# Catches script bugs before we point them at prod.
#
# Prerequisites:
#   1. Local stack running: docker compose ps shows app + postgres Up
#   2. Admin user created (you said you did this earlier)
#   3. API token generated in the local UI:
#        Settings -> API -> copy the token
#   4. Export it:
#        export DOCUSEAL_API_KEY=<paste-token>
#   5. (Optional) export TEST_RECIPIENT=<your-real-email> to receive the test invite.
#      Without SMTP configured locally, the email won't send -- but the API call
#      still creates the submission, which exercises send_batch.py end-to-end.
#
# Usage: deploy/deliverability/local_validate.sh

set -euo pipefail

: "${DOCUSEAL_API_KEY:?Set DOCUSEAL_API_KEY (Settings -> API in the local UI)}"

export DOCUSEAL_URL="http://localhost:3000"
export DOCUSEAL_API_KEY
TEST_RECIPIENT="${TEST_RECIPIENT:-validate@example.invalid}"

echo "==> 1. Health probe"
code=$(curl -s -o /dev/null -w "%{http_code}" "$DOCUSEAL_URL/api/templates?limit=1" \
  -H "X-Auth-Token: $DOCUSEAL_API_KEY")
[ "$code" = "200" ] || { echo "API auth failed (HTTP $code) -- check token"; exit 1; }
echo "    API auth OK"

echo "==> 2. Upload test template"
TPL_OUT=$(python deploy/deliverability/upload_template.py)
echo "$TPL_OUT"
TEMPLATE_ID=$(echo "$TPL_OUT" | grep -oP 'template_id=\K\d+')
[ -n "$TEMPLATE_ID" ] || { echo "could not parse template_id"; exit 1; }
export TEMPLATE_ID
echo "    template_id=$TEMPLATE_ID"

echo "==> 3. Tiny send batch (1 recipient)"
TMP_CSV=$(mktemp --suffix=.csv)
trap 'rm -f "$TMP_CSV"' EXIT
cat > "$TMP_CSV" <<EOF
email,name,provider
$TEST_RECIPIENT,Local Validate,test
EOF

POLL_SECS=20 python deploy/deliverability/send_batch.py "$TMP_CSV" || rc=$?
rc=${rc:-0}

echo
if [ "$rc" -eq 0 ]; then
  echo "LOCAL VALIDATION PASSED. Scripts work against a live DocuSeal stack."
else
  echo "LOCAL VALIDATION FAILED (rc=$rc). Fix script issues before pointing at prod."
fi
exit "$rc"

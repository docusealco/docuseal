"""DocuSeal deliverability batch sender.

Reads a CSV of test recipients, sends one signing-request submission per row
through the deployed DocuSeal API, then polls for SMTP send confirmation and
open events. Reports per-provider results.

Usage:
    DOCUSEAL_URL=https://e-sign.360dmmc.com \\
    DOCUSEAL_API_KEY=xxxxx \\
    TEMPLATE_ID=42 \\
    python deploy/deliverability/send_batch.py recipients.csv

What this DOES verify:
    - SMTP accepted the message (DocuSeal records send result per submitter)
    - Recipient opened the signing link within the polling window

What this does NOT verify (requires manual inspection of mailboxes you own):
    - Inbox vs Spam folder placement
    - DKIM/SPF/DMARC header alignment
    - Mail-tester.com style content scoring (use that separately for one address)
"""

import csv
import os
import sys
import time
from collections import Counter, defaultdict

import requests

URL = os.environ["DOCUSEAL_URL"].rstrip("/")
KEY = os.environ["DOCUSEAL_API_KEY"]
TEMPLATE_ID = int(os.environ["TEMPLATE_ID"])
POLL_SECS = int(os.environ.get("POLL_SECS", "180"))

S = requests.Session()
S.headers.update({"X-Auth-Token": KEY, "Content-Type": "application/json"})


def create_submission(email: str, name: str) -> int:
    r = S.post(
        f"{URL}/api/submissions",
        json={
            "template_id": TEMPLATE_ID,
            "send_email": True,
            "submitters": [{"email": email, "name": name, "role": "Client"}],
        },
        timeout=30,
    )
    r.raise_for_status()
    payload = r.json()
    sub = payload[0] if isinstance(payload, list) else payload
    return sub["submission_id"] if "submission_id" in sub else sub["id"]


def fetch_submission(sid: int) -> dict:
    r = S.get(f"{URL}/api/submissions/{sid}", timeout=30)
    r.raise_for_status()
    return r.json()


def main(csv_path: str) -> int:
    rows: list[dict] = []
    with open(csv_path, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            rows.append(row)

    print(f"sending {len(rows)} submissions to {URL} (template {TEMPLATE_ID})")
    sent: list[tuple[dict, int]] = []
    send_errors: list[tuple[dict, str]] = []
    for row in rows:
        try:
            sid = create_submission(row["email"], row["name"])
            sent.append((row, sid))
            print(f"  ✓ {row['email']:40s} -> submission {sid}")
        except requests.HTTPError as e:
            send_errors.append((row, f"{e.response.status_code} {e.response.text[:120]}"))
            print(f"  ✗ {row['email']:40s} -> {e}")
        time.sleep(0.5)

    print(f"\npolling for {POLL_SECS}s to capture sent/opened events...")
    deadline = time.time() + POLL_SECS
    final: dict[int, dict] = {}
    while time.time() < deadline and len(final) < len(sent):
        for row, sid in sent:
            if sid in final:
                continue
            try:
                sub = fetch_submission(sid)
                submitter = sub["submitters"][0] if sub.get("submitters") else {}
                if submitter.get("sent_at") or submitter.get("opened_at"):
                    final[sid] = {"row": row, "submitter": submitter}
            except requests.HTTPError:
                pass
        time.sleep(10)

    by_provider: dict[str, Counter] = defaultdict(Counter)
    for row, sid in sent:
        provider = row.get("provider", "unknown")
        by_provider[provider]["total"] += 1
        st = final.get(sid, {}).get("submitter", {})
        if st.get("sent_at"):
            by_provider[provider]["sent"] += 1
        if st.get("opened_at"):
            by_provider[provider]["opened"] += 1

    print("\n=== Results ===")
    print(f"API submission errors: {len(send_errors)}")
    for row, err in send_errors:
        print(f"  - {row['email']}: {err}")
    print()
    print(f"{'provider':<12}{'total':>8}{'sent':>8}{'opened':>8}{'sent%':>8}{'open%':>8}")
    for prov, c in sorted(by_provider.items()):
        total = c["total"] or 1
        print(
            f"{prov:<12}{c['total']:>8}{c['sent']:>8}{c['opened']:>8}"
            f"{100 * c['sent'] / total:>7.0f}%{100 * c['opened'] / total:>7.0f}%"
        )
    print(
        "\nNote: 'opened' captures only recipients who clicked the link or "
        "whose mail client loaded the tracking pixel within the poll window. "
        "It is NOT a spam-folder check. Inspect test mailboxes you own to "
        "verify inbox placement."
    )
    return 0 if not send_errors else 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "recipients.csv"))

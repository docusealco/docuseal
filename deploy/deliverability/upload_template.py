"""Upload the test service-agreement PDF to DocuSeal as a template.

Prints the resulting template_id so you can plug it straight into send_batch.py.

Usage:
    DOCUSEAL_URL=https://e-sign.360dmmc.com \\
    DOCUSEAL_API_KEY=xxxxx \\
    python deploy/deliverability/upload_template.py [path-to-pdf]
"""

import base64
import os
import sys
from pathlib import Path

import requests

URL = os.environ["DOCUSEAL_URL"].rstrip("/")
KEY = os.environ["DOCUSEAL_API_KEY"]

DEFAULT_PDF = Path(__file__).parent.parent / "test-fixtures" / "service_agreement.pdf"
pdf_path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_PDF
if not pdf_path.exists():
    sys.exit(f"PDF not found: {pdf_path}")

with pdf_path.open("rb") as f:
    pdf_b64 = base64.b64encode(f.read()).decode("ascii")

# DocuSeal POST /api/templates/pdf:
# https://www.docuseal.com/docs/api#create-a-template-from-pdf
payload = {
    "name": "Smoke Test Service Agreement",
    "documents": [
        {
            "name": pdf_path.stem,
            "file": pdf_b64,
            "fields": [
                {"name": "Client Signature", "type": "signature", "role": "Client",
                 "areas": [{"x": 0.15, "y": 0.78, "w": 0.35, "h": 0.04, "page": 0}]},
                {"name": "Client Name",      "type": "text",      "role": "Client",
                 "areas": [{"x": 0.15, "y": 0.74, "w": 0.35, "h": 0.03, "page": 0}]},
                {"name": "Client Date",      "type": "date",      "role": "Client",
                 "areas": [{"x": 0.15, "y": 0.82, "w": 0.20, "h": 0.03, "page": 0}]},
            ],
        }
    ],
}

r = requests.post(
    f"{URL}/api/templates/pdf",
    json=payload,
    headers={"X-Auth-Token": KEY, "Content-Type": "application/json"},
    timeout=60,
)
r.raise_for_status()
tpl = r.json()
print(f"template_id={tpl['id']}")
print(f"name={tpl.get('name')}")
print(f"slug={tpl.get('slug')}")
print(f"\nNext: TEMPLATE_ID={tpl['id']} python deploy/deliverability/send_batch.py recipients.csv")

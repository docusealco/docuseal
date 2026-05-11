"""Generate a placeholder service-agreement PDF for DocuSeal smoke testing.

This is fictional sample text only. Not legal advice, not a real contract.
"""

from pathlib import Path

from reportlab.lib.pagesizes import LETTER
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer

OUT = Path(__file__).parent / "service_agreement.pdf"

styles = getSampleStyleSheet()
h1, body = styles["Title"], styles["BodyText"]

story = [
    Paragraph("PROFESSIONAL SERVICES AGREEMENT", h1),
    Spacer(1, 18),
    Paragraph(
        "This Agreement (\"Agreement\") is entered into as of the date last "
        "signed below (\"Effective Date\") between <strong>360DMMC LLC</strong> "
        "(\"Provider\") and the undersigned <strong>Client</strong>.",
        body,
    ),
    Spacer(1, 12),
    Paragraph("<strong>1. Services.</strong> Provider agrees to deliver the services described in any mutually executed statement of work.", body),
    Paragraph("<strong>2. Fees.</strong> Client shall pay Provider the fees set forth in each statement of work, net 30 days from invoice.", body),
    Paragraph("<strong>3. Term.</strong> This Agreement begins on the Effective Date and continues until terminated by either party with 30 days written notice.", body),
    Paragraph("<strong>4. Confidentiality.</strong> Each party agrees to protect the other's confidential information using reasonable care for two (2) years following disclosure.", body),
    Paragraph("<strong>5. Limitation of Liability.</strong> Neither party shall be liable for indirect, incidental, or consequential damages arising out of this Agreement.", body),
    Paragraph("<strong>6. Governing Law.</strong> This Agreement is governed by the laws of the jurisdiction in which Provider is incorporated.", body),
    Spacer(1, 24),
    Paragraph("<strong>SIGNATURES</strong>", body),
    Spacer(1, 24),
    Paragraph("Provider name: ____________________________", body),
    Paragraph("Provider signature: ________________________", body),
    Paragraph("Date: ____________________________________", body),
    Spacer(1, 18),
    Paragraph("Client name: ______________________________", body),
    Paragraph("Client signature: __________________________", body),
    Paragraph("Date: ____________________________________", body),
]

SimpleDocTemplate(str(OUT), pagesize=LETTER).build(story)
print(f"wrote {OUT} ({OUT.stat().st_size} bytes)")

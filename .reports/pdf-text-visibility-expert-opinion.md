# Expert Opinion: Should PDF Text Be Made Visible to All Users?

**Date**: 2026-02-25
**Branch**: extract-content-from-pdf
**Question from product team**: Should the extracted PDF text (currently in `sr-only` divs) be made available to non-AT (non-assistive technology) users?

---

## Current Implementation

The implementation extracts raw text from each PDF page via Pdfium's `FPDFText_GetText` API during the document processing pipeline (`lib/templates/process_document.rb` → `extract_page_texts()`). The text is stored in blob metadata at `attachment.metadata['pdf']['pages_text']` as a hash keyed by page index string (e.g., `{ "0" => "...", "1" => "..." }`).

In both `app/views/submit_form/show.html.erb` and `app/views/submissions/show.html.erb`, the text is rendered as:

```erb
<% if (page_text = document.blob.metadata.dig('pdf', 'pages_text', index.to_s)).present? %>
  <div class="sr-only" role="region" aria-label="Page N text content"><%= page_text %></div>
<% end %>
```

The `sr-only` class (Tailwind: `position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0,0,0,0)`) hides this content from all sighted users while keeping it in the DOM for screen readers. The text is placed directly after the page `<img>` and before the absolutely-positioned field overlay div.

---

## 1. The Case FOR Making Text Visible to All Users

### Browser "Find in Page" (Cmd/Ctrl+F)

This is the strongest argument for keeping text in the DOM — and it already works with `sr-only`. Content hidden with `sr-only` (CSS clip, not `display:none` or `visibility:hidden`) IS searchable via browser Find. This means the current implementation already provides this benefit without any additional work. Sighted users who press Cmd+F and search for a word that appears in the document will get a match — they just will not be able to see the highlighted result because it's a 1×1px invisible element. This is a meaningful half-win, but it's not the full experience.

If text were rendered visibly, Find in Page would highlight the matched text in context, which is genuinely useful for long contracts where a user is scanning for a specific clause.

### Copy/Paste

Users frequently need to copy text from documents they are signing. The page images are raster renders — nothing is selectable. If users need to copy a reference number, an address, or a clause, they must download the PDF separately. Visible text would eliminate this friction entirely.

### Machine Translation / Browser Translation

Chrome's built-in translation, third-party extensions (e.g., DeepL), and OS-level translation tools all require actual visible text in the DOM. With `sr-only`, the text is technically in the DOM but browser translation tools may or may not act on hidden content — behavior is inconsistent across browsers. For multilingual signers who receive contracts in a language they are less fluent in, being able to trigger instant browser translation is a meaningful accessibility gain beyond the AT population.

### Low-Vision Users Who Are Not Screen Reader Users

WCAG explicitly distinguishes screen reader users from the broader low-vision population. Someone with 20/200 vision using 400% browser zoom, or someone using browser text-size overrides, is not served by `sr-only`. They interact with the visual rendering. They cannot read a raster JPEG zoomed to 400% — text becomes a blocky mess. Exposed text would reflow properly with zoom and respect OS font size preferences.

### Cognitive Accessibility

Users with dyslexia, ADHD, or reading disabilities often benefit from using browser extensions like Helperbird, BeeLine Reader, or OpenDyslexic that restyle text for easier reading. These tools only work on rendered DOM text. A sighted person with dyslexia who uses a rendering aid gets zero benefit from the current implementation.

### Low-Bandwidth / Low-End Devices

JPEG page previews are already lazy-loaded and compressed, but on very slow connections or older devices, the images may not load at all. If text were visible, the document content would degrade gracefully — users could read the contract even if images are slow or fail.

### Print Accessibility

When users print the submission preview or signing view, `sr-only` content does not print (CSS `@media print` typically hides it). Visible text would print, giving sighted users a readable text version alongside or instead of image renders.

---

## 2. The Case Against / Concerns

### Layout Fidelity vs. Extracted Text Mismatch — This Is the Decisive Concern

Pdfium's `FPDFText_GetText` returns Unicode text in the order it appears in the PDF's content stream. For simple, linearly-structured PDFs (one-column contracts, standard letter format), this order is identical to reading order and the output is clean prose.

For complex PDFs — multi-column layouts, tables, forms with floating labels, PDFs that are digitally-created but with non-logical drawing order — the extracted text can be:
- Out of reading order (columns mixed together)
- Missing separators between adjacent text runs (words concatenated with no space)
- Duplicated (headers and footers repeated on every page)
- Garbled (text drawn right-to-left in the content stream for visual effect but extracted left-to-right by Pdfium)

DocuSeal's actual users will be sending a wide variety of PDFs. Contracts from Word exports are usually fine. Scanned-with-OCR PDFs, Adobe InDesign exports, and PDFs generated from complex Excel templates are often problematic. If the visible text shown to a signer says something different from what the page image shows — even just word ordering that differs from what is visually readable — this creates a trust and legal problem. A signer might rely on the extracted text version to read a clause and then dispute having signed a different version of that clause.

This risk is specific to DocuSeal's legal document use case. It is not a fatal concern for Google Drive file viewer (viewing only) but is a real concern in signing workflows where the exact text has legal weight.

### Visual Noise in the Signing Flow

The signing interface is carefully designed around a focused, linear task: read the document, complete fields, sign. Adding a visible text block adjacent to or beneath each page image would require a significant UX design decision about how it coexists with:
- Overlaid form fields (which are absolutely positioned over the page image)
- The sticky signature/form panel at the bottom
- The document title header

A naive implementation — dump the text in a visible div right after the image — would make the page look like a duplicated document with the image on top and a text transcript below. This would confuse nearly all users.

### Duplicate Content Perception

Sighted users who see both the rendered PDF page and a text transcript directly below it will immediately ask "why is there a text version of what I can already see?" If the text ordering is slightly different from the visual layout, the confusion escalates to "is this the same document?" This is not a hypothetical — it is the exact UX problem that early PDF viewer accessibility overlays created.

### Performance

Text extraction already happens at document processing time and is stored in metadata. Rendering it visible adds no server-side cost. The concern is DOM size: a 15-page dense contract may have 20,000+ characters of extracted text. All of it rendered in `sr-only` divs is already in the DOM; making it visible does not change DOM size. Performance is therefore a non-issue here specifically.

### Text Extraction Completeness

`extract_page_texts()` caps at `MAX_NUMBER_OF_PAGES_PROCESSED = 15` pages. Documents beyond page 15 have no extracted text at all. If a visible text view were added, users would see text for pages 1-15 and nothing for pages 16+. This inconsistency would be confusing and would need to be addressed before shipping a visible text feature.

---

## 3. Patterns from Other Document Tools

### Google Docs Viewer (docs.google.com/viewer)

Uses a canvas/SVG rendering approach. The actual text layer is rendered invisibly over the canvas in correctly-positioned spans — exact pixel coordinates from the PDF content stream. Find in Page works because the text spans are in the DOM. The text is not visible as a separate block; it overlays the rendered image at the correct coordinates. This is the gold standard but requires knowing the exact bounding box of every character — which the current DocuSeal implementation does NOT do (it stores only the plain text string, not character positions).

### Adobe Acrobat Web (documentcloud.adobe.com)

Renders PDF as a canvas with a separate invisible text layer using absolute-positioned spans at the correct character positions. This enables accurate selection, copy/paste, and Find. Again, requires coordinate-level text positioning data.

### DocuSign

Does not expose extracted text at all in the signing flow. The page is rendered as an image, and no text layer is added. Accessibility is handled through a separate "accessible view" feature that presents a simplified HTML form with field labels and instructions — it does not attempt to show the document text itself. DocuSign's approach acknowledges that trying to make arbitrary PDFs accessible inline is too risky; it separates the accessible interface from the document rendering entirely.

### GOV.UK

For documents published on GOV.UK, the standard pattern is to always provide an HTML version alongside the PDF. The HTML version is a fully authored, human-reviewed alternative — not an automated extraction. Gov.uk's accessibility guidance explicitly states that automatically extracted text from PDFs is unreliable and should not be treated as an accessible alternative without human review. The standard is: if you need an accessible document, publish HTML.

### PDF.js (Mozilla's open-source PDF renderer, used in Firefox)

Uses the same coordinate-based invisible text layer approach as Google and Adobe, allowing Find and selection on the exact rendered text. The text spans are positioned to overlay each character on the canvas render. This approach requires per-character bounding box data.

---

## 4. WCAG 2.2 Perspective

### Does hiding text from sighted users create compliance issues?

No. WCAG 2.2 does not require that all content be visible to all users. What it requires is that content and functionality available via one modality (e.g., visual) also be available via other modalities (e.g., keyboard, AT). The `sr-only` pattern is explicitly supported by WCAG — it is the recommended technique for providing accessible names and supplementary context to AT users without cluttering the visual interface (WCAG Technique C7: Using CSS to hide a portion of the link text).

The content in the `sr-only` divs is supplementary — it provides a text alternative for image-rendered PDF pages, satisfying WCAG 1.1.1 (Non-text Content) for AT users. Sighted users are served by the visual image render. This is perfectly compliant.

### Does making it visible help WCAG conformance?

Not meaningfully. WCAG is already satisfied by the current `sr-only` implementation for the criteria it addresses. Visibility to sighted users does not improve WCAG scores because the criteria being addressed (1.1.1, 1.3.1) are about AT access, not sighted-user access.

However, there is one WCAG criterion where visible text would help that `sr-only` does not:

**1.4.4 Resize Text (Level AA)**: Content rendered as an image cannot be resized without loss of quality. If sighted users with low vision rely on browser text zoom, the JPEG page renders will degrade. Visible text would reflow and scale properly. However, DocuSeal's page image approach is a standard PDF viewer pattern, and WCAG 1.4.4 has an exception for "images of text" — text in the page preview images is exempt from this criterion if the same visual presentation cannot reasonably be achieved using actual text.

**1.4.5 Images of Text (Level AA)**: The pages-as-images approach technically fails this criterion if the information conveyed by the text in those images could be presented as actual text without significantly changing the presentation. However, this criterion also has an exception for "essential" presentations — and a PDF document signing interface where layout fidelity is legally important qualifies as essential. Enterprise document tools universally use this exception.

### Does anything in WCAG prohibit `sr-only` content with `role="region"`?

One nuance: WCAG Technique ARIA20 (Using the region role to identify a region of the page) requires that landmark regions be named and that they not be overused, because too many landmark regions make AT navigation noisy. A 15-page document with `role="region"` on each page's text block creates 15 landmarks in the AT landmark navigation menu. This is a real usability concern for screen reader users, not a WCAG failure per se, but it is worth reconsidering whether `role="region"` is appropriate here.

The correct role for a supplementary text alternative that is not a primary navigation landmark is probably no explicit ARIA role at all, or `role="doc-pagebreak"` before each page with a well-labeled container. Alternatively, wrapping all pages in a single `role="document"` or `role="article"` would create one landmark instead of 15. This is a minor concern but worth addressing.

---

## 5. Recommended UX Patterns if Text Were Exposed to All Users

If the product team decides to expose text to sighted users, here are the options ranked by quality:

### Option A: Coordinate-Positioned Invisible Text Layer (Like PDF.js / Google Docs)

Requires per-character bounding box data from Pdfium — which IS available via `FPDFText_GetCharBox` and `FPDFText_GetRect` (both are already attached in `lib/pdfium.rb`). Each character or word would be rendered in an absolutely-positioned `<span>` over the page image at the correct coordinates. Users could select text, copy it, and trigger browser Find with highlighted results at the correct positions.

**Verdict**: Best possible implementation. Provides all the sighted-user benefits without any visual noise. Requires significant additional engineering (per-character coordinates, word grouping, scaling to displayed size, handling RTL text). This is the right long-term target.

### Option B: Optional "Text View" Toggle

A toggle button in the document header switches between Image View (current) and Text View (plain accessible HTML). In Text View, page images are replaced with the extracted text in a readable, styled `<article>` element. The toggle state persists per-session via localStorage.

**Verdict**: Good for specific use cases (mobile users on slow connections, low-vision users who prefer reflowing text, users who want to copy text). The risk of text extraction quality issues is mitigated because the label clearly says "text view" — users understand they are seeing a different representation. This is achievable with moderate engineering effort.

### Option C: Collapsible "Page Text" Accordion Below Each Page

A `<details>/<summary>` element below each page image, collapsed by default, labeled "Show text content for page N". Sighted users who want the text can expand it; others ignore it.

**Verdict**: Functional but poor UX. Most users will never discover it. The pattern is used in low-effort accessibility retrofits and signals "we added text as an afterthought." It also suffers from the layout mismatch trust problem: once visible, users may compare the accordion text to the image and notice discrepancies.

### Option D: Full-Document Side Panel or Drawer

A "Document Text" panel accessible via a toggle button, showing the full extracted text as a continuous readable document. Similar to how some PDF readers have a "reading mode" or "outline" panel.

**Verdict**: Good for power users, low discoverability for casual users. Avoids the per-page layout mismatch problem by presenting the text holistically. The side panel approach fits the existing UI pattern (the `parties_view` panel on the right in `submissions/show.html.erb` shows a similar right-panel design). Engineering effort is moderate.

### Option E: Keep sr-only, It's Sufficient

The current implementation serves AT users, satisfies all applicable WCAG criteria, and avoids the layout-fidelity trust problem inherent in exposing extracted text to sighted users. For a legal document signing platform, this is a defensible and reasonable product position.

---

## 6. Recommendation

**Keep the `sr-only` implementation as the primary path. Do not expose extracted text to sighted users in the current signing and preview flow.**

Here is the reasoning:

**The legal context is the deciding factor.** DocuSeal is not a PDF viewer or a reading application. It is a document signing platform. Users sign documents — they attest to the content of a specific visual representation. Pdfium's `FPDFText_GetText` produces reading-order text that may differ from visual order in complex PDFs. If a signer reads a clause from the extracted text version and signs, then later claims the text they relied on was different from the image they were presented, that creates ambiguity in the evidentiary record. The JPEG page images are the canonical document representation. Extracted text is a best-effort approximation.

**The sr-only approach already delivers most of the incidental benefits.** Browser Find in Page works on `sr-only` content (it is only hidden via CSS clip, not `display:none`). The text is in the DOM. It contributes to browser translation in most engines. It is fully searchable by crawlers. The only concrete benefit blocked by `sr-only` is user-initiated text selection/copy, which requires visible or `user-select: text` styled text.

**If copy/paste is a priority, implement it narrowly.** If the product team hears repeated feedback that users want to copy text from documents, the right response is to add a per-page "Copy page text" button that copies the extracted text to clipboard without rendering it visibly on the page. This gives users the utility without the layout-fidelity trust problem. The button can be visually subtle (small icon button with accessible label) and appear on hover over the page image.

**The right long-term investment is the coordinate text layer (Option A).** If the team wants to invest in a proper text-layer feature, the Pdfium bindings already include `FPDFText_GetCharBox` and `FPDFText_GetRect`. Building coordinate-positioned text spans would provide Find-in-Page highlighting at correct positions, text selection, copy/paste, and low-vision zoom support — all without the layout mismatch trust problem, because the text would visually align with the image underneath. This is non-trivial engineering (a few days of work) but is the architecturally correct solution.

**Fix the `role="region"` overuse.** Regardless of the visibility decision, 15 `role="region"` landmarks per document is a real AT navigation problem. Consider removing the role entirely and relying only on the `aria-label` on a plain `<div>`, or wrapping all page text divs in a single `role="document"` or `role="article"` region per document.

### Decision Matrix

| Concern | sr-only (current) | Visible text block | Text view toggle | Coordinate layer |
|---|---|---|---|---|
| WCAG compliance | Full | Full | Full | Full |
| Layout mismatch risk | None (hidden) | High | Medium (clearly labeled) | None (aligned) |
| Copy/paste for sighted | No | Yes | Yes | Yes |
| Find in Page highlighting | No (match not visible) | Yes | Yes | Yes |
| Low-vision reflow | No | Yes | Yes | Yes |
| Browser translation | Partial | Yes | Yes | Yes |
| Legal/trust risk | None | Real | Low | None |
| Engineering effort | Done | Low | Medium | High |
| UX confusion | None | High | Low | None |

**Recommendation summary**: Ship Option E now (the `sr-only` implementation is correct). Add a narrow "Copy page text" icon button for copy/paste utility. Plan Option A (coordinate text layer) as a future accessibility investment.

---

## Minor Issues to Fix in the Current Implementation

1. **Remove `role="region"` from page text divs** or replace all per-page regions with a single per-document region. 15 unnamed sub-landmarks per document creates AT navigation clutter. Per-page text divs should be plain `<div>` with `aria-label` only, or use `role="note"`.

2. **15-page cap consistency**: If a document exceeds 15 pages, pages 16+ have no text alternative at all. Consider whether the `sr-only` div should be omitted (as currently) or whether a fallback message ("Text content not available for this page") is more honest for AT users.

3. **Scanned PDF handling**: The current implementation gracefully omits `pages_text` for scanned PDFs. This is correct — do not emit a misleading sr-only div for pages with no extractable text. The current code handles this properly.

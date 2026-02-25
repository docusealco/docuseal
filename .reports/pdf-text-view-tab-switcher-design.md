# PDF View / Text View Tab Switcher: Accessibility Design Report

**Date**: 2026-02-25
**Branch**: extract-content-from-pdf
**Author**: Accessibility specialist review
**Question origin**: Product team request for "PDF View / Text View" tab switcher on document pages

---

## Prior Art in This Codebase

The previous expert opinion (`pdf-text-visibility-expert-opinion.md`) recommended keeping `sr-only` as the primary path and warned that exposing extracted text to sighted users creates a layout-fidelity trust problem in a legal document signing context. The current implementation stores extracted text in `attachment.metadata['pdf']['pages_text']` and renders it in `sr-only` divs after each page image.

This report evaluates the specific "tab switcher" UI pattern now requested and gives concrete implementation guidance.

---

## 1. The ARIA Tab Pattern: What Is Required

### Is it a well-established pattern?

Yes. The ARIA Authoring Practices Guide (APG) defines the Tab Panel widget as a first-class interactive widget with a documented keyboard interaction model. It is one of the most commonly used ARIA patterns. Examples: browser DevTools, VS Code settings panels, GOV.UK design system, and virtually every design system (DaisyUI, shadcn, Headless UI).

### Required ARIA structure

```html
<!-- Tab list container -->
<div role="tablist" aria-label="Document view options">

  <!-- Individual tabs -->
  <button role="tab"
          id="tab-pdf"
          aria-selected="true"
          aria-controls="panel-pdf"
          tabindex="0">
    PDF View
  </button>

  <button role="tab"
          id="tab-text"
          aria-selected="false"
          aria-controls="panel-text"
          tabindex="-1">
    Text View
  </button>
</div>

<!-- Panel for PDF View (active) -->
<div role="tabpanel"
     id="panel-pdf"
     aria-labelledby="tab-pdf"
     tabindex="0">
  <!-- PDF page images + overlaid fields -->
</div>

<!-- Panel for Text View (hidden) -->
<div role="tabpanel"
     id="panel-text"
     aria-labelledby="tab-text"
     tabindex="0"
     hidden>
  <!-- Structured HTML text -->
</div>
```

### Required keyboard behavior (WCAG 2.1.1 + APG)

| Key | Behavior |
|-----|----------|
| Tab | Moves focus INTO the tab list (to the active tab), then OUT OF the tab list to the first focusable element in the active panel |
| Arrow Left / Arrow Right | Moves focus between tabs within the tablist; DOES NOT change content — content changes happen on focus (automatic activation) OR on Enter/Space (manual activation) |
| Home | Focus first tab |
| End | Focus last tab |
| Enter / Space | Activates a tab if using manual activation model |

**Automatic vs. manual activation**: For two-tab switchers with fast content swaps (no async load), automatic activation (content switches as you arrow between tabs) is acceptable. If Text View requires any async work (API call, processing), use manual activation (Tab content only switches on Enter/Space) to prevent jarring focus/content shifts.

### tabindex roving pattern

Only the currently selected tab has `tabindex="0"`. All other tabs have `tabindex="-1"`. This ensures Tab key only hits the active tab, not every tab in sequence. Arrow keys cycle through all tabs.

### Panel tabindex

`tabindex="0"` on the panel div makes it focusable so pressing Tab from the active tab moves focus into the panel. This is required by APG. If the panel has focusable children (form fields, buttons), `tabindex` on the panel itself can be omitted — focus will land on the first focusable child.

---

## 2. Text View: What Should It Contain

### The honest answer about Pdfium plain text

Pdfium's `FPDFText_GetText` returns Unicode text in content-stream order. For standard contracts produced by Word, Google Docs, or document-generation libraries, content-stream order matches reading order and produces clean prose with `\r\n` line breaks. This is what DocuSeal's actual documents will mostly be.

For the purposes of a text accessibility view, the goal is not "identical representation of the PDF" — it is "readable, searchable, reflowable alternative for users who cannot access the image rendering." That is a different and more achievable bar.

### Evaluation of approaches

#### Approach A: `<pre>` or whitespace-preserved `<p>` tags

**What it delivers**: Raw text with whitespace preserved. No semantic structure. Line breaks from the raw string become visible in `<pre>` or require `white-space: pre-wrap` in `<p>`.

**Accessibility value**: Low. `<pre>` is technically for preformatted text (code, ASCII art). Screen readers announce `<pre>` as a "code block" in some modes. More importantly: a raw text dump with no structure has no heading hierarchy, no navigable sections, no landmark regions — AT users cannot skip to relevant sections.

**Recommendation**: Do not use `<pre>`. Use `<p>` with `white-space: pre-wrap` only as a last resort.

#### Approach B: Heuristic parsing

**What it delivers**: Lines matching `/^[A-Z][A-Z\s]{4,}$/` become `<h2>`, numbered lines become `<ol>`, lines starting with `•` or `-` become `<ul>`, everything else becomes `<p>`.

**Accuracy for legal documents**: Surprisingly good. Standard NDA/contract PDFs produced by Word/Google Docs have all-caps or title-case section headings. Numbered clauses are by definition numbered lines. The heuristic does not need to be perfect — it needs to be better than a wall of unseparated text.

**False positive risk**: A sentence beginning with "1." that is NOT a list item gets wrapped in `<ol>`. This is a minor misrepresentation. In a legal context, the risk is acceptable when the text view is clearly labeled as an accessibility alternative, not a legal copy.

**Recommended rules** (conservative, order matters):

```ruby
# 1. Split on \r\n or \n
# 2. Skip blank lines (preserve as paragraph breaks)
# 3. ALL_CAPS line 3+ chars with no sentence punctuation → <h2>
# 4. Line matching /^\d+\.\s/ → accumulate as <ol><li>
# 5. Line matching /^[•\-\*]\s/ → accumulate as <ul><li>
# 6. Remaining non-blank lines → <p>
```

**Recommendation**: Use this for an MVP. It is sufficient for the 90% case (Word-generated legal documents). It requires ~50 lines of Ruby in a service object.

#### Approach C: LLM conversion (Claude API)

**What it delivers**: Accurate semantic structure, correct heading levels, properly identified tables, clause detection.

**Why it is wrong for this use case**:

1. **Privacy**: Document content (NDA text, employment agreements, financial disclosures) would leave the customer's instance and be sent to an external API. DocuSeal is self-hosted and open-source specifically because enterprises need data sovereignty. This is a non-starter for most DocuSeal deployments.

2. **Latency**: LLM API calls take 2-10 seconds. Text View would have a loading state that breaks the UX promise of an accessibility alternative. AT users would experience worse performance than sighted users.

3. **Cost**: Per-document API costs at scale are non-trivial and inconsistent with the open-source, self-hosted model.

4. **Accuracy caveat**: LLMs hallucinate. For a legal document where the exact wording matters, an LLM that paraphrases or restructures while parsing could introduce errors that sighted reviewers would not catch.

**Recommendation**: Reject entirely for this use case.

#### Approach D: Pdfium layout data (`text_nodes`)

**What it delivers**: Character-level bounding boxes, font sizes, and positions. Can reconstruct reading order, infer heading level from font size, identify columns, detect table cell boundaries from coordinate alignment.

**What the codebase already has**: `Pdfium::Page#text_nodes` (already implemented in `lib/pdfium.rb`) returns `TextNode` structs with `x`, `y`, `w`, `h`, and `content`. `FPDFText_GetFontSize` is already attached. This is the data needed.

**Recommended use**: Font size analysis. Collect all unique font sizes per page, find the median body text size, and flag runs of text where font size > 120% of median as headings. This is a 30-40 line addition to the processing pipeline.

**Current limitation**: `text_nodes` is per-page and re-computed on demand (not cached in metadata). The processing pipeline already calls `page.text` (the plain string); calling `page.text_nodes` additionally during `extract_page_texts()` would add processing time at document upload.

**Recommendation**: Use for a Phase 2 enhancement if heuristic parsing proves insufficient. Do not block the MVP on this.

### Minimum viable semantic structure

For the MVP, deliver:

1. A single `<article>` per document (not per page) with `lang` attribute matching document locale
2. Per-page sections as `<section aria-label="Page N">` — one heading-level landmark per page
3. Heuristic parsing converting all-caps lines to `<h2>`, numbered lines to `<ol>`, bullets to `<ul>`, rest to `<p>`
4. Full-document single scroll (NOT paginated) — see question 4 for rationale

This is readable, navigable by AT users, and can be produced entirely from the stored `pages_text` metadata without any additional Pdfium calls.

---

## 3. Signing Form Complication

### The core problem

In the signing form (`submit_form/show.html.erb`), the sticky bottom panel contains the Vue 3 submission form component that drives the signing workflow — field navigation, signature capture, completion. This Vue component reads the DOM for `page-container` elements to drive its scroll-to-field logic. A tab switch that replaces the PDF panel with a text panel would break the Vue component's DOM assumptions.

Additionally, in the signing context, the legally relevant representation is the PDF image. The signer is attesting to the document as visually presented. Replacing that with extracted text in the signing flow creates the same trust problem identified in the previous expert opinion.

### Evaluation of options

#### Option A: Text View is read-only; switch back to PDF View to sign

**UX model**: Two-mode. User can read in Text View, then explicitly return to PDF View to complete fields.

**Accessibility impact**: For AT users (screen reader, keyboard-only), this is workable. The tab switch is a clear, explicit action. However, it creates a redundant navigation burden: AT user reads text in Text View, must switch back to PDF View, must re-navigate to the first incomplete field.

**Implementation complexity**: Low. Text panel has no form fields. Vue component remains in PDF panel and is not affected.

**Verdict**: Acceptable for MVP. The return-to-sign burden is real but not severe for a two-page NDA. For a 40-page complex form, it is a problem.

#### Option B: Inline form fields in Text View

**What it would require**: Mapping each form field's page/coordinates to a position in the heuristic-parsed text, then inserting Vue field components at those positions. This requires coordinate-to-text-position mapping that the current data model does not support — you would need to store character bounding boxes (Approach D data) and match field bounding boxes (from `fields_index` areas) to character positions.

**Verdict**: Reject for MVP. Engineering effort is 2-3 weeks minimum. The data infrastructure does not exist. This is a future Phase 3 investment if the product team commits to it.

#### Option C: Text View with sticky "Continue Signing" CTA

**What it is**: Text View shows the document text. At the bottom (sticky) is a persistent call-to-action: "Return to PDF View to complete signing" that scrolls or switches to the PDF tab.

**Accessibility impact**: This is good. AT users can read the full document without losing context, then explicitly navigate to the completion action. The CTA is focusable, labeled, and persistent.

**Implementation complexity**: Low. The sticky CTA is just a button in the Text panel that calls the tab-switch function and scrolls to the first incomplete field.

**Verdict**: This is the right choice for the signing form MVP. Minimal engineering, clear user model, accessible.

#### Option D: Text View as a drawer/panel, not a full tab replace

**What it is**: Text View does not replace the PDF panel. Instead, a side panel or overlay drawer shows the text alongside the PDF. On mobile, it would be a bottom sheet.

**Problem in signing context**: The signing form already has a fixed bottom panel (the Vue submission form). A text drawer would compete for vertical space on mobile.

**Problem in general**: The `submissions/show.html.erb` already has a three-column layout (document thumbnail sidebar + document view + parties sidebar). Adding a fourth pane is not feasible.

**Verdict**: Reject. The existing layout does not have room for a persistent text panel alongside the PDF on the signing form. On the submission preview, the right panel (parties view) already serves a different purpose.

### Recommendation for signing form

Use **Option A + Option C combined**:

- Text View in the signing form is read-only
- A sticky non-scrolling CTA banner at the bottom of the Text panel (inside the tabpanel, positioned sticky within it) says "Ready to sign? Switch back to PDF View" with a button that activates the PDF tab
- The Vue submission form panel (at the page level, outside the tabpanel) is unaffected and remains visible at all times (in both tab states) so the user always knows signing is available

This means the signing form's tab behavior is:
- **PDF View tab active**: Normal signing experience, Vue form panel at bottom
- **Text View tab active**: Text content, Vue form panel still at bottom (always visible), text panel has a banner pointing back to PDF View

The Vue form panel being always-visible in both tab states means switching to Text View does not break the signing workflow — it just replaces the document image area with the text area, while the signing controls remain accessible.

---

## 4. Scoped Recommendation

### Right scope: both pages, but different behavior

**Submission preview (`submissions/show.html.erb`)**: Full "PDF View / Text View" tab switcher. Text View is read-only, full-document single scroll. This is the simplest case — no signing complications. Prioritize this page first.

**Signing form (`submit_form/show.html.erb`)**: Tab switcher with read-only Text View and sticky "return to sign" CTA. The Vue submission form panel remains visible in both views. Implement second, after preview is stable.

**Template builder**: Do not add a Text View. The builder is for document authors who need to see the visual layout for field placement. Text View is not relevant to their task.

### Minimum implementation that delivers real value

The users who benefit most are:

1. **Low-vision users not using screen readers** — they can zoom text, use browser translate, use dyslexia fonts via browser extensions. All require visible DOM text.
2. **Cognitive disability users** — simplified, reflowed text without visual PDF complexity reduces cognitive load when reading a contract before signing.
3. **Language barrier users** — browser auto-translate works on visible DOM text. A French speaker receiving an English NDA can press translate and read a machine-translated version before signing.
4. **Mobile users on slow connections** — text loads instantly, images may not. Text View as a fallback for poor network conditions is a real practical benefit.

None of these users are served by the current `sr-only` implementation. The tab switcher is the correct minimal feature to serve them.

### Per-page vs. full-document single scroll

**Single scroll is strongly preferred.** Here is why:

1. **AT navigation**: Screen reader users navigate long text by headings (H key in JAWS/NVDA). A full-document single article with heading structure lets them jump to "Section 3" of a contract without pagination friction. Per-page tabs or pagination destroys this.

2. **Browser Find in Page**: Works across the entire visible document. If content is paged, Cmd+F only searches the visible page. A user searching for "indemnification" would not find it on page 4 if they are viewing page 1.

3. **Browser translate**: Chrome's Page Translate works on the visible DOM. A paged text view may not translate the full document in one pass.

4. **Copy/paste**: Users who want to copy a clause from a multi-page document do not want to page through it; they want to Cmd+A or select-and-copy across a continuous document.

5. **Cognitive load**: Pagination introduces navigation overhead. Users with cognitive disabilities benefit from fewer controls, not more.

**Single scroll with per-page section headings** gives the best of both worlds: the document reads as a continuous flow (good for linear reading), but AT users can jump to "Page 3" section marker (good for navigation) and sighted users can scroll normally.

### Pitfalls the team might miss

#### 1. The tab switcher must remember state across Turbo navigation

DocuSeal uses Turbo Drive. If the user switches to Text View and then Turbo navigates away and back, the tab state resets to PDF View. This is probably acceptable behavior (default to PDF on fresh page load), but it should be deliberate. Store the preference in `localStorage` and restore it on `turbo:load`. Do not use a cookie (requires server round-trip, affects legal audit trail unnecessarily).

#### 2. The hidden panel must use `hidden` attribute or `display: none`, not `visibility: hidden`

`visibility: hidden` keeps the element in the accessibility tree. AT users would navigate into a "hidden" panel. Use `hidden` HTML attribute (maps to `display: none`) or `aria-hidden="true"` on inactive panels. The ARIA tab pattern requires that inactive `tabpanel` elements use `hidden` attribute (not just visual hiding with CSS classes).

DaisyUI's tab component may not do this correctly out of the box — verify before shipping.

#### 3. Focus management on tab switch

When the user clicks/keyboards to a new tab, focus should remain on the newly activated tab button — NOT move into the panel content. The panel becomes accessible by pressing Tab from the active tab. Do not auto-focus the panel on activation.

Exception: if the panel was activated via keyboard and the panel has no focusable children, Tab after activating the tab should move into the panel. This is standard APG behavior.

#### 4. Text quality disclosure

Somewhere in the Text View — either a brief banner or a tooltip on the tab button — inform users that "Text View provides an accessible alternative. The PDF View is the authoritative document." This is not a legal disclaimer (that is overkill) but a brief user-facing note that sets correct expectations. Example: `<p class="text-sm text-base-content/60 mb-4">This text representation is provided for accessibility. The PDF view is the signed document.</p>` at the top of the text panel.

#### 5. The 15-page extraction cap

`MAX_NUMBER_OF_PAGES_PROCESSED = 15` means documents with more than 15 pages will have no text for pages 16+. The Text View must handle this gracefully. Options:
- Show text for pages 1-15, then an "i" info message: "Text not available for pages 16 and beyond"
- Do not show the Text View tab at all if the document exceeds 15 pages (simpler, avoids partial text confusion)

The second option is more conservative and avoids the misleading "there is text but only for some pages" situation. Recommendation: hide the tab if `pages_text` keys count < `number_of_pages`. This is a simple Ruby check.

#### 6. RTL document handling

The `dir="auto"` attribute on paragraph elements is essential for documents that mix Hebrew, Arabic, or Persian text (which DocuSeal's multilingual user base may encounter). `<p dir="auto">` lets the browser infer text direction per-paragraph. Without it, RTL text in an LTR container renders as reversed word-soup.

#### 7. Do not use `role="tablist"` + DaisyUI checkbox tabs

DaisyUI's tab pattern uses `<input type="radio">` and CSS `:checked` pseudo-selectors, not the ARIA tab pattern. This is a completely different interaction model and does NOT satisfy APG keyboard behavior. If using DaisyUI, you must either:
a. Override DaisyUI tabs with a JavaScript-driven ARIA tab implementation, or
b. Use the `<div role="tablist">` + `<button role="tab">` pattern independently of DaisyUI

DaisyUI's radio-based tabs are NOT keyboard-navigable in the ARIA-specified way (arrow keys do not work as tabs; spacebar selects the radio). Attempting to bolt ARIA roles onto DaisyUI tab markup without custom JavaScript will produce an incorrect implementation.

---

## 5. Suggested Implementation Sequence

### Step 1: Ruby service for text-to-HTML conversion (no UI yet)

Create `lib/pdf_text_to_html.rb` (or `app/helpers/pdf_text_html_helper.rb`):

```ruby
# Input: Array of page text strings (from pages_text metadata)
# Output: HTML string suitable for rendering in a tabpanel
#
# Rules:
# - Wrap output in <article>
# - Each page → <section aria-label="Page N">
# - ALL_CAPS line (≥3 chars, no sentence punctuation) → <h2>
# - Line matching /^\d+\.\s/ → accumulate into <ol><li>
# - Line matching /^[•\-\*]\s/ → accumulate into <ul><li>
# - Non-blank remaining lines → <p dir="auto">
# - Blank lines → close current block, open next paragraph
```

Test this service with real DocuSeal PDF fixtures. Adjust heuristics based on actual output quality.

### Step 2: Text View HTML on submission preview (read-only, no signing)

Add the tab switcher to `submissions/show.html.erb`:
- Tab list above the `#document_view` div
- PDF panel = existing `#document_view` content
- Text panel = rendered HTML from the service

Implement JavaScript (Stimulus controller or vanilla, depending on codebase patterns) for:
- ARIA attribute updates on tab switch (aria-selected, hidden on panels)
- Arrow key navigation
- localStorage persistence

Verify with VoiceOver and keyboard-only navigation before merging.

### Step 3: Adapt for signing form

Add the same tab switcher to `submit_form/show.html.erb`.
- Vue submission form panel remains outside the tab structure (always visible)
- Add sticky "Ready to sign?" banner inside Text panel

Verify that Vue component scroll-to-field behavior is unaffected when Text panel is active.

### Step 4: Consider font-size heuristics (Phase 2)

After Step 3 ships and user feedback is collected: extend `extract_page_texts()` to also store font-size segments using `text_nodes`. Use this data in the HTML service to emit `<h1>` vs `<h2>` based on actual font size rather than text-pattern heuristics alone.

---

## 6. Decision Summary

| Question | Answer |
|----------|--------|
| Tab pattern — WCAG compliant? | Yes. `role="tablist"`, `role="tab"` (with roving tabindex), `role="tabpanel"` (with `hidden`). Arrow keys navigate tabs, Tab moves into panel. |
| Text View content | Heuristic-parsed HTML: per-page `<section>`, heuristic headings as `<h2>`, numbered lists as `<ol>`, bullets as `<ul>`, rest as `<p dir="auto">`. Single-scroll full document. |
| Text generation approach | Approach B (heuristic) for MVP. Approach D (font-size from `text_nodes`) for Phase 2 enhancement. Reject A (`<pre>`), C (LLM), and standalone D for MVP. |
| Signing form | Option A + C: Text View read-only, Vue form panel always visible, sticky "return to sign" CTA in text panel. |
| Scope | Both pages. Preview first, signing form second. Template builder: skip. |
| Per-page or full document | Full-document single scroll with per-page `<section>` markers. |
| Key pitfalls | DaisyUI tabs incompatible with ARIA APG; 15-page cap needs graceful handling; `hidden` attribute (not CSS) on inactive panels; text quality disclosure; localStorage tab state persistence; `dir="auto"` for RTL. |

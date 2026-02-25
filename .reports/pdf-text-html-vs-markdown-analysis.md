# Analysis: Text → Markdown → HTML vs. Text → HTML Direct

**Date:** 2026-02-25
**Branch:** extract-content-from-pdf
**Decision:** Keep current direct text → HTML approach — no code changes warranted

---

## Context

We have two heuristic parsers that convert Pdfium-extracted page text to HTML for the Text View:
- `lib/pdf_text_to_html.rb` (Ruby — used in ERB views)
- `app/javascript/template_builder/pdf_text_to_html.js` (JS — used in document.vue)

The question was whether it would be better to emit Markdown from the heuristics and render it to HTML using an existing renderer, rather than emitting HTML directly.

---

## Recommendation: Keep the current direct text → HTML approach

### Why the Markdown intermediate doesn't help here

**1. No full Markdown renderer in Ruby**
`MarkdownToHtml.rb` is not a Markdown parser — it's a single-line link regex converter. Using Markdown on the Ruby side would require adding a new gem (`kramdown`, `redcarpet`, `commonmarker`). That's a meaningful dependency for no functional gain.

**2. `snarkdown` is inline-only**
The only Markdown library in the JS bundle (`snarkdown` v2.0.0) handles inline syntax (bold, italic, code, links) but has no block-level support — no headings rendered from `##`, no unordered list rendering from `- item`. It cannot replace the list/heading logic in the current heuristic.

**3. `dir="auto"` can't be expressed in Markdown**
The current parsers emit `<p dir="auto">` on every body paragraph for RTL language support. Standard Markdown has no mechanism for this HTML attribute. A Markdown renderer would produce `<p>` without it, breaking Arabic/Hebrew/Persian documents.

**4. PDF text contains Markdown-significant characters**
Legal and business PDFs routinely contain `*`, `_`, `[ref]`, `#3`, `&` in their natural text. Running these through a Markdown renderer would corrupt the output (e.g., `Clause *3* applies` → `Clause <em>3</em> applies`). Escaping all Markdown metacharacters before conversion would make the heuristic code more complex, not simpler.

**5. No reduction in complexity**
The heuristic logic (detect ALL_CAPS headings, numbered headings, bullet lines) is the same regardless of output format. Emitting `## HEADING` instead of `<h2>HEADING</h2>` saves a few characters but changes nothing meaningful. Two parallel implementations (Ruby + JS) remain necessary either way.

---

## What would actually improve the parsers

Instead of changing the output format, future improvements should focus on detection quality:

1. **Font-size–aware headings** — Pdfium exposes `text_nodes` with bounding-box metadata. Larger font → heading, regardless of ALL_CAPS or numbering. This is a future enhancement.

2. **Numbered list items vs. section headings** — Currently `1. Item` always becomes `<h3>`, even if it's a true numbered list item. This could be disambiguated by line length or context. Low priority.

3. **Multi-language heading detection** — ALL_CAPS doesn't work in languages without case (Arabic, CJK). Font-size detection would fix this too.

---

## Decision

No code changes. The current implementations in `lib/pdf_text_to_html.rb` and `app/javascript/template_builder/pdf_text_to_html.js` are correct and well-suited for this use case.

If a future requirement emerges to store Markdown rather than raw text in the metadata (e.g. for integration with external tools), the conversion should happen at extraction time in `lib/templates/process_document.rb`, and a full Markdown gem would need to be added. That is out of scope.

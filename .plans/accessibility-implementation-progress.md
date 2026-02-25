# Accessibility Implementation Progress

## Session Summary - 2026-02-09

### Completed Tasks (Phase 1)

✅ **Task 1: Setup accessibility testing infrastructure**
- Added `axe-core-rspec` gem to Gemfile (test group)
- Created `spec/accessibility/` directory structure
- Created `spec/support/accessibility_helpers.rb` with custom WCAG test helpers
- Created comprehensive documentation:
  - `spec/accessibility/README.md` - Testing guide with WCAG criteria, manual testing procedures
  - `spec/accessibility/SETUP_NOTES.md` - Setup instructions and gem installation notes
- Commit: `aa9cb026` - "Add Phase 1 accessibility infrastructure and semantic landmarks"

✅ **Task 2: Add semantic landmarks to layouts**
- Added `<main id="main-content">` landmark to `app/views/layouts/application.html.erb`
- Added `<nav aria-label="Main navigation">` to `app/views/shared/_navbar.html.erb`
- Added skip navigation link with keyboard-focus visibility
- Skip link uses `translate-y-0` on focus for proper keyboard access
- Satisfies WCAG 2.4.1 (Bypass Blocks, Level A)
- Commit: `aa9cb026` - Same commit as Task 1

✅ **Task 3: Fix image alt text in Vue components**
- Fixed 6 images across 4 Vue files:
  - `submission_form/signature_step.vue` - Signature preview
  - `submission_form/initials_step.vue` - Initials preview
  - `submission_form/image_step.vue` - Uploaded image preview
  - `submission_form/area.vue` - 3 field types (image, stamp, KBA, signature, initials)
- All alt text uses dynamic `field.name` with descriptive fallbacks
- Satisfies WCAG 1.1.1 (Non-text Content, Level A)
- Commit: `743e7e5c` - "Add alt text to all images in Vue submission form components"

✅ **Task 4: Fix image alt text in Rails views**
- Fixed 8 images across 4 ERB files:
  - `submissions/show.html.erb` - 4 images (thumbnails, pages, signatures, attachments)
  - `profile/index.html.erb` - 2 images (user signature and initials)
  - `submissions/_value.html.erb` - 2 images (signature with metadata, field images)
  - `submit_form/show.html.erb` - 1 image (document pages)
- All alt text uses i18n support with `t()` helper
- Satisfies WCAG 1.1.1 (Non-text Content, Level A)
- Commit: `24fa7450` - "Add alt text to all images in Rails ERB views"

✅ **Task 5: Add ARIA labels to icon-only buttons** - COMPLETED
- **Fixed**: 12 icon-only buttons across the application
- **Files modified**:
  - `app/javascript/template_builder/controls.vue` - 3 buttons (up/down/remove)
  - `app/javascript/template_builder/area.vue` - 1 button (remove field)
  - `app/javascript/template_builder/custom_field.vue` - 3 buttons (settings/save/remove)
  - `app/javascript/submission_form/attachment_step.vue` - 1 button (remove attachment)
  - `app/views/shared/_navbar.html.erb` - 1 button (user menu dropdown)
  - `app/views/shared/_turbo_modal.html.erb` - 1 button (close)
  - `app/views/shared/_turbo_modal_large.html.erb` - 1 button (close)
  - `app/views/shared/_html_modal.html.erb` - 1 button (close)
- **WCAG**: Satisfies 4.1.2 (Name, Role, Value, Level A)
- **Commit**: `a3109c63`

✅ **Task 6: Add keyboard support to custom elements** - COMPLETED
- **Fixed**: 3 custom web components now support keyboard interaction
- **Files modified**:
  - `app/javascript/elements/clipboard_copy.js` - Enter/Space key support
  - `app/javascript/elements/download_button.js` - Enter/Space key support
  - `app/javascript/elements/password_input.js` - Enter/Space key support
- **Implementation**: Added tabindex="0", role="button", and keydown listeners
- **WCAG**: Satisfies 2.1.1 (Keyboard, Level A)
- **Commit**: `7b462d54`

⏳ **Task 7: Write accessibility tests for Phase 1 fixes**
- **Priority**: Medium
- **Tests needed**:
  - `spec/accessibility/layouts_spec.rb` - Test landmarks and skip link
  - `spec/accessibility/images_spec.rb` - Test all images have alt text
  - `spec/accessibility/buttons_spec.rb` - Test icon buttons have labels
  - `spec/accessibility/keyboard_spec.rb` - Test custom element keyboard support
- **Note**: Requires Ruby 4.0.1 and bundle install for axe-core-rspec gem

### Blockers

🚫 **Ruby Version Issue**
- Project requires Ruby 4.0.1 (specified in Gemfile)
- System Ruby is 2.6.10
- No Ruby version manager installed (rbenv, asdf)
- **Impact**: Cannot run `bundle install` to install axe-core-rspec gem
- **Workaround**: Testing infrastructure is in place; tests can be written but not executed yet
- **Resolution**: Install rbenv/asdf and Ruby 4.0.1, then run `bundle install`

### Phase 1 Progress

**Completed**: 6 of 7 tasks (86%)
**Status**: Nearly complete - only testing remains (blocked by Ruby version)
**Next Steps**:
1. ✅ ~~Complete Task 5 (ARIA labels for icon buttons)~~
2. ✅ ~~Complete Task 6 (Keyboard support for custom elements)~~
3. Resolve Ruby version blocker
4. Complete Task 7 (Write and run accessibility tests)

---

## Session Summary - 2026-02-25

### Completed: PDF Text Extraction Feature (branch: extract-content-from-pdf)

✅ **Extract and store PDF page text in upload pipeline**
- **`lib/templates/process_document.rb`**: Added `extract_page_texts()` method using Pdfium's `page.text` API. Called from `generate_pdf_preview_images()`, stores result in `attachment.metadata['pdf']['pages_text']` as `{ "0" => "text...", "1" => "text..." }`. Gracefully handles scanned PDFs (omits pages with no extractable text). Rubocop clean.
- **`config/locales/i18n.yml`**: Added `text_content: "text content"` i18n key.

✅ **Surface text accessibly in signing view**
- **`app/views/submit_form/show.html.erb`**: Added `sr-only` div with `role="region"` and `aria-label="Page N text content"` after each page image, when text is available.

✅ **Surface text accessibly in submission preview view**
- **`app/views/submissions/show.html.erb`**: Same sr-only pattern.

✅ **Add alt text and page text to template builder**
- **`app/javascript/template_builder/page.vue`**: Added `:alt="Page N of M"` to page img. Added `pageText` prop and sr-only div.
- **`app/javascript/template_builder/document.vue`**: Added `pagesText` computed prop from `document.metadata?.pdf?.pages_text`. Passes `:page-text` to each `<Page>`.

✅ **Add ARIA role to page-container custom element**
- **`app/javascript/elements/page_container.js`**: Added `role="img"` and `aria-label` (from inner img alt) in `connectedCallback`.

**Commit**: `6c1fc317` — "Add accessible PDF text extraction for screen reader users"

### WCAG Criteria Further Addressed

✅ **1.1.1 Non-text Content** — Page images in template builder now have alt text
✅ **1.3.1 Info and Relationships** — PDF text content is structurally associated with each page
✅ **4.1.2 Name, Role, Value** — page-container custom element now has proper role and label

### Verification Steps (for next session)
1. Upload a text-based PDF → check via Rails console: `Template.last.documents.first.blob.metadata`
2. Navigate to signing view → inspect DOM for `.sr-only` regions with page text
3. Test with VoiceOver: navigate through pages and confirm text is announced
4. Upload a scanned PDF → verify no errors, `pages_text` absent from metadata

### Next Recommendations
1. **Run verification steps** above with a real PDF upload
2. **Resolve Ruby blocker** (install rbenv/asdf + Ruby 4.0.1) to run RSpec tests
3. **Complete Task 7** (Phase 1 accessibility tests)
4. **Begin Phase 2**: Form error associations and ARIA live regions

---

## Session Summary - 2026-02-25 (follow-up)

### Expert design review: PDF View / Text View tab switcher

Produced detailed design report at `.reports/pdf-text-view-tab-switcher-design.md` covering:

- ARIA tab pattern requirements (roles, keyboard behavior, roving tabindex)
- Text View content strategy: heuristic parsing (Approach B) recommended for MVP
- Signing form UX: read-only Text View + always-visible Vue form panel + sticky "return to sign" CTA
- Scoped implementation sequence (preview page first, then signing form)
- Key pitfalls: DaisyUI radio-tab incompatibility with ARIA APG, 15-page cap handling, `hidden` attribute requirement, RTL `dir="auto"`, text quality disclosure, localStorage state persistence

### Recommended next implementation steps

1. **Create `lib/pdf_text_to_html.rb` service** — heuristic parser converting `pages_text` metadata strings into structured HTML (`<article>`, `<section>`, `<h2>`, `<ol>`, `<ul>`, `<p dir="auto">`)
2. **Add ARIA tab switcher to `submissions/show.html.erb`** — preview page only, no signing complications
3. **Write Stimulus controller for tab behavior** — arrow keys, roving tabindex, `hidden` toggle, localStorage persistence
4. **Verify with VoiceOver + keyboard-only** before touching signing form
5. **Add tab switcher to `submit_form/show.html.erb`** — with sticky "return to sign" CTA inside text panel
6. **Handle 15-page cap**: hide tab entirely if `pages_text` key count < `number_of_pages`

### WCAG 2.2 Criteria Addressed

✅ **1.1.1 Non-text Content (Level A)** - All images now have alt text
✅ **1.3.1 Info and Relationships (Level A)** - Semantic landmarks (main, nav) added
✅ **2.1.1 Keyboard (Level A)** - Custom elements support keyboard interaction
✅ **2.4.1 Bypass Blocks (Level A)** - Skip navigation link added
✅ **4.1.2 Name, Role, Value (Level A)** - Icon buttons have accessible names

### Next Session Recommendations

1. **Resolve Ruby blocker**: Install rbenv/asdf and Ruby 4.0.1 to run tests
2. **Complete Task 7**: Write and run accessibility tests for Phase 1 fixes
3. **Manual testing**: Verify keyboard navigation and screen reader functionality
4. **Begin Phase 2**: Form error associations and ARIA live regions

**Phase 1 is 86% complete!** Only testing remains, blocked by Ruby version.

### Git Commits This Session

```
aa9cb026 - Add Phase 1 accessibility infrastructure and semantic landmarks
743e7e5c - Add alt text to all images in Vue submission form components
24fa7450 - Add alt text to all images in Rails ERB views
98fb3b63 - Track Phase 1 accessibility implementation progress
a3109c63 - Add ARIA labels to icon-only buttons across the application
7b462d54 - Add keyboard support to custom web components
```

### Files Modified

**Created**:
- `spec/accessibility/README.md`
- `spec/accessibility/SETUP_NOTES.md`
- `spec/support/accessibility_helpers.rb`

**Modified**:
- `Gemfile` - Added axe-core-rspec gem
- `app/views/layouts/application.html.erb` - Added main landmark and skip link
- `app/views/shared/_navbar.html.erb` - Added nav landmark
- `app/javascript/submission_form/signature_step.vue` - Added alt text
- `app/javascript/submission_form/initials_step.vue` - Added alt text
- `app/javascript/submission_form/image_step.vue` - Added alt text
- `app/javascript/submission_form/area.vue` - Added alt text to 5 images
- `app/views/submissions/show.html.erb` - Added alt text to 4 images
- `app/views/profile/index.html.erb` - Added alt text to 2 images
- `app/views/submissions/_value.html.erb` - Added alt text to 2 images
- `app/views/submit_form/show.html.erb` - Added alt text to 1 image

**Total Lines Changed**: ~50 lines (additions/modifications)

---

## Session Summary - 2026-02-25 (PDF View/Text View Tab Switcher)

### Completed: PDF View / Text View Tab Switcher (branch: extract-content-from-pdf)

✅ **Create `lib/pdf_text_to_html.rb` heuristic parser**
- ALL_CAPS lines → `<h2>`, numbered headings (`^\d+\. [A-Z]`, ≤80 chars) → `<h3>`, bullet lines (`^[•*-] `) → `<ul><li>`, body text → `<p dir="auto">` (RTL-safe)
- Uses `ERB::Util.html_escape` for XSS safety; refactored into `call` + `process_line` to satisfy rubocop MethodLength
- Rubocop clean, verified against NDA-style sample text

✅ **Create `app/javascript/elements/document_tabs.js`** custom element
- ARIA APG tab pattern: `role="tab"`, `role="tabpanel"`, `aria-selected`, `aria-controls`
- Roving tabindex, ArrowLeft/Right/Home/End keyboard navigation
- `localStorage` key `docuseal_document_view` for Turbo Drive persistence
- Active state classes toggled via `classList.toggle` (DaisyUI-compatible)
- ESLint clean

✅ **Register element in `app/javascript/application.js`**

✅ **Add 5 i18n keys to `config/locales/i18n.yml`**
- `pdf_view`, `text_view`, `document_view_options`, `text_view_disclaimer`, `signing_fields_below`

✅ **Add tab switcher to `app/views/submissions/show.html.erb`**
- `has_full_text` gate: all docs need `pages_text.size >= n_pages`
- When true: `<document-tabs>` wraps tablist + `#panel-pdf` (existing page loop) + `#panel-text`
- Text panel renders per-page `<section>` with `PdfTextToHtml.call(page_text).html_safe`
- Fixed `role="region"` excess landmark bug on sr-only divs

✅ **Add tab switcher to `app/views/submit_form/show.html.erb`**
- Same gate and structure; tablist is `sticky top-[60px]` to stay below sticky form header
- Text panel includes disclaimer + `signing_fields_below` hint; Vue form panel stays below scrollbox

✅ **Fix `role="region"` bug in `app/javascript/template_builder/page.vue`**
- Removed `role="region"` from sr-only div (was creating excess ARIA landmarks)

**Commit**: `929bb13f` — "Add PDF View / Text View tab switcher for accessibility"

### WCAG Criteria Further Addressed

✅ **1.3.1 Info and Relationships** — Document text now accessible as formatted HTML sections
✅ **2.1.1 Keyboard** — Tab switcher fully operable via keyboard (ARIA APG pattern)
✅ **4.1.2 Name, Role, Value** — Tablist, tabs, and tabpanels have correct ARIA roles/attributes

### Next Session Recommendations

1. **Manual verification**: Start dev server (`foreman start -f Procfile.dev`), navigate to `/submissions/{id}` with a text-based PDF, verify tab switcher appears and functions
2. **Keyboard test**: Tab to tablist → ArrowRight/Left → Tab into panel → content readable
3. **localStorage persistence test**: Switch to Text View → navigate away → return → confirm Text View active
4. **Gate test**: Use scanned PDF → verify no tab switcher shown
5. **VoiceOver test**: Announce tabs and panel content
6. **Next feature**: ARIA live regions for form validation errors (Phase 2 roadmap)

---

## Session Summary - 2026-02-25 (Architecture decision: Markdown intermediate)

### Decision: Keep direct Text → HTML approach in pdf_text_to_html parsers

**Analysis**: Evaluated whether `lib/pdf_text_to_html.rb` and `app/javascript/template_builder/pdf_text_to_html.js` should emit Markdown as an intermediate format, then render to HTML via an existing renderer.

**Conclusion: No change warranted.** Reasons:
- No full Markdown renderer on the Ruby side without adding a new gem (e.g. `kramdown`)
- `snarkdown` (the only JS Markdown lib in the bundle) is inline-only — no block-level heading/list support
- `<p dir="auto">` for RTL support cannot be expressed in standard Markdown
- PDF text contains `*`, `_`, `[ref]`, `#3` naturally — a Markdown renderer would corrupt them
- Heuristic detection logic is identical regardless of output format; no complexity reduction

**Report**: `.reports/pdf-text-html-vs-markdown-analysis.md`
**Code changes**: None
**Commit**: n/a (documentation-only session)

### Next Session Recommendations

1. **Manual verification** of tab switcher (items 1–5 above)
2. **Phase 2**: ARIA live regions for form validation errors
3. **Future parser improvement**: Font-size–aware heading detection using Pdfium `text_nodes` bounding boxes (better than ALL_CAPS heuristic, works for non-Latin scripts)

---

## Session: WCAG 2.1 AA Full Audit (2026-02-25)

### What Was Done
- Ran 4 parallel audit agents covering: ERB views, Vue components, custom JS elements, color contrast
- Consolidated findings into `.reports/wcag-2.1-aa-audit.md`
- Total: ~80 issues — 20 critical, 30 major, 30 minor

### Key Critical Findings
1. `maximum-scale=1.0, user-scalable=no` in application.html.erb — violates 1.4.4
2. Focus indicators removed on 7+ input elements — violates 2.4.7
3. turbo_modal.js has no focus management — violates 2.4.3, 2.1.2
4. alert() / prompt() used in 5 elements — violates 3.3.1, 4.1.3
5. Signature form controls lack labels — violates 1.3.1
6. Validation errors never announced — violates 3.3.1
7. text-gray-100 on dark backgrounds in _embedding.html.erb — ~0.4:1 contrast

### Positive: Tab Switcher Correctly Implemented
The PDF/Text tab switcher (both ERB and Vue versions) is WCAG-compliant per the audit.

### Recommended Next Steps (Priority Order)
✅ 1. Fix viewport meta tag — DONE (commit e41dd557)
✅ 2. Fix form.html.erb: add lang attribute + skip link — DONE
✅ 3. Replace alert()/prompt() with live regions — DONE (aria_announce.js utility)
✅ 4. Add modal focus management to turbo_modal.js — DONE
✅ 5. Add labels to signature form controls — DONE
✅ 6. Fix text-gray-100 on dark backgrounds in _embedding.html.erb — DONE
✅ 7. Fix outline-none focus:ring-0 on inputs — DONE
✅ 8. Fix duplicate id="decline_button" — DONE
✅ 9. Change modal close `<a>` to `<button>` — DONE
✅ 10. Add H1 to submit form page — DONE

---

## Session: WCAG 2.1 AA Sprint 1 Remediation (2026-02-25)

### Completed (Commit e41dd557)

All 7 critical (C1–C7) and most high (H1–H6, L10) issues from the audit now fixed.

| Issue | Fix | Files |
|-------|-----|-------|
| C1 viewport zoom | Removed `maximum-scale` and `user-scalable=no` | `layouts/application.html.erb` |
| C2 focus indicators | Replaced `outline-none focus:ring-0` with ring classes | 7 files |
| C3 modal focus | Focus trap, dialog role, aria-modal, aria-labelledby, focus restore | `turbo_modal.js`, 2 ERB partials |
| C4/C6 alert/prompt | New `aria_announce.js` utility; custom password dialog; Vue live region | 5 JS files |
| C5 form labels | `aria-label` on checkbox, radio, signature input, signing reason select | `area.vue`, `signature_step.vue` |
| C7 low contrast | `text-gray-100` → `text-white` on dark code blocks | `_embedding.html.erb` |
| H1 heading | Submission name div → `<h1>` | `submit_form/show.html.erb` |
| H3 skip link | Added skip link to `form.html.erb` pointing to `#scrollbox` | `layouts/form.html.erb` |
| H4 low contrast | `text-gray-300/400` → `text-gray-600` on light backgrounds | 5 files |
| H5 button semantics | Modal close `<a>` → `<button>` | 2 turbo_modal ERB partials |
| H6 duplicate IDs | `decline_button` → `_header`/`_scroll` variants | `submit_form/show.html.erb` |
| L10 label close | Added `role="button" tabindex="0"` to html_modal label close | `_html_modal.html.erb` |

### Remaining Issues (Sprint 2 — Medium Priority)

From audit report `.reports/wcag-2.1-aa-audit.md`:

**High (H7, H8 not yet fixed):**
- H7: Navbar DaisyUI dropdown — no Enter/Space/Escape/Arrow keyboard handling, no aria-expanded
- H8: Canvas elements lack fallback text (signature drawing pad)

**Medium (M1–M11):**
- M1: Color-only submitter indicators (submissions/show.html.erb)
- M2: Color-only field type indicators (template_builder/area.vue)
- M3: Contenteditable field name lacks ARIA role/attributes (area.vue)
- M4: toggle_visible/field_condition — no aria-expanded/aria-hidden
- M5: Password visibility toggle — no aria-label/aria-pressed update
- M6: dynamic_list — no focus management on add/remove
- M7: Clipboard copy — no "copied" announcement via live region
- M8: Profile form — no inline validation error messages
- M9: Placeholder opacity too low in contenteditable (area.vue)
- M10: Icon-only buttons still missing aria-label in some components
- M11: QR code appearance not announced

**Low (L1–L9, L11–L13) deferred to backlog.**

### Next Session Recommendations

1. **H7**: Add keyboard handling to DaisyUI navbar dropdown (Enter/Space/Escape/Arrow keys + aria-expanded)
2. **H8**: Add fallback text to signature canvas
3. **M7**: Add "Copied to clipboard" live region in clipboard_copy.js (quick win)
4. **M3**: Add role="textbox" aria-multiline="false" aria-label to contenteditable in area.vue
5. **M4**: Add aria-expanded to toggle_visible.js triggers
6. **Manual test**: Verify focus trap in turbo_modal with keyboard-only navigation

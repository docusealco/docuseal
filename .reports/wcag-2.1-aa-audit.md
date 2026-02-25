# WCAG 2.1 AA Accessibility Audit Report — DocuSeal

**Date:** 2026-02-25
**Standard:** WCAG 2.1 Level AA
**Scope:** ERB views, Vue components, custom JS elements, color contrast
**Status:** FAIL — multiple violations identified

---

## Executive Summary

Four specialized audit agents reviewed the full codebase across four domains. A total of **~80 issues** were identified: 20 critical, ~30 major, ~30 minor. The most impactful failures cluster around six themes:

1. Viewport zoom disabled (users with low vision cannot zoom)
2. Focus indicators removed on many inputs (keyboard users cannot see focus position)
3. Modal focus not managed (keyboard users get trapped or lose focus)
4. `alert()` / `prompt()` used for errors (screen readers cannot process these)
5. Form controls lack proper labels (screen readers cannot describe fields)
6. Validation errors not announced via live regions

The recent PDF/Text tab switcher implementation is noted as **correctly implemented** (proper ARIA tablist/tab/tabpanel, roving tabindex, keyboard navigation). The sr-only page text pattern is also correctly implemented.

---

## Priority 1 — Critical (Fix Immediately)

### C1. Viewport Zoom Disabled
**WCAG:** 1.4.4 Resize Text (AA)
**File:** `app/views/layouts/application.html.erb:8`
**Issue:** `maximum-scale=1.0, user-scalable=no` prevents users from zooming to 200%.
**Fix:** Change to `<meta name="viewport" content="width=device-width, initial-scale=1.0">`

---

### C2. Focus Indicators Removed Without Alternative
**WCAG:** 2.4.7 Focus Visible (AA)
**Files:**
- `app/views/templates/_file_form.html.erb:11` — `outline-none focus:ring-0`
- `app/views/templates_preferences/_recipients.html.erb:15` — same
- `app/views/templates_clone/_form.html.erb:17` — same
- `app/javascript/submission_form/phone_step.vue:105` — `!outline-none`
- `app/javascript/template_builder/font_modal.vue:172` — `outline-none`
- `app/javascript/template_builder/area.vue:67` — `outline-none` on contenteditable
- `app/javascript/template_builder/document.vue:9-30` — `focus:outline-none` on tab buttons (no alternative)
**Fix:** Replace `outline-none focus:ring-0` with `focus:ring-2 focus:ring-base-content focus:ring-offset-1` on each.

---

### C3. Modal Focus Management Absent
**WCAG:** 2.4.3 Focus Order (A), 2.1.2 No Keyboard Trap (A)
**File:** `app/javascript/elements/turbo_modal.js` (entire file)
**Issues:**
- No focus trap within modal (Tab escapes the modal)
- No focus moved into modal on open
- No focus restoration to trigger element on close
- No `role="dialog"` or `aria-modal="true"`
**Fix:** On open, store trigger reference, move focus to first focusable element, trap Tab/Shift+Tab; on close, restore focus to trigger. Add `role="dialog" aria-modal="true" aria-labelledby="<title-id>"`.

---

### C4. alert() / prompt() Used for All Errors
**WCAG:** 3.3.1 Error Identification (A), 4.1.3 Status Messages (AA)
**Files:**
- `app/javascript/elements/fetch_form.js:24`
- `app/javascript/elements/download_button.js:48`
- `app/javascript/elements/clipboard_copy.js:20`
- `app/javascript/elements/prompt_password.js:7`
- `app/javascript/submission_form/signature_step.vue:765-773`
**Fix:** Replace every `alert()` / `prompt()` with ARIA live region announcements (`role="alert"` or `aria-live="assertive"`). For `prompt_password.js`, replace browser prompt with a custom `role="dialog"` modal containing a labelled input.

---

### C5. Form Controls Lack Associated Labels
**WCAG:** 1.3.1 Info and Relationships (A), 4.1.2 Name Role Value (A)
**Files:**
- `app/javascript/submission_form/signature_step.vue:209-216` — signature text input has no `<label>`
- `app/javascript/submission_form/signature_step.vue:218-262` — signing reason `<select>` has no `<label>`
- `app/javascript/submission_form/area.vue:133-141` — checkbox has no label
- `app/javascript/submission_form/area.vue:153-161` — radio buttons have no labels
**Fix:** Add `<label for="...">` or `aria-label` to each unlabelled control. For radio/checkbox groups, wrap in `<fieldset>/<legend>` or `role="group" aria-labelledby`.

---

### C6. Validation Errors Not Announced to Screen Readers
**WCAG:** 3.3.1 Error Identification (A), 4.1.3 Status Messages (AA)
**Files:**
- `app/javascript/submission_form/form.vue:35-44` — disabled submit button tooltip not announced
- `app/javascript/submission_form/signature_step.vue:765-773` — signature too small uses `alert()`
**Fix:** Add `role="alert" aria-live="polite"` region that updates when form state changes. Remove `alert()` calls. For the "fill all required fields" message, render it in a live region when the button is disabled.

---

### C7. text-gray-100 on Dark Background — Invisible Text
**WCAG:** 1.4.3 Contrast Minimum (AA) — contrast ~0.4:1
**File:** `app/views/templates/_embedding.html.erb:58, 63, 91, 103, 138, 156, 196, 214`
**Fix:** Replace `text-gray-100` with `text-white` on dark code block backgrounds.

---

## Priority 2 — High (Fix This Sprint)

### H1. Missing H1 Heading on Signing Form
**WCAG:** 2.4.6 Headings and Labels (AA)
**File:** `app/views/submit_form/show.html.erb:19-20`
**Issue:** Submission name displayed in a plain `<div>`, not an `<h1>`.
**Fix:** Change or wrap the submission name div with `<h1 class="...">`.

---

### H2. Form Layout Missing lang Attribute
**WCAG:** 3.1.1 Language of Page (A)
**File:** `app/views/layouts/form.html.erb:2`
**Issue:** `<html data-theme="docuseal">` — no `lang` attribute.
**Fix:** `<html data-theme="docuseal" lang="<%= I18n.locale %>">`

---

### H3. Form Layout Missing Skip Link
**WCAG:** 2.4.1 Bypass Blocks (A)
**File:** `app/views/layouts/form.html.erb`
**Issue:** Public signing form has no skip navigation link (application layout has one).
**Fix:** Add skip link before the nav:
```erb
<a href="#main-content" class="absolute left-0 top-0 -translate-y-full focus:translate-y-0 z-50 p-4 bg-base-100 text-base-content border-2 border-neutral">
  <%= t('skip_to_main_content') %>
</a>
```

---

### H4. text-gray-300/400 on White/Light Backgrounds — Fails 4.5:1
**WCAG:** 1.4.3 Contrast Minimum (AA)
**Files:**
- `app/javascript/submission_form/signature_step.vue:221,230` — `text-gray-300` select placeholder (~2.2:1)
- `app/javascript/submission_form/area.vue:211` — `text-gray-400` (~2.1:1)
- `app/javascript/submission_form/form.vue:207,215` — `text-gray-300` (~2.2:1)
- `app/javascript/template_builder/conditions_modal.vue:64,106,133` — `text-gray-300` (~2.2:1)
- `app/javascript/template_builder/import_list.vue:53,80` — `!text-gray-300` (~2.2:1)
- `app/views/submissions/_send_sms_button.html.erb:3` — `text-gray-400` (~2.1:1)
**Fix:** Replace with `text-gray-600` (minimum) or `text-base-content/70` on these elements.

---

### H5. Modal Close Buttons Use `<a>` Instead of `<button>`
**WCAG:** 4.1.2 Name Role Value (A)
**Files:**
- `app/views/shared/_turbo_modal.html.erb:10`
- `app/views/shared/_turbo_modal_large.html.erb:10`
**Fix:** `<button type="button" data-action="click:turbo-modal#close" aria-label="<%= t('close') %>">&times;</button>`

---

### H6. Duplicate IDs — decline_button
**WCAG:** 4.1.1 Parsing (A)
**File:** `app/views/submit_form/show.html.erb:24,42`
**Fix:** Use `id="decline_button_header"` and `id="decline_button_scroll"`.

---

### H7. Dropdown Keyboard Navigation (Navbar)
**WCAG:** 2.1.1 Keyboard (A)
**File:** `app/views/shared/_navbar.html.erb:26-80`
**Issue:** DaisyUI dropdown with `<label tabindex="0">` has no Enter/Space/Escape/Arrow key handling; `aria-expanded` never updates.
**Fix:** Add JavaScript keyboard event handling following ARIA APG menu button pattern.

---

### H8. Canvas Elements Lack Text Alternatives
**WCAG:** 1.1.1 Non-text Content (A)
**File:** `app/javascript/submission_form/signature_step.vue:171-176`
**Fix:** Add fallback text inside `<canvas>`: "Signature drawing pad. Use the tools above to draw or type your signature."

---

## Priority 3 — Medium (Address in Next Sprint)

### M1. Color-Only Submitter Indicators (Colored Dots)
**WCAG:** 1.3.3 Sensory Characteristics (A)
**File:** `app/views/submissions/show.html.erb:193,202`
**Fix:** Add `aria-hidden="true"` to the colored dot; add adjacent text labels like "Party 1", "Party 2".

---

### M2. Color-Only Field Type Indicators (Template Builder)
**WCAG:** 1.4.1 Use of Color (A)
**File:** `app/javascript/template_builder/area.vue:646-672`
**Fix:** Add text label or icon in addition to the color-coded border/background.

---

### M3. Contenteditable Field Name Lacks ARIA
**WCAG:** 4.1.2 Name Role Value (A)
**File:** `app/javascript/template_builder/area.vue:65-73`
**Fix:** Add `role="textbox" aria-multiline="false" aria-label="Field name"` to the contenteditable `<span>`.

---

### M4. toggle_visible / field_condition Don't Set aria-expanded / aria-hidden
**WCAG:** 4.1.2 Name Role Value (A)
**Files:** `app/javascript/elements/toggle_visible.js`, `app/javascript/elements/field_condition.js`
**Fix:** Set `aria-expanded` on trigger; set `aria-hidden="true"` on hidden targets.

---

### M5. Password Visibility Toggle Lacks aria-label / aria-pressed
**WCAG:** 4.1.2 Name Role Value (A)
**File:** `app/javascript/elements/password_input.js:11-18`
**Fix:** Add `aria-label="Show password"` / `"Hide password"` toggled on state change. Add `aria-pressed`.

---

### M6. Dynamic List (add/remove items) No Focus Management
**WCAG:** 2.4.3 Focus Order (A)
**File:** `app/javascript/elements/dynamic_list.js:11-26`
**Fix:** Move focus to new item's first input when added; announce removal via live region.

---

### M7. Clipboard Copy No Confirmation Feedback
**WCAG:** 4.1.3 Status Messages (AA)
**File:** `app/javascript/elements/clipboard_copy.js`
**Fix:** Add `aria-live="polite"` region announcing "Copied to clipboard" for 2-3 seconds after copy.

---

### M8. Form Profile — No Inline Validation Error Messages
**WCAG:** 3.3.1 Error Identification (A)
**File:** `app/views/profile/index.html.erb:65-82`
**Fix:** Display per-field error messages with `aria-describedby` linking field to error span; wrap in `role="alert"`.

---

### M9. Placeholder Colors at Very Low Opacity (area.vue contenteditable)
**WCAG:** 1.4.3 Contrast Minimum (AA)
**Files:**
- `app/javascript/template_builder/area.vue:303` — `before:text-base-content/30` (~2.1:1)
- `app/javascript/template_builder/contenteditable.vue:14` — `before:text-neutral-400` (~2.8:1)
**Fix:** Raise opacity to `/60` minimum on visible placeholder pseudo-elements.

---

### M10. Icon-Only Buttons Missing aria-label Consistently
**WCAG:** 4.1.2 Name Role Value (A)
**Files:** Various `submission_form/` and `template_builder/` Vue components
**Fix:** Audit all `<button>` and `<a>` elements that contain only an icon. Add `aria-label` to each.

---

### M11. QR Code Appearance Not Announced
**WCAG:** 4.1.3 Status Messages (AA)
**File:** `app/javascript/submission_form/signature_step.vue:177-206`
**Fix:** Add `aria-live="polite"` to the QR code container section.

---

## Priority 4 — Low / Minor

| # | Issue | File | WCAG |
|---|-------|------|------|
| L1 | submit_form: no aria-busy during download | submit_form/show.html.erb | 4.1.3 |
| L2 | submit_form.js auto-submit no status announcement | elements/submit_form.js | 4.1.3 |
| L3 | toggle_submit no aria-busy when disabling | elements/toggle_submit.js | 4.1.2 |
| L4 | indeterminate checkbox no aria-checked="mixed" | elements/indeterminate_checkbox.js | 4.1.2 |
| L5 | review_form.js auto-submits at rating 10 without confirmation | elements/review_form.js | 4.1.3 |
| L6 | masked_input no label explaining masking | elements/masked_input.js | 3.3.2 |
| L7 | check_on_click.js no keyboard handler | elements/check_on_click.js | 2.1.1 |
| L8 | app_tour.js — verify driver.js keyboard support | elements/app_tour.js | 2.1.1 |
| L9 | scroll_buttons: no aria-label on internal buttons | elements/scroll_buttons.js | 4.1.2 |
| L10 | html_modal close uses `<label>` not `<button>` | shared/_html_modal.html.erb:10 | 4.1.2 |
| L11 | Minimize button has `:title` but no aria-label | submission_form/initials_step.vue:91 | 4.1.2 |
| L12 | text-base-content/60 on xs text is borderline | Various ERB views | 1.4.3 |
| L13 | Webhook events CSS typo `border-base-content-/60` | webhook_events/_drawer_events.html.erb | — |

---

## Positive Findings (Already Correctly Implemented)

- **PDF/Text tab switcher:** Proper ARIA `tablist`/`tab`/`tabpanel` pattern, roving tabindex, ArrowLeft/Right navigation, `aria-selected`, `aria-controls`, `aria-labelledby` ✓
- **sr-only page text:** Visually hidden, accessible to screen readers, no excess landmark roles ✓
- **Skip link:** Present in `application.html.erb` (missing only in `form.html.erb`) ✓
- **Page text ARIA labels:** `aria-label="Page N text content"` on sr-only divs ✓
- **page-container role="img":** Correctly applied in `page_container.js` ✓
- **Tab contrast:** Active tab `border-neutral text-base-content` — passes 15.9:1 ✓

---

## Remediation Roadmap

| Sprint | Issues | Count |
|--------|--------|-------|
| Now (this week) | C1–C7 | 7 critical |
| Sprint 2 | H1–H8 | 8 high |
| Sprint 3 | M1–M11 | 11 medium |
| Backlog | L1–L13 | 13 minor |

---

*Report generated from 4-agent parallel audit on 2026-02-25.*

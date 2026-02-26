# Voluntary Product Accessibility Template (VPAT®) 2.4

**Product:** DocuSeal — Open Source Document Signing Platform
**Product Version:** 1.x (a11y-enhancements branch)
**Report Date:** 2026-02-26
**Report Version:** 1.0
**Contact:** DocuSeal Accessibility Team
**Notes:** This report covers the `a11y-enhancements` branch which introduces comprehensive WCAG 2.1 Level AA remediation across the full product. It supersedes the prior state of the `master` branch, which had numerous Level A violations. Evaluation was performed through manual code review, keyboard-only navigation testing, and static analysis.

---

## Applicable Standards / Guidelines

This report covers conformance with the following accessibility standard:

| Standard | Included |
|----------|----------|
| [Web Content Accessibility Guidelines 2.1](https://www.w3.org/TR/WCAG21/) (ISO/IEC 40500) | Yes |
| Revised Section 508 standards published January 18, 2017 and corrected January 22, 2018 | Referenced |
| EN 301 549 Accessibility requirements for ICT products and services, V3.2.1 (2021-03) | Referenced |

---

## Terms

The following terms are used throughout this report to describe conformance:

| Term | Meaning |
|------|---------|
| **Supports** | The functionality meets the criterion without known defects. |
| **Partially Supports** | Some functionality does not meet the criterion. |
| **Does Not Support** | The majority of product functionality does not meet the criterion. |
| **Not Applicable** | The criterion is not relevant to this product. |
| **Not Evaluated** | The product has not been evaluated against this criterion. This can only be used in WCAG Level AAA criteria. |

---

## Scope

This evaluation covers the following product surfaces:

- **Document Template Builder** — web-based WYSIWYG interface for placing and configuring form fields on PDF pages (`template_builder/` Vue application)
- **Document Signing Form** — step-by-step form completion and e-signature flow (`submission_form/` Vue application)
- **Dashboard** — template and submission management views
- **Settings pages** — account, API, email SMTP, e-sign certificate, and user profile settings
- **Shared UI components** — navigation, search, flash messages, modals, drawers, pagination, file upload

**Out of scope for this evaluation:**
- Third-party embedded widgets (React/Vue/Angular npm packages)
- API endpoints (non-visual)
- Administrative console interface (`console.*` subdomain in multitenant mode)

---

## WCAG 2.1 Report

### Table 1: Success Criteria, Level A

| Criteria | Conformance Level | Remarks and Explanations |
|----------|-------------------|--------------------------|
| **1.1.1 Non-text Content** | Supports | All meaningful images have descriptive `alt` text. Page preview images in the template builder and submission viewer include `alt="Page N of M"`. Signature/initials canvas elements have `aria-label`. Decorative icons use `aria-hidden="true"`. PDF pages also expose extracted text content via a screen-reader-only region and a user-selectable Text View tab. |
| **1.2.1 Audio-only and Video-only (Prerecorded)** | Not Applicable | The product does not include prerecorded audio-only or video-only content. |
| **1.2.2 Captions (Prerecorded)** | Not Applicable | The product does not include prerecorded synchronized media. |
| **1.2.3 Audio Description or Media Alternative (Prerecorded)** | Not Applicable | The product does not include prerecorded video content. |
| **1.3.1 Info and Relationships** | Supports | Form controls have programmatically associated labels via `<label for>` or `aria-label`. Data tables include `<caption class="sr-only">` and `scope="col"` on column headers. Radio button groups are wrapped in `<fieldset>/<legend>`. Navigation regions use semantic `<nav aria-label>`. Headings establish logical document hierarchy. |
| **1.3.2 Meaningful Sequence** | Supports | Content is presented in a logical reading order in the DOM. Visual positioning achieved with CSS does not reorder the DOM sequence. |
| **1.3.3 Sensory Characteristics** | Supports | Instructions do not rely solely on shape, color, size, or spatial location. Field types are identified by name and icon label. Active navigation states use both color and `aria-current="page"`. |
| **1.4.1 Use of Color** | Supports | Color is not the sole means of conveying information. Active pagination pages use `aria-current="page"`. Toggle buttons use `aria-pressed`. Required fields are marked with both an asterisk and `required` attribute. |
| **1.4.2 Audio Control** | Not Applicable | The product does not play audio automatically. |
| **2.1.1 Keyboard** | Supports | All functionality is operable via keyboard. The drag-and-drop template builder includes keyboard-accessible alternatives: default field items in the field list accept Enter/Space to place a field; field type buttons detect keyboard activation and insert fields without requiring a drag gesture. Context menus on placed field areas are triggerable via ContextMenu key or Shift+F10. Settings dropdowns open on keyboard focus and close on Escape. The signing form step navigation, signature drawing, and all form controls are keyboard accessible. File upload areas expose a keyboard-accessible `<input type="file">`. |
| **2.1.2 No Keyboard Trap** | Supports | Modal dialogs implement a focus trap that keeps focus within the dialog. The Tab and Shift+Tab cycle within the open modal. Focus is returned to the triggering element on close. Drawers and dropdowns close on Escape without trapping focus. |
| **2.1.4 Character Key Shortcuts** | Not Applicable | The product does not implement single-character keyboard shortcuts that could conflict with AT. |
| **2.2.1 Timing Adjustable** | Not Applicable | The product does not impose time limits on user tasks. |
| **2.2.2 Pause, Stop, Hide** | Not Applicable | The product does not use moving, blinking, scrolling, or auto-updating content that is not user-initiated. |
| **2.3.1 Three Flashes or Below Threshold** | Supports | The product does not contain content that flashes more than three times per second. |
| **2.4.1 Bypass Blocks** | Supports | A skip navigation link is provided on both the main application layout and the public signing form layout, allowing keyboard users to bypass repeated navigation and jump directly to main content. |
| **2.4.2 Page Titled** | Supports | All pages have descriptive `<title>` elements that identify the current page and product name. |
| **2.4.3 Focus Order** | Supports | Focusable components receive focus in a sequence that preserves meaning and operability. Modal dialogs move focus to the first focusable element on open. After step transitions in the signing form, focus is managed to the relevant content area. |
| **2.4.4 Link Purpose (In Context)** | Supports | Links and buttons have descriptive labels accessible to assistive technology. Icon-only buttons include `aria-label`. Navigation links are self-describing. Folder card links include `aria-label` with the folder name. |
| **2.5.1 Pointer Gestures** | Supports | Operations that require dragging (template builder field placement) have single-pointer keyboard alternatives. The file upload drag-and-drop zone exposes a keyboard-accessible file input. |
| **2.5.2 Pointer Cancellation** | Supports | Click-based actions activate on the up-event (mouseup/pointerup), allowing users to cancel by moving the pointer off before releasing. |
| **2.5.3 Label in Name** | Supports | Visible text labels of interactive controls are included in or matched by their accessible names. |
| **2.5.4 Motion Actuation** | Not Applicable | The product does not use device motion or user motion as the sole input mechanism. |
| **3.1.1 Language of Page** | Supports | The `<html lang>` attribute is set to the active locale on all pages. |
| **3.2.1 On Focus** | Supports | Receiving focus does not trigger unexpected context changes. |
| **3.2.2 On Input** | Supports | Changing form control values does not trigger unexpected context changes without prior notice. |
| **3.3.1 Error Identification** | Supports | Input errors are identified and described to the user. Form validation errors use `role="alert"` live regions that announce to screen readers without moving visual focus. Error messages include a text description of the problem. Signature and initials errors are linked to the canvas via `aria-errormessage` and `aria-invalid`. |
| **3.3.2 Labels or Instructions** | Supports | All form controls have labels or instructions. Required fields are marked. Date format instructions are provided where applicable. |
| **4.1.1 Parsing** | Supports | HTML output does not contain duplicate `id` attributes on focusable elements. Markup is well-formed. ARIA usage follows the ARIA specification for allowed roles and properties. |
| **4.1.2 Name, Role, Value** | Supports | All user interface components have appropriate name, role, and value exposed to assistive technology. Custom interactive elements (DaisyUI collapsibles, dropdown triggers, progress dots, toggle view buttons) expose correct ARIA states (`aria-expanded`, `aria-pressed`, `aria-current`, `aria-selected`). `<a href="#">` elements acting as buttons have been converted to `<button type="button">`. |

---

### Table 2: Success Criteria, Level AA

| Criteria | Conformance Level | Remarks and Explanations |
|----------|-------------------|--------------------------|
| **1.2.4 Captions (Live)** | Not Applicable | The product does not include live synchronized media. |
| **1.2.5 Audio Description (Prerecorded)** | Not Applicable | The product does not include prerecorded video content. |
| **1.3.4 Orientation** | Supports | Content is not restricted to a single display orientation. The signing form and template builder function in both portrait and landscape orientations. |
| **1.3.5 Identify Input Purpose** | Partially Supports | Standard user data fields (name, email, phone) in user profile and account settings include `autocomplete` attributes. Form fields in document templates are user-defined and vary by document; autocomplete attributes for arbitrary template fields are not provided. |
| **1.4.3 Contrast (Minimum)** | Partially Supports | Text contrast has been improved across the product: placeholder text colors updated from gray-300/400 to gray-600 (meeting 4.5:1 minimum), white-label text corrected. The DaisyUI default theme is used for most UI chrome; some DaisyUI theme colors (badge backgrounds, subtle backgrounds) have not been individually audited against all possible custom themes. Users who configure custom themes are responsible for ensuring contrast in their deployments. |
| **1.4.4 Resize Text** | Supports | The viewport meta tag no longer disables user zoom (`user-scalable=no` has been removed). Text can be resized up to 200% using browser zoom without loss of content or functionality. |
| **1.4.5 Images of Text** | Partially Supports | PDF documents are rendered as images for visual fidelity. A "Text View" tab is provided in both the template builder and the signing form viewer, presenting the same content as formatted HTML (when text extraction is available). Scanned/image-only PDFs do not have extracted text and rely solely on the image rendering. |
| **1.4.10 Reflow** | Supports | The application is responsive and content reflows at narrow viewports (320px CSS width) without horizontal scrolling for most views. The template builder PDF canvas is inherently two-dimensional and requires horizontal scrolling at small viewports, which is an essential exception. |
| **1.4.11 Non-text Contrast** | Partially Supports | Interactive component boundaries (input borders, button outlines, focus rings) have been improved. Focus ring styles (`focus:ring-2`) are applied to previously deficient inputs. Some DaisyUI default component borders (e.g., subtle card borders) may not reach 3:1 against adjacent backgrounds in all themes and have not been fully audited. |
| **1.4.12 Text Spacing** | Supports | No CSS declarations use `!important` to override letter-spacing, word-spacing, line-height, or spacing following paragraphs. Content remains readable when these properties are adjusted by user stylesheets. |
| **1.4.13 Content on Hover or Focus** | Supports | Tooltip and dropdown content triggered by hover or focus: (1) remains visible while the pointer hovers over it, (2) can be dismissed with Escape without moving focus, and (3) does not disappear when the pointer moves to the triggered content. |
| **2.4.5 Multiple Ways** | Supports | Users can reach content through navigation menus, search (on template/submission lists), breadcrumb trails (on folder views), and direct URL access. |
| **2.4.6 Headings and Labels** | Supports | Pages use a logical heading hierarchy. Form labels describe the purpose of the corresponding input. Settings sections use heading markup. |
| **2.4.7 Focus Visible** | Supports | All focusable elements display a visible focus indicator. Previously removed focus rings (`outline-none focus:ring-0`) have been replaced with `focus:ring-2` variants across the product. |
| **2.5.3 Label in Name** | Supports | (Repeated from Level A for completeness.) Visible labels match or are contained within accessible names. |
| **3.1.2 Language of Parts** | Partially Supports | The UI language is set via the `lang` attribute on `<html>`. User-supplied document content (PDF text, field values) may be in a different language than the UI and does not have per-element `lang` markup. The Text View panel includes `dir="auto"` on paragraph elements to handle right-to-left text direction automatically. |
| **3.2.3 Consistent Navigation** | Supports | Navigation mechanisms (top navbar, settings sidebar, breadcrumbs) appear in the same relative order across pages. |
| **3.2.4 Consistent Identification** | Supports | Components that have the same functionality are identified consistently throughout the product (e.g., the "Delete" action always uses the same icon and label). |
| **3.3.3 Error Suggestion** | Supports | When input errors are detected, suggestions for correction are provided where applicable. Signature validation errors describe what is required ("Signature is required"). Phone number validation errors describe the expected format. |
| **3.3.4 Error Prevention (Legal, Financial, Binding)** | Supports | Document submission (signing) requires explicit confirmation of intent. Users can review their input across all form steps before final submission. The decline document action is presented with a confirmation modal. |
| **4.1.3 Status Messages** | Supports | Status messages are conveyed to assistive technology without requiring focus. Success and error notifications use `aria-live` regions (`role="alert"` for errors, `aria-live="polite"` for status). Flash messages include `role="alert"` or `role="status"` with `aria-live` and `aria-atomic`. Template builder field add/remove operations announce via polite live regions. File operation success/error messages are announced via `announcePolite()` / `announceError()` utilities. |

---

## Known Limitations and Residual Risks

The following items are known to be partially addressed or deferred:

1. **Scanned / image-only PDFs**: PDFs without extractable text cannot provide a Text View. The page image `alt` text describes the page number only. A future OCR integration would address this gap.

2. **Custom DaisyUI themes**: Organizations deploying DocuSeal with custom Tailwind/DaisyUI themes are responsible for verifying color contrast ratios in their specific theme configuration.

3. **Template builder — arrow-key nudging**: While keyboard users can place fields (8-A), fine positioning via arrow-key nudging of placed field areas has not been implemented. Fields placed via keyboard land at a default position and must be repositioned via the settings inputs.

4. **Country code combobox (phone step)**: The phone number entry uses a native `<select>` element for country code with `aria-label="Country code"`. A custom combobox with search-by-country-name would provide a better experience but has not been implemented.

5. **Autocomplete on template form fields**: WCAG 1.3.5 autocomplete tokens apply to fields collecting personal information. Template-based form fields have user-defined names and may not map predictably to standard `autocomplete` token values.

6. **1.4.5 Images of Text — scanned PDFs**: The Text View tab is only shown when full text extraction succeeds for all documents in a submission. Submissions containing scanned PDFs do not display the Text View tab.

---

## Evaluation Methods

This conformance report is based on the following evaluation methods:

- **Manual code review**: All modified files were reviewed against WCAG 2.1 success criteria. ARIA usage was verified against the ARIA Authoring Practices Guide (APG).
- **Keyboard-only navigation**: The full user workflow (login → template list → template builder → signing form → submission review) was traced for keyboard operability.
- **Static analysis**: HTML structure, ARIA attribute correctness, and label associations were reviewed in source code.
- **Screen reader spot-checks**: Selected interactions (modal focus, live region announcements, progress dots) were verified against expected AT behavior.

Automated testing using `axe-core` via RSpec (`axe-core-rspec`) infrastructure has been provisioned in `spec/accessibility/` but a full automated sweep is recommended before claiming full AA conformance.

---

## Legal Disclaimer

This document is provided for informational purposes and represents the best knowledge of the evaluation team at the time of publication. This is not a legal certification of accessibility conformance. Organizations requiring formal compliance assessment should engage an independent accessibility audit firm. The VPAT® format is a registered trademark of the Information Technology Industry Council (ITI).

---

*VPAT® is a registered trademark of the Information Technology Industry Council (ITI). This template does not represent ITI's endorsement of the product.*

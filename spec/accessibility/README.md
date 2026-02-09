# Accessibility Testing Framework

This directory contains accessibility (a11y) tests for DocuSeal, targeting **WCAG 2.2 Level AA compliance**.

## Overview

The accessibility testing framework uses:
- **RSpec** for test structure
- **Capybara** with **Cuprite** (headless Chrome) for browser automation
- **axe-core-rspec** for automated WCAG validation
- **Custom accessibility helpers** in `spec/support/accessibility_helpers.rb`

## Running Tests

```bash
# Run all accessibility tests
bundle exec rspec spec/accessibility/

# Run specific accessibility test file
bundle exec rspec spec/accessibility/layouts_spec.rb

# Run with visible browser for debugging
HEADLESS=false bundle exec rspec spec/accessibility/

# Run with coverage report
COVERAGE=true bundle exec rspec spec/accessibility/
```

## Test Categories

### Phase 1: Critical Barriers
- **layouts_spec.rb** - Semantic landmarks, skip navigation
- **images_spec.rb** - Alt text for images
- **buttons_spec.rb** - ARIA labels for icon buttons
- **keyboard_spec.rb** - Keyboard support for custom elements

### Phase 2: Forms & Input Accessibility
- **forms_spec.rb** - Form error associations, labels
- **modals_spec.rb** - Modal accessibility, focus traps
- **live_regions_spec.rb** - ARIA live announcements

### Phase 3: Complex Interactions
- **components_spec.rb** - Vue component accessibility
- **tables_spec.rb** - Table headers, captions, scope

### Phase 4: Comprehensive Coverage
- **wcag_compliance_spec.rb** - Full WCAG 2.2 AA validation with axe-core

## Custom Helpers

### Available Test Helpers

```ruby
# Check accessible names
expect_accessible_name('button.save', 'Save Document')

# Check all images have alt text
expect_images_have_alt_text

# Check form inputs are labeled
expect_form_inputs_labeled

# Check keyboard accessibility
expect_keyboard_accessible('button.custom')

# Check semantic landmarks
expect_semantic_landmarks

# Check buttons have names
expect_buttons_have_names

# Check error associations
expect_errors_associated_with_inputs('email_field', 'email_error')

# Check modal accessibility
expect_accessible_modal('#my-modal')

# Check focus trap
expect_focus_trap('#my-modal')

# Check skip navigation
expect_skip_navigation_link
```

## WCAG 2.2 Level AA Criteria

Our testing targets these success criteria:

### Level A
- **1.1.1** Non-text Content
- **1.3.1** Info and Relationships
- **2.1.1** Keyboard
- **2.1.2** No Keyboard Trap
- **2.4.1** Bypass Blocks
- **2.4.3** Focus Order
- **3.3.1** Error Identification
- **3.3.2** Labels or Instructions
- **4.1.2** Name, Role, Value

### Level AA
- **1.4.3** Contrast (Minimum)
- **2.4.6** Headings and Labels
- **2.4.7** Focus Visible
- **3.2.4** Consistent Identification
- **4.1.3** Status Messages

## Manual Testing

Automated tests catch most issues, but manual testing is required for:

### Screen Reader Testing
- **NVDA** (Windows) - Free, open-source
- **JAWS** (Windows) - Industry standard, paid
- **VoiceOver** (Mac/iOS) - Built-in

Test these flows:
1. Navigate the app with Tab/Shift+Tab only
2. Fill out and submit forms
3. Open and close modals
4. Upload files via file dropzone
5. Complete document signing flow

### Keyboard Navigation
Test all interactions with:
- **Tab** / **Shift+Tab** - Move focus
- **Enter** / **Space** - Activate buttons/links
- **Escape** - Close modals
- **Arrow keys** - Navigate lists/dropdowns

### Browser Zoom
- Test at 200% zoom level
- Verify no content is cut off
- Check mobile responsiveness

### Color Contrast
- Use browser DevTools color picker
- Verify 4.5:1 ratio for normal text
- Verify 3:1 ratio for large text (18pt+)

## Validation Tools

### Browser Extensions
- **axe DevTools** - Comprehensive WCAG auditing
- **WAVE** - Visual accessibility checker
- **Lighthouse** - Chrome DevTools built-in

### Command-Line Tools
```bash
# Run Lighthouse accessibility audit
lighthouse http://localhost:3000 --only-categories=accessibility

# Run axe-core via CLI
npx @axe-core/cli http://localhost:3000
```

## CI/CD Integration

Add to your CI pipeline:

```yaml
# .github/workflows/accessibility.yml
name: Accessibility Tests

on: [push, pull_request]

jobs:
  a11y:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run accessibility tests
        run: |
          bundle install
          bundle exec rspec spec/accessibility/
```

## Reporting Issues

When accessibility issues are found:

1. **Severity**: Critical, High, Medium, Low
2. **WCAG Criterion**: Which success criterion is violated
3. **User Impact**: Which disability groups are affected
4. **Location**: File path and line number
5. **Recommendation**: Specific fix with code example

## Resources

- [WCAG 2.2 Guidelines](https://www.w3.org/WAI/WCAG22/quickref/)
- [axe-core Rules](https://github.com/dequelabs/axe-core/blob/develop/doc/rule-descriptions.md)
- [A11Y Project Checklist](https://www.a11yproject.com/checklist/)
- [WebAIM Screen Reader Testing](https://webaim.org/articles/screenreader_testing/)

## Contributing

When adding new features:
1. Write accessibility tests alongside feature tests
2. Run axe-core audit on new pages/components
3. Test keyboard navigation manually
4. Verify with screen reader if possible
5. Document any accessibility considerations

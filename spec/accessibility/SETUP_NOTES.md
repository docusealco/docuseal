# Accessibility Testing Setup Notes

## Gem Installation Required

The `axe-core-rspec` gem has been added to the Gemfile but requires installation.

### Prerequisites

This project requires **Ruby 4.0.1** (as specified in Gemfile).

Currently, the system Ruby is 2.6.10, which is incompatible. You'll need to:

1. **Install a Ruby version manager** (recommended: rbenv or asdf)

   ```bash
   # Using rbenv
   brew install rbenv ruby-build
   rbenv install 4.0.1
   rbenv local 4.0.1

   # Or using asdf
   brew install asdf
   asdf plugin add ruby
   asdf install ruby 4.0.1
   asdf local ruby 4.0.1
   ```

2. **Install dependencies**

   ```bash
   bundle install
   yarn install
   ```

3. **Run accessibility tests**

   ```bash
   bundle exec rspec spec/accessibility/
   ```

## What's Been Set Up

✅ **Added to Gemfile (test group):**
- `axe-core-rspec` - Automated WCAG 2.2 validation

✅ **Created directory structure:**
- `spec/accessibility/` - Test files for a11y specs
- `spec/support/` - Helper modules

✅ **Created accessibility helpers:**
- `spec/support/accessibility_helpers.rb` - Custom test helpers for WCAG validation
- Methods for checking landmarks, labels, keyboard access, modals, etc.

✅ **Created documentation:**
- `spec/accessibility/README.md` - Comprehensive testing guide
- Covers running tests, manual testing, WCAG criteria, and resources

## Using axe-core-rspec

Once the gem is installed, you can use it in your tests:

```ruby
# spec/accessibility/wcag_compliance_spec.rb
RSpec.describe 'WCAG Compliance', type: :system do
  it 'passes axe audit on home page' do
    visit root_path
    expect(page).to be_axe_clean
  end

  it 'passes WCAG 2.2 AA on submissions page' do
    visit submissions_path
    expect(page).to be_axe_clean.according_to(:wcag2aa, :wcag22aa)
  end

  it 'passes specific tag checks' do
    visit template_path
    expect(page).to be_axe_clean
      .excluding('.legacy-component')
      .according_to(:wcag2aa)
  end
end
```

## Next Steps

After bundle install completes, the testing infrastructure will be fully operational and ready for Phase 1 fixes.

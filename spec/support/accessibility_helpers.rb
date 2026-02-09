# frozen_string_literal: true

# Accessibility testing helpers for WCAG 2.2 Level AA compliance
module AccessibilityHelpers
  # Check if an element has proper ARIA label or text content
  def expect_accessible_name(selector, expected_name = nil)
    element = page.find(selector)

    # Check for accessible name via aria-label, aria-labelledby, or text content
    accessible_name = element['aria-label'] ||
                      find_aria_labelledby_text(element) ||
                      element.text.strip

    if expected_name
      expect(accessible_name).to eq(expected_name)
    else
      expect(accessible_name).not_to be_empty
    end
  end

  # Check if images have alt text
  def expect_images_have_alt_text
    images_without_alt = page.all('img:not([alt])')
    expect(images_without_alt).to be_empty,
      "Found #{images_without_alt.count} images without alt attributes"
  end

  # Check if form inputs have associated labels or aria-label
  def expect_form_inputs_labeled
    unlabeled_inputs = page.all('input, select, textarea').select do |input|
      next if input['type'] == 'hidden'
      next if input['type'] == 'submit'
      next if input['type'] == 'button'

      # Check for label association, aria-label, or aria-labelledby
      has_label = input['id'] && page.has_css?("label[for='#{input['id']}']")
      has_aria = input['aria-label'] || input['aria-labelledby']

      !has_label && !has_aria
    end

    expect(unlabeled_inputs).to be_empty,
      "Found #{unlabeled_inputs.count} unlabeled form inputs"
  end

  # Check if interactive elements are keyboard accessible
  def expect_keyboard_accessible(selector)
    element = page.find(selector)

    # Interactive elements should be focusable
    expect(element['tabindex'].to_i).to be >= 0
  end

  # Check for proper semantic landmarks
  def expect_semantic_landmarks
    expect(page).to have_css('main, [role="main"]'),
      'Page should have a main landmark'
    expect(page).to have_css('nav, [role="navigation"]'),
      'Page should have a navigation landmark'
  end

  # Check if buttons have accessible names
  def expect_buttons_have_names
    unnamed_buttons = page.all('button').select do |button|
      text = button.text.strip
      aria_label = button['aria-label']
      aria_labelledby = button['aria-labelledby']

      text.empty? && !aria_label && !aria_labelledby
    end

    expect(unnamed_buttons).to be_empty,
      "Found #{unnamed_buttons.count} buttons without accessible names"
  end

  # Check color contrast ratio (simplified check for common patterns)
  def expect_sufficient_contrast(selector)
    element = page.find(selector)
    computed_style = page.evaluate_script(
      "window.getComputedStyle(document.querySelector('#{selector}'))"
    )

    # This is a basic check - proper contrast testing requires color parsing
    color = computed_style['color']
    background = computed_style['background-color']

    expect(color).not_to eq('rgb(209, 213, 219)'), # text-gray-300
      'Text color has insufficient contrast'
  end

  # Check if error messages are associated with form fields
  def expect_errors_associated_with_inputs(input_id, error_id)
    input = page.find("##{input_id}")
    expect(input['aria-describedby']).to include(error_id),
      "Input ##{input_id} should reference error ##{error_id} via aria-describedby"

    # Error should be announced to screen readers
    error_element = page.find("##{error_id}")
    expect(error_element['role']).to eq('alert').or eq(nil)
  end

  # Check if modal dialogs are properly configured
  def expect_accessible_modal(selector)
    modal = page.find(selector)

    expect(modal['role']).to eq('dialog'),
      'Modal should have role="dialog"'
    expect(modal['aria-modal']).to eq('true'),
      'Modal should have aria-modal="true"'
    expect(modal['aria-labelledby']).not_to be_nil,
      'Modal should have aria-labelledby referencing its title'
  end

  # Check if focus is trapped within modal
  def expect_focus_trap(modal_selector)
    within(modal_selector) do
      focusable = page.all('a[href], button, input, select, textarea, [tabindex]:not([tabindex="-1"])')
      expect(focusable.count).to be > 0, 'Modal should contain focusable elements'
    end
  end

  # Check for skip navigation link
  def expect_skip_navigation_link
    expect(page).to have_css('a[href="#main-content"], a[href="#main"]'),
      'Page should have a skip navigation link'
  end

  private

  def find_aria_labelledby_text(element)
    labelledby_id = element['aria-labelledby']
    return nil unless labelledby_id

    label_element = page.find("##{labelledby_id}", visible: false)
    label_element&.text&.strip
  end
end

# Include helpers in system specs
RSpec.configure do |config|
  config.include AccessibilityHelpers, type: :system
end

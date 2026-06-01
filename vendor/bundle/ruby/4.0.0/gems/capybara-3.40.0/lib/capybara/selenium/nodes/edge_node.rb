# frozen_string_literal: true

require 'capybara/selenium/extensions/html5_drag'

class Capybara::Selenium::EdgeNode < Capybara::Selenium::Node
  include Html5Drag

  def set_text(value, clear: nil, **_unused)
    return super unless chrome_edge?

    super.tap do
      # React doesn't see the chromedriver element clear
      send_keys(:space, :backspace) if value.to_s.empty? && clear.nil?
    end
  end

  def set_file(value) # rubocop:disable Naming/AccessorMethodName
    # In Chrome 75+ files are appended (due to WebDriver spec - why?) so we have to clear here if its multiple and already set
    if chrome_edge?
      driver.execute_script(<<~JS, self)
        if (arguments[0].multiple && arguments[0].files.length){
          arguments[0].value = null;
        }
      JS
    end
    super
  end

  def drop(*args)
    return super unless chrome_edge?

    html5_drop(*args)
  end

  def click(*, **)
    super
  rescue Selenium::WebDriver::Error::InvalidArgumentError => e
    tag_name, type = attrs(:tagName, :type).map { |val| val&.downcase }
    if tag_name == 'input' && type == 'file'
      raise Selenium::WebDriver::Error::InvalidArgumentError, "EdgeChrome can't click on file inputs.\n#{e.message}"
    end

    raise
  end

  def disabled?
    return super unless chrome_edge?

    driver.evaluate_script("arguments[0].matches(':disabled, select:disabled *')", self)
  end

  def select_option
    return super unless chrome_edge?

    # To optimize to only one check and then click
    selected_or_disabled = driver.evaluate_script(<<~JS, self)
      arguments[0].matches(':disabled, select:disabled *, :checked')
    JS
    click unless selected_or_disabled
  end

  def visible?
    return super unless chrome_edge? && native_displayed?

    begin
      bridge.send(:execute, :is_element_displayed, id: native_id)
    rescue Selenium::WebDriver::Error::UnknownCommandError
      # If the is_element_displayed command is unknown, no point in trying again
      driver.options[:native_displayed] = false
      super
    end
  end

  def send_keys(*args)
    args.chunk { |inp| inp.is_a?(String) && inp.match?(/\p{Emoji Presentation}/) }
        .each do |contains_emoji, inputs|
      if contains_emoji
        inputs.join.grapheme_clusters.chunk { |gc| gc.match?(/\p{Emoji Presentation}/) }
              .each do |emoji, clusters|
          if emoji
            driver.send(:execute_cdp, 'Input.insertText', text: clusters.join)
          else
            super(clusters.join)
          end
        end
      else
        super(*inputs)
      end
    end
  end

private

  def browser_version
    @browser_version ||= begin
      caps = driver.browser.capabilities
      (caps[:browser_version] || caps[:version]).to_f
    end
  end

  def chrome_edge?
    browser_version >= 75
  end

  def native_displayed?
    (driver.options[:native_displayed] != false) &&
      # chromedriver_supports_displayed_endpoint? &&
      (!ENV['DISABLE_CAPYBARA_SELENIUM_OPTIMIZATIONS'])
  end
end

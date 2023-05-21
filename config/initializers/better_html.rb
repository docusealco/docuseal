# frozen_string_literal: true

ActionView::Helpers.include(BetterHtml::Helpers)

if defined?(BetterHtml)
  BetterHtml.configure do |config|
    config.template_exclusion_filter = ->(filename) { filename.include?('/gems/') }
  end
end

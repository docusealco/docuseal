# frozen_string_literal: true

require_relative 'support/a_lambda' # inheritable

class Pagy
  module NumericHelpers
    # Return the enabled/disabled previous page anchor tag
    def previous_tag(...) = anchor_tag_for(:previous, ...)
  end

  # Return the enabled/disabled next page anchor tag
  def next_tag(...) = anchor_tag_for(:next, ...)

  private

  def anchor_tag_for(which, a = nil, text: I18n.translate("pagy.#{which}"),
                     aria_label: I18n.translate("pagy.aria_label.#{which}"), **)
    page = send(which)
    return %(<a role="link" aria-disabled="true" aria-label="#{aria_label}">#{text}</a>) unless page

    (a || a_lambda(**)).(page, text, aria_label:)
  end
end

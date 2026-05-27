# frozen_string_literal: true

require_relative 'support/wrap_series_nav'

class Pagy
  module NumericHelpers
    # Return the HTML with the series of links to the pages
    def series_nav(style = nil, **)
      return send(:"#{style}_series_nav", **) if style && style.to_s != 'pagy'

      a_lambda = a_lambda(**)

      html = previous_tag(a_lambda)
      series(**).each do |item|   # series example: [1, :gap, 7, 8, "9", 10, 11, :gap, 36]
        html << case item
                when Integer
                  a_lambda.(item)
                when String
                  %(<a role="link" aria-disabled="true" aria-current="page">#{page_label(item)}</a>)
                when :gap
                  %(<a role="separator" aria-disabled="true">#{I18n.translate('pagy.gap')}</a>)
                else
                  raise InternalError, "expected item types in series to be Integer, String or :gap; got #{item.inspect}"
                end
      end
      html << next_tag(a_lambda)

      wrap_series_nav(html, 'pagy series-nav', **)
    end
  end
end

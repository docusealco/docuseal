# frozen_string_literal: true

require_relative 'previous_next_html'
require_relative '../support/wrap_series_nav'

class Pagy
  module NumericHelpers
    private

    # Pagination for bootstrap: it returns the html with the series of links to the pages
    def bootstrap_series_nav(classes: 'pagination', **)
      a_lambda = a_lambda(**)

      html = %(<ul class="#{classes}">#{bootstrap_html_for(:previous, a_lambda)})
      series(**).each do |item| # series example: [1, :gap, 7, 8, "9", 10, 11, :gap, 36]
        html << case item
                when Integer
                  %(<li class="page-item">#{a_lambda.(item, classes: 'page-link')}</li>)
                when String
                  %(<li class="page-item active"><a role="link" class="page-link" aria-current="page" aria-disabled="true">#{
                      page_label(item)}</a></li>)
                when :gap
                  %(<li class="page-item gap disabled"><a role="link" class="page-link" aria-disabled="true">#{
                    I18n.translate('pagy.gap')}</a></li>)
                else raise InternalError, "expected item types in series to be Integer, String or :gap; got #{item.inspect}"
                end
      end
      html << %(#{bootstrap_html_for(:next, a_lambda)}</ul>)

      wrap_series_nav(html, 'pagy-bootstrap series-nav', **)
    end
  end
end

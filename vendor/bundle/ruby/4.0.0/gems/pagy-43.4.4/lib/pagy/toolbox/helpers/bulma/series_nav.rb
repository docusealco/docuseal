# frozen_string_literal: true

require_relative 'previous_next_html'
require_relative '../support/wrap_series_nav'

class Pagy
  module NumericHelpers
    private

    # Pagination for bulma: it returns the html with the series of links to the pages
    def bulma_series_nav(classes: 'pagination', **)
      a_lambda = a_lambda(**)

      html = %(<ul class="pagination-list">#{bulma_html_for(:previous, a_lambda)})
      series(**).each do |item| # series example: [1, :gap, 7, 8, "9", 10, 11, :gap, 36]
        html << case item
                when Integer
                  %(<li>#{a_lambda.(item, page_label(item), classes: 'pagination-link')}</li>)
                when String
                  %(<li><a role="link" class="pagination-link is-current" aria-current="page" aria-disabled="true">#{
                    page_label(item)}</a></li>)
                when :gap
                  %(<li><span class="pagination-ellipsis">#{I18n.translate('pagy.gap')}</span></li>)
                else raise InternalError, "expected item types in series to be Integer, String or :gap; got #{item.inspect}"
                end
      end
      html << %(#{bulma_html_for(:next, a_lambda)}</ul>)

      wrap_series_nav(html, "pagy-bulma series-nav #{classes}", **)
    end
  end
end

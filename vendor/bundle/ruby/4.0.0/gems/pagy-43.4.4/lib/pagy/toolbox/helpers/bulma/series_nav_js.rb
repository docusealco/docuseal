# frozen_string_literal: true

require_relative 'previous_next_html'
require_relative '../support/wrap_series_nav_js'

class Pagy
  module NumericHelpers
    private

    # Javascript pagination for bulma: it returns a nav with a data-pagy attribute used by the Pagy.nav javascript
    def bulma_series_nav_js(classes: 'pagination', **)
      a_lambda = a_lambda(**)

      tokens   = { before:  %(<ul class="pagination-list">#{bulma_html_for(:previous, a_lambda)}),
                   anchor:  %(<li>#{a_lambda.(PAGE_TOKEN, LABEL_TOKEN, classes: 'pagination-link')}</li>),
                   current: %(<li><a role="link" class="pagination-link is-current" ) +
                            %(aria-current="page" aria-disabled="true">#{LABEL_TOKEN}</a></li>),
                   gap:     %(<li><span class="pagination-ellipsis">#{I18n.translate('pagy.gap')}</span></li>),
                   after:   %(#{bulma_html_for(:next, a_lambda)}</ul>) }

      wrap_series_nav_js(tokens, "pagy-bulma series-nav-js #{classes}", **)
    end
  end
end

# frozen_string_literal: true

require_relative 'previous_next_html'
require_relative '../support/wrap_series_nav_js'

class Pagy
  module NumericHelpers
    private

    # Javascript pagination for bootstrap: it returns a nav with a data-pagy attribute used by the pagy.js file
    def bootstrap_series_nav_js(classes: 'pagination', **)
      a_lambda = a_lambda(**)

      tokens   = { before:  %(<ul class="#{classes}">#{bootstrap_html_for(:previous, a_lambda)}),
                   anchor:  %(<li class="page-item">#{a_lambda.(PAGE_TOKEN, LABEL_TOKEN, classes: 'page-link')}</li>),
                   current: %(<li class="page-item active"><a role="link" class="page-link" ) +
                            %(aria-current="page" aria-disabled="true">#{LABEL_TOKEN}</a></li>),
                   gap:     %(<li class="page-item gap disabled"><a role="link" class="page-link" aria-disabled="true">#{
                              I18n.translate('pagy.gap')}</a></li>),
                   after:   %(#{bootstrap_html_for(:next, a_lambda)}</ul>) }

      wrap_series_nav_js(tokens, 'pagy-bootstrap series-nav-js', **)
    end
  end
end

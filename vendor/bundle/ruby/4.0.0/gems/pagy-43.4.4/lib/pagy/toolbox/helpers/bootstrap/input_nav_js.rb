# frozen_string_literal: true

require_relative 'previous_next_html'
require_relative '../support/wrap_input_nav_js'

class Pagy
  module NumericHelpers
    private

    # Javascript combo pagination for bootstrap: it returns a nav with a data-pagy attribute used by the pagy.js file
    def bootstrap_input_nav_js(classes: 'pagination', **)
      a_lambda = a_lambda(**)

      input    = %(<input name="page" type="number" min="1" max="#{last}" value="#{@page}" aria-current="page" ) +
                 %(style="text-align: center; width: #{@page.to_s.length + 1}rem; padding: 0; border-radius: .25rem; ) +
                 %(border: none; display: inline-block;" class="page-link active">#{A_TAG})

      html     = %(<ul class="#{classes}">#{
                   bootstrap_html_for(:previous, a_lambda)
                   }<li class="page-item"><label class="page-link">#{
                   I18n.translate('pagy.input_nav_js', page_input: input, pages: @last)
                   }</label></li>#{
                   bootstrap_html_for(:next, a_lambda)
                   }</ul>)

      wrap_input_nav_js(html, 'pagy-bootstrap input-nav-js', **)
    end
  end
end

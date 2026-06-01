# frozen_string_literal: true

require_relative 'previous_next_html'
require_relative '../support/wrap_input_nav_js'

class Pagy
  module NumericHelpers
    private

    # Javascript combo pagination for bulma: it returns a nav with a data-pagy attribute used by the pagy.js file
    def bulma_input_nav_js(classes: 'pagination', **)
      a_lambda = a_lambda(**)

      input    = %(<input name="page" type="number" min="1" max="#{@last}" value="#{@page}" aria-current="page") +
                 %(style="text-align: center; width: #{@page.to_s.length + 1}rem; line-height: 1.2rem; ) +
                 %(border: none; border-radius: .25rem; padding: .0625rem; color: white; ) +
                 %(background-color: #485fc7;">#{A_TAG})

      html     = %(<ul class="pagination-list">#{bulma_html_for(:previous, a_lambda)}<li class="pagination-link"><label>#{
                   I18n.translate('pagy.input_nav_js', page_input: input, pages: @last)
                   }</label></li>#{bulma_html_for(:next, a_lambda)}</ul>)

      wrap_input_nav_js(html, "pagy-bulma input-nav-js #{classes}", **)
    end
  end
end

# frozen_string_literal: true

require_relative 'support/wrap_input_nav_js'

class Pagy
  module NumericHelpers
    # JavaScript input pagination: it returns a nav with a data-pagy attribute used by the pagy.js file
    def input_nav_js(style = nil, **)
      return send(:"#{style}_input_nav_js", **) if style && style.to_s != 'pagy'

      a_lambda = a_lambda(**)

      input = %(<input name="page" type="number" min="1" max="#{@last}" value="#{@page}" aria-current="page" ) +
              %(style="text-align: center; width: #{@page.to_s.length + 1}rem; padding: 0;">#{A_TAG})

      html  = %(#{previous_tag(a_lambda)}<label>#{
                I18n.translate('pagy.input_nav_js', page_input: input, pages: @last)}</label>#{
                next_tag(a_lambda)})

      wrap_input_nav_js(html, 'pagy input-nav-js', **)
    end
  end
end

# frozen_string_literal: true

class Pagy
  module NumericHelpers
    private

    # Return the enabled/disabled previous/next page anchor tag
    def bulma_html_for(which, a_lambda)
      %(<li>#{
        if send(which)
          a_lambda.(send(which), I18n.translate("pagy.#{which}"),
                    classes:    "pagination-#{which}",
                    aria_label: I18n.translate("pagy.aria_label.#{which}"))
        else
          %(<a role="link" class="pagination-#{which}" disabled aria-disabled="true" aria-label="#{
          I18n.translate("pagy.aria_label.#{which}")}">#{I18n.translate("pagy.#{which}")}</a>)
        end
        }</li>)
    end
  end
end
